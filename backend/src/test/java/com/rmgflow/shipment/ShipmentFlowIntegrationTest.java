package com.rmgflow.shipment;

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
import com.rmgflow.order.dto.OrderItemRequest;
import com.rmgflow.order.dto.OrderRequest;
import com.rmgflow.order.dto.OrderResponse;
import com.rmgflow.order.entity.OrderStatus;
import com.rmgflow.quality.dto.InspectionRequest;
import com.rmgflow.quality.dto.InspectionResponse;
import com.rmgflow.quality.entity.InspectionResult;
import com.rmgflow.quality.entity.InspectionType;
import com.rmgflow.shipment.dto.ShipmentRequest;
import com.rmgflow.shipment.dto.ShipmentResponse;
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
 * Document 9.7/9.8/9.11/16.5 scenario #4: the final-inspection quality gate,
 * the never-exceed-order-quantity hard block (no override exists for this one),
 * and the partial-shipment authorization permission.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class ShipmentFlowIntegrationTest {

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

    private OrderResponse createOrder(String token, int quantity) {
        BuyerRequest buyerRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "Shipment Test Buyer", null, null, null, null, null, null);
        BuyerResponse buyer = restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(buyerRequest, TestUsers.bearer(token)), BuyerResponse.class).getBody();
        StyleRequest styleRequest = new StyleRequest("STY-" + UUID.randomUUID(), buyer.id(), null, "Jeans", null, null, null);
        StyleResponse style = restTemplate.exchange("/api/v1/styles", HttpMethod.POST,
                new HttpEntity<>(styleRequest, TestUsers.bearer(token)), StyleResponse.class).getBody();
        FactoryRequest factoryRequest = new FactoryRequest("FAC-" + UUID.randomUUID(), "Shipment Test Factory",
                PartnerType.GARMENT_FACTORY, null, null, null, null, null);
        FactoryResponse factory = restTemplate.exchange("/api/v1/factories", HttpMethod.POST,
                new HttpEntity<>(factoryRequest, TestUsers.bearer(token)), FactoryResponse.class).getBody();
        restTemplate.exchange("/api/v1/factories/" + factory.id() + "/buyer-approvals", HttpMethod.PUT,
                new HttpEntity<>(new FactoryBuyerApprovalRequest(buyer.id(), FactoryBuyerApprovalStatus.APPROVED, LocalDate.now(), null), TestUsers.bearer(token)),
                Void.class);
        OrderItemRequest item = new OrderItemRequest(style.id(), factory.id(), "Blue", "32", quantity, new BigDecimal("6.00"));
        OrderRequest orderRequest = new OrderRequest("PO-" + UUID.randomUUID(), buyer.id(), null, LocalDate.now(), null, null,
                null, null, null, "USD", false, null, List.of(item));
        return restTemplate.exchange("/api/v1/orders", HttpMethod.POST,
                new HttpEntity<>(orderRequest, TestUsers.bearer(token)), OrderResponse.class).getBody();
    }

    private ShipmentRequest shipmentRequest(int qty) {
        return new ShipmentRequest(LocalDate.now(), LocalDate.now(), LocalDate.now().plusDays(20), qty, 10,
                new BigDecimal("500"), new BigDecimal("480"), new BigDecimal("3.5"), "Chittagong", "Rotterdam",
                null, "Maersk", "CONT123", "BL123", false, null);
    }

    @Test
    void shipmentBlockedWithoutPassingFinalInspection_succeedsWithOverride() {
        String token = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "GENERAL_MANAGER").accessToken();
        OrderResponse order = createOrder(token, 100);

        ResponseEntity<String> blockedResponse = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/shipments", HttpMethod.POST,
                new HttpEntity<>(shipmentRequest(100), TestUsers.bearer(token)), String.class);
        assertThat(blockedResponse.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);

        ShipmentRequest overrideRequest = new ShipmentRequest(LocalDate.now(), LocalDate.now(), LocalDate.now().plusDays(20), 100, 10,
                new BigDecimal("500"), new BigDecimal("480"), new BigDecimal("3.5"), "Chittagong", "Rotterdam",
                null, "Maersk", "CONT123", "BL123", true, "Buyer accepted with concession");
        ResponseEntity<ShipmentResponse> overrideResponse = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/shipments", HttpMethod.POST,
                new HttpEntity<>(overrideRequest, TestUsers.bearer(token)), ShipmentResponse.class);
        assertThat(overrideResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);

        OrderResponse shippedOrder = restTemplate.exchange("/api/v1/orders/" + order.id(), HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), OrderResponse.class).getBody();
        assertThat(shippedOrder.status()).isEqualTo(OrderStatus.SHIPPED);
    }

    @Test
    void shipmentQuantity_neverExceedsOrderQuantity_noOverrideExists() {
        String token = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "GENERAL_MANAGER").accessToken();
        OrderResponse order = createOrder(token, 100);
        passFinalInspection(token, order.id());

        ResponseEntity<String> response = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/shipments", HttpMethod.POST,
                new HttpEntity<>(shipmentRequest(150), TestUsers.bearer(token)), String.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void partialShipment_requiresAuthorizationPermission_commercialExecutiveCannotAuthorize() {
        TestSession gmSession = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "GENERAL_MANAGER");
        String gmToken = gmSession.accessToken();
        OrderResponse order = createOrder(gmToken, 100);
        passFinalInspection(gmToken, order.id());

        String commercialToken = TestUsers.createAndLoginInOrganization(restTemplate, userRepository, roleRepository,
                organizationRepository, passwordEncoder, "COMMERCIAL_EXECUTIVE", gmSession.organizationId());

        // Partial (60 of 100) attempted by a role without SHIPMENT_PARTIAL_AUTHORIZE.
        ResponseEntity<String> deniedResponse = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/shipments", HttpMethod.POST,
                new HttpEntity<>(shipmentRequest(60), TestUsers.bearer(commercialToken)), String.class);
        assertThat(deniedResponse.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);

        // GM (holds SHIPMENT_PARTIAL_AUTHORIZE) can.
        ResponseEntity<ShipmentResponse> partialResponse = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/shipments", HttpMethod.POST,
                new HttpEntity<>(shipmentRequest(60), TestUsers.bearer(gmToken)), ShipmentResponse.class);
        assertThat(partialResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(partialResponse.getBody().partial()).isTrue();

        OrderResponse partiallyShipped = restTemplate.exchange("/api/v1/orders/" + order.id(), HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(gmToken)), OrderResponse.class).getBody();
        assertThat(partiallyShipped.status()).isEqualTo(OrderStatus.PARTIALLY_SHIPPED);

        // Completing shipment exactly fills the remaining 40 and is not "partial".
        ResponseEntity<ShipmentResponse> finalResponse = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/shipments", HttpMethod.POST,
                new HttpEntity<>(shipmentRequest(40), TestUsers.bearer(gmToken)), ShipmentResponse.class);
        assertThat(finalResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(finalResponse.getBody().partial()).isFalse();

        OrderResponse fullyShipped = restTemplate.exchange("/api/v1/orders/" + order.id(), HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(gmToken)), OrderResponse.class).getBody();
        assertThat(fullyShipped.status()).isEqualTo(OrderStatus.SHIPPED);
    }

    private void passFinalInspection(String token, Long orderId) {
        InspectionRequest passRequest = new InspectionRequest(InspectionType.FINAL, LocalDate.now(), 100, "2.5", InspectionResult.PASS);
        ResponseEntity<InspectionResponse> response = restTemplate.exchange("/api/v1/orders/" + orderId + "/inspections", HttpMethod.POST,
                new HttpEntity<>(passRequest, TestUsers.bearer(token)), InspectionResponse.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
    }
}
