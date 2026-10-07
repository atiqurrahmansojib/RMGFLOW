package com.rmgflow.support;

import com.rmgflow.identity.dto.LoginRequest;
import com.rmgflow.identity.dto.TokenResponse;
import com.rmgflow.identity.entity.Assignment;
import com.rmgflow.identity.entity.Organization;
import com.rmgflow.identity.entity.ScopeType;
import com.rmgflow.identity.repository.AssignmentRepository;
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

    /** Creates the user in a brand-new organization and returns both the token and
     * that organization's id. Use the plain token for cross-org IDOR tests (each
     * call is its own tenant); pass the returned organizationId to
     * {@link #createAndLoginInOrganization} when a test needs a second user in the
     * SAME tenant (e.g. testing role/assignment-based authorization). */
    public static TestSession createAndLogin(TestRestTemplate restTemplate, UserRepository userRepository,
                                              RoleRepository roleRepository, OrganizationRepository organizationRepository,
                                              PasswordEncoder passwordEncoder, String roleName) {
        Organization org = new Organization();
        org.setName("Test Org " + UUID.randomUUID());
        org = organizationRepository.save(org);
        String token = createAndLoginInOrganization(restTemplate, userRepository, roleRepository, organizationRepository,
                passwordEncoder, roleName, org.getId());
        return new TestSession(token, org.getId());
    }

    /** Creates the user inside an EXISTING organization — use this when a test needs
     * two different roles/users who must be in the SAME tenant. */
    public static String createAndLoginInOrganization(TestRestTemplate restTemplate, UserRepository userRepository,
                                                        RoleRepository roleRepository, OrganizationRepository organizationRepository,
                                                        PasswordEncoder passwordEncoder, String roleName, Long organizationId) {
        Role role = roleRepository.findByName(roleName).orElseThrow();

        String email = roleName.toLowerCase() + "+" + UUID.randomUUID() + "@rmgflow.local";
        User user = new User();
        user.setOrganization(organizationRepository.getReferenceById(organizationId));
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(PASSWORD));
        user.setFullName("Test " + roleName);
        user.setRoles(Set.of(role));
        userRepository.save(user);

        TokenResponse tokens = restTemplate.postForEntity(
                "/api/v1/auth/login", new LoginRequest(email, PASSWORD, "junit"), TokenResponse.class).getBody();
        return tokens.accessToken();
    }

    /** Doc 5.3: creates a scoped user in an existing organization, assigns them to one
     * buyer/factory (object-level scope) and logs them in. */
    public static String createAndLoginAssigned(TestRestTemplate restTemplate, UserRepository userRepository,
                                                RoleRepository roleRepository, OrganizationRepository organizationRepository,
                                                PasswordEncoder passwordEncoder, AssignmentRepository assignmentRepository,
                                                String roleName, Long organizationId, ScopeType scopeType, Long scopeId) {
        String token = createAndLoginInOrganization(restTemplate, userRepository, roleRepository, organizationRepository,
                passwordEncoder, roleName, organizationId);
        User user = userRepository.findAll().stream()
                .filter(u -> u.getOrganization().getId().equals(organizationId)
                        && u.getEmail().startsWith(roleName.toLowerCase() + "+"))
                .max(java.util.Comparator.comparing(User::getId)).orElseThrow();
        Assignment assignment = new Assignment();
        assignment.setUser(user);
        assignment.setScopeType(scopeType);
        assignment.setScopeId(scopeId);
        assignmentRepository.save(assignment);
        return token;
    }

    public static HttpHeaders bearer(String accessToken) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(accessToken);
        return headers;
    }
}
