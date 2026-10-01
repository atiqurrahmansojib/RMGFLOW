package com.rmgflow.identity;

import com.rmgflow.identity.dto.LoginRequest;
import com.rmgflow.identity.dto.RefreshRequest;
import com.rmgflow.identity.dto.TokenResponse;
import com.rmgflow.identity.entity.Organization;
import com.rmgflow.identity.entity.Role;
import com.rmgflow.identity.entity.User;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.RoleRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.support.PostgresTestContainerConfig;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.resttestclient.TestRestTemplate;
import org.springframework.boot.resttestclient.autoconfigure.AutoConfigureTestRestTemplate;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;

import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Document 16.2/16.3: end-to-end login -> refresh -> rotation -> logout, matching
 * ADR-04's stated behavior (each refresh invalidates the prior refresh token).
 *
 * Note: deliberately NOT @Transactional — with RANDOM_PORT the HTTP call runs on a
 * separate server thread/connection than the test method, so a test-side transaction
 * would roll back invisibly to the server and would never be visible to it anyway.
 * Seed data is committed via ordinary repository.save() calls instead.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class AuthFlowIntegrationTest {

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

    private static final String PASSWORD = "Str0ngPassword!";

    @BeforeEach
    void seedUser() {
        if (userRepository.existsByEmailIgnoreCase("merchandiser@rmgflow.local")) {
            return;
        }
        Organization org = new Organization();
        org.setName("Test Org");
        org = organizationRepository.save(org);

        Role role = roleRepository.findByName("SENIOR_MERCHANDISER").orElseThrow();

        User user = new User();
        user.setOrganization(org);
        user.setEmail("merchandiser@rmgflow.local");
        user.setPasswordHash(passwordEncoder.encode(PASSWORD));
        user.setFullName("Test Merchandiser");
        user.setRoles(Set.of(role));
        userRepository.save(user);
    }

    @Test
    void loginThenRefreshRotatesToken_oldRefreshTokenNoLongerWorks() {
        var loginResponse = restTemplate.postForEntity(
                "/api/v1/auth/login",
                new LoginRequest("merchandiser@rmgflow.local", PASSWORD, "junit"),
                TokenResponse.class);

        assertThat(loginResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        TokenResponse tokens = loginResponse.getBody();
        assertThat(tokens).isNotNull();
        assertThat(tokens.accessToken()).isNotBlank();
        assertThat(tokens.refreshToken()).isNotBlank();

        ResponseEntity<TokenResponse> refreshResponse = restTemplate.postForEntity(
                "/api/v1/auth/refresh", new RefreshRequest(tokens.refreshToken()), TokenResponse.class);
        assertThat(refreshResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        TokenResponse rotated = refreshResponse.getBody();
        assertThat(rotated).isNotNull();
        assertThat(rotated.refreshToken()).isNotEqualTo(tokens.refreshToken());

        // Reusing the now-revoked original refresh token must be rejected (ADR-04 rotation).
        ResponseEntity<String> reuseResponse = restTemplate.postForEntity(
                "/api/v1/auth/refresh", new RefreshRequest(tokens.refreshToken()), String.class);
        assertThat(reuseResponse.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    void loginWithWrongPassword_returnsUnauthorized() {
        ResponseEntity<String> response = restTemplate.postForEntity(
                "/api/v1/auth/login",
                new LoginRequest("merchandiser@rmgflow.local", "wrong-password", "junit"),
                String.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    void protectedEndpointWithoutToken_isRejected() {
        ResponseEntity<String> response = restTemplate.getForEntity("/api/v1/audit-logs?entityType=User&entityId=1", String.class);
        assertThat(response.getStatusCode().value()).isIn(401, 403);
    }
}
