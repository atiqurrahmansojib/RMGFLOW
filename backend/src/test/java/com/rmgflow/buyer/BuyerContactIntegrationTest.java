package com.rmgflow.buyer;

import com.rmgflow.buyer.dto.BuyerContactRequest;
import com.rmgflow.buyer.dto.BuyerContactResponse;
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

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/** Document 8.2/9.3-adjacent: exactly one primary contact per buyer, even across multiple inserts. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class BuyerContactIntegrationTest {

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
    void firstContactIsAutoPrimary_andSettingANewPrimaryUnsetsTheOld() {
        String token = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "SENIOR_MERCHANDISER").accessToken();

        BuyerRequest buyerRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "Contact Test Buyer", null, null, null, null, null, null);
        BuyerResponse buyer = restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(buyerRequest, TestUsers.bearer(token)), BuyerResponse.class).getBody();

        BuyerContactRequest firstContact = new BuyerContactRequest("Alice", "Merchandising", "alice@buyer.example", null, false);
        BuyerContactResponse alice = restTemplate.exchange("/api/v1/buyers/" + buyer.id() + "/contacts", HttpMethod.POST,
                new HttpEntity<>(firstContact, TestUsers.bearer(token)), BuyerContactResponse.class).getBody();
        assertThat(alice.primary()).as("first contact ever added must be auto-primary").isTrue();

        BuyerContactRequest secondContact = new BuyerContactRequest("Bob", "Merchandising", "bob@buyer.example", null, true);
        restTemplate.exchange("/api/v1/buyers/" + buyer.id() + "/contacts", HttpMethod.POST,
                new HttpEntity<>(secondContact, TestUsers.bearer(token)), BuyerContactResponse.class);

        ResponseEntity<BuyerContactResponse[]> listResponse = restTemplate.exchange(
                "/api/v1/buyers/" + buyer.id() + "/contacts", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), BuyerContactResponse[].class);
        List<BuyerContactResponse> contacts = List.of(listResponse.getBody());

        assertThat(contacts).hasSize(2);
        assertThat(contacts.stream().filter(BuyerContactResponse::primary).count())
                .as("exactly one primary contact must remain after adding a second primary")
                .isEqualTo(1);
        assertThat(contacts.stream().filter(BuyerContactResponse::primary).findFirst().orElseThrow().name())
                .isEqualTo("Bob");
    }
}
