package com.rmgflow.claim;

import com.rmgflow.buyer.dto.BuyerRequest;
import com.rmgflow.buyer.dto.BuyerResponse;
import com.rmgflow.claim.dto.ClaimRequest;
import com.rmgflow.claim.dto.ClaimResolutionRequest;
import com.rmgflow.claim.dto.ClaimResponse;
import com.rmgflow.claim.entity.ClaimRaisedBy;
import com.rmgflow.claim.entity.ClaimStatus;
import com.rmgflow.claim.entity.ClaimType;
import com.rmgflow.factory.dto.FactoryBuyerApprovalRequest;
import com.rmgflow.factory.dto.FactoryRequest;
import com.rmgflow.factory.dto.FactoryResponse;
import com.rmgflow.factory.entity.FactoryBuyerApprovalStatus;
import com.rmgflow.factory.entity.PartnerType;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.RoleRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.order.dto.OrderItemRequest;
import com.rmgflow.order.dto.OrderRequest;
import com.rmgflow.order.dto.OrderResponse;
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

/** Document 9.11/10.8/16.1: a claim's resolution never alters the original order's
 * own commercial record — only the claim row itself changes. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class ClaimFlowIntegrationTest {

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
    void claimLifecycle_openToResolved_orderUnaffected() {
        String token = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "GENERAL_MANAGER").accessToken();

        BuyerRequest buyerRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "Claim Test Buyer", null, null, null, null, null, null);
        BuyerResponse buyer = restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(buyerRequest, TestUsers.bearer(token)), BuyerResponse.class).getBody();
        StyleRequest styleRequest = new StyleRequest("STY-" + UUID.randomUUID(), buyer.id(), null, "Coat", null, null, null);
        StyleResponse style = restTemplate.exchange("/api/v1/styles", HttpMethod.POST,
                new HttpEntity<>(styleRequest, TestUsers.bearer(token)), StyleResponse.class).getBody();
        FactoryRequest factoryRequest = new FactoryRequest("FAC-" + UUID.randomUUID(), "Claim Test Factory",
                PartnerType.GARMENT_FACTORY, null, null, null, null, null);
        FactoryResponse factory = restTemplate.exchange("/api/v1/factories", HttpMethod.POST,
                new HttpEntity<>(factoryRequest, TestUsers.bearer(token)), FactoryResponse.class).getBody();
        restTemplate.exchange("/api/v1/factories/" + factory.id() + "/buyer-approvals", HttpMethod.PUT,
                new HttpEntity<>(new FactoryBuyerApprovalRequest(buyer.id(), FactoryBuyerApprovalStatus.APPROVED, LocalDate.now(), null), TestUsers.bearer(token)),
                Void.class);
        OrderItemRequest item = new OrderItemRequest(style.id(), factory.id(), "Camel", "M", 80, new BigDecimal("15.00"));
        OrderRequest orderRequest = new OrderRequest("PO-" + UUID.randomUUID(), buyer.id(), null, LocalDate.now(), null, null,
                null, null, null, "USD", false, null, List.of(item));
        OrderResponse orderBefore = restTemplate.exchange("/api/v1/orders", HttpMethod.POST,
                new HttpEntity<>(orderRequest, TestUsers.bearer(token)), OrderResponse.class).getBody();

        ClaimRequest claimRequest = new ClaimRequest(null, ClaimRaisedBy.BUYER, ClaimType.QUALITY, "Received goods had loose buttons", new BigDecimal("200.00"));
        ResponseEntity<ClaimResponse> createResponse = restTemplate.exchange("/api/v1/orders/" + orderBefore.id() + "/claims", HttpMethod.POST,
                new HttpEntity<>(claimRequest, TestUsers.bearer(token)), ClaimResponse.class);
        assertThat(createResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(createResponse.getBody().status()).isEqualTo(ClaimStatus.OPEN);
        Long claimId = createResponse.getBody().id();

        restTemplate.exchange("/api/v1/claims/" + claimId + "/resolve", HttpMethod.POST,
                new HttpEntity<>(new ClaimResolutionRequest(ClaimStatus.UNDER_REVIEW, null), TestUsers.bearer(token)), ClaimResponse.class);

        ResponseEntity<ClaimResponse> resolveResponse = restTemplate.exchange("/api/v1/claims/" + claimId + "/resolve", HttpMethod.POST,
                new HttpEntity<>(new ClaimResolutionRequest(ClaimStatus.RESOLVED, "Replacement buttons shipped free of charge"), TestUsers.bearer(token)),
                ClaimResponse.class);
        assertThat(resolveResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(resolveResponse.getBody().status()).isEqualTo(ClaimStatus.RESOLVED);
        assertThat(resolveResponse.getBody().resolvedAt()).isNotNull();

        // Re-resolving an already-resolved claim is rejected.
        ResponseEntity<String> secondResolve = restTemplate.exchange("/api/v1/claims/" + claimId + "/resolve", HttpMethod.POST,
                new HttpEntity<>(new ClaimResolutionRequest(ClaimStatus.REJECTED, "too late"), TestUsers.bearer(token)), String.class);
        assertThat(secondResolve.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);

        // The order's own commercial record is untouched by the claim.
        OrderResponse orderAfter = restTemplate.exchange("/api/v1/orders/" + orderBefore.id(), HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), OrderResponse.class).getBody();
        assertThat(orderAfter.totalValue()).isEqualByComparingTo(orderBefore.totalValue());
        assertThat(orderAfter.status()).isEqualTo(orderBefore.status());
    }
}
