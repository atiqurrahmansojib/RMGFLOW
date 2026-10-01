# Document 17 — Deployment Architecture

## 17.1 Environment Separation
```
Development → Testing (CI, ephemeral) → Staging (production-like, pre-release) → Production
```
- Dev: local Docker Compose (Postgres + backend + object storage emulator e.g. MinIO).
- Testing: CI pipeline spins up Testcontainers PostgreSQL per run, no shared state.
- Staging: mirrors production topology at smaller scale, used for UAT and pre-release regression (Doc 16.5 E2E scenarios run here).
- Production: as below.

## 17.2 Production Topology (recommendation for a single-buying-house deployment scale)
```
                        ┌─────────────┐
 Android App ──HTTPS──▶ │ Reverse Proxy│ (nginx / Caddy, TLS termination, HTTP→HTTPS redirect)
                        └──────┬──────┘
                               ▼
                        ┌─────────────┐
                        │ Spring Boot │ (containerized, 1-2 replicas behind the proxy for availability)
                        │   API       │
                        └──────┬──────┘
                 ┌─────────────┼──────────────┐
                 ▼                            ▼
         ┌───────────────┐           ┌──────────────────┐
         │  PostgreSQL    │           │ Object Storage    │ (S3-compatible: AWS S3 or
         │ (managed, e.g. │           │ (attachments,      │  self-hosted MinIO)
         │ RDS/Cloud SQL  │           │  documents, photos)│
         │ or self-hosted │           └──────────────────┘
         │ w/ backups)    │
         └───────────────┘
```
**Recommendation**: use a **managed PostgreSQL** service (automated backups, point-in-time recovery) over self-hosting for a small ops team — the cost delta is small relative to the risk of a DIY backup process that's "never been restored successfully" (prompt §42's own stated bar).

## 17.3 HTTPS / Domain
- TLS via Let's Encrypt (reverse proxy auto-renewal) or managed cert if on a cloud load balancer.
- Single domain (e.g., `api.rmgflow.example`) fronting the API; mobile app pinned to HTTPS only, no cleartext fallback.

## 17.4 Monitoring & Logging
- Application logs shipped to a centralized store (e.g., self-hosted Loki or a managed log service) — not left only on container stdout with no retention.
- API monitoring (uptime + latency) via a lightweight external check (e.g., UptimeRobot/Healthchecks) hitting a `/actuator/health` endpoint.
- Database monitoring: connection count, slow query log enabled, alert on disk usage threshold.
- Error tracking (e.g., Sentry) wired into the Spring Boot app for unhandled exceptions, and into Flutter for crash reporting.

## 17.5 CI/CD
- Backend: on push to main, run unit + integration tests (Doc 16.1/16.2) → build container image → deploy to staging automatically → manual promote to production.
- Flutter: on release branch, run Flutter tests (Doc 16.4) → build signed APK/AAB → manual upload to Play Console (internal testing track first, then staged rollout to production — never 100% immediate rollout for a transactional business app).

## 17.6 Database Backup & Disaster Recovery
- Automated daily full backup + continuous WAL archiving (point-in-time recovery) if managed Postgres is used; equivalent `pg_basebackup` + WAL-G/pgBackRest setup if self-hosted.
- Object storage: versioning enabled on the bucket (protects against accidental overwrite/delete) + cross-region replication if budget allows (**C**, recommended not mandatory for v1).
- **Retention**: daily backups for 30 days, weekly for 6 months, monthly for 2 years (adjust to actual compliance/business retention needs — **E**, owner should confirm statutory document retention requirements, which may exceed this for export commercial documents).
- **Restore testing**: quarterly scheduled restore-to-staging drill, logged — directly satisfies prompt §42's explicit bar ("a backup that has never been restored successfully should not be considered sufficient").

## 17.7 Android Release Process
- Signed App Bundle (AAB) via Play App Signing.
- Staged rollout (e.g., 10% → 50% → 100%) with crash-rate monitoring gate between stages.
- Versioned release notes tied to backend API version compatibility (a mobile release should state its minimum compatible backend API version; backend should tolerate N-1 mobile version per a documented deprecation window).

## 17.8 Secrets & Configuration
Per Document 15.6 — environment-specific config (DB URL, storage keys, JWT signing key) injected via environment variables/secrets manager per environment, never baked into container images or the mobile app bundle.
