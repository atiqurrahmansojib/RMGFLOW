package com.rmgflow.attachment;

import com.rmgflow.attachment.dto.AttachmentResponse;
import com.rmgflow.attachment.dto.DownloadUrlResponse;
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
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.*;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;

import java.nio.charset.StandardCharsets;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Document 15.4/21 P3-T3: upload -> signed download URL -> actual download round trip,
 * plus the content-type allow-list (Doc 15.4) and tenant isolation (ADR-10 lesson
 * applied from day one of this module, not retrofitted like Buyer/Factory were).
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class AttachmentFlowIntegrationTest {

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

    private HttpEntity<MultiValueMap<String, Object>> multipartBody(String token, String filename, String contentType, byte[] content) {
        ByteArrayResource resource = new ByteArrayResource(content) {
            @Override
            public String getFilename() {
                return filename;
            }
        };
        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        HttpHeaders fileHeaders = new HttpHeaders();
        fileHeaders.setContentType(MediaType.parseMediaType(contentType));
        body.add("file", new HttpEntity<>(resource, fileHeaders));

        HttpHeaders headers = TestUsers.bearer(token);
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);
        return new HttpEntity<>(body, headers);
    }

    @Test
    void uploadThenDownload_roundTripsTheOriginalContent() {
        String token = tokenFor("SENIOR_MERCHANDISER");
        byte[] content = "fake-pdf-bytes".getBytes(StandardCharsets.UTF_8);

        ResponseEntity<AttachmentResponse> uploadResponse = restTemplate.exchange(
                "/api/v1/attachments?entityType=STYLE&entityId=1", HttpMethod.POST,
                multipartBody(token, "techpack.pdf", "application/pdf", content), AttachmentResponse.class);
        assertThat(uploadResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        AttachmentResponse attachment = uploadResponse.getBody();
        assertThat(attachment.fileName()).isEqualTo("techpack.pdf");

        ResponseEntity<DownloadUrlResponse> urlResponse = restTemplate.exchange(
                "/api/v1/attachments/" + attachment.id() + "/url", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), DownloadUrlResponse.class);
        assertThat(urlResponse.getStatusCode()).isEqualTo(HttpStatus.OK);

        // The download endpoint deliberately takes NO Authorization header — the
        // signed token in the URL itself is the credential (Doc 15.4).
        ResponseEntity<byte[]> downloadResponse = restTemplate.exchange(
                urlResponse.getBody().url(), HttpMethod.GET, HttpEntity.EMPTY, byte[].class);
        assertThat(downloadResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(downloadResponse.getBody()).isEqualTo(content);
    }

    @Test
    void disallowedContentType_isRejected() {
        String token = tokenFor("SENIOR_MERCHANDISER");
        ResponseEntity<String> response = restTemplate.exchange(
                "/api/v1/attachments?entityType=STYLE&entityId=1", HttpMethod.POST,
                multipartBody(token, "virus.exe", "application/x-msdownload", "x".getBytes(StandardCharsets.UTF_8)), String.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void attachmentList_isTenantIsolated() {
        String orgAToken = tokenFor("SENIOR_MERCHANDISER");
        restTemplate.exchange("/api/v1/attachments?entityType=STYLE&entityId=42", HttpMethod.POST,
                multipartBody(orgAToken, "spec.pdf", "application/pdf", "a".getBytes(StandardCharsets.UTF_8)), AttachmentResponse.class);

        String orgBToken = tokenFor("SENIOR_MERCHANDISER");
        ResponseEntity<AttachmentResponse[]> listResponse = restTemplate.exchange(
                "/api/v1/attachments?entityType=STYLE&entityId=42", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(orgBToken)), AttachmentResponse[].class);

        assertThat(listResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(List.of(listResponse.getBody())).isEmpty();
    }
}
