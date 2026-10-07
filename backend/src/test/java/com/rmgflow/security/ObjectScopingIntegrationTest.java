package com.rmgflow.security;

import tools.jackson.databind.JsonNode;
import com.rmgflow.buyer.dto.BuyerRequest;
import com.rmgflow.buyer.dto.BuyerResponse;
import com.rmgflow.factory.dto.FactoryBuyerApprovalRequest;
import com.rmgflow.factory.dto.FactoryRequest;
import com.rmgflow.factory.dto.FactoryResponse;
import com.rmgflow.factory.entity.FactoryBuyerApprovalStatus;
import com.rmgflow.factory.entity.PartnerType;
import com.rmgflow.identity.entity.Assignment;
import com.rmgflow.identity.entity.ScopeType;
import com.rmgflow.identity.repository.AssignmentRepository;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.RoleRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.order.dto.OrderItemRequest;
import com.rmgflow.order.dto.OrderRequest;
import com.rmgflow.order.dto.OrderResponse;
import com.rmgflow.style.dto.StyleRequest;
import com.rmgflow.style.dto.StyleResponse;
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

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Doc 5.1/5.2/5.3 object-level scoping: a scoped user only lists/gets records of
 * their assigned buyers (merchandisers) or factories (production follow-up), and an
 * out-of-scope id is a 404 on get and on order-child resources. Also covers the
 * approvals inbox permission rule and the minimal user directory.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class ObjectScopingIntegrationTest {

    @Autowired private TestRestTemplate restTemplate;
    @Autowired private UserRepository userRepository;
    @Autowired private RoleRepository roleRepository;
    @Autowired private OrganizationRepository organizationRepository;
    @Autowired private AssignmentRepository assignmentRepository;
    @Autowired private PasswordEncoder passwordEncoder;

    private record Fixture(TestSession gm, BuyerResponse buyerA, BuyerResponse buyerB, FactoryResponse factoryA,
                           FactoryResponse factoryB, StyleResponse styleA, StyleResponse styleB,
                           OrderResponse orderA, OrderResponse orderB) {
    }

    private Fixture fixture() {
        TestSession gm = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository,
                passwordEncoder, "GENERAL_MANAGER");
        BuyerResponse buyerA = post(gm.accessToken(), "/api/v1/buyers",
                new BuyerRequest("BA-" + UUID.randomUUID(), "Scope Buyer A", null, null, null, null, null, null), BuyerResponse.class);
        BuyerResponse buyerB = post(gm.accessToken(), "/api/v1/buyers",
                new BuyerRequest("BB-" + UUID.randomUUID(), "Scope Buyer B", null, null, null, null, null, null), BuyerResponse.class);
        FactoryResponse factoryA = factory(gm.accessToken(), buyerA);
        FactoryResponse factoryB = factory(gm.accessToken(), buyerB);
        StyleResponse styleA = post(gm.accessToken(), "/api/v1/styles",
                new StyleRequest("SA-" + UUID.randomUUID(), buyerA.id(), null, "Tee", null, null, null), StyleResponse.class);
        StyleResponse styleB = post(gm.accessToken(), "/api/v1/styles",
                new StyleRequest("SB-" + UUID.randomUUID(), buyerB.id(), null, "Tee", null, null, null), StyleResponse.class);
        OrderResponse orderA = order(gm.accessToken(), buyerA, styleA, factoryA);
        OrderResponse orderB = order(gm.accessToken(), buyerB, styleB, factoryB);
        return new Fixture(gm, buyerA, buyerB, factoryA, factoryB, styleA, styleB, orderA, orderB);
    }

    @Test
    void merchandiser_seesOnlyAssignedBuyersRecords() {
        Fixture f = fixture();
        String merch = scopedUser(f.gm(), "SENIOR_MERCHANDISER", ScopeType.BUYER, f.buyerA().id());

        assertThat(ids(get(merch, "/api/v1/orders?size=100"))).contains(f.orderA().id()).doesNotContain(f.orderB().id());
        assertThat(ids(get(merch, "/api/v1/buyers?size=100"))).containsExactly(f.buyerA().id());
        assertThat(ids(get(merch, "/api/v1/styles?size=100"))).contains(f.styleA().id()).doesNotContain(f.styleB().id());
        // Buyer-facing roles keep the full factory directory for sourcing.
        assertThat(ids(get(merch, "/api/v1/factories?size=100"))).contains(f.factoryA().id(), f.factoryB().id());

        assertThat(status(merch, "/api/v1/orders/" + f.orderA().id())).isEqualTo(HttpStatus.OK);
        assertThat(status(merch, "/api/v1/orders/" + f.orderB().id())).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(status(merch, "/api/v1/buyers/" + f.buyerB().id())).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(status(merch, "/api/v1/styles/" + f.styleB().id())).isEqualTo(HttpStatus.NOT_FOUND);
        // Order-child resources are scoped through their order.
        assertThat(status(merch, "/api/v1/orders/" + f.orderB().id() + "/ta-milestones")).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(status(merch, "/api/v1/orders/" + f.orderB().id() + "/amendments")).isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void productionFollowUp_seesOnlyAssignedFactoryOrders() {
        Fixture f = fixture();
        String prod = scopedUser(f.gm(), "PRODUCTION_FOLLOWUP", ScopeType.FACTORY, f.factoryA().id());

        assertThat(ids(get(prod, "/api/v1/orders?size=100"))).containsExactly(f.orderA().id());
        assertThat(ids(get(prod, "/api/v1/factories?size=100"))).containsExactly(f.factoryA().id());
        assertThat(status(prod, "/api/v1/orders/" + f.orderB().id())).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(status(prod, "/api/v1/orders/" + f.orderB().id() + "/production-updates")).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(status(prod, "/api/v1/factories/" + f.factoryB().id())).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(status(prod, "/api/v1/dashboard/my-day")).isEqualTo(HttpStatus.OK);
    }

    @Test
    void unassignedScopedUser_seesNothing_unrestrictedSeesAll() {
        Fixture f = fixture();
        String unassigned = TestUsers.createAndLoginInOrganization(restTemplate, userRepository, roleRepository,
                organizationRepository, passwordEncoder, "JUNIOR_MERCHANDISER", f.gm().organizationId());
        assertThat(ids(get(unassigned, "/api/v1/orders?size=100"))).isEmpty();

        String viewer = TestUsers.createAndLoginInOrganization(restTemplate, userRepository, roleRepository,
                organizationRepository, passwordEncoder, "MANAGEMENT_VIEWER", f.gm().organizationId());
        assertThat(ids(get(viewer, "/api/v1/orders?size=100"))).contains(f.orderA().id(), f.orderB().id());
    }

    @Test
    void approvalsInbox_requiresDecidePermissionForTargetType() {
        Fixture f = fixture();
        String prod = scopedUser(f.gm(), "PRODUCTION_FOLLOWUP", ScopeType.FACTORY, f.factoryA().id());
        // No decide permission: filtered inbox is refused, unfiltered inbox is empty.
        assertThat(status(prod, "/api/v1/approvals?targetType=COSTING")).isEqualTo(HttpStatus.FORBIDDEN);
        assertThat(get(prod, "/api/v1/approvals").get("content").size()).isZero();
        assertThat(status(f.gm().accessToken(), "/api/v1/approvals?targetType=COSTING")).isEqualTo(HttpStatus.OK);
    }

    @Test
    void userDirectory_isOrgScopedAndMinimal() {
        Fixture f = fixture();
        TestSession other = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository,
                passwordEncoder, "GENERAL_MANAGER");
        JsonNode users = get(f.gm().accessToken(), "/api/v1/users");
        assertThat(users.size()).isEqualTo(1);
        assertThat(users.get(0).has("fullName")).isTrue();
        assertThat(users.get(0).has("phone")).isFalse();
        assertThat(get(other.accessToken(), "/api/v1/users").size()).isEqualTo(1);

        String viewer = TestUsers.createAndLoginInOrganization(restTemplate, userRepository, roleRepository,
                organizationRepository, passwordEncoder, "MANAGEMENT_VIEWER", f.gm().organizationId());
        assertThat(status(viewer, "/api/v1/users")).isEqualTo(HttpStatus.FORBIDDEN);
    }

    // ------------------------------------------------------------------ helpers

    private String scopedUser(TestSession gm, String role, ScopeType type, Long scopeId) {
        String token = TestUsers.createAndLoginInOrganization(restTemplate, userRepository, roleRepository,
                organizationRepository, passwordEncoder, role, gm.organizationId());
        var user = userRepository.findAll().stream()
                .filter(u -> u.getOrganization().getId().equals(gm.organizationId()) && u.getEmail().startsWith(role.toLowerCase() + "+"))
                .findFirst().orElseThrow();
        Assignment assignment = new Assignment();
        assignment.setUser(user);
        assignment.setScopeType(type);
        assignment.setScopeId(scopeId);
        assignmentRepository.save(assignment);
        return token;
    }

    private FactoryResponse factory(String token, BuyerResponse buyer) {
        FactoryResponse factory = post(token, "/api/v1/factories", new FactoryRequest("F-" + UUID.randomUUID(), "Scope Factory",
                PartnerType.GARMENT_FACTORY, null, null, null, null, null), FactoryResponse.class);
        restTemplate.exchange("/api/v1/factories/" + factory.id() + "/buyer-approvals", HttpMethod.PUT,
                new HttpEntity<>(new FactoryBuyerApprovalRequest(buyer.id(), FactoryBuyerApprovalStatus.APPROVED, LocalDate.now(), null),
                        TestUsers.bearer(token)), Void.class);
        return factory;
    }

    private OrderResponse order(String token, BuyerResponse buyer, StyleResponse style, FactoryResponse factory) {
        return post(token, "/api/v1/orders", new OrderRequest("PO-" + UUID.randomUUID(), buyer.id(), null, LocalDate.now(),
                LocalDate.now().plusDays(60), null, null, null, null, "USD", false, null,
                List.of(new OrderItemRequest(style.id(), factory.id(), "Navy", "M", 100, new BigDecimal("5.00")))), OrderResponse.class);
    }

    private <T> T post(String token, String url, Object body, Class<T> type) {
        ResponseEntity<T> response = restTemplate.exchange(url, HttpMethod.POST, new HttpEntity<>(body, TestUsers.bearer(token)), type);
        assertThat(response.getStatusCode().is2xxSuccessful()).as("POST " + url).isTrue();
        return response.getBody();
    }

    private JsonNode get(String token, String url) {
        ResponseEntity<JsonNode> response = restTemplate.exchange(url, HttpMethod.GET, new HttpEntity<>(TestUsers.bearer(token)), JsonNode.class);
        assertThat(response.getStatusCode()).as("GET " + url).isEqualTo(HttpStatus.OK);
        return response.getBody();
    }

    private HttpStatus status(String token, String url) {
        return HttpStatus.valueOf(restTemplate.exchange(url, HttpMethod.GET, new HttpEntity<>(TestUsers.bearer(token)), String.class)
                .getStatusCode().value());
    }

    private static List<Long> ids(JsonNode page) {
        List<Long> ids = new ArrayList<>();
        page.get("content").forEach(n -> ids.add(n.get("id").asLong()));
        return ids;
    }
}
