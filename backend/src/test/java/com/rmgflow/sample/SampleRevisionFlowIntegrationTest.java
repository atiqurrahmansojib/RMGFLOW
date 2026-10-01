package com.rmgflow.sample;

import com.rmgflow.approval.dto.ApprovalDecisionRequest;
import com.rmgflow.approval.dto.ApprovalResponse;
import com.rmgflow.approval.entity.ApprovalStatus;
import com.rmgflow.buyer.dto.BuyerRequest;
import com.rmgflow.buyer.dto.BuyerResponse;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.RoleRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.sample.dto.SampleRequest;
import com.rmgflow.sample.dto.SampleResponse;
import com.rmgflow.sample.dto.SampleRevisionRequest;
import com.rmgflow.sample.dto.SampleRevisionResponse;
import com.rmgflow.sample.entity.SampleStatus;
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

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Document 9.3/10.5/16.5 scenario #2: reject twice, approve on the third revision,
 * full history retained — the approval engine's second real consumer after costing
 * (Doc 20 Phase 5 rationale), proving it generalizes beyond its first user.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class SampleRevisionFlowIntegrationTest {

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

    private ApprovalResponse latestApprovalFor(String token, Long revisionId) {
        ApprovalResponse[] history = restTemplate.exchange(
                "/api/v1/approvals/history?targetType=SAMPLE_REVISION&targetId=" + revisionId, HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), ApprovalResponse[].class).getBody();
        return history[0];
    }

    @Test
    void rejectTwice_thenApproveOnThirdRevision_fullHistoryRetained() {
        String token = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "SENIOR_MERCHANDISER").accessToken();

        BuyerRequest buyerRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "Sample Test Buyer", null, null, null, null, null, null);
        BuyerResponse buyer = restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(buyerRequest, TestUsers.bearer(token)), BuyerResponse.class).getBody();
        StyleRequest styleRequest = new StyleRequest("STY-" + UUID.randomUUID(), buyer.id(), null, "Dress", null, null, null);
        StyleResponse style = restTemplate.exchange("/api/v1/styles", HttpMethod.POST,
                new HttpEntity<>(styleRequest, TestUsers.bearer(token)), StyleResponse.class).getBody();

        var sampleTypes = restTemplate.exchange("/api/v1/sample-types", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), com.rmgflow.sample.entity.SampleType[].class).getBody();
        long sampleTypeId = sampleTypes[0].getId();

        SampleRequest sampleRequest = new SampleRequest(style.id(), buyer.id(), null, sampleTypeId, LocalDate.now(), LocalDate.now().plusDays(10));
        SampleResponse sample = restTemplate.exchange("/api/v1/samples", HttpMethod.POST,
                new HttpEntity<>(sampleRequest, TestUsers.bearer(token)), SampleResponse.class).getBody();
        assertThat(sample.currentStatus()).isEqualTo(SampleStatus.REQUESTED);

        // Revision 1 -> rejected.
        SampleRevisionResponse rev1 = restTemplate.exchange("/api/v1/samples/" + sample.id() + "/revisions", HttpMethod.POST,
                new HttpEntity<>(new SampleRevisionRequest(LocalDate.now(), "First attempt"), TestUsers.bearer(token)), SampleRevisionResponse.class).getBody();
        assertThat(rev1.revisionNo()).isEqualTo(1);
        ApprovalResponse approval1 = latestApprovalFor(token, rev1.id());
        restTemplate.exchange("/api/v1/approvals/" + approval1.id() + "/decide", HttpMethod.POST,
                new HttpEntity<>(new ApprovalDecisionRequest(ApprovalStatus.REJECTED, null, "Wrong color"), TestUsers.bearer(token)), ApprovalResponse.class);
        restTemplate.exchange("/api/v1/samples/" + sample.id() + "/revisions/sync-status", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(token)), SampleRevisionResponse.class);

        // Revision 2 -> rejected again.
        SampleRevisionResponse rev2 = restTemplate.exchange("/api/v1/samples/" + sample.id() + "/revisions", HttpMethod.POST,
                new HttpEntity<>(new SampleRevisionRequest(LocalDate.now(), "Second attempt"), TestUsers.bearer(token)), SampleRevisionResponse.class).getBody();
        assertThat(rev2.revisionNo()).isEqualTo(2);
        ApprovalResponse approval2 = latestApprovalFor(token, rev2.id());
        restTemplate.exchange("/api/v1/approvals/" + approval2.id() + "/decide", HttpMethod.POST,
                new HttpEntity<>(new ApprovalDecisionRequest(ApprovalStatus.REJECTED, null, "Wrong size"), TestUsers.bearer(token)), ApprovalResponse.class);
        restTemplate.exchange("/api/v1/samples/" + sample.id() + "/revisions/sync-status", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(token)), SampleRevisionResponse.class);

        ResponseEntity<SampleResponse> afterSecondRejection = restTemplate.exchange("/api/v1/samples/" + sample.id(), HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), SampleResponse.class);
        assertThat(afterSecondRejection.getBody().currentStatus()).isEqualTo(SampleStatus.REJECTED);

        // Revision 3 -> approved.
        SampleRevisionResponse rev3 = restTemplate.exchange("/api/v1/samples/" + sample.id() + "/revisions", HttpMethod.POST,
                new HttpEntity<>(new SampleRevisionRequest(LocalDate.now(), "Third attempt"), TestUsers.bearer(token)), SampleRevisionResponse.class).getBody();
        assertThat(rev3.revisionNo()).isEqualTo(3);
        ApprovalResponse approval3 = latestApprovalFor(token, rev3.id());
        restTemplate.exchange("/api/v1/approvals/" + approval3.id() + "/decide", HttpMethod.POST,
                new HttpEntity<>(new ApprovalDecisionRequest(ApprovalStatus.APPROVED, "Finally good", null), TestUsers.bearer(token)), ApprovalResponse.class);
        ResponseEntity<SampleRevisionResponse> syncResponse = restTemplate.exchange(
                "/api/v1/samples/" + sample.id() + "/revisions/sync-status", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(token)), SampleRevisionResponse.class);
        assertThat(syncResponse.getStatusCode()).isEqualTo(HttpStatus.OK);

        ResponseEntity<SampleResponse> finalSample = restTemplate.exchange("/api/v1/samples/" + sample.id(), HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), SampleResponse.class);
        assertThat(finalSample.getBody().currentStatus()).isEqualTo(SampleStatus.APPROVED);

        // Full history retained — nothing was overwritten.
        ResponseEntity<SampleRevisionResponse[]> allRevisionsResponse = restTemplate.exchange(
                "/api/v1/samples/" + sample.id() + "/revisions", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), SampleRevisionResponse[].class);
        List<SampleRevisionResponse> allRevisions = List.of(allRevisionsResponse.getBody());
        assertThat(allRevisions).hasSize(3);
        assertThat(allRevisions).extracting(SampleRevisionResponse::comments)
                .containsExactlyInAnyOrder("First attempt", "Second attempt", "Third attempt");

        // And the full approval round history for the sample's revisions is independently retrievable.
        ApprovalResponse[] rev1History = restTemplate.exchange(
                "/api/v1/approvals/history?targetType=SAMPLE_REVISION&targetId=" + rev1.id(), HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), ApprovalResponse[].class).getBody();
        assertThat(rev1History).hasSize(1);
        assertThat(rev1History[0].status()).isEqualTo(ApprovalStatus.REJECTED);
        assertThat(rev1History[0].rejectionReason()).isEqualTo("Wrong color");
    }

    @Test
    void decidingTheSameRevisionApprovalTwice_isRejected() {
        String token = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "SENIOR_MERCHANDISER").accessToken();

        BuyerRequest buyerRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "Sample Test Buyer 2", null, null, null, null, null, null);
        BuyerResponse buyer = restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(buyerRequest, TestUsers.bearer(token)), BuyerResponse.class).getBody();
        StyleRequest styleRequest = new StyleRequest("STY-" + UUID.randomUUID(), buyer.id(), null, "Shirt", null, null, null);
        StyleResponse style = restTemplate.exchange("/api/v1/styles", HttpMethod.POST,
                new HttpEntity<>(styleRequest, TestUsers.bearer(token)), StyleResponse.class).getBody();
        var sampleTypes = restTemplate.exchange("/api/v1/sample-types", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), com.rmgflow.sample.entity.SampleType[].class).getBody();

        SampleResponse sample = restTemplate.exchange("/api/v1/samples", HttpMethod.POST,
                new HttpEntity<>(new SampleRequest(style.id(), buyer.id(), null, sampleTypes[0].getId(), LocalDate.now(), null), TestUsers.bearer(token)),
                SampleResponse.class).getBody();
        SampleRevisionResponse revision = restTemplate.exchange("/api/v1/samples/" + sample.id() + "/revisions", HttpMethod.POST,
                new HttpEntity<>(new SampleRevisionRequest(LocalDate.now(), "Only attempt"), TestUsers.bearer(token)), SampleRevisionResponse.class).getBody();

        ApprovalResponse approval = latestApprovalFor(token, revision.id());
        restTemplate.exchange("/api/v1/approvals/" + approval.id() + "/decide", HttpMethod.POST,
                new HttpEntity<>(new ApprovalDecisionRequest(ApprovalStatus.APPROVED, null, null), TestUsers.bearer(token)), ApprovalResponse.class);

        ResponseEntity<String> secondDecision = restTemplate.exchange("/api/v1/approvals/" + approval.id() + "/decide", HttpMethod.POST,
                new HttpEntity<>(new ApprovalDecisionRequest(ApprovalStatus.REJECTED, null, "too late"), TestUsers.bearer(token)), String.class);
        assertThat(secondDecision.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }
}
