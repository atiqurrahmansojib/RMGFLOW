package com.rmgflow.config;

import com.rmgflow.identity.dto.LoginRequest;
import com.rmgflow.identity.dto.TokenResponse;
import com.rmgflow.support.PostgresTestContainerConfig;
import com.rmgflow.support.TestUsers;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.DefaultApplicationArguments;
import org.springframework.boot.resttestclient.TestRestTemplate;
import org.springframework.boot.resttestclient.autoconfigure.AutoConfigureTestRestTemplate;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import javax.sql.DataSource;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * DemoDataSeeder runs at startup (property enabled) on this context's own, empty
 * Testcontainers database, must populate every module so each Doc 14 report has rows,
 * and must be a no-op on a second run.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = "rmgflow.demo-data.enabled=true")
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class DemoDataSeederTest {

    private static final List<String> TABLES = List.of("users", "assignments", "buyers", "buyer_contacts", "factories",
            "factory_contacts", "factory_capabilities", "factory_certifications", "factory_buyer_approvals", "seasons",
            "inquiries", "inquiry_factory_candidates", "styles", "style_revisions", "attachments", "costings", "costing_items",
            "quotations", "approvals", "samples", "sample_revisions", "ta_templates", "ta_template_milestones", "orders",
            "order_items", "order_amendments", "ta_milestones", "production_updates", "inspections", "defects", "capa_records",
            "shipments", "documents", "order_financials", "receivables", "payables", "payment_records", "claims",
            "activities", "tasks", "notifications");

    private static final List<String> DEMO_EMAILS = List.of(DemoDataSeeder.MARKER_EMAIL, "owner@rmgflow.test", "gm@rmgflow.test",
            "sr.merch@rmgflow.test", "jr.merch@rmgflow.test", "sampling@rmgflow.test", "production@rmgflow.test",
            "quality@rmgflow.test", "commercial@rmgflow.test", "accounts@rmgflow.test", "factory.coord@rmgflow.test",
            "viewer@rmgflow.test");

    @Autowired
    private DemoDataSeeder seeder;
    @Autowired
    private TestRestTemplate restTemplate;
    @Autowired
    private DataSource dataSource;

    @Test
    void seedsEveryModule_everyReportHasRows_andSecondRunIsNoOp() {
        Map<String, Long> afterFirstRun = tableCounts();
        afterFirstRun.forEach((table, rows) -> assertThat(rows).as(table).isPositive());
        assertThat(seeder.lastRunCounts()).containsKeys("Orders", "Shipments", "Claims", "Tasks");

        seeder.run(new DefaultApplicationArguments());
        assertThat(tableCounts()).as("second run must not add rows").isEqualTo(afterFirstRun);

        // Business-state variety the screens and reports rely on.
        JdbcTemplate jdbc = new JdbcTemplate(dataSource);
        assertThat(jdbc.queryForList("SELECT DISTINCT status FROM orders", String.class))
                .contains("CONFIRMED", "IN_PROGRESS", "PARTIALLY_SHIPPED", "SHIPPED", "CLOSED", "CANCELLED");
        assertThat(jdbc.queryForList("SELECT DISTINCT status FROM inquiries", String.class))
                .contains("OPEN", "QUOTED", "WON", "LOST", "HOLD");
        assertThat(jdbc.queryForList("SELECT DISTINCT status FROM approvals", String.class))
                .contains("SUBMITTED", "APPROVED", "REJECTED", "RETURNED");
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM inspections WHERE inspection_type = 'FINAL' AND result = 'FAIL'", Long.class))
                .isPositive();
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM tasks WHERE due_date < CURRENT_DATE AND status <> 'DONE'", Long.class))
                .isPositive();

        for (String email : DEMO_EMAILS) {
            assertThat(login(email)).as(email).isNotBlank();
        }

        String gm = login("gm@rmgflow.test");
        ResponseEntity<List> catalog = get("/api/v1/reports", gm, List.class);
        assertThat(catalog.getStatusCode()).isEqualTo(HttpStatus.OK);
        List<String> codes = ((List<Map<String, Object>>) catalog.getBody()).stream().map(r -> (String) r.get("code")).toList();
        assertThat(codes).hasSizeGreaterThanOrEqualTo(14);
        for (String code : codes) {
            ResponseEntity<Map> result = get("/api/v1/reports/" + code, gm, Map.class);
            assertThat(result.getStatusCode()).as(code).isEqualTo(HttpStatus.OK);
            assertThat((List<?>) result.getBody().get("rows")).as(code + " rows").isNotEmpty();
        }

        // Scoped role: the factory coordinator sees its assigned factory's orders.
        ResponseEntity<Map> scoped = get("/api/v1/reports/order-status", login("factory.coord@rmgflow.test"), Map.class);
        assertThat(scoped.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat((List<?>) scoped.getBody().get("rows")).isNotEmpty();
    }

    private Map<String, Long> tableCounts() {
        JdbcTemplate jdbc = new JdbcTemplate(dataSource);
        Map<String, Long> counts = new LinkedHashMap<>();
        for (String table : TABLES) {
            counts.put(table, jdbc.queryForObject("SELECT COUNT(*) FROM " + table, Long.class));
        }
        return counts;
    }

    private String login(String email) {
        ResponseEntity<TokenResponse> response = restTemplate.postForEntity("/api/v1/auth/login",
                new LoginRequest(email, DemoDataSeeder.DEMO_PASSWORD, "junit"), TokenResponse.class);
        assertThat(response.getStatusCode()).as("login " + email).isEqualTo(HttpStatus.OK);
        return response.getBody().accessToken();
    }

    private <T> ResponseEntity<T> get(String path, String token, Class<T> type) {
        return restTemplate.exchange(path, HttpMethod.GET, new HttpEntity<>(TestUsers.bearer(token)), type);
    }
}
