package com.rmgflow.factory;

import com.rmgflow.buyer.dto.BuyerRequest;
import com.rmgflow.buyer.dto.BuyerResponse;
import com.rmgflow.factory.dto.FactoryBuyerApprovalRequest;
import com.rmgflow.factory.dto.FactoryBuyerApprovalResponse;
import com.rmgflow.factory.dto.FactoryRequest;
import com.rmgflow.factory.dto.FactoryResponse;
import com.rmgflow.factory.entity.FactoryBuyerApprovalStatus;
import com.rmgflow.factory.entity.PartnerType;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.RoleRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.support.PostgresTestContainerConfig;
import com.rmgflow.support.TestUsers;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.resttestclient.TestRestTemplate;
import org.springframework.boot.resttestclient.autoconfigure.AutoConfigureTestRestTemplate;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.*;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Document 9.4/21 P2-T5: proves the factory-buyer approval data model works end to
 * end — this is the exact table OrderService (Phase 6) will query before allowing
 * a factory onto a buyer's order, so its CRUD correctness matters beyond Phase 2.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class FactoryBuyerApprovalIntegrationTest {

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

    private String tokenFor(String role) {
        return TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, role);
    }

    @Test
    void generalManager_canApproveFactoryForBuyer_andJuniorCannot() {
        String gmToken = tokenFor("GENERAL_MANAGER");

        FactoryRequest factoryRequest = new FactoryRequest("FAC-" + UUID.randomUUID(), "Dhaka Garments Ltd",
                PartnerType.GARMENT_FACTORY, "Dhaka Garments Ltd.", "Dhaka, Bangladesh", "BD", 50000, null);
        FactoryResponse factory = restTemplate.exchange("/api/v1/factories", HttpMethod.POST,
                new HttpEntity<>(factoryRequest, TestUsers.bearer(gmToken)), FactoryResponse.class).getBody();

        BuyerRequest buyerRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "H&M-like Buyer", null, null, null, null, null, null);
        BuyerResponse buyer = restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(buyerRequest, TestUsers.bearer(gmToken)), BuyerResponse.class).getBody();

        FactoryBuyerApprovalRequest approvalRequest = new FactoryBuyerApprovalRequest(
                buyer.id(), FactoryBuyerApprovalStatus.APPROVED, LocalDate.now(), LocalDate.now().plusYears(1));

        ResponseEntity<FactoryBuyerApprovalResponse> approveResponse = restTemplate.exchange(
                "/api/v1/factories/" + factory.id() + "/buyer-approvals", HttpMethod.PUT,
                new HttpEntity<>(approvalRequest, TestUsers.bearer(gmToken)), FactoryBuyerApprovalResponse.class);
        assertThat(approveResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(approveResponse.getBody().status()).isEqualTo(FactoryBuyerApprovalStatus.APPROVED);

        // A Junior Merchandiser has FACTORY_VIEW but not FACTORY_APPROVE_FOR_BUYER (Doc 5.2).
        String juniorToken = tokenFor("JUNIOR_MERCHANDISER");
        ResponseEntity<String> deniedResponse = restTemplate.exchange(
                "/api/v1/factories/" + factory.id() + "/buyer-approvals", HttpMethod.PUT,
                new HttpEntity<>(approvalRequest, TestUsers.bearer(juniorToken)), String.class);
        assertThat(deniedResponse.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);

        ResponseEntity<FactoryBuyerApprovalResponse[]> listResponse = restTemplate.exchange(
                "/api/v1/factories/" + factory.id() + "/buyer-approvals", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(juniorToken)), FactoryBuyerApprovalResponse[].class);
        assertThat(listResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(List.of(listResponse.getBody())).hasSize(1);
    }
}
