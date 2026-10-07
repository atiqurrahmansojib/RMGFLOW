package com.rmgflow.costing;

import com.rmgflow.approval.dto.ApprovalDecisionRequest;
import com.rmgflow.approval.dto.ApprovalResponse;
import com.rmgflow.approval.entity.ApprovalStatus;
import com.rmgflow.buyer.dto.BuyerRequest;
import com.rmgflow.buyer.dto.BuyerResponse;
import com.rmgflow.costing.dto.CostingItemRequest;
import com.rmgflow.costing.dto.CostingRequest;
import com.rmgflow.costing.dto.CostingResponse;
import com.rmgflow.costing.entity.CostingComponentType;
import com.rmgflow.costing.entity.CostingStatus;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.RoleRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.style.dto.StyleRequest;
import com.rmgflow.style.dto.StyleResponse;
import com.rmgflow.support.PostgresTestContainerConfig;
import com.rmgflow.support.TestSession;
import com.rmgflow.support.TestUsers;
import com.rmgflow.identity.entity.ScopeType;
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

/**
 * Document 9.1/10.2/16.1: margin math, the DRAFT->APPROVED immutability gate, and
 * field-level margin masking (Doc 5.2/11.1) — all backend-authoritative, never
 * client-supplied (NFR-01/FR-52).
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class CostingFlowIntegrationTest {

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
    private com.rmgflow.identity.repository.AssignmentRepository assignmentRepository;

    private StyleResponse createStyle(String token) {
        BuyerRequest buyerRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "Costing Test Buyer", null, null, null, null, null, null);
        BuyerResponse buyer = restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(buyerRequest, TestUsers.bearer(token)), BuyerResponse.class).getBody();
        StyleRequest styleRequest = new StyleRequest("STY-" + UUID.randomUUID(), buyer.id(), null, "T-Shirt", null, null, null);
        return restTemplate.exchange("/api/v1/styles", HttpMethod.POST,
                new HttpEntity<>(styleRequest, TestUsers.bearer(token)), StyleResponse.class).getBody();
    }

    private CostingRequest buildRequest(Long styleId, BigDecimal targetPrice) {
        List<CostingItemRequest> items = List.of(
                new CostingItemRequest(CostingComponentType.FABRIC, "Cotton fabric", new BigDecimal("2.00"), new BigDecimal("1.5"), new BigDecimal("5")),
                new CostingItemRequest(CostingComponentType.CM, "Cut & make", new BigDecimal("1.50"), BigDecimal.ONE, BigDecimal.ZERO)
        );
        // FABRIC: 2.00 * 1.5 * 1.05 = 3.15 ; CM: 1.50 * 1 * 1 = 1.50 ; total = 4.65
        return new CostingRequest(styleId, null, "USD", BigDecimal.ONE, 1000, targetPrice, items);
    }

    @Test
    void marginIsComputedServerSide_andMaskedForRolesWithoutViewPermission() {
        TestSession seniorSession = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "SENIOR_MERCHANDISER");
        String seniorToken = seniorSession.accessToken();
        StyleResponse style = createStyle(seniorToken);

        CostingRequest request = buildRequest(style.id(), new BigDecimal("6.00"));
        ResponseEntity<CostingResponse> createResponse = restTemplate.exchange("/api/v1/costings", HttpMethod.POST,
                new HttpEntity<>(request, TestUsers.bearer(seniorToken)), CostingResponse.class);
        assertThat(createResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        CostingResponse costing = createResponse.getBody();

        // total = 4.65, target = 6.00 -> margin = (6.00 - 4.65) / 6.00 * 100 = 22.5%
        assertThat(costing.totalCost()).isEqualByComparingTo("4.65");
        assertThat(costing.marginPercent()).isEqualByComparingTo("22.500");

        // Junior Merchandiser has COSTING_VIEW but NOT COSTING_VIEW_MARGIN (Doc 5.2/V15
        // seed) — must be in the SAME org as the costing to test masking, not tenant denial.
        // Doc 5.3: and assigned to the costing's buyer (object-level scope).
        String juniorToken = TestUsers.createAndLoginAssigned(restTemplate, userRepository, roleRepository,
                organizationRepository, passwordEncoder, assignmentRepository, "JUNIOR_MERCHANDISER",
                seniorSession.organizationId(), ScopeType.BUYER, style.buyerId());

        ResponseEntity<CostingResponse> juniorViewResponse = restTemplate.exchange(
                "/api/v1/costings/" + costing.id(), HttpMethod.GET, new HttpEntity<>(TestUsers.bearer(juniorToken)), CostingResponse.class);
        assertThat(juniorViewResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(juniorViewResponse.getBody().totalCost()).isNull();
        assertThat(juniorViewResponse.getBody().marginPercent()).isNull();
        assertThat(juniorViewResponse.getBody().items()).allSatisfy(item -> {
            assertThat(item.unitCost()).isNull();
            assertThat(item.totalCost()).isNull();
        });

        // Junior revises consumption only: hidden unit costs (sent as null) are carried
        // over server-side from the source version instead of being wiped or required.
        var hiddenItems = juniorViewResponse.getBody().items();
        List<CostingItemRequest> revisedItems = List.of(
                new CostingItemRequest(CostingComponentType.FABRIC, "Cotton fabric", null, new BigDecimal("2.0"), new BigDecimal("5"),
                        hiddenItems.get(0).id()),
                new CostingItemRequest(CostingComponentType.CM, "Cut & make", null, BigDecimal.ONE, BigDecimal.ZERO));
        ResponseEntity<CostingResponse> revised = restTemplate.exchange("/api/v1/costings/" + costing.id() + "/revise",
                HttpMethod.POST, new HttpEntity<>(new CostingRequest(style.id(), null, "USD", BigDecimal.ONE, 1000,
                        new BigDecimal("6.00"), revisedItems), TestUsers.bearer(juniorToken)), CostingResponse.class);
        assertThat(revised.getStatusCode().is2xxSuccessful()).isTrue();
        CostingResponse seniorView = restTemplate.exchange("/api/v1/costings/" + revised.getBody().id(), HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(seniorToken)), CostingResponse.class).getBody();
        // FABRIC: 2.00 * 2.0 * 1.05 = 4.20 ; CM: 1.50 -> 5.70
        assertThat(seniorView.totalCost()).isEqualByComparingTo("5.70");

        // A brand-new line without a unit cost cannot be carried over -> 400.
        ResponseEntity<String> newLine = restTemplate.exchange("/api/v1/costings/" + revised.getBody().id() + "/revise",
                HttpMethod.POST, new HttpEntity<>(new CostingRequest(style.id(), null, "USD", BigDecimal.ONE, 1000,
                        new BigDecimal("6.00"), List.of(new CostingItemRequest(CostingComponentType.TRIMS, "Buttons", null,
                        BigDecimal.ONE, BigDecimal.ZERO))), TestUsers.bearer(juniorToken)), String.class);
        assertThat(newLine.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void draftCosting_canBeEdited_approvedCosting_cannotBeMutatedDirectly() {
        String token = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "SENIOR_MERCHANDISER").accessToken();
        StyleResponse style = createStyle(token);

        CostingRequest request = buildRequest(style.id(), new BigDecimal("6.00"));
        CostingResponse costing = restTemplate.exchange("/api/v1/costings", HttpMethod.POST,
                new HttpEntity<>(request, TestUsers.bearer(token)), CostingResponse.class).getBody();
        assertThat(costing.status()).isEqualTo(CostingStatus.DRAFT);

        // DRAFT costing can be edited freely.
        CostingRequest updatedRequest = buildRequest(style.id(), new BigDecimal("7.00"));
        ResponseEntity<CostingResponse> updateResponse = restTemplate.exchange("/api/v1/costings/" + costing.id(), HttpMethod.PUT,
                new HttpEntity<>(updatedRequest, TestUsers.bearer(token)), CostingResponse.class);
        assertThat(updateResponse.getStatusCode()).isEqualTo(HttpStatus.OK);

        // Submit -> approve via the shared approval engine -> mark-approved.
        restTemplate.exchange("/api/v1/costings/" + costing.id() + "/submit", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(token)), CostingResponse.class);

        // /history (a plain List, unlike the paginated /approvals inbox) is the
        // exact-target lookup tests want — no need to search through other targets'
        // pending rounds.
        ResponseEntity<ApprovalResponse[]> historyResponse = restTemplate.exchange(
                "/api/v1/approvals/history?targetType=COSTING&targetId=" + costing.id(), HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), ApprovalResponse[].class);
        ApprovalResponse approval = List.of(historyResponse.getBody()).get(0);

        ResponseEntity<ApprovalResponse> decideResponse = restTemplate.exchange(
                "/api/v1/approvals/" + approval.id() + "/decide", HttpMethod.POST,
                new HttpEntity<>(new ApprovalDecisionRequest(ApprovalStatus.APPROVED, "Looks good", null), TestUsers.bearer(token)),
                ApprovalResponse.class);
        assertThat(decideResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(decideResponse.getBody().status()).isEqualTo(ApprovalStatus.APPROVED);

        ResponseEntity<CostingResponse> markApprovedResponse = restTemplate.exchange(
                "/api/v1/costings/" + costing.id() + "/mark-approved", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(token)), CostingResponse.class);
        assertThat(markApprovedResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(markApprovedResponse.getBody().status()).isEqualTo(CostingStatus.APPROVED);

        // Now immutable: PUT (edit-in-place) must be rejected.
        ResponseEntity<String> blockedEditResponse = restTemplate.exchange("/api/v1/costings/" + costing.id(), HttpMethod.PUT,
                new HttpEntity<>(updatedRequest, TestUsers.bearer(token)), String.class);
        assertThat(blockedEditResponse.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);

        // A revision creates a NEW version instead.
        ResponseEntity<CostingResponse> revisionResponse = restTemplate.exchange(
                "/api/v1/costings/" + costing.id() + "/revise", HttpMethod.POST,
                new HttpEntity<>(updatedRequest, TestUsers.bearer(token)), CostingResponse.class);
        assertThat(revisionResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(revisionResponse.getBody().versionNo()).isEqualTo(2);
        assertThat(revisionResponse.getBody().supersededFromId()).isEqualTo(costing.id());
    }

    @Test
    void decidingAnAlreadyDecidedApproval_isRejected() {
        String token = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "SENIOR_MERCHANDISER").accessToken();
        StyleResponse style = createStyle(token);
        CostingResponse costing = restTemplate.exchange("/api/v1/costings", HttpMethod.POST,
                new HttpEntity<>(buildRequest(style.id(), new BigDecimal("6.00")), TestUsers.bearer(token)), CostingResponse.class).getBody();
        restTemplate.exchange("/api/v1/costings/" + costing.id() + "/submit", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(token)), CostingResponse.class);

        ApprovalResponse approval = List.of(restTemplate.exchange(
                        "/api/v1/approvals/history?targetType=COSTING&targetId=" + costing.id(), HttpMethod.GET,
                        new HttpEntity<>(TestUsers.bearer(token)), ApprovalResponse[].class).getBody())
                .get(0);

        restTemplate.exchange("/api/v1/approvals/" + approval.id() + "/decide", HttpMethod.POST,
                new HttpEntity<>(new ApprovalDecisionRequest(ApprovalStatus.APPROVED, null, null), TestUsers.bearer(token)), ApprovalResponse.class);

        ResponseEntity<String> secondDecisionResponse = restTemplate.exchange(
                "/api/v1/approvals/" + approval.id() + "/decide", HttpMethod.POST,
                new HttpEntity<>(new ApprovalDecisionRequest(ApprovalStatus.REJECTED, null, "too late"), TestUsers.bearer(token)), String.class);
        assertThat(secondDecisionResponse.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }
}
