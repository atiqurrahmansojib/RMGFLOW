package com.rmgflow.buyer;

import com.rmgflow.buyer.dto.BuyerContactRequest;
import com.rmgflow.buyer.dto.BuyerRequest;
import com.rmgflow.buyer.dto.BuyerResponse;
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

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Security review finding (multi-tenant IDOR): a GENERAL_MANAGER in one organization
 * must not be able to read, edit, or attach contacts to a buyer that belongs to a
 * DIFFERENT organization just by guessing/incrementing its id — even though a GM has
 * full BUYER_MANAGE rights within their own org. Every Buyer* endpoint must treat a
 * cross-org id exactly like a nonexistent one (404), per Doc 15.2.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class BuyerTenantIsolationIntegrationTest {

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
    void generalManagerInOneOrg_cannotReadEditOrAttachContactsToAnotherOrgsBuyer() {
        String orgAToken = tokenFor("GENERAL_MANAGER");
        BuyerRequest createRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "Org A's Buyer", null, null, null, null, null, null);
        BuyerResponse buyer = restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(createRequest, TestUsers.bearer(orgAToken)), BuyerResponse.class).getBody();

        // A different GM, in a brand-new (different) organization — same broad role,
        // different tenant.
        String orgBToken = tokenFor("GENERAL_MANAGER");

        ResponseEntity<String> getResponse = restTemplate.exchange(
                "/api/v1/buyers/" + buyer.id(), HttpMethod.GET, new HttpEntity<>(TestUsers.bearer(orgBToken)), String.class);
        assertThat(getResponse.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);

        BuyerRequest updateRequest = new BuyerRequest(buyer.code(), "Hijacked By Org B", null, null, null, null, null, buyer.version());
        ResponseEntity<String> updateResponse = restTemplate.exchange(
                "/api/v1/buyers/" + buyer.id(), HttpMethod.PUT, new HttpEntity<>(updateRequest, TestUsers.bearer(orgBToken)), String.class);
        assertThat(updateResponse.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);

        BuyerContactRequest contactRequest = new BuyerContactRequest("Eve", "Attacker", "eve@evil.example", null, true);
        ResponseEntity<String> contactResponse = restTemplate.exchange(
                "/api/v1/buyers/" + buyer.id() + "/contacts", HttpMethod.POST,
                new HttpEntity<>(contactRequest, TestUsers.bearer(orgBToken)), String.class);
        assertThat(contactResponse.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);

        ResponseEntity<String> listContactsResponse = restTemplate.exchange(
                "/api/v1/buyers/" + buyer.id() + "/contacts", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(orgBToken)), String.class);
        assertThat(listContactsResponse.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);

        ResponseEntity<String> deleteResponse = restTemplate.exchange(
                "/api/v1/buyers/" + buyer.id(), HttpMethod.DELETE, new HttpEntity<>(TestUsers.bearer(orgBToken)), String.class);
        assertThat(deleteResponse.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);

        // Sanity: Org A can still read its own buyer fine.
        ResponseEntity<BuyerResponse> ownGetResponse = restTemplate.exchange(
                "/api/v1/buyers/" + buyer.id(), HttpMethod.GET, new HttpEntity<>(TestUsers.bearer(orgAToken)), BuyerResponse.class);
        assertThat(ownGetResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void buyerList_onlyReturnsBuyersFromCallersOwnOrganization() {
        String orgAToken = tokenFor("GENERAL_MANAGER");
        String uniqueName = "OrgAOnly-" + UUID.randomUUID();
        BuyerRequest createRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), uniqueName, null, null, null, null, null, null);
        restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(createRequest, TestUsers.bearer(orgAToken)), BuyerResponse.class);

        String orgBToken = tokenFor("GENERAL_MANAGER");
        ResponseEntity<String> searchResponse = restTemplate.exchange(
                "/api/v1/buyers?search=" + uniqueName, HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(orgBToken)), String.class);

        assertThat(searchResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(searchResponse.getBody()).doesNotContain(uniqueName);
    }
}
