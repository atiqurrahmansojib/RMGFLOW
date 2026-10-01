package com.rmgflow.support;

import com.rmgflow.identity.dto.LoginRequest;
import com.rmgflow.identity.dto.TokenResponse;
import com.rmgflow.identity.entity.Organization;
import com.rmgflow.identity.entity.Role;
import com.rmgflow.identity.entity.User;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.RoleRepository;
import com.rmgflow.identity.repository.UserRepository;
import org.springframework.boot.resttestclient.TestRestTemplate;
import org.springframework.http.HttpHeaders;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Set;
import java.util.UUID;

/** Document 16.2/16.3 test helper: creates a user with a given role and logs them in,
 * so authorization tests don't each hand-roll org/user/role seeding. */
public class TestUsers {

    public static final String PASSWORD = "Str0ngPassword!";

    public static String createAndLogin(TestRestTemplate restTemplate, UserRepository userRepository,
                                         RoleRepository roleRepository, OrganizationRepository organizationRepository,
                                         PasswordEncoder passwordEncoder, String roleName) {
        Organization org = new Organization();
        org.setName("Test Org " + UUID.randomUUID());
        org = organizationRepository.save(org);

        Role role = roleRepository.findByName(roleName).orElseThrow();

        String email = roleName.toLowerCase() + "+" + UUID.randomUUID() + "@rmgflow.local";
        User user = new User();
        user.setOrganization(org);
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(PASSWORD));
        user.setFullName("Test " + roleName);
        user.setRoles(Set.of(role));
        userRepository.save(user);

        TokenResponse tokens = restTemplate.postForEntity(
                "/api/v1/auth/login", new LoginRequest(email, PASSWORD, "junit"), TokenResponse.class).getBody();
        return tokens.accessToken();
    }

    public static HttpHeaders bearer(String accessToken) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(accessToken);
        return headers;
    }
}
