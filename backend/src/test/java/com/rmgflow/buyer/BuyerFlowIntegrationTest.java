package com.rmgflow.buyer;

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
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Document 16.2/16.3/9.4-adjacent: covers buyer CRUD, optimistic locking (Doc 8.12),
 * and the Doc 5.3 object-level scoping rule — a Junior Merchandiser can create a
 * buyer (becoming auto-assigned) but cannot edit a buyer created by someone else.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class BuyerFlowIntegrationTest {

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
    void seniorMerchandiser_canCreateUpdateAndListBuyers() {
        String token = tokenFor("SENIOR_MERCHANDISER");
        BuyerRequest createRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "Acme Apparel", "Acme Group", "US", "USD", null, "FOB", null);

        ResponseEntity<BuyerResponse> createResponse = restTemplate.exchange(
                "/api/v1/buyers", HttpMethod.POST, new HttpEntity<>(createRequest, TestUsers.bearer(token)), BuyerResponse.class);
        assertThat(createResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        BuyerResponse created = createResponse.getBody();
        assertThat(created).isNotNull();
        assertThat(created.version()).isZero();

        BuyerRequest updateRequest = new BuyerRequest(created.code(), "Acme Apparel Ltd.", "Acme Group", "US", "USD", null, "FOB", created.version());
        ResponseEntity<BuyerResponse> updateResponse = restTemplate.exchange(
                "/api/v1/buyers/" + created.id(), HttpMethod.PUT, new HttpEntity<>(updateRequest, TestUsers.bearer(token)), BuyerResponse.class);
        assertThat(updateResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(updateResponse.getBody().name()).isEqualTo("Acme Apparel Ltd.");
        assertThat(updateResponse.getBody().version()).isEqualTo(1);

        // Stale version (still 0) must be rejected with 409 (Doc 8.12/11.3).
        ResponseEntity<String> staleResponse = restTemplate.exchange(
                "/api/v1/buyers/" + created.id(), HttpMethod.PUT, new HttpEntity<>(updateRequest, TestUsers.bearer(token)), String.class);
        assertThat(staleResponse.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
    }

    @Test
    void juniorMerchandiser_cannotEditABuyerTheyAreNotAssignedTo() {
        String seniorToken = tokenFor("SENIOR_MERCHANDISER");
        BuyerRequest createRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "Other Buyer Co", null, null, null, null, null, null);
        BuyerResponse buyer = restTemplate.exchange(
                "/api/v1/buyers", HttpMethod.POST, new HttpEntity<>(createRequest, TestUsers.bearer(seniorToken)), BuyerResponse.class).getBody();

        String juniorToken = tokenFor("JUNIOR_MERCHANDISER");
        BuyerRequest updateRequest = new BuyerRequest(buyer.code(), "Hijacked Name", null, null, null, null, null, buyer.version());
        ResponseEntity<String> response = restTemplate.exchange(
                "/api/v1/buyers/" + buyer.id(), HttpMethod.PUT, new HttpEntity<>(updateRequest, TestUsers.bearer(juniorToken)), String.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
    }

    @Test
    void juniorMerchandiser_canEditABuyerTheyCreatedThemselves() {
        String juniorToken = tokenFor("JUNIOR_MERCHANDISER");
        BuyerRequest createRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "My Own Buyer", null, null, null, null, null, null);
        ResponseEntity<BuyerResponse> createResponse = restTemplate.exchange(
                "/api/v1/buyers", HttpMethod.POST, new HttpEntity<>(createRequest, TestUsers.bearer(juniorToken)), BuyerResponse.class);
        assertThat(createResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        BuyerResponse buyer = createResponse.getBody();

        BuyerRequest updateRequest = new BuyerRequest(buyer.code(), "My Own Buyer Renamed", null, null, null, null, null, buyer.version());
        ResponseEntity<BuyerResponse> updateResponse = restTemplate.exchange(
                "/api/v1/buyers/" + buyer.id(), HttpMethod.PUT, new HttpEntity<>(updateRequest, TestUsers.bearer(juniorToken)), BuyerResponse.class);

        assertThat(updateResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(updateResponse.getBody().name()).isEqualTo("My Own Buyer Renamed");
    }
}
