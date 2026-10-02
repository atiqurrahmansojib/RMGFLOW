package com.rmgflow.production;

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
import com.rmgflow.production.dto.ProductionProgressResponse;
import com.rmgflow.production.dto.ProductionUpdateRequest;
import com.rmgflow.production.dto.ProductionUpdateResponse;
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
 * Document 9.6/16.1: cumulative totals are always derived (never a stored running
 * total), cutting/sewing/finishing over-order-quantity is a soft signal, and
 * packing cumulative exceeding the order quantity is a hard block.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class ProductionUpdateFlowIntegrationTest {

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
        BuyerRequest buyerRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "Production Test Buyer", null, null, null, null, null, null);
        BuyerResponse buyer = restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(buyerRequest, TestUsers.bearer(token)), BuyerResponse.class).getBody();
        StyleRequest styleRequest = new StyleRequest("STY-" + UUID.randomUUID(), buyer.id(), null, "Shorts", null, null, null);
        StyleResponse style = restTemplate.exchange("/api/v1/styles", HttpMethod.POST,
                new HttpEntity<>(styleRequest, TestUsers.bearer(token)), StyleResponse.class).getBody();
        FactoryRequest factoryRequest = new FactoryRequest("FAC-" + UUID.randomUUID(), "Production Test Factory",
                PartnerType.GARMENT_FACTORY, null, null, null, null, null);
        FactoryResponse factory = restTemplate.exchange("/api/v1/factories", HttpMethod.POST,
                new HttpEntity<>(factoryRequest, TestUsers.bearer(token)), FactoryResponse.class).getBody();
        restTemplate.exchange("/api/v1/factories/" + factory.id() + "/buyer-approvals", HttpMethod.PUT,
                new HttpEntity<>(new FactoryBuyerApprovalRequest(buyer.id(), FactoryBuyerApprovalStatus.APPROVED, LocalDate.now(), null), TestUsers.bearer(token)),
                Void.class);
        OrderItemRequest item = new OrderItemRequest(style.id(), factory.id(), "White", "S", quantity, new BigDecimal("3.00"));
        OrderRequest orderRequest = new OrderRequest("PO-" + UUID.randomUUID(), buyer.id(), null, LocalDate.now(), null, null,
                null, null, null, "USD", false, null, List.of(item));
        return restTemplate.exchange("/api/v1/orders", HttpMethod.POST,
                new HttpEntity<>(orderRequest, TestUsers.bearer(token)), OrderResponse.class).getBody();
    }

    @Test
    void cumulativeTotals_areDerivedFromDailyEntries_cuttingCanExceedOrderQtySoftly() {
        String token = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "GENERAL_MANAGER").accessToken();
        OrderResponse order = createOrder(token, 100);

        restTemplate.exchange("/api/v1/orders/" + order.id() + "/production-updates", HttpMethod.POST,
                new HttpEntity<>(new ProductionUpdateRequest(LocalDate.now().minusDays(1), 60, 40, 30, 20, 2, 1), TestUsers.bearer(token)),
                ProductionUpdateResponse.class);
        ResponseEntity<ProductionUpdateResponse> secondDay = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/production-updates", HttpMethod.POST,
                new HttpEntity<>(new ProductionUpdateRequest(LocalDate.now(), 50, 40, 30, 20, 0, 0), TestUsers.bearer(token)), ProductionUpdateResponse.class);
        assertThat(secondDay.getStatusCode()).isEqualTo(HttpStatus.OK);

        // Cutting cumulative (110) exceeds order qty (100) — allowed (soft signal only, Doc 9.6).
        ResponseEntity<ProductionProgressResponse> progress = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/production-updates", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), ProductionProgressResponse.class);
        assertThat(progress.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(progress.getBody().cumulativeCutting()).isEqualTo(110);
        assertThat(progress.getBody().cumulativeSewing()).isEqualTo(80);
        assertThat(progress.getBody().cumulativePacking()).isEqualTo(40);
        assertThat(progress.getBody().packingProgressPercent()).isEqualTo(40.0);
        assertThat(progress.getBody().dailyUpdates()).hasSize(2);
    }

    @Test
    void sameDayCorrection_overwritesRatherThanDuplicating() {
        String token = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "GENERAL_MANAGER").accessToken();
        OrderResponse order = createOrder(token, 100);
        LocalDate today = LocalDate.now();

        restTemplate.exchange("/api/v1/orders/" + order.id() + "/production-updates", HttpMethod.POST,
                new HttpEntity<>(new ProductionUpdateRequest(today, 10, 0, 0, 0, 0, 0), TestUsers.bearer(token)), ProductionUpdateResponse.class);
        restTemplate.exchange("/api/v1/orders/" + order.id() + "/production-updates", HttpMethod.POST,
                new HttpEntity<>(new ProductionUpdateRequest(today, 25, 0, 0, 0, 0, 0), TestUsers.bearer(token)), ProductionUpdateResponse.class);

        ProductionProgressResponse progress = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/production-updates", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), ProductionProgressResponse.class).getBody();
        assertThat(progress.dailyUpdates()).hasSize(1);
        assertThat(progress.cumulativeCutting()).isEqualTo(25);
    }

    @Test
    void packingCumulative_exceedingOrderQuantity_isHardBlocked() {
        String token = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "GENERAL_MANAGER").accessToken();
        OrderResponse order = createOrder(token, 100);

        restTemplate.exchange("/api/v1/orders/" + order.id() + "/production-updates", HttpMethod.POST,
                new HttpEntity<>(new ProductionUpdateRequest(LocalDate.now().minusDays(1), 100, 100, 100, 90, 0, 0), TestUsers.bearer(token)),
                ProductionUpdateResponse.class);

        ResponseEntity<String> blockedResponse = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/production-updates", HttpMethod.POST,
                new HttpEntity<>(new ProductionUpdateRequest(LocalDate.now(), 0, 0, 0, 15, 0, 0), TestUsers.bearer(token)), String.class);
        assertThat(blockedResponse.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);

        // Exactly filling the remaining quantity succeeds.
        ResponseEntity<ProductionUpdateResponse> exactResponse = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/production-updates", HttpMethod.POST,
                new HttpEntity<>(new ProductionUpdateRequest(LocalDate.now(), 0, 0, 0, 10, 0, 0), TestUsers.bearer(token)), ProductionUpdateResponse.class);
        assertThat(exactResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
    }
}
