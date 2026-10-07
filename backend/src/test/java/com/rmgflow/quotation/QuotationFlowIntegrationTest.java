package com.rmgflow.quotation;

import com.rmgflow.approval.dto.ApprovalDecisionRequest;
import com.rmgflow.approval.dto.ApprovalResponse;
import com.rmgflow.approval.entity.ApprovalStatus;
import com.rmgflow.buyer.dto.BuyerRequest;
import com.rmgflow.buyer.dto.BuyerResponse;
import com.rmgflow.costing.dto.CostingItemRequest;
import com.rmgflow.costing.dto.CostingRequest;
import com.rmgflow.costing.dto.CostingResponse;
import com.rmgflow.costing.entity.CostingComponentType;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.RoleRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.quotation.dto.QuotationRequest;
import com.rmgflow.quotation.dto.QuotationResponse;
import com.rmgflow.quotation.entity.QuotationStatus;
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
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/** Document 9.2/10.2/16.1: a quotation must reference an APPROVED costing, and is
 * itself immutable once APPROVED — revisions create a new version instead. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class QuotationFlowIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;
    @Autowired
    private com.rmgflow.identity.repository.AssignmentRepository assignmentRepository;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private RoleRepository roleRepository;
    @Autowired
    private OrganizationRepository organizationRepository;
    @Autowired
    private PasswordEncoder passwordEncoder;

    private BuyerResponse buyer;
    private StyleResponse style;

    private StyleResponse createStyle(String token) {
        BuyerRequest buyerRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "Quotation Test Buyer", null, null, null, null, null, null);
        buyer = restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(buyerRequest, TestUsers.bearer(token)), BuyerResponse.class).getBody();
        StyleRequest styleRequest = new StyleRequest("STY-" + UUID.randomUUID(), buyer.id(), null, "Polo", null, null, null);
        style = restTemplate.exchange("/api/v1/styles", HttpMethod.POST,
                new HttpEntity<>(styleRequest, TestUsers.bearer(token)), StyleResponse.class).getBody();
        return style;
    }

    private CostingResponse createApprovedCosting(String token) {
        List<CostingItemRequest> items = List.of(
                new CostingItemRequest(CostingComponentType.FABRIC, "Pique", new BigDecimal("3.00"), BigDecimal.ONE, BigDecimal.ZERO));
        CostingRequest costingRequest = new CostingRequest(style.id(), null, "USD", BigDecimal.ONE, 500, new BigDecimal("8.00"), items);
        CostingResponse costing = restTemplate.exchange("/api/v1/costings", HttpMethod.POST,
                new HttpEntity<>(costingRequest, TestUsers.bearer(token)), CostingResponse.class).getBody();

        restTemplate.exchange("/api/v1/costings/" + costing.id() + "/submit", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(token)), CostingResponse.class);
        ApprovalResponse approval = List.of(restTemplate.exchange(
                        "/api/v1/approvals/history?targetType=COSTING&targetId=" + costing.id(), HttpMethod.GET,
                        new HttpEntity<>(TestUsers.bearer(token)), ApprovalResponse[].class).getBody())
                .get(0);
        restTemplate.exchange("/api/v1/approvals/" + approval.id() + "/decide", HttpMethod.POST,
                new HttpEntity<>(new ApprovalDecisionRequest(ApprovalStatus.APPROVED, null, null), TestUsers.bearer(token)), ApprovalResponse.class);
        return restTemplate.exchange("/api/v1/costings/" + costing.id() + "/mark-approved", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(token)), CostingResponse.class).getBody();
    }

    @Test
    void quotation_requiresAnApprovedCosting() {
        String token = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "SENIOR_MERCHANDISER").accessToken();
        createStyle(token);

        List<CostingItemRequest> items = List.of(
                new CostingItemRequest(CostingComponentType.FABRIC, "Pique", new BigDecimal("3.00"), BigDecimal.ONE, BigDecimal.ZERO));
        CostingResponse draftCosting = restTemplate.exchange("/api/v1/costings", HttpMethod.POST,
                new HttpEntity<>(new CostingRequest(style.id(), null, "USD", BigDecimal.ONE, 500, new BigDecimal("8.00"), items), TestUsers.bearer(token)),
                CostingResponse.class).getBody();

        QuotationRequest quotationRequest = new QuotationRequest(draftCosting.id(), null, buyer.id(), style.id(), 500,
                new BigDecimal("7.50"), "USD", "FOB", null, null, 60);
        ResponseEntity<String> response = restTemplate.exchange("/api/v1/quotations", HttpMethod.POST,
                new HttpEntity<>(quotationRequest, TestUsers.bearer(token)), String.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void approvedQuotation_isImmutable_revisionCreatesNewVersion() {
        String token = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "SENIOR_MERCHANDISER").accessToken();
        createStyle(token);
        CostingResponse approvedCosting = createApprovedCosting(token);

        QuotationRequest quotationRequest = new QuotationRequest(approvedCosting.id(), null, buyer.id(), style.id(), 500,
                new BigDecimal("7.50"), "USD", "FOB", null, null, 60);
        ResponseEntity<QuotationResponse> createResponse = restTemplate.exchange("/api/v1/quotations", HttpMethod.POST,
                new HttpEntity<>(quotationRequest, TestUsers.bearer(token)), QuotationResponse.class);
        assertThat(createResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        QuotationResponse quotation = createResponse.getBody();
        assertThat(quotation.status()).isEqualTo(QuotationStatus.DRAFT);

        // Doc 10.2: DRAFT cannot jump straight to APPROVED; it must be SENT first.
        ResponseEntity<String> draftToApproved = restTemplate.exchange(
                "/api/v1/quotations/" + quotation.id() + "/status?status=APPROVED", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(token)), String.class);
        assertThat(draftToApproved.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        restTemplate.exchange("/api/v1/quotations/" + quotation.id() + "/status?status=SENT", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(token)), QuotationResponse.class);
        ResponseEntity<QuotationResponse> approved = restTemplate.exchange(
                "/api/v1/quotations/" + quotation.id() + "/status?status=APPROVED", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(token)), QuotationResponse.class);
        assertThat(approved.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(approved.getBody().status()).isEqualTo(QuotationStatus.APPROVED);

        ResponseEntity<String> blockedStatusChange = restTemplate.exchange(
                "/api/v1/quotations/" + quotation.id() + "/status?status=REJECTED", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(token)), String.class);
        assertThat(blockedStatusChange.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);

        QuotationRequest revisedRequest = new QuotationRequest(approvedCosting.id(), null, buyer.id(), style.id(), 500,
                new BigDecimal("7.25"), "USD", "FOB", null, null, 60);
        ResponseEntity<QuotationResponse> revisionResponse = restTemplate.exchange(
                "/api/v1/quotations/" + quotation.id() + "/revise", HttpMethod.POST,
                new HttpEntity<>(revisedRequest, TestUsers.bearer(token)), QuotationResponse.class);
        assertThat(revisionResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(revisionResponse.getBody().versionNo()).isEqualTo(2);
        assertThat(revisionResponse.getBody().quotationNo()).isEqualTo(quotation.quotationNo());
    }

    /** Doc 10.3: QUOTATION_MANAGE alone cannot self-approve through the status endpoint. */
    @Test
    void juniorMerchandiser_cannotMarkQuotationApproved() {
        var senior = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "SENIOR_MERCHANDISER");
        String token = senior.accessToken();
        createStyle(token);
        CostingResponse approvedCosting = createApprovedCosting(token);
        QuotationResponse quotation = restTemplate.exchange("/api/v1/quotations", HttpMethod.POST,
                new HttpEntity<>(new QuotationRequest(approvedCosting.id(), null, buyer.id(), style.id(), 500,
                        new BigDecimal("7.50"), "USD", "FOB", null, null, 60), TestUsers.bearer(token)),
                QuotationResponse.class).getBody();

        String junior = TestUsers.createAndLoginAssigned(restTemplate, userRepository, roleRepository,
                organizationRepository, passwordEncoder, assignmentRepository, "JUNIOR_MERCHANDISER",
                senior.organizationId(), com.rmgflow.identity.entity.ScopeType.BUYER, buyer.id());
        ResponseEntity<String> selfApprove = restTemplate.exchange(
                "/api/v1/quotations/" + quotation.id() + "/status?status=APPROVED", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(junior)), String.class);
        assertThat(selfApprove.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);

        ResponseEntity<QuotationResponse> negotiating = restTemplate.exchange(
                "/api/v1/quotations/" + quotation.id() + "/status?status=NEGOTIATING", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(junior)), QuotationResponse.class);
        assertThat(negotiating.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(negotiating.getBody().status()).isEqualTo(QuotationStatus.NEGOTIATING);
    }
}
