package com.rmgflow.inquiry;

import com.rmgflow.buyer.dto.BuyerRequest;
import com.rmgflow.buyer.dto.BuyerResponse;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.RoleRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.inquiry.dto.InquiryRequest;
import com.rmgflow.inquiry.dto.InquiryResponse;
import com.rmgflow.inquiry.dto.MarkWonLostRequest;
import com.rmgflow.inquiry.entity.InquiryStatus;
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

/** Document 10.1/16.1: the inquiry state machine must reject invalid transitions and
 * require a lost reason, enforced server-side regardless of what the client sends. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class InquiryFlowIntegrationTest {

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

    private BuyerResponse createBuyer(String token) {
        BuyerRequest request = new BuyerRequest("BYR-" + UUID.randomUUID(), "Inquiry Test Buyer", null, null, null, null, null, null);
        return restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(request, TestUsers.bearer(token)), BuyerResponse.class).getBody();
    }

    @Test
    void fullHappyPath_openToQuotedToWon() {
        String token = tokenFor("SENIOR_MERCHANDISER");
        BuyerResponse buyer = createBuyer(token);

        InquiryRequest createRequest = new InquiryRequest("INQ-" + UUID.randomUUID(), buyer.id(), null, null, 5000, null, null, null);
        InquiryResponse inquiry = restTemplate.exchange("/api/v1/inquiries", HttpMethod.POST,
                new HttpEntity<>(createRequest, TestUsers.bearer(token)), InquiryResponse.class).getBody();
        assertThat(inquiry.status()).isEqualTo(InquiryStatus.OPEN);

        ResponseEntity<InquiryResponse> quotedResponse = restTemplate.exchange(
                "/api/v1/inquiries/" + inquiry.id() + "/status", HttpMethod.POST,
                new HttpEntity<>(new MarkWonLostRequest(InquiryStatus.QUOTED, null), TestUsers.bearer(token)), InquiryResponse.class);
        assertThat(quotedResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(quotedResponse.getBody().status()).isEqualTo(InquiryStatus.QUOTED);

        ResponseEntity<InquiryResponse> wonResponse = restTemplate.exchange(
                "/api/v1/inquiries/" + inquiry.id() + "/status", HttpMethod.POST,
                new HttpEntity<>(new MarkWonLostRequest(InquiryStatus.WON, null), TestUsers.bearer(token)), InquiryResponse.class);
        assertThat(wonResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(wonResponse.getBody().status()).isEqualTo(InquiryStatus.WON);
    }

    @Test
    void directOpenToWon_isRejected_mustGoThroughQuoted() {
        String token = tokenFor("SENIOR_MERCHANDISER");
        BuyerResponse buyer = createBuyer(token);
        InquiryRequest createRequest = new InquiryRequest("INQ-" + UUID.randomUUID(), buyer.id(), null, null, null, null, null, null);
        InquiryResponse inquiry = restTemplate.exchange("/api/v1/inquiries", HttpMethod.POST,
                new HttpEntity<>(createRequest, TestUsers.bearer(token)), InquiryResponse.class).getBody();

        ResponseEntity<String> response = restTemplate.exchange(
                "/api/v1/inquiries/" + inquiry.id() + "/status", HttpMethod.POST,
                new HttpEntity<>(new MarkWonLostRequest(InquiryStatus.WON, null), TestUsers.bearer(token)), String.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void markingLost_withoutReason_isRejected() {
        String token = tokenFor("SENIOR_MERCHANDISER");
        BuyerResponse buyer = createBuyer(token);
        InquiryRequest createRequest = new InquiryRequest("INQ-" + UUID.randomUUID(), buyer.id(), null, null, null, null, null, null);
        InquiryResponse inquiry = restTemplate.exchange("/api/v1/inquiries", HttpMethod.POST,
                new HttpEntity<>(createRequest, TestUsers.bearer(token)), InquiryResponse.class).getBody();

        ResponseEntity<String> response = restTemplate.exchange(
                "/api/v1/inquiries/" + inquiry.id() + "/status", HttpMethod.POST,
                new HttpEntity<>(new MarkWonLostRequest(InquiryStatus.LOST, null), TestUsers.bearer(token)), String.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);

        ResponseEntity<InquiryResponse> withReasonResponse = restTemplate.exchange(
                "/api/v1/inquiries/" + inquiry.id() + "/status", HttpMethod.POST,
                new HttpEntity<>(new MarkWonLostRequest(InquiryStatus.LOST, "Price too high"), TestUsers.bearer(token)), InquiryResponse.class);
        assertThat(withReasonResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(withReasonResponse.getBody().lostReason()).isEqualTo("Price too high");
    }

    @Test
    void terminalStatus_cannotTransitionAgain() {
        String token = tokenFor("SENIOR_MERCHANDISER");
        BuyerResponse buyer = createBuyer(token);
        InquiryRequest createRequest = new InquiryRequest("INQ-" + UUID.randomUUID(), buyer.id(), null, null, null, null, null, null);
        InquiryResponse inquiry = restTemplate.exchange("/api/v1/inquiries", HttpMethod.POST,
                new HttpEntity<>(createRequest, TestUsers.bearer(token)), InquiryResponse.class).getBody();

        restTemplate.exchange("/api/v1/inquiries/" + inquiry.id() + "/status", HttpMethod.POST,
                new HttpEntity<>(new MarkWonLostRequest(InquiryStatus.LOST, "No budget"), TestUsers.bearer(token)), InquiryResponse.class);

        ResponseEntity<String> response = restTemplate.exchange(
                "/api/v1/inquiries/" + inquiry.id() + "/status", HttpMethod.POST,
                new HttpEntity<>(new MarkWonLostRequest(InquiryStatus.OPEN, null), TestUsers.bearer(token)), String.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }
}
