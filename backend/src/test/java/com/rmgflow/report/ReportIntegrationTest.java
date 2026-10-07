package com.rmgflow.report;

import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.RoleRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.support.PostgresTestContainerConfig;
import com.rmgflow.support.TestSession;
import com.rmgflow.support.TestUsers;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.resttestclient.TestRestTemplate;
import org.springframework.boot.resttestclient.autoconfigure.AutoConfigureTestRestTemplate;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;

import javax.sql.DataSource;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/** Document 14 reports: catalog, run, CSV/PDF export, per-report RBAC and tenant scoping. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class ReportIntegrationTest {

    private static final List<String> ALL_CODES = List.of("buyer-summary", "inquiry-pipeline", "costing-margin",
            "sample-approval", "order-status", "order-delay", "production-progress", "factory-performance",
            "quality-inspections", "defect-analysis", "shipment-status", "document-expiry", "receivables-payables",
            "order-profitability", "claims-summary");
    private static final List<String> FINANCIAL_CODES = List.of("costing-margin", "receivables-payables", "order-profitability");

    @Autowired
    private TestRestTemplate restTemplate;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private RoleRepository roleRepository;
    @Autowired
    private OrganizationRepository organizationRepository;
    @Autowired
    private PasswordEncoder passwordEncoder;
    @Autowired
    private DataSource dataSource;

    @Test
    void generalManager_listsAndRunsEveryReport_withSeededData() {
        TestSession gm = login("GENERAL_MANAGER");
        Seed seed = seed(gm.organizationId());

        ResponseEntity<List> catalog = get("/api/v1/reports", gm.accessToken(), List.class);
        assertThat(catalog.getStatusCode()).isEqualTo(HttpStatus.OK);
        List<String> codes = ((List<Map<String, Object>>) catalog.getBody()).stream().map(r -> (String) r.get("code")).toList();
        assertThat(codes).containsExactlyInAnyOrderElementsOf(ALL_CODES);

        for (String code : ALL_CODES) {
            ResponseEntity<Map> result = get("/api/v1/reports/" + code, gm.accessToken(), Map.class);
            assertThat(result.getStatusCode()).as(code).isEqualTo(HttpStatus.OK);
            assertThat((List<?>) result.getBody().get("columns")).as(code).isNotEmpty();
            assertThat((List<?>) result.getBody().get("rows")).as(code + " rows").isNotEmpty();
            assertThat((List<?>) result.getBody().get("summary")).as(code).isNotEmpty();
            assertThat(result.getBody().get("generatedAt")).as(code).isNotNull();
        }

        Map<String, Object> orders = get("/api/v1/reports/order-status?buyerId=" + seed.buyerId() + "&status=IN_PROGRESS",
                gm.accessToken(), Map.class).getBody();
        List<Map<String, Object>> rows = (List<Map<String, Object>>) orders.get("rows");
        assertThat(rows).hasSize(1);
        assertThat(rows.get(0).get("order_no")).isEqualTo(seed.orderNo());
        assertThat(((Number) rows.get(0).get("quantity")).intValue()).isEqualTo(1000);
        assertThat(rows.get(0).get("delivery_date")).isEqualTo(LocalDate.now().plusDays(20).toString());

        // A filter that excludes the seeded order returns no rows, not an error.
        Map<String, Object> filteredOut = get("/api/v1/reports/order-status?status=CLOSED", gm.accessToken(), Map.class).getBody();
        assertThat((List<?>) filteredOut.get("rows")).isEmpty();

        // Profitability: quoted 5.00 vs cost 4.60 -> 8% margin, flagged below the 10% floor.
        Map<String, Object> profit = get("/api/v1/reports/order-profitability", gm.accessToken(), Map.class).getBody();
        Map<String, Object> profitRow = ((List<Map<String, Object>>) profit.get("rows")).get(0);
        assertThat(((Number) profitRow.get("margin_percent")).doubleValue()).isEqualTo(8.0);
        assertThat((List<Map<String, Object>>) profit.get("summary"))
                .anySatisfy(s -> {
                    assertThat(s.get("label")).isEqualTo("Below 10% margin floor");
                    assertThat(((Number) s.get("value")).intValue()).isEqualTo(1);
                });
    }

    @Test
    void export_csvHasBomHeaderAndFilename_pdfIsAPdf() {
        TestSession gm = login("GENERAL_MANAGER");
        Seed seed = seed(gm.organizationId());
        String today = LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE);

        ResponseEntity<byte[]> csv = get("/api/v1/reports/order-status/export?format=csv&buyerId=" + seed.buyerId(),
                gm.accessToken(), byte[].class);
        assertThat(csv.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(csv.getHeaders().getContentType().toString()).startsWith("text/csv");
        assertThat(csv.getHeaders().getFirst(HttpHeaders.CONTENT_DISPOSITION))
                .contains("attachment").contains("order-status-" + today + ".csv");
        byte[] bytes = csv.getBody();
        assertThat(Arrays.copyOf(bytes, 3)).containsExactly((byte) 0xEF, (byte) 0xBB, (byte) 0xBF);
        String text = new String(bytes, 3, bytes.length - 3, StandardCharsets.UTF_8);
        assertThat(text.lines().findFirst().orElseThrow()).startsWith("Order no,Buyer PO,Buyer");
        assertThat(text).contains(seed.orderNo()).contains("Filter,Buyer: Report Buyer");

        ResponseEntity<byte[]> pdf = get("/api/v1/reports/quality-inspections/export?format=pdf&from=2000-01-01",
                gm.accessToken(), byte[].class);
        assertThat(pdf.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(pdf.getHeaders().getContentType().toString()).isEqualTo("application/pdf");
        assertThat(pdf.getHeaders().getFirst(HttpHeaders.CONTENT_DISPOSITION))
                .contains("quality-inspections-" + today + ".pdf");
        assertThat(new String(Arrays.copyOf(pdf.getBody(), 5), StandardCharsets.US_ASCII)).isEqualTo("%PDF-");

        ResponseEntity<byte[]> financialPdf = get("/api/v1/reports/receivables-payables/export?format=pdf",
                gm.accessToken(), byte[].class);
        assertThat(financialPdf.getStatusCode()).isEqualTo(HttpStatus.OK);

        ResponseEntity<String> badFormat = get("/api/v1/reports/order-status/export?format=xlsx", gm.accessToken(), String.class);
        assertThat(badFormat.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void rbac_moduleAndFinancialPermissionsAreEnforced() {
        TestSession sampling = login("SAMPLING_COORDINATOR");
        List<String> samplingCodes = ((List<Map<String, Object>>) get("/api/v1/reports", sampling.accessToken(), List.class).getBody())
                .stream().map(r -> (String) r.get("code")).toList();
        assertThat(samplingCodes).contains("sample-approval", "order-status")
                .doesNotContain("order-profitability", "receivables-payables", "quality-inspections", "inquiry-pipeline");
        assertThat(get("/api/v1/reports/sample-approval", sampling.accessToken(), String.class).getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(get("/api/v1/reports/quality-inspections", sampling.accessToken(), String.class).getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        assertThat(get("/api/v1/reports/order-profitability", sampling.accessToken(), String.class).getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        assertThat(get("/api/v1/reports/order-profitability/export?format=csv", sampling.accessToken(), String.class).getStatusCode())
                .isEqualTo(HttpStatus.FORBIDDEN);

        // Junior merchandiser can view costings but not margins (Doc 5.1).
        TestSession junior = login("JUNIOR_MERCHANDISER");
        assertThat(get("/api/v1/reports/costing-margin", junior.accessToken(), String.class).getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        assertThat(get("/api/v1/reports/order-status", junior.accessToken(), String.class).getStatusCode()).isEqualTo(HttpStatus.OK);

        // Management Viewer: full read of every non-financial report; financial ones only per Owner grant (not by default).
        TestSession viewer = login("MANAGEMENT_VIEWER");
        List<String> viewerCodes = ((List<Map<String, Object>>) get("/api/v1/reports", viewer.accessToken(), List.class).getBody())
                .stream().map(r -> (String) r.get("code")).toList();
        assertThat(viewerCodes).containsExactlyInAnyOrderElementsOf(ALL_CODES.stream()
                .filter(c -> !FINANCIAL_CODES.contains(c)).toList());
        assertThat(get("/api/v1/reports/inquiry-pipeline", viewer.accessToken(), String.class).getStatusCode()).isEqualTo(HttpStatus.OK);
        for (String code : FINANCIAL_CODES) {
            assertThat(get("/api/v1/reports/" + code, viewer.accessToken(), String.class).getStatusCode()).as(code)
                    .isEqualTo(HttpStatus.FORBIDDEN);
            assertThat(get("/api/v1/reports/" + code + "/export?format=csv", viewer.accessToken(), String.class).getStatusCode())
                    .as(code).isEqualTo(HttpStatus.FORBIDDEN);
        }

        assertThat(restTemplate.getForEntity("/api/v1/reports", String.class).getStatusCode()).isIn(HttpStatus.UNAUTHORIZED, HttpStatus.FORBIDDEN);
    }

    @Test
    void reportsAreTenantScoped_andFiltersValidated() {
        TestSession owner = login("OWNER_MD");
        Seed seed = seed(owner.organizationId());
        TestSession otherTenant = login("OWNER_MD");

        Map<String, Object> mine = get("/api/v1/reports/order-status", owner.accessToken(), Map.class).getBody();
        assertThat((List<?>) mine.get("rows")).hasSize(1);
        for (String code : ALL_CODES) {
            Map<String, Object> theirs = get("/api/v1/reports/" + code, otherTenant.accessToken(), Map.class).getBody();
            assertThat((List<?>) theirs.get("rows")).as(code).isEmpty();
        }
        // Filtering by another tenant's buyer id leaks nothing.
        Map<String, Object> probe = get("/api/v1/reports/order-status?buyerId=" + seed.buyerId(), otherTenant.accessToken(), Map.class).getBody();
        assertThat((List<?>) probe.get("rows")).isEmpty();

        assertThat(get("/api/v1/reports/order-status?status=BOGUS", owner.accessToken(), String.class).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(get("/api/v1/reports/order-status?from=31-12-2025", owner.accessToken(), String.class).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(get("/api/v1/reports/order-status?from=2026-02-01&to=2026-01-01", owner.accessToken(), String.class).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(get("/api/v1/reports/no-such-report", owner.accessToken(), String.class).getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void seniorMerchandiser_financialReportScopedToAssignedBuyers() {
        TestSession owner = login("OWNER_MD");
        Long orgId = owner.organizationId();
        Seed a = seed(orgId);
        Seed b = seed(orgId);
        String senior = loginInOrg("SENIOR_MERCHANDISER", orgId);
        assign("senior_merchandiser", orgId, "BUYER", a.buyerId());

        // Financial report (costing margin): only buyer A's costing.
        List<Map<String, Object>> rows = rows(get("/api/v1/reports/costing-margin", senior, Map.class));
        assertThat(rows).extracting(r -> r.get("style_no")).containsExactly(a.styleNo());
        // Non-financial reports are scoped the same way.
        assertThat(rows(get("/api/v1/reports/order-status", senior, Map.class)))
                .extracting(r -> r.get("order_no")).containsExactly(a.orderNo());

        // Explicitly probing buyer B is refused, for both run and export.
        assertThat(get("/api/v1/reports/costing-margin?buyerId=" + b.buyerId(), senior, String.class).getStatusCode())
                .isEqualTo(HttpStatus.FORBIDDEN);
        assertThat(get("/api/v1/reports/costing-margin/export?format=csv&buyerId=" + b.buyerId(), senior, String.class).getStatusCode())
                .isEqualTo(HttpStatus.FORBIDDEN);
        assertThat(rows(get("/api/v1/reports/costing-margin?buyerId=" + a.buyerId(), senior, Map.class))).hasSize(1);

        // Export goes through the same scoped path.
        String csv = new String(get("/api/v1/reports/costing-margin/export?format=csv", senior, byte[].class).getBody(), StandardCharsets.UTF_8);
        assertThat(csv).contains(a.styleNo()).doesNotContain(b.styleNo());

        // The owner still sees both buyers.
        assertThat(rows(get("/api/v1/reports/costing-margin", owner.accessToken(), Map.class))).hasSize(2);

        // A merchandiser with no assignments sees nothing (never "everything").
        String unassigned = loginInOrg("SENIOR_MERCHANDISER", orgId);
        for (String code : List.of("costing-margin", "order-status", "inquiry-pipeline", "buyer-summary")) {
            assertThat(rows(get("/api/v1/reports/" + code, unassigned, Map.class))).as(code).isEmpty();
        }
    }

    @Test
    void factoryCoordinator_seesOnlyOwnFactory_andMgmtViewerSeesAllNonFinancial() {
        TestSession owner = login("OWNER_MD");
        Long orgId = owner.organizationId();
        Seed a = seed(orgId);
        Seed b = seed(orgId);
        String coordinator = loginInOrg("FACTORY_COORDINATOR", orgId);
        assign("factory_coordinator", orgId, "FACTORY", a.factoryId());

        for (String code : List.of("production-progress", "order-status")) {
            assertThat(rows(get("/api/v1/reports/" + code, coordinator, Map.class))).as(code)
                    .extracting(r -> r.get("order_no")).containsExactly(a.orderNo());
        }
        assertThat(rows(get("/api/v1/reports/factory-performance", coordinator, Map.class))).hasSize(1);
        assertThat(get("/api/v1/reports/production-progress?factoryId=" + b.factoryId(), coordinator, String.class).getStatusCode())
                .isEqualTo(HttpStatus.FORBIDDEN);
        String csv = get("/api/v1/reports/production-progress/export?format=csv", coordinator, String.class).getBody();
        assertThat(csv).contains(a.orderNo()).doesNotContain(b.orderNo());
        assertThat(get("/api/v1/reports/order-profitability", coordinator, String.class).getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);

        String viewer = loginInOrg("MANAGEMENT_VIEWER", orgId);
        assertThat(rows(get("/api/v1/reports/order-status", viewer, Map.class))).hasSize(2);
        assertThat(get("/api/v1/reports/order-profitability", viewer, String.class).getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        assertThat(get("/api/v1/reports/costing-margin", viewer, String.class).getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
    }

    /** Exercises every report's scope SQL (buyer AND factory clauses) for a user scoped on both dimensions. */
    @Test
    void everyReport_runsScoped_forUserWithBuyerAndFactoryAssignments() {
        TestSession owner = login("OWNER_MD");
        Long orgId = owner.organizationId();
        Seed a = seed(orgId);
        Seed b = seed(orgId);
        String sampling = loginInOrg("SAMPLING_COORDINATOR", orgId);
        assign("sampling_coordinator", orgId, "BUYER", a.buyerId());
        assign("sampling_coordinator", orgId, "FACTORY", a.factoryId());

        // Temporarily let this role open every report so each query's scoped SQL is executed.
        JdbcTemplate jdbc = new JdbcTemplate(dataSource);
        String grant = """
                INSERT INTO role_permissions (role_id, permission_id)
                SELECT r.id, p.id FROM roles r, permissions p
                WHERE r.name = 'SAMPLING_COORDINATOR' AND p.code IN ('REPORT_VIEW_ALL', 'REPORT_FINANCIAL_VIEW')""";
        String revoke = """
                DELETE FROM role_permissions WHERE role_id = (SELECT id FROM roles WHERE name = 'SAMPLING_COORDINATOR')
                  AND permission_id IN (SELECT id FROM permissions WHERE code IN ('REPORT_VIEW_ALL', 'REPORT_FINANCIAL_VIEW'))""";
        jdbc.update(grant);
        try {
            for (String code : ALL_CODES) {
                List<Map<String, Object>> rows = rows(get("/api/v1/reports/" + code, sampling, Map.class));
                assertThat(rows.toString()).as(code).doesNotContain(b.orderNo()).doesNotContain(b.styleNo());
            }
            assertThat(rows(get("/api/v1/reports/order-status", sampling, Map.class)))
                    .extracting(r -> r.get("order_no")).containsExactly(a.orderNo());
            assertThat(rows(get("/api/v1/reports/document-expiry", sampling, Map.class))).hasSize(1);
            assertThat(rows(get("/api/v1/reports/receivables-payables", sampling, Map.class))).hasSize(2);
        } finally {
            jdbc.update(revoke);
        }
    }

    private static List<Map<String, Object>> rows(ResponseEntity<Map> response) {
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        return (List<Map<String, Object>>) response.getBody().get("rows");
    }

    private String loginInOrg(String role, Long orgId) {
        return TestUsers.createAndLoginInOrganization(restTemplate, userRepository, roleRepository, organizationRepository,
                passwordEncoder, role, orgId);
    }

    /** Assigns every user of the given role prefix in the org (normally just one) via the existing assignments table. */
    private void assign(String emailPrefix, Long orgId, String scopeType, Long scopeId) {
        new JdbcTemplate(dataSource).update("""
                INSERT INTO assignments (user_id, scope_type, scope_id)
                SELECT id, ?, ? FROM users WHERE organization_id = ? AND email LIKE ?""",
                scopeType, scopeId, orgId, emailPrefix + "+%");
    }

    private TestSession login(String role) {
        return TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, role);
    }

    private <T> ResponseEntity<T> get(String url, String token, Class<T> type) {
        return restTemplate.exchange(url, HttpMethod.GET, new HttpEntity<>(TestUsers.bearer(token)), type);
    }

    private record Seed(Long buyerId, Long factoryId, String orderNo, String styleNo) {
    }

    /** One order with data in every module a report reads, inserted directly in the given tenant. */
    private Seed seed(Long orgId) {
        JdbcTemplate jdbc = new JdbcTemplate(dataSource);
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        LocalDate today = LocalDate.now();

        Long buyerId = jdbc.queryForObject("INSERT INTO buyers (organization_id, code, name, country) VALUES (?, ?, 'Report Buyer', 'US') RETURNING id",
                Long.class, orgId, "B-" + suffix);
        Long factoryId = jdbc.queryForObject("INSERT INTO factories (organization_id, code, name, partner_type) VALUES (?, ?, 'Report Factory', 'GARMENT_FACTORY') RETURNING id",
                Long.class, orgId, "F-" + suffix);
        Long styleId = jdbc.queryForObject("INSERT INTO styles (organization_id, style_no, buyer_id) VALUES (?, ?, ?) RETURNING id",
                Long.class, orgId, "S-" + suffix, buyerId);
        String orderNo = "ORD-" + suffix;
        Long orderId = jdbc.queryForObject("""
                INSERT INTO orders (organization_id, order_no, buyer_po_no, buyer_id, status, order_date, ex_factory_date, delivery_date, total_value, currency)
                VALUES (?, ?, ?, ?, 'IN_PROGRESS', ?, ?, ?, 5000, 'USD') RETURNING id""",
                Long.class, orgId, orderNo, "PO-" + suffix, buyerId, today.minusDays(30), today.plusDays(10), today.plusDays(20));
        jdbc.update("INSERT INTO order_items (order_id, style_id, factory_id, quantity, unit_price) VALUES (?, ?, ?, 1000, 5)", orderId, styleId, factoryId);

        jdbc.update("INSERT INTO inquiries (organization_id, inquiry_no, buyer_id, target_quantity, target_price, target_currency, status) VALUES (?, ?, ?, 1000, 5, 'USD', 'OPEN')",
                orgId, "INQ-" + suffix, buyerId);
        jdbc.update("INSERT INTO costings (organization_id, style_id, version_no, currency, quantity, total_cost, target_price, margin_percent) VALUES (?, ?, 1, 'USD', 1000, 4.6, 5, 8)",
                orgId, styleId);
        Long sampleTypeId = jdbc.queryForObject("SELECT MIN(id) FROM sample_types", Long.class);
        jdbc.update("""
                INSERT INTO samples (organization_id, sample_no, style_id, buyer_id, factory_id, sample_type_id, request_date, required_date, current_status)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'SUBMITTED')""",
                orgId, "SMP-" + suffix, styleId, buyerId, factoryId, sampleTypeId, today.minusDays(15), today.minusDays(2));

        Long milestoneTypeId = jdbc.queryForObject("SELECT MIN(id) FROM milestone_types", Long.class);
        jdbc.update("INSERT INTO ta_milestones (order_id, milestone_type_id, sequence, planned_date, responsible_factory_id) VALUES (?, ?, 1, ?, ?)",
                orderId, milestoneTypeId, today.minusDays(10), factoryId);
        jdbc.update("INSERT INTO production_updates (order_id, update_date, cutting_qty, sewing_qty, finishing_qty, packing_qty, rejection_qty) VALUES (?, ?, 800, 600, 500, 400, 10)",
                orderId, today.minusDays(1));

        Long inspectionId = jdbc.queryForObject("INSERT INTO inspections (order_id, inspection_type, inspection_date, inspected_qty, aql_level, result) VALUES (?, 'FINAL', ?, 200, '2.5', 'FAIL') RETURNING id",
                Long.class, orderId, today.minusDays(3));
        Long defectTypeId = jdbc.queryForObject("SELECT MIN(id) FROM defect_types", Long.class);
        jdbc.update("INSERT INTO defects (inspection_id, defect_type_id, quantity, severity) VALUES (?, ?, 5, 'MAJOR')", inspectionId, defectTypeId);
        jdbc.update("INSERT INTO capa_records (inspection_id, description) VALUES (?, 'Re-train sewing line 4')", inspectionId);

        Long shipmentId = jdbc.queryForObject("INSERT INTO shipments (organization_id, shipment_no, order_id, etd, quantity_shipped, status) VALUES (?, ?, ?, ?, 400, 'BOOKED') RETURNING id",
                Long.class, orgId, "SHP-" + suffix, orderId, today.minusDays(1));
        jdbc.update("INSERT INTO factory_certifications (factory_id, cert_name, expiry_date) VALUES (?, 'BSCI', ?)", factoryId, today.plusDays(10));

        jdbc.update("INSERT INTO order_financials (order_id, quoted_unit_price, actual_cost_unit) VALUES (?, 5, 4.6)", orderId);
        jdbc.update("INSERT INTO receivables (order_id, buyer_id, amount, currency, due_date, received_amount) VALUES (?, ?, 5000, 'USD', ?, 1000)",
                orderId, buyerId, today.minusDays(40));
        jdbc.update("INSERT INTO payables (order_id, factory_id, amount, currency, due_date) VALUES (?, ?, 4000, 'USD', ?)",
                orderId, factoryId, today.plusDays(10));
        jdbc.update("INSERT INTO claims (order_id, shipment_id, raised_by, claim_type, description, claimed_amount) VALUES (?, ?, 'BUYER', 'QUALITY', 'Loose buttons', 200)",
                orderId, shipmentId);
        return new Seed(buyerId, factoryId, orderNo, "S-" + suffix);
    }
}
