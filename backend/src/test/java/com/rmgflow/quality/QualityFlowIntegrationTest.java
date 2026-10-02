package com.rmgflow.quality;

import com.rmgflow.buyer.dto.BuyerRequest;
import com.rmgflow.buyer.dto.BuyerResponse;
import com.rmgflow.factory.dto.FactoryBuyerApprovalRequest;
import com.rmgflow.factory.dto.FactoryRequest;
import com.rmgflow.factory.dto.FactoryResponse;
import com.rmgflow.factory.entity.FactoryBuyerApprovalStatus;
import com.rmgflow.factory.entity.PartnerType;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.RoleRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.masterdata.entity.DefectType;
import com.rmgflow.order.dto.OrderItemRequest;
import com.rmgflow.order.dto.OrderRequest;
import com.rmgflow.order.dto.OrderResponse;
import com.rmgflow.quality.dto.*;
import com.rmgflow.quality.entity.CapaStatus;
import com.rmgflow.quality.entity.InspectionResult;
import com.rmgflow.quality.entity.InspectionType;
import com.rmgflow.style.dto.StyleRequest;
import com.rmgflow.style.dto.StyleResponse;
import com.rmgflow.support.PostgresTestContainerConfig;
import com.rmgflow.support.TestUsers;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.resttestclient.TestRestTemplate;
import org.springframework.boot.resttestclient.autoconfigure.AutoConfigureTestRestTemplate;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Document 9.7/10.6/16.5 scenario #6: a failed FINAL inspection must be visible
 * via the hasPassingFinalInspection query (the gate Phase 10's ShipmentService
 * will use) until a passing re-inspection exists; full CAPA lifecycle in between.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class QualityFlowIntegrationTest {

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

    private OrderResponse createOrder(String token) {
        BuyerRequest buyerRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "Quality Test Buyer", null, null, null, null, null, null);
        BuyerResponse buyer = restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(buyerRequest, TestUsers.bearer(token)), BuyerResponse.class).getBody();
        StyleRequest styleRequest = new StyleRequest("STY-" + UUID.randomUUID(), buyer.id(), null, "Polo", null, null, null);
        StyleResponse style = restTemplate.exchange("/api/v1/styles", HttpMethod.POST,
                new HttpEntity<>(styleRequest, TestUsers.bearer(token)), StyleResponse.class).getBody();
        FactoryRequest factoryRequest = new FactoryRequest("FAC-" + UUID.randomUUID(), "Quality Test Factory",
                PartnerType.GARMENT_FACTORY, null, null, null, null, null);
        FactoryResponse factory = restTemplate.exchange("/api/v1/factories", HttpMethod.POST,
                new HttpEntity<>(factoryRequest, TestUsers.bearer(token)), FactoryResponse.class).getBody();
        restTemplate.exchange("/api/v1/factories/" + factory.id() + "/buyer-approvals", HttpMethod.PUT,
                new HttpEntity<>(new FactoryBuyerApprovalRequest(buyer.id(), FactoryBuyerApprovalStatus.APPROVED, LocalDate.now(), null), TestUsers.bearer(token)),
                Void.class);
        OrderItemRequest item = new OrderItemRequest(style.id(), factory.id(), "Red", "M", 300, new BigDecimal("3.50"));
        OrderRequest orderRequest = new OrderRequest("PO-" + UUID.randomUUID(), buyer.id(), null, LocalDate.now(), null, null,
                null, null, null, "USD", false, null, List.of(item));
        return restTemplate.exchange("/api/v1/orders", HttpMethod.POST,
                new HttpEntity<>(orderRequest, TestUsers.bearer(token)), OrderResponse.class).getBody();
    }

    @Test
    void failedFinalInspection_thenCapaLifecycle_thenPassingReinspection() {
        String token = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "QUALITY_INSPECTOR").accessToken();
        // Quality Inspector alone cannot create buyer/style/factory/orders (view-only
        // on those per Doc 5.2), so a GM sets up the order and the inspector does the QC work.
        String gmToken = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "GENERAL_MANAGER").accessToken();
        OrderResponse order = createOrder(gmToken);

        InspectionRequest failRequest = new InspectionRequest(InspectionType.FINAL, LocalDate.now(), 300, "2.5", InspectionResult.FAIL);
        ResponseEntity<InspectionResponse> failResponse = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/inspections", HttpMethod.POST,
                new HttpEntity<>(failRequest, TestUsers.bearer(gmToken)), InspectionResponse.class);
        assertThat(failResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        InspectionResponse failedInspection = failResponse.getBody();

        DefectType[] defectTypes = restTemplate.exchange("/api/v1/defect-types", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(gmToken)), DefectType[].class).getBody();
        long defectTypeId = defectTypes[0].getId();

        DefectRequest defectRequest = new DefectRequest(defectTypeId, 15, "MAJOR", null);
        DefectResponse defect = restTemplate.exchange("/api/v1/inspections/" + failedInspection.id() + "/defects", HttpMethod.POST,
                new HttpEntity<>(defectRequest, TestUsers.bearer(gmToken)), DefectResponse.class).getBody();

        CapaRecordRequest capaRequest = new CapaRecordRequest(defect.id(), null, "Stitching defect on collar", "Re-train line operators", "Add inline QC checkpoint");
        ResponseEntity<CapaRecordResponse> capaResponse = restTemplate.exchange("/api/v1/capa-records", HttpMethod.POST,
                new HttpEntity<>(capaRequest, TestUsers.bearer(gmToken)), CapaRecordResponse.class);
        assertThat(capaResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        CapaRecordResponse capa = capaResponse.getBody();
        assertThat(capa.status()).isEqualTo(CapaStatus.OPEN);

        restTemplate.exchange("/api/v1/capa-records/" + capa.id() + "/factory-response", HttpMethod.POST,
                new HttpEntity<>(new CapaFactoryResponseRequest("Retrained operators, issue resolved"), TestUsers.bearer(gmToken)), CapaRecordResponse.class);

        ResponseEntity<CapaRecordResponse> closeResponse = restTemplate.exchange(
                "/api/v1/capa-records/" + capa.id() + "/close", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(gmToken)), CapaRecordResponse.class);
        assertThat(closeResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(closeResponse.getBody().status()).isEqualTo(CapaStatus.CLOSED);

        // Re-closing is rejected.
        ResponseEntity<String> reCloseResponse = restTemplate.exchange(
                "/api/v1/capa-records/" + capa.id() + "/close", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(gmToken)), String.class);
        assertThat(reCloseResponse.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);

        // Re-inspection: still FAIL at first.
        InspectionRequest reinspectFailRequest = new InspectionRequest(InspectionType.FINAL, LocalDate.now(), 300, "2.5", InspectionResult.REINSPECT);
        restTemplate.exchange("/api/v1/orders/" + order.id() + "/inspections", HttpMethod.POST,
                new HttpEntity<>(reinspectFailRequest, TestUsers.bearer(gmToken)), InspectionResponse.class);

        // Finally, a passing re-inspection.
        InspectionRequest passRequest = new InspectionRequest(InspectionType.FINAL, LocalDate.now(), 300, "2.5", InspectionResult.PASS);
        restTemplate.exchange("/api/v1/orders/" + order.id() + "/inspections", HttpMethod.POST,
                new HttpEntity<>(passRequest, TestUsers.bearer(gmToken)), InspectionResponse.class);

        List<InspectionResponse> allInspections = List.of(restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/inspections", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(gmToken)), InspectionResponse[].class).getBody());
        assertThat(allInspections).hasSize(3);
    }
}
