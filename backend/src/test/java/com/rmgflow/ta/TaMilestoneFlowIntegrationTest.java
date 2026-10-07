package com.rmgflow.ta;

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
import com.rmgflow.masterdata.entity.MilestoneType;
import com.rmgflow.order.dto.OrderItemRequest;
import com.rmgflow.order.dto.OrderRequest;
import com.rmgflow.order.dto.OrderResponse;
import com.rmgflow.style.dto.StyleRequest;
import com.rmgflow.style.dto.StyleResponse;
import com.rmgflow.support.PostgresTestContainerConfig;
import com.rmgflow.support.TestUsers;
import com.rmgflow.ta.dto.RecordActualDateRequest;
import com.rmgflow.ta.dto.TaMilestoneResponse;
import com.rmgflow.ta.dto.TaTemplateMilestoneRequest;
import com.rmgflow.ta.dto.TaTemplateRequest;
import com.rmgflow.ta.dto.TaTemplateResponse;
import com.rmgflow.ta.entity.TaMilestoneStatus;
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
 * Document 10.3/13.1/16.1: proves A15 (auto-generation from a resolved template)
 * and A16 (the delay-cascade automation, the single highest-value feature per
 * Document 10.3's own framing) — recording a late actual date on one milestone
 * must shift every downstream dependent's revised_date, transitively.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class TaMilestoneFlowIntegrationTest {

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

    @Test
    void delayOnOneMilestone_cascadesForwardThroughTwoLevelsOfDependents() {
        String token = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "GENERAL_MANAGER").accessToken();

        BuyerRequest buyerRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "TA Test Buyer", null, null, null, null, null, null);
        BuyerResponse buyer = restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(buyerRequest, TestUsers.bearer(token)), BuyerResponse.class).getBody();
        StyleRequest styleRequest = new StyleRequest("STY-" + UUID.randomUUID(), buyer.id(), null, "Hoodie", null, null, null);
        StyleResponse style = restTemplate.exchange("/api/v1/styles", HttpMethod.POST,
                new HttpEntity<>(styleRequest, TestUsers.bearer(token)), StyleResponse.class).getBody();
        FactoryRequest factoryRequest = new FactoryRequest("FAC-" + UUID.randomUUID(), "TA Test Factory",
                PartnerType.GARMENT_FACTORY, null, null, null, null, null);
        FactoryResponse factory = restTemplate.exchange("/api/v1/factories", HttpMethod.POST,
                new HttpEntity<>(factoryRequest, TestUsers.bearer(token)), FactoryResponse.class).getBody();
        restTemplate.exchange("/api/v1/factories/" + factory.id() + "/buyer-approvals", HttpMethod.PUT,
                new HttpEntity<>(new FactoryBuyerApprovalRequest(buyer.id(), FactoryBuyerApprovalStatus.APPROVED, LocalDate.now(), null), TestUsers.bearer(token)),
                Void.class);

        MilestoneType[] milestoneTypes = restTemplate.exchange("/api/v1/milestone-types", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), MilestoneType[].class).getBody();
        long cuttingTypeId = findByName(milestoneTypes, "Cutting").getId();
        long sewingTypeId = findByName(milestoneTypes, "Sewing").getId();
        long finishingTypeId = findByName(milestoneTypes, "Finishing").getId();

        TaTemplateResponse template = restTemplate.exchange("/api/v1/ta-templates", HttpMethod.POST,
                new HttpEntity<>(new TaTemplateRequest("Test Template " + UUID.randomUUID(), buyer.id(), null, false), TestUsers.bearer(token)),
                TaTemplateResponse.class).getBody();

        var m1 = restTemplate.exchange("/api/v1/ta-templates/" + template.id() + "/milestones", HttpMethod.POST,
                new HttpEntity<>(new TaTemplateMilestoneRequest(cuttingTypeId, 1, 30, null), TestUsers.bearer(token)),
                com.rmgflow.ta.dto.TaTemplateMilestoneResponse.class).getBody();
        var m2 = restTemplate.exchange("/api/v1/ta-templates/" + template.id() + "/milestones", HttpMethod.POST,
                new HttpEntity<>(new TaTemplateMilestoneRequest(sewingTypeId, 2, 20, m1.id()), TestUsers.bearer(token)),
                com.rmgflow.ta.dto.TaTemplateMilestoneResponse.class).getBody();
        restTemplate.exchange("/api/v1/ta-templates/" + template.id() + "/milestones", HttpMethod.POST,
                new HttpEntity<>(new TaTemplateMilestoneRequest(finishingTypeId, 3, 10, m2.id()), TestUsers.bearer(token)),
                com.rmgflow.ta.dto.TaTemplateMilestoneResponse.class).getBody();

        LocalDate exFactory = LocalDate.now().plusDays(60);
        OrderItemRequest item = new OrderItemRequest(style.id(), factory.id(), "Grey", "L", 200, new BigDecimal("4.00"));
        OrderRequest orderRequest = new OrderRequest("PO-" + UUID.randomUUID(), buyer.id(), null, LocalDate.now(), exFactory, null,
                null, null, null, "USD", false, null, List.of(item));
        OrderResponse order = restTemplate.exchange("/api/v1/orders", HttpMethod.POST,
                new HttpEntity<>(orderRequest, TestUsers.bearer(token)), OrderResponse.class).getBody();

        // Doc A15: confirming the order auto-generated the plan from the buyer's template.
        ResponseEntity<TaMilestoneResponse[]> generateResponse = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/ta-milestones", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), TaMilestoneResponse[].class);
        assertThat(generateResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        List<TaMilestoneResponse> generated = List.of(generateResponse.getBody());
        assertThat(generated).hasSize(3);

        TaMilestoneResponse cutting = generated.stream().filter(m -> m.sequence() == 1).findFirst().orElseThrow();
        TaMilestoneResponse sewing = generated.stream().filter(m -> m.sequence() == 2).findFirst().orElseThrow();
        TaMilestoneResponse finishing = generated.stream().filter(m -> m.sequence() == 3).findFirst().orElseThrow();

        assertThat(cutting.plannedDate()).isEqualTo(exFactory.minusDays(30));
        assertThat(sewing.plannedDate()).isEqualTo(exFactory.minusDays(20));
        assertThat(finishing.plannedDate()).isEqualTo(exFactory.minusDays(10));

        // Re-generating must be rejected (already exists for this order).
        ResponseEntity<String> duplicateResponse = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/ta-milestones/generate?styleId=" + style.id(), HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(token)), String.class);
        assertThat(duplicateResponse.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);

        // Cutting finishes 5 days late -> cascades onto sewing AND (transitively) finishing.
        LocalDate lateActual = cutting.plannedDate().plusDays(5);
        ResponseEntity<TaMilestoneResponse> recordResponse = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/ta-milestones/" + cutting.id() + "/actual-date", HttpMethod.POST,
                new HttpEntity<>(new RecordActualDateRequest(lateActual, "Fabric shortage"), TestUsers.bearer(token)), TaMilestoneResponse.class);
        assertThat(recordResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(recordResponse.getBody().status()).isEqualTo(TaMilestoneStatus.DONE);

        // A late actual date with no reason must be rejected (fetch a second order's milestone... simpler: assert via a fresh attempt below is unnecessary here).

        List<TaMilestoneResponse> afterCascade = List.of(restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/ta-milestones", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), TaMilestoneResponse[].class).getBody());

        TaMilestoneResponse sewingAfter = afterCascade.stream().filter(m -> m.sequence() == 2).findFirst().orElseThrow();
        TaMilestoneResponse finishingAfter = afterCascade.stream().filter(m -> m.sequence() == 3).findFirst().orElseThrow();

        assertThat(sewingAfter.revisedDate()).isEqualTo(sewing.plannedDate().plusDays(5));
        assertThat(finishingAfter.revisedDate()).isEqualTo(finishing.plannedDate().plusDays(5));
    }

    @Test
    void recordingALateActualDate_withoutReason_isRejected() {
        String token = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "GENERAL_MANAGER").accessToken();

        BuyerRequest buyerRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "TA Reason Test Buyer", null, null, null, null, null, null);
        BuyerResponse buyer = restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(buyerRequest, TestUsers.bearer(token)), BuyerResponse.class).getBody();
        StyleRequest styleRequest = new StyleRequest("STY-" + UUID.randomUUID(), buyer.id(), null, "Cap", null, null, null);
        StyleResponse style = restTemplate.exchange("/api/v1/styles", HttpMethod.POST,
                new HttpEntity<>(styleRequest, TestUsers.bearer(token)), StyleResponse.class).getBody();
        FactoryRequest factoryRequest = new FactoryRequest("FAC-" + UUID.randomUUID(), "TA Reason Test Factory",
                PartnerType.GARMENT_FACTORY, null, null, null, null, null);
        FactoryResponse factory = restTemplate.exchange("/api/v1/factories", HttpMethod.POST,
                new HttpEntity<>(factoryRequest, TestUsers.bearer(token)), FactoryResponse.class).getBody();
        restTemplate.exchange("/api/v1/factories/" + factory.id() + "/buyer-approvals", HttpMethod.PUT,
                new HttpEntity<>(new FactoryBuyerApprovalRequest(buyer.id(), FactoryBuyerApprovalStatus.APPROVED, LocalDate.now(), null), TestUsers.bearer(token)),
                Void.class);
        MilestoneType[] milestoneTypes = restTemplate.exchange("/api/v1/milestone-types", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), MilestoneType[].class).getBody();
        long cuttingTypeId = findByName(milestoneTypes, "Cutting").getId();

        TaTemplateResponse template = restTemplate.exchange("/api/v1/ta-templates", HttpMethod.POST,
                new HttpEntity<>(new TaTemplateRequest("Reason Test Template " + UUID.randomUUID(), buyer.id(), null, false), TestUsers.bearer(token)),
                TaTemplateResponse.class).getBody();
        restTemplate.exchange("/api/v1/ta-templates/" + template.id() + "/milestones", HttpMethod.POST,
                new HttpEntity<>(new TaTemplateMilestoneRequest(cuttingTypeId, 1, 30, null), TestUsers.bearer(token)),
                com.rmgflow.ta.dto.TaTemplateMilestoneResponse.class);

        LocalDate exFactory = LocalDate.now().plusDays(60);
        OrderItemRequest item = new OrderItemRequest(style.id(), factory.id(), "Black", "OS", 50, new BigDecimal("2.00"));
        OrderRequest orderRequest = new OrderRequest("PO-" + UUID.randomUUID(), buyer.id(), null, LocalDate.now(), exFactory, null,
                null, null, null, "USD", false, null, List.of(item));
        OrderResponse order = restTemplate.exchange("/api/v1/orders", HttpMethod.POST,
                new HttpEntity<>(orderRequest, TestUsers.bearer(token)), OrderResponse.class).getBody();
        TaMilestoneResponse cutting = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/ta-milestones", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), TaMilestoneResponse[].class).getBody()[0];

        ResponseEntity<String> response = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/ta-milestones/" + cutting.id() + "/actual-date", HttpMethod.POST,
                new HttpEntity<>(new RecordActualDateRequest(cutting.plannedDate().plusDays(2), null), TestUsers.bearer(token)), String.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    private MilestoneType findByName(MilestoneType[] types, String name) {
        for (MilestoneType type : types) {
            if (type.getName().equals(name)) return type;
        }
        throw new IllegalStateException("Milestone type not found: " + name);
    }
}
