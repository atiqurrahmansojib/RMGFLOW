package com.rmgflow.factory;

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
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/** Security review finding (multi-tenant IDOR), factory side — mirrors BuyerTenantIsolationIntegrationTest. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class FactoryTenantIsolationIntegrationTest {

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
        return TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, role).accessToken();
    }

    @Test
    void generalManagerInOneOrg_cannotReadOrEditAnotherOrgsFactory() {
        String orgAToken = tokenFor("GENERAL_MANAGER");
        FactoryRequest createRequest = new FactoryRequest("FAC-" + UUID.randomUUID(), "Org A's Factory",
                PartnerType.GARMENT_FACTORY, null, null, null, null, null);
        FactoryResponse factory = restTemplate.exchange("/api/v1/factories", HttpMethod.POST,
                new HttpEntity<>(createRequest, TestUsers.bearer(orgAToken)), FactoryResponse.class).getBody();

        String orgBToken = tokenFor("GENERAL_MANAGER");

        ResponseEntity<String> getResponse = restTemplate.exchange(
                "/api/v1/factories/" + factory.id(), HttpMethod.GET, new HttpEntity<>(TestUsers.bearer(orgBToken)), String.class);
        assertThat(getResponse.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);

        FactoryRequest updateRequest = new FactoryRequest(factory.code(), "Hijacked", PartnerType.GARMENT_FACTORY,
                null, null, null, null, factory.version());
        ResponseEntity<String> updateResponse = restTemplate.exchange(
                "/api/v1/factories/" + factory.id(), HttpMethod.PUT, new HttpEntity<>(updateRequest, TestUsers.bearer(orgBToken)), String.class);
        assertThat(updateResponse.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void factoryBuyerApproval_cannotLinkAcrossOrganizations() {
        String orgAToken = tokenFor("GENERAL_MANAGER");
        FactoryRequest factoryRequest = new FactoryRequest("FAC-" + UUID.randomUUID(), "Org A Factory",
                PartnerType.GARMENT_FACTORY, null, null, null, null, null);
        FactoryResponse factory = restTemplate.exchange("/api/v1/factories", HttpMethod.POST,
                new HttpEntity<>(factoryRequest, TestUsers.bearer(orgAToken)), FactoryResponse.class).getBody();

        // A buyer that belongs to a completely different organization.
        String orgBToken = tokenFor("GENERAL_MANAGER");
        BuyerRequest buyerRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "Org B Buyer", null, null, null, null, null, null);
        BuyerResponse orgBBuyer = restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(buyerRequest, TestUsers.bearer(orgBToken)), BuyerResponse.class).getBody();

        // Org A's GM tries to approve ITS factory for Org B's buyer — must fail,
        // not silently create a cross-tenant approval link.
        FactoryBuyerApprovalRequest approvalRequest = new FactoryBuyerApprovalRequest(
                orgBBuyer.id(), FactoryBuyerApprovalStatus.APPROVED, LocalDate.now(), null);
        ResponseEntity<String> response = restTemplate.exchange(
                "/api/v1/factories/" + factory.id() + "/buyer-approvals", HttpMethod.PUT,
                new HttpEntity<>(approvalRequest, TestUsers.bearer(orgAToken)), String.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }
}
