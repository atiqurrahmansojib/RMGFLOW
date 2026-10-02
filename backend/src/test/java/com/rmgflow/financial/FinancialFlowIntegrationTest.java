package com.rmgflow.financial;

import com.rmgflow.buyer.dto.BuyerRequest;
import com.rmgflow.buyer.dto.BuyerResponse;
import com.rmgflow.factory.dto.FactoryBuyerApprovalRequest;
import com.rmgflow.factory.dto.FactoryRequest;
import com.rmgflow.factory.dto.FactoryResponse;
import com.rmgflow.factory.entity.FactoryBuyerApprovalStatus;
import com.rmgflow.factory.entity.PartnerType;
import com.rmgflow.financial.dto.*;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.RoleRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.order.dto.OrderItemRequest;
import com.rmgflow.order.dto.OrderRequest;
import com.rmgflow.order.dto.OrderResponse;
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

/** Document 9.10/16.1: margin falls back to an estimate (quoted price) until a
 * realized price is recorded; receivable status is always derived, never set directly. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class FinancialFlowIntegrationTest {

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

    private BuyerResponse buyer;

    private OrderResponse createOrder(String token) {
        BuyerRequest buyerRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "Financial Test Buyer", null, null, null, null, null, null);
        buyer = restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(buyerRequest, TestUsers.bearer(token)), BuyerResponse.class).getBody();
        StyleRequest styleRequest = new StyleRequest("STY-" + UUID.randomUUID(), buyer.id(), null, "Vest", null, null, null);
        StyleResponse style = restTemplate.exchange("/api/v1/styles", HttpMethod.POST,
                new HttpEntity<>(styleRequest, TestUsers.bearer(token)), StyleResponse.class).getBody();
        FactoryRequest factoryRequest = new FactoryRequest("FAC-" + UUID.randomUUID(), "Financial Test Factory",
                PartnerType.GARMENT_FACTORY, null, null, null, null, null);
        FactoryResponse factory = restTemplate.exchange("/api/v1/factories", HttpMethod.POST,
                new HttpEntity<>(factoryRequest, TestUsers.bearer(token)), FactoryResponse.class).getBody();
        restTemplate.exchange("/api/v1/factories/" + factory.id() + "/buyer-approvals", HttpMethod.PUT,
                new HttpEntity<>(new FactoryBuyerApprovalRequest(buyer.id(), FactoryBuyerApprovalStatus.APPROVED, LocalDate.now(), null), TestUsers.bearer(token)),
                Void.class);
        OrderItemRequest item = new OrderItemRequest(style.id(), factory.id(), "Black", "L", 200, new BigDecimal("5.00"));
        OrderRequest orderRequest = new OrderRequest("PO-" + UUID.randomUUID(), buyer.id(), null, LocalDate.now(), null, null,
                null, null, null, "USD", false, null, List.of(item));
        return restTemplate.exchange("/api/v1/orders", HttpMethod.POST,
                new HttpEntity<>(orderRequest, TestUsers.bearer(token)), OrderResponse.class).getBody();
    }

    @Test
    void marginFallsBackToEstimate_untilRealizedPriceRecorded() {
        String token = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "GENERAL_MANAGER").accessToken();
        OrderResponse order = createOrder(token);

        OrderFinancialsRequest estimateRequest = new OrderFinancialsRequest(new BigDecimal("5.00"), new BigDecimal("4.00"), null);
        ResponseEntity<OrderFinancialsResponse> estimateResponse = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/financials", HttpMethod.PUT,
                new HttpEntity<>(estimateRequest, TestUsers.bearer(token)), OrderFinancialsResponse.class);
        assertThat(estimateResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(estimateResponse.getBody().isEstimate()).isTrue();
        assertThat(estimateResponse.getBody().operationalMarginPercent()).isEqualByComparingTo("20.000");

        OrderFinancialsRequest realizedRequest = new OrderFinancialsRequest(new BigDecimal("5.00"), new BigDecimal("4.00"), new BigDecimal("4.50"));
        ResponseEntity<OrderFinancialsResponse> realizedResponse = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/financials", HttpMethod.PUT,
                new HttpEntity<>(realizedRequest, TestUsers.bearer(token)), OrderFinancialsResponse.class);
        assertThat(realizedResponse.getBody().isEstimate()).isFalse();
        // (4.50 - 4.00) / 4.50 * 100 = 11.111%
        assertThat(realizedResponse.getBody().operationalMarginPercent()).isEqualByComparingTo("11.111");
    }

    @Test
    void receivableStatus_isAlwaysDerived_neverSetDirectly() {
        TestSession gmSession = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "GENERAL_MANAGER");
        String gmToken = gmSession.accessToken();
        OrderResponse order = createOrder(gmToken);

        String accountsToken = TestUsers.createAndLoginInOrganization(restTemplate, userRepository, roleRepository,
                organizationRepository, passwordEncoder, "ACCOUNTS_FINANCE", gmSession.organizationId());

        ReceivableRequest receivableRequest = new ReceivableRequest(buyer.id(), new BigDecimal("1000.00"), "USD", LocalDate.now().minusDays(1));
        ResponseEntity<ReceivableResponse> createResponse = restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/receivables", HttpMethod.POST,
                new HttpEntity<>(receivableRequest, TestUsers.bearer(accountsToken)), ReceivableResponse.class);
        assertThat(createResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        // due_date already in the past, nothing received -> OVERDUE, derived not stored.
        assertThat(createResponse.getBody().status()).isEqualTo("OVERDUE");
        Long receivableId = createResponse.getBody().id();

        PaymentRecordRequest partialPayment = new PaymentRecordRequest(receivableId, null, new BigDecimal("400.00"), LocalDate.now(), "TT", "REF-1");
        restTemplate.exchange("/api/v1/payment-records", HttpMethod.POST,
                new HttpEntity<>(partialPayment, TestUsers.bearer(accountsToken)), PaymentRecordResponse.class);

        List<ReceivableResponse> afterPartial = List.of(restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/receivables", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(accountsToken)), ReceivableResponse[].class).getBody());
        assertThat(afterPartial).hasSize(1);
        // Still overdue (due date passed) even though partially received — not yet fully received.
        assertThat(afterPartial.get(0).status()).isEqualTo("OVERDUE");
        assertThat(afterPartial.get(0).receivedAmount()).isEqualByComparingTo("400.00");

        PaymentRecordRequest finalPayment = new PaymentRecordRequest(receivableId, null, new BigDecimal("600.00"), LocalDate.now(), "TT", "REF-2");
        restTemplate.exchange("/api/v1/payment-records", HttpMethod.POST,
                new HttpEntity<>(finalPayment, TestUsers.bearer(accountsToken)), PaymentRecordResponse.class);

        List<ReceivableResponse> afterFull = List.of(restTemplate.exchange(
                "/api/v1/orders/" + order.id() + "/receivables", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(accountsToken)), ReceivableResponse[].class).getBody());
        assertThat(afterFull.get(0).status()).isEqualTo("RECEIVED");
        assertThat(afterFull.get(0).receivedAmount()).isEqualByComparingTo("1000.00");
    }
}
