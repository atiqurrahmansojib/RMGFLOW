# RMGFlow Backend

Spring Boot + PostgreSQL backend for the RMGFlow Bangladesh garments buying-house
management system. See [`/docs`](../docs/00-INDEX.md) at the repo root for the full
business/architecture analysis this implementation follows.

## Phase 1 (Foundation) — implemented

- Organizations, users, roles, permissions, role-permission mapping (Doc 8.1)
- JWT authentication with rotating refresh tokens (Doc 15.1, ADR-04)
- Object-level assignment scaffolding (buyer/factory scope, Doc 5.3)
- Append-only audit log with DB-level grant restriction (Doc 15.7)
- Argon2id password hashing (Doc 15.1 recommendation)
- RBAC enforced server-side via `@PreAuthorize` (Doc 15.2)

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
