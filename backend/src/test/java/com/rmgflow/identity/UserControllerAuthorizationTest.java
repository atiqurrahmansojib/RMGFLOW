package com.rmgflow.identity;

import com.rmgflow.identity.dto.CreateUserRequest;
import com.rmgflow.identity.dto.LoginRequest;
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
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;

import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Document 16.3/5.2: a non-Super-Admin role (SENIOR_MERCHANDISER) must be denied
 * user-management access even with a valid token, enforced server-side (Doc 15.2) —
 * never by the client hiding the button.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class UserControllerAuthorizationTest {

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
    private static final String EMAIL = "non-admin@rmgflow.local";

    @BeforeEach
    void seedNonAdminUser() {
        if (userRepository.existsByEmailIgnoreCase(EMAIL)) {
            return;
        }
        Organization org = organizationRepository.save(newOrg());
        Role role = roleRepository.findByName("SENIOR_MERCHANDISER").orElseThrow();

        User user = new User();
        user.setOrganization(org);
        user.setEmail(EMAIL);
        user.setPasswordHash(passwordEncoder.encode(PASSWORD));
        user.setFullName("Non Admin");
        user.setRoles(Set.of(role));
        userRepository.save(user);
    }

    private Organization newOrg() {
        Organization org = new Organization();
        org.setName("Authz Test Org");
        return org;
    }

    @Test
    void nonSuperAdmin_cannotCreateUsers() {
        TokenResponse tokens = restTemplate.postForEntity(
                "/api/v1/auth/login", new LoginRequest(EMAIL, PASSWORD, "junit"), TokenResponse.class).getBody();
        assertThat(tokens).isNotNull();

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(tokens.accessToken());
        var request = new org.springframework.http.HttpEntity<>(
                new CreateUserRequest("someone.else@rmgflow.local", "AnotherPass1!", "Someone Else", null, Set.of("JUNIOR_MERCHANDISER")),
                headers);

        ResponseEntity<String> response = restTemplate.postForEntity("/api/v1/users", request, String.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
    }
}
