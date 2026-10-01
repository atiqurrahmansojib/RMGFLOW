# Document 15 — Security Architecture

## 15.1 Authentication
- Email + password login; passwords hashed with **bcrypt** (or Argon2id — **Recommendation: Argon2id**, stronger modern default, well-supported in Spring Security as of recent versions) with per-user salt, never reversible storage.
- **JWT access token** (short-lived, ~15 minutes), signed (RS256, asymmetric so only the auth service holds the signing key) — contains user id, org id, role codes only (no sensitive data).
- **Refresh token** (longer-lived, rotating on each use), stored hashed in `sessions` table server-side; client stores the raw refresh token in `flutter_secure_storage` (Android Keystore-backed), never SharedPreferences.
- Refresh rotation: each refresh invalidates the prior token (`sessions.revoked_at` set) — detects token theft/replay (reuse of a revoked token revokes the entire session family).
- Login rate-limited (e.g., 5 attempts / 15 min per account + per IP) to blunt credential-stuffing/brute force.

## 15.2 Authorization
- RBAC + object-level scope, fully server-side (Doc 5.3, Doc 11.3) — `@PreAuthorize` for permission codes, explicit service-layer checks against `assignments` for object scope. The Flutter client's role-based UI hiding is cosmetic only.
- Field-level masking (margin/cost visibility) enforced in the DTO mapping layer (Doc 11.1), never trusted to client-side conditional rendering.

## 15.3 Session / Device Management
- `sessions` table tracks device info, IP, created/expiry/revoked timestamps — exposed to the user as "Active Sessions" (Doc 7 screen 3) with a manual revoke action (e.g., lost phone).
- Admin can force-revoke any user's sessions (e.g., offboarding).

## 15.4 File Access Security
- Attachments stored in object storage (S3-compatible — see Doc 17), never directly web-accessible; access via short-lived signed URLs generated per request after an authorization check in the API (NFR-01/09) — prevents guessable-URL leakage of buyer tech packs or commercial documents.
- Upload validation: content-type allow-list, size limits (Doc 30 in prompt → folded here), filename sanitization to prevent path traversal.
- **Recommendation**: run uploaded files through a virus-scan step (e.g., ClamAV container in the upload pipeline) before marking an attachment "available" — buying houses receive files from many external parties (buyers, factories), making this a real, not theoretical, risk; classified **C** (recommended, not blocking v1 if budget-constrained, but should not be silently dropped).

## 15.5 API Security
- Input validation at DTO (Bean Validation) + business-rule layer (Doc 9) — rejects malformed/out-of-range input before it reaches persistence.
- Parameterized queries only (JPA/Hibernate by default) — no string-concatenated SQL, eliminating SQL injection risk by construction.
- CORS restricted to known origins (admin web console if any, not public).
- Rate limiting on mutation-heavy endpoints to prevent abuse/runaway mobile retry loops.
- Security headers (HSTS, X-Content-Type-Options, X-Frame-Options) on any web-facing surface.

## 15.6 Secrets Management
- No secrets in source control or client bundles. Backend secrets (DB credentials, JWT signing key, object storage keys) in environment variables sourced from a secrets manager (e.g., Doppler, AWS Secrets Manager, or at minimum an encrypted `.env` outside the repo) — never hardcoded.
- JWT signing key rotation procedure documented (even if rotation cadence is initially manual/annual for a small deployment).

## 15.7 Logging & Audit
- `audit_logs` (Doc 8.9) append-only at the DB role level — the application's DB user has no UPDATE/DELETE grant on that table, only INSERT/SELECT, enforced by Postgres `GRANT`/`REVOKE`, not just application discipline.
- Application logs exclude PII/secrets (no password, token, or full buyer financial data in plain log lines) — structured logging with field redaction for sensitive keys.
- Mandatory audit events (Doc 28 response, below) cover every state transition identified as a business invariant in Document 9.11.

## 15.8 Mandatory Audit Actions (prompt §28)
Who/what/when/entity/entity_id/previous/new/reason/IP recorded for: login, role/permission change, costing approval, quotation approval, order confirmation, order amendment, order cancellation, sample approval decision, factory-buyer approval change, shipment creation/authorization (especially partial), document approval, payment record creation, user account creation/deactivation.

## 15.9 Backup Security
See Document 19 for backup/DR; access to backups restricted to infra admin role, backups encrypted at rest, retention policy documented there.

## 15.10 Threat Model Summary (top risks and mitigations)
| Threat | Mitigation |
|---|---|
| Stolen mobile device | Short-lived access token, Keystore-backed refresh token, remote session revoke |
| Leaked signed file URL | Short expiry, scoped to one file, re-issued per authorized request |
| Insider over-access (e.g., junior staff viewing margin) | Field-level masking server-side, object-level assignment scoping |
| Credential stuffing | Rate limiting, bcrypt/Argon2id, optional 2FA (recommended C, not blocking v1) |
| Tampered audit trail | DB-role-level append-only grant, no application code path performs UPDATE/DELETE on `audit_logs` |
| Malicious file upload | Content-type/size validation, recommended virus scan (15.4) |
