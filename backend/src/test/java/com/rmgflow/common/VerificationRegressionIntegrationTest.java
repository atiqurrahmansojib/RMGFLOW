package com.rmgflow.common;

import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.RoleRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.support.PostgresTestContainerConfig;
import com.rmgflow.support.TestSession;
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
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/** Regressions found by the end-to-end verification pass against the demo dataset. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class VerificationRegressionIntegrationTest {

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

    /** Jackson 3 fails on an omitted primitive by default; clients must be able to leave
     *  out optional booleans/ints such as a contact's `primary` flag. */
    @Test
    void omittedPrimitiveField_isAccepted() {
        TestSession gm = login("GENERAL_MANAGER");
        Long buyerId = createBuyer(gm.accessToken());

        ResponseEntity<Map> contact = exchange(HttpMethod.POST, "/api/v1/buyers/" + buyerId + "/contacts",
                gm.accessToken(), Map.of("name", "No primary flag"), Map.class);
        assertThat(contact.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(contact.getBody().get("primary")).isNotNull();
    }

    /** Doc 5 grants the General Manager audit-log VIEW; rows of another tenant stay invisible. */
    @Test
    void auditLog_generalManagerCanRead_andItIsTenantScoped() {
        TestSession gm = login("GENERAL_MANAGER");
        Long buyerId = createBuyer(gm.accessToken());
        String url = "/api/v1/audit-logs?entityType=Buyer&entityId=" + buyerId;

        ResponseEntity<Map> own = exchange(HttpMethod.GET, url, gm.accessToken(), null, Map.class);
        assertThat(own.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat((List<?>) own.getBody().get("content")).isNotEmpty();

        TestSession otherOwner = login("OWNER_MD");
        ResponseEntity<Map> other = exchange(HttpMethod.GET, url, otherOwner.accessToken(), null, Map.class);
        assertThat(other.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat((List<?>) other.getBody().get("content")).isEmpty();

        TestSession viewer = login("MANAGEMENT_VIEWER");
        assertThat(exchange(HttpMethod.GET, url, viewer.accessToken(), null, Map.class).getStatusCode())
                .isEqualTo(HttpStatus.FORBIDDEN);
    }

    /** Sample types are DTOs (no serialized Buyer entity) and buyer-specific types are tenant-private. */
    @Test
    void sampleTypes_areDtos_andBuyerSpecificTypesAreTenantScoped() {
        TestSession gm = login("GENERAL_MANAGER");
        Long buyerId = createBuyer(gm.accessToken());
        String name = "Buyer special " + UUID.randomUUID();

        ResponseEntity<Map> created = exchange(HttpMethod.POST, "/api/v1/sample-types", gm.accessToken(),
                Map.of("name", name, "buyerId", buyerId), Map.class);
        assertThat(created.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(created.getBody()).containsEntry("buyerSpecific", true).doesNotContainKey("buyer");

        List<Map<String, Object>> own = exchange(HttpMethod.GET, "/api/v1/sample-types", gm.accessToken(), null, List.class).getBody();
        assertThat(own).anyMatch(t -> name.equals(t.get("name")));
        assertThat(own).allSatisfy(t -> assertThat(t).doesNotContainKey("buyer"));

        TestSession other = login("GENERAL_MANAGER");
        List<Map<String, Object>> others = exchange(HttpMethod.GET, "/api/v1/sample-types", other.accessToken(), null, List.class).getBody();
        assertThat(others).isNotEmpty().noneMatch(t -> name.equals(t.get("name")));

        // Another tenant cannot attach a type to this tenant's buyer.
        assertThat(exchange(HttpMethod.POST, "/api/v1/sample-types", other.accessToken(),
                Map.of("name", "Hijack " + UUID.randomUUID(), "buyerId", buyerId), Map.class).getStatusCode())
                .isEqualTo(HttpStatus.NOT_FOUND);
    }

    private Long createBuyer(String token) {
        String code = "VR" + UUID.randomUUID().toString().substring(0, 6);
        ResponseEntity<Map> buyer = exchange(HttpMethod.POST, "/api/v1/buyers", token,
                Map.of("code", code, "name", "Regression Buyer " + code), Map.class);
        assertThat(buyer.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        return ((Number) buyer.getBody().get("id")).longValue();
    }

    private TestSession login(String role) {
        return TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, role);
    }

    private <T> ResponseEntity<T> exchange(HttpMethod method, String url, String token, Object body, Class<T> type) {
        return restTemplate.exchange(url, method, new HttpEntity<>(body, TestUsers.bearer(token)), type);
    }
}
