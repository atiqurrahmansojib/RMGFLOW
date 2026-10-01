package com.rmgflow.order;

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
import com.rmgflow.order.dto.OrderAmendmentRequest;
import com.rmgflow.order.dto.OrderAmendmentResponse;
import com.rmgflow.order.dto.OrderItemRequest;
import com.rmgflow.order.dto.OrderRequest;
import com.rmgflow.order.dto.OrderResponse;
import com.rmgflow.order.entity.OrderStatus;
import com.rmgflow.style.dto.StyleRequest;
import com.rmgflow.style.dto.StyleResponse;
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
 * Document 9.4/16.5 scenario #5: a factory not approved for a buyer cannot be
 * assigned to that buyer's order without an explicit, permission-gated override;
 * amendments are append-only and require Owner/GM approval to actually take effect.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class OrderFlowIntegrationTest {

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

    private OrderItemRequest buildItem(Long styleId, Long factoryId) {
        return new OrderItemRequest(styleId, factoryId, "Navy", "M", 100, new BigDecimal("5.00"));
    }

    @Test
    void orderCreation_blockedForUnapprovedFactory_succeedsWithOverride() {
        TestSession gmSession = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "GENERAL_MANAGER");
        String gmToken = gmSession.accessToken();

        BuyerRequest buyerRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "Order Test Buyer", null, null, null, null, null, null);
        BuyerResponse buyer = restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(buyerRequest, TestUsers.bearer(gmToken)), BuyerResponse.class).getBody();
        StyleRequest styleRequest = new StyleRequest("STY-" + UUID.randomUUID(), buyer.id(), null, "Jacket", null, null, null);
        StyleResponse style = restTemplate.exchange("/api/v1/styles", HttpMethod.POST,
                new HttpEntity<>(styleRequest, TestUsers.bearer(gmToken)), StyleResponse.class).getBody();
        FactoryRequest factoryRequest = new FactoryRequest("FAC-" + UUID.randomUUID(), "Unapproved Factory",
                PartnerType.GARMENT_FACTORY, null, null, null, null, null);
        FactoryResponse factory = restTemplate.exchange("/api/v1/factories", HttpMethod.POST,
                new HttpEntity<>(factoryRequest, TestUsers.bearer(gmToken)), FactoryResponse.class).getBody();

        OrderRequest blockedRequest = new OrderRequest("PO-" + UUID.randomUUID(), buyer.id(), null, LocalDate.now(), null, null,
                null, null, null, "USD", false, null, List.of(buildItem(style.id(), factory.id())));
        ResponseEntity<String> blockedResponse = restTemplate.exchange("/api/v1/orders", HttpMethod.POST,
                new HttpEntity<>(blockedRequest, TestUsers.bearer(gmToken)), String.class);
        assertThat(blockedResponse.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);

        OrderRequest overrideRequest = new OrderRequest("PO-" + UUID.randomUUID(), buyer.id(), null, LocalDate.now(), null, null,
                null, null, null, "USD", true, "Urgent order, approval pending", List.of(buildItem(style.id(), factory.id())));
        ResponseEntity<OrderResponse> overrideResponse = restTemplate.exchange("/api/v1/orders", HttpMethod.POST,
                new HttpEntity<>(overrideRequest, TestUsers.bearer(gmToken)), OrderResponse.class);
        assertThat(overrideResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(overrideResponse.getBody().totalValue()).isEqualByComparingTo("500.00");

        // Now actually approve the factory for this buyer -> plain creation should succeed too.
        restTemplate.exchange("/api/v1/factories/" + factory.id() + "/buyer-approvals", HttpMethod.PUT,
                new HttpEntity<>(new FactoryBuyerApprovalRequest(buyer.id(), FactoryBuyerApprovalStatus.APPROVED, LocalDate.now(), null), TestUsers.bearer(gmToken)),
                Void.class);
        OrderRequest normalRequest = new OrderRequest("PO-" + UUID.randomUUID(), buyer.id(), null, LocalDate.now(), null, null,
                null, null, null, "USD", false, null, List.of(buildItem(style.id(), factory.id())));
        ResponseEntity<OrderResponse> normalResponse = restTemplate.exchange("/api/v1/orders", HttpMethod.POST,
                new HttpEntity<>(normalRequest, TestUsers.bearer(gmToken)), OrderResponse.class);
        assertThat(normalResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);

        // A Senior Merchandiser without ORDER_FACTORY_OVERRIDE cannot bypass the gate either.
        String seniorToken = TestUsers.createAndLoginInOrganization(restTemplate, userRepository, roleRepository,
                organizationRepository, passwordEncoder, "SENIOR_MERCHANDISER", gmSession.organizationId());
        FactoryRequest secondFactoryRequest = new FactoryRequest("FAC-" + UUID.randomUUID(), "Another Unapproved Factory",
                PartnerType.GARMENT_FACTORY, null, null, null, null, null);
        FactoryResponse secondFactory = restTemplate.exchange("/api/v1/factories", HttpMethod.POST,
                new HttpEntity<>(secondFactoryRequest, TestUsers.bearer(gmToken)), FactoryResponse.class).getBody();
        OrderRequest deniedOverrideRequest = new OrderRequest("PO-" + UUID.randomUUID(), buyer.id(), null, LocalDate.now(), null, null,
                null, null, null, "USD", true, "I am not authorized to do this", List.of(buildItem(style.id(), secondFactory.id())));
        ResponseEntity<String> deniedResponse = restTemplate.exchange("/api/v1/orders", HttpMethod.POST,
                new HttpEntity<>(deniedOverrideRequest, TestUsers.bearer(seniorToken)), String.class);
        assertThat(deniedResponse.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void amendmentRequest_onlyTakesEffectAfterApproval() {
        TestSession gmSession = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "GENERAL_MANAGER");
        String gmToken = gmSession.accessToken();

        BuyerRequest buyerRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "Amendment Test Buyer", null, null, null, null, null, null);
        BuyerResponse buyer = restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(buyerRequest, TestUsers.bearer(gmToken)), BuyerResponse.class).getBody();
        StyleRequest styleRequest = new StyleRequest("STY-" + UUID.randomUUID(), buyer.id(), null, "Trouser", null, null, null);
        StyleResponse style = restTemplate.exchange("/api/v1/styles", HttpMethod.POST,
                new HttpEntity<>(styleRequest, TestUsers.bearer(gmToken)), StyleResponse.class).getBody();
        FactoryRequest factoryRequest = new FactoryRequest("FAC-" + UUID.randomUUID(), "Approved Factory",
                PartnerType.GARMENT_FACTORY, null, null, null, null, null);
        FactoryResponse factory = restTemplate.exchange("/api/v1/factories", HttpMethod.POST,
                new HttpEntity<>(factoryRequest, TestUsers.bearer(gmToken)), FactoryResponse.class).getBody();
        restTemplate.exchange("/api/v1/factories/" + factory.id() + "/buyer-approvals", HttpMethod.PUT,
                new HttpEntity<>(new FactoryBuyerApprovalRequest(buyer.id(), FactoryBuyerApprovalStatus.APPROVED, LocalDate.now(), null), TestUsers.bearer(gmToken)),
                Void.class);

        LocalDate originalExFactory = LocalDate.now().plusDays(60);
        OrderRequest orderRequest = new OrderRequest("PO-" + UUID.randomUUID(), buyer.id(), null, LocalDate.now(), originalExFactory, null,
                null, null, null, "USD", false, null, List.of(buildItem(style.id(), factory.id())));
        OrderResponse order = restTemplate.exchange("/api/v1/orders", HttpMethod.POST,
                new HttpEntity<>(orderRequest, TestUsers.bearer(gmToken)), OrderResponse.class).getBody();
        assertThat(order.exFactoryDate()).isEqualTo(originalExFactory);

        String seniorToken = TestUsers.createAndLoginInOrganization(restTemplate, userRepository, roleRepository,
                organizationRepository, passwordEncoder, "SENIOR_MERCHANDISER", gmSession.organizationId());
        LocalDate newExFactory = originalExFactory.plusDays(14);
        OrderAmendmentRequest amendmentRequest = new OrderAmendmentRequest("exFactoryDate", newExFactory.toString(), "Fabric delayed at source");
        ResponseEntity<OrderAmendmentResponse> requestResponse = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/amendments", HttpMethod.POST,
                new HttpEntity<>(amendmentRequest, TestUsers.bearer(seniorToken)), OrderAmendmentResponse.class);
        assertThat(requestResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);

        // A Senior Merchandiser cannot approve their own amendment request (Doc 5.2).
        ResponseEntity<String> deniedApproval = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/amendments/" + requestResponse.getBody().id() + "/approve", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(seniorToken)), String.class);
        assertThat(deniedApproval.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);

        // The order's actual field is unchanged until approved.
        OrderResponse stillOriginal = restTemplate.exchange("/api/v1/orders/" + order.id(), HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(gmToken)), OrderResponse.class).getBody();
        assertThat(stillOriginal.exFactoryDate()).isEqualTo(originalExFactory);

        ResponseEntity<OrderAmendmentResponse> approveResponse = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/amendments/" + requestResponse.getBody().id() + "/approve", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(gmToken)), OrderAmendmentResponse.class);
        assertThat(approveResponse.getStatusCode()).isEqualTo(HttpStatus.OK);

        OrderResponse updatedOrder = restTemplate.exchange("/api/v1/orders/" + order.id(), HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(gmToken)), OrderResponse.class).getBody();
        assertThat(updatedOrder.exFactoryDate()).isEqualTo(newExFactory);

        // Re-deciding the same amendment is rejected (Doc 9.3/9.4 pattern, DB trigger backed).
        ResponseEntity<String> secondDecision = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/amendments/" + requestResponse.getBody().id() + "/reject", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(gmToken)), String.class);
        assertThat(secondDecision.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void cancellation_requiresReasonAndOrderCancelApprovePermission() {
        TestSession gmSession = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "GENERAL_MANAGER");
        String gmToken = gmSession.accessToken();

        BuyerRequest buyerRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "Cancel Test Buyer", null, null, null, null, null, null);
        BuyerResponse buyer = restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(buyerRequest, TestUsers.bearer(gmToken)), BuyerResponse.class).getBody();
        StyleRequest styleRequest = new StyleRequest("STY-" + UUID.randomUUID(), buyer.id(), null, "Skirt", null, null, null);
        StyleResponse style = restTemplate.exchange("/api/v1/styles", HttpMethod.POST,
                new HttpEntity<>(styleRequest, TestUsers.bearer(gmToken)), StyleResponse.class).getBody();
        FactoryRequest factoryRequest = new FactoryRequest("FAC-" + UUID.randomUUID(), "Cancel Test Factory",
                PartnerType.GARMENT_FACTORY, null, null, null, null, null);
        FactoryResponse factory = restTemplate.exchange("/api/v1/factories", HttpMethod.POST,
                new HttpEntity<>(factoryRequest, TestUsers.bearer(gmToken)), FactoryResponse.class).getBody();
        restTemplate.exchange("/api/v1/factories/" + factory.id() + "/buyer-approvals", HttpMethod.PUT,
                new HttpEntity<>(new FactoryBuyerApprovalRequest(buyer.id(), FactoryBuyerApprovalStatus.APPROVED, LocalDate.now(), null), TestUsers.bearer(gmToken)),
                Void.class);
        OrderRequest orderRequest = new OrderRequest("PO-" + UUID.randomUUID(), buyer.id(), null, LocalDate.now(), null, null,
                null, null, null, "USD", false, null, List.of(buildItem(style.id(), factory.id())));
        OrderResponse order = restTemplate.exchange("/api/v1/orders", HttpMethod.POST,
                new HttpEntity<>(orderRequest, TestUsers.bearer(gmToken)), OrderResponse.class).getBody();

        String seniorToken = TestUsers.createAndLoginInOrganization(restTemplate, userRepository, roleRepository,
                organizationRepository, passwordEncoder, "SENIOR_MERCHANDISER", gmSession.organizationId());
        ResponseEntity<String> deniedCancel = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/cancel?reason=buyer+walked+away", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(seniorToken)), String.class);
        assertThat(deniedCancel.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);

        ResponseEntity<Void> cancelResponse = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/cancel?reason=buyer+walked+away", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(gmToken)), Void.class);
        assertThat(cancelResponse.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);

        OrderResponse cancelled = restTemplate.exchange("/api/v1/orders/" + order.id(), HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(gmToken)), OrderResponse.class).getBody();
        assertThat(cancelled.status()).isEqualTo(OrderStatus.CANCELLED);
    }
}
