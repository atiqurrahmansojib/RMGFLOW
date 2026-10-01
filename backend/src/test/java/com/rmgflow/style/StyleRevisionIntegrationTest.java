package com.rmgflow.style;

import com.rmgflow.buyer.dto.BuyerRequest;
import com.rmgflow.buyer.dto.BuyerResponse;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.RoleRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.style.dto.StyleRequest;
import com.rmgflow.style.dto.StyleResponse;
import com.rmgflow.style.dto.StyleRevisionRequest;
import com.rmgflow.style.dto.StyleRevisionResponse;
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
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/** Document FR-31/NFR-05/16.1: style revisions are append-only — a new spec creates a
 * new revision row, and nothing ever mutates a prior one (there is no update endpoint at all). */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class StyleRevisionIntegrationTest {

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
    void creatingASecondRevision_neverMutatesTheFirst_andBothRemainVisible() {
        String token = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "SENIOR_MERCHANDISER").accessToken();

        BuyerRequest buyerRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "Style Test Buyer", null, null, null, null, null, null);
        BuyerResponse buyer = restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(buyerRequest, TestUsers.bearer(token)), BuyerResponse.class).getBody();

        StyleRequest styleRequest = new StyleRequest("STY-" + UUID.randomUUID(), buyer.id(), "B-123", "T-Shirt", null, "MEN", "Basic crew neck tee");
        StyleResponse style = restTemplate.exchange("/api/v1/styles", HttpMethod.POST,
                new HttpEntity<>(styleRequest, TestUsers.bearer(token)), StyleResponse.class).getBody();

        StyleRevisionRequest firstRevisionRequest = new StyleRevisionRequest("100% Cotton", "Single Jersey", new BigDecimal("180.00"), "Navy", "S-XXL", null);
        ResponseEntity<StyleRevisionResponse> firstResponse = restTemplate.exchange(
                "/api/v1/styles/" + style.id() + "/revisions", HttpMethod.POST,
                new HttpEntity<>(firstRevisionRequest, TestUsers.bearer(token)), StyleRevisionResponse.class);
        assertThat(firstResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(firstResponse.getBody().revisionNo()).isEqualTo(1);

        StyleRevisionRequest secondRevisionRequest = new StyleRevisionRequest("95% Cotton 5% Elastane", "Single Jersey", new BigDecimal("190.00"), "Black", "S-XXL", null);
        ResponseEntity<StyleRevisionResponse> secondResponse = restTemplate.exchange(
                "/api/v1/styles/" + style.id() + "/revisions", HttpMethod.POST,
                new HttpEntity<>(secondRevisionRequest, TestUsers.bearer(token)), StyleRevisionResponse.class);
        assertThat(secondResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(secondResponse.getBody().revisionNo()).isEqualTo(2);

        ResponseEntity<StyleRevisionResponse[]> listResponse = restTemplate.exchange(
                "/api/v1/styles/" + style.id() + "/revisions", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), StyleRevisionResponse[].class);
        List<StyleRevisionResponse> revisions = List.of(listResponse.getBody());

        assertThat(revisions).hasSize(2);
        StyleRevisionResponse firstStillIntact = revisions.stream().filter(r -> r.revisionNo() == 1).findFirst().orElseThrow();
        assertThat(firstStillIntact.color()).isEqualTo("Navy");
        assertThat(firstStillIntact.fabric()).isEqualTo("100% Cotton");

        StyleRevisionResponse second = revisions.stream().filter(r -> r.revisionNo() == 2).findFirst().orElseThrow();
        assertThat(second.color()).isEqualTo("Black");

        // The style master's current-revision pointer advances to the latest (Doc 8.3).
        StyleResponse refreshedStyle = restTemplate.exchange("/api/v1/styles/" + style.id(), HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), StyleResponse.class).getBody();
        assertThat(refreshedStyle.currentRevisionId()).isEqualTo(second.id());
    }
}
