# RMGFlow Backend

Spring Boot + PostgreSQL backend for the RMGFlow Bangladesh garments buying-house
management system. See [`/docs`](../docs/00-INDEX.md) at the repo root for the full
business/architecture analysis this implementation follows.

## Implementation status — all 13 phases complete

Every phase in `docs/20-implementation-roadmap.md` is implemented and covered by
integration tests (48 tests, 0 failures as of the last full run):

1. **Foundation** — organizations, users, roles, permissions, JWT auth with rotating
   refresh tokens, Argon2id hashing, append-only audit log, server-side RBAC.
2. **Buyers & Factories** — buyer/contact/requirement management, factory capability
   and certification tracking, factory-buyer approval gate.
3. **Inquiry & Styles** — inquiry state machine, style + append-only style revisions.
4. **Approval Engine & Attachments** — shared polymorphic approval engine (ADR-08),
   generic attachment module with signed download tokens.
5. **Costing & Quotation** — server-computed margins, field masking, quotation
   requires an APPROVED costing.
6. **Sampling** — sample types/samples/revisions, second Approval Engine consumer.
7. **Orders & T&A** — order confirmation, T&A milestone instantiation from templates,
   delay-cascade automation (A16) with audit trail per shifted milestone.
8. **Production Follow-up** — cumulative production updates, packing hard-block.
9. **Quality** — inspections, defects, CAPA records, quality gate for shipment.
10. **Shipment & Commercial Documents** — shipment with quality/quantity/partial-auth
    gates, versioned commercial documents (reuses the attachment module).
11. **Financial Tracking & Claims** — receivables/payables with derived status,
    estimate-vs-realized order margin, claims isolated by construction from
    order/shipment mutation.
12. **Communication, Tasks, Notifications, Dashboards** — entity-attached activities
    and tasks, in-app notifications, the first real scheduled-job automation
    (`TaMilestoneOverdueScanService`, A2), and the cross-module "My Day" dashboard.
13. **Hardening** — repo-wide tenant-scoping security review (no un-scoped
    `findById` or missing-authorization gaps found beyond the two intentional
    `findInCurrentOrganization()` helper implementations in the quality module),
    full regression run (48/48 passing), deployment/backup posture reviewed in
    `docs/17-deployment-architecture.md` (no live infrastructure exists to
    provision in this environment).

## Running locally

Requires Java 21+, Docker (for tests via Testcontainers), and a PostgreSQL instance
for actually running the app (not needed just to run `./mvnw test`, which spins up
its own container).

```bash
# Run the test suite (spins up PostgreSQL via Testcontainers automatically)
./mvnw test

# Run the app (needs a real Postgres reachable via DB_URL/DB_USERNAME/DB_PASSWORD,
# defaults to jdbc:postgresql://localhost:5432/rmgflow)
BOOTSTRAP_ADMIN_EMAIL=admin@yourcompany.com \
BOOTSTRAP_ADMIN_PASSWORD=change-me-now \
JWT_SECRET=$(openssl rand -base64 48) \
./mvnw spring-boot:run
```

On first startup with no users in the database, `BootstrapSeeder` creates the first
Super Admin from `BOOTSTRAP_ADMIN_EMAIL`/`BOOTSTRAP_ADMIN_PASSWORD` — required because
the `/api/v1/users` endpoint that creates subsequent users is itself Super-Admin-only
(see `BootstrapSeeder` javadoc). Every subsequent user is created through that endpoint.

## Notable stack facts (Spring Boot 4 / Spring Security 7)

This project targets Spring Boot 4.1.x, which made a few breaking changes relevant
to this codebase if you're used to Boot 3:

- Jackson's Spring-managed `ObjectMapper`/`JsonNode` beans are now the **Jackson 3**
  fork under `tools.jackson.databind`, not `com.fasterxml.jackson.databind`. The
  `com.fasterxml.jackson.databind` classes still exist on the classpath (pulled in
  transitively by `jjwt-jackson`) but are a *different, unmanaged* copy — do not mix
  the two for anything Spring needs to autowire.
- `TestRestTemplate` moved to `org.springframework.boot.resttestclient.TestRestTemplate`
  (module `spring-boot-resttestclient`), enabled via `@AutoConfigureTestRestTemplate`
  from `org.springframework.boot.resttestclient.autoconfigure`.
- `Argon2PasswordEncoder` requires Bouncy Castle (`bcprov-jdk18on`) explicitly on the
  classpath; it is not pulled in by `spring-boot-starter-security`.
- Starters are now split per concern, including separate `*-test` starters
  (`spring-boot-starter-webmvc-test`, `-data-jpa-test`, etc.) in addition to the
  `spring-boot-starter-webmvc` etc. compile-scope starters.
