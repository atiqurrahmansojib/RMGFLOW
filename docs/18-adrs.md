# Document 18 — Architectural Decision Records

## ADR-01: Mobile Technology — Flutter vs Native Android vs PWA
**Problem**: choose the client technology.
**Options**: Flutter, Native Android (Kotlin), PWA.
**Decision**: Flutter.
**Reason**: matches prompt's default assumption; strong camera/offline/push support; single codebase keeps future iOS option open at near-zero extra cost; team size implied (small) favors one stack over native's per-platform cost.
**Consequences**: dependent on plugin ecosystem maturity for camera/secure storage/offline DB; slightly heavier app size than native.
**Alternatives rejected**: Native Android (higher dev cost, no iOS path, not justified without stated iOS exclusion + existing native expertise); PWA (weak background push/offline/camera on Android, poor fit for factory field use).
**My recommendation**: Flutter — confirmed, no reason found to deviate.

## ADR-02: Backend Architecture — Spring Boot Modular Monolith vs Microservices
**Problem**: choose backend decomposition.
**Options**: (a) Modular monolith (single Spring Boot app, module-per-package per Doc 6), (b) Microservices per module.
**Decision**: Modular monolith.
**Reason**: single buying house, modest team and traffic (NFR-08 assumption: small-to-mid scale); microservices add deployment/ops complexity (service discovery, distributed transactions across Costing/Order/T&A which are tightly coupled anyway) without a scale justification.
**Consequences**: must enforce module boundaries via package structure/code review discipline, not network boundaries — easier to accidentally couple modules; revisit only if usage scales to multiple independent buying-house organizations needing independent scaling (multi-tenant SaaS pivot).
**Alternatives rejected**: Microservices (premature for this scale; the heavily cross-referenced domain — order/T&A/production/quality all centered on one aggregate — would need constant cross-service calls or event sourcing complexity not justified here).
**My recommendation**: Modular monolith, strongly — this is a textbook case where microservices would slow delivery without benefit.

## ADR-03: Database — PostgreSQL
**Problem**: choose primary datastore.
**Decision**: PostgreSQL (per prompt §26 assumption, confirmed).
**Reason**: strong relational integrity features needed throughout (Doc 8/9 — FKs, check constraints, triggers for immutability), JSONB for the few genuinely flexible fields (buyer requirements, T&A measurement spec), full-text search sufficient for v1 search needs (Doc "Search" area) without a separate search engine.
**Consequences**: if search/reporting scale demands grow significantly (large multi-year history, complex full-text relevance), a dedicated search index (e.g., OpenSearch) may be added later as a read-model, not a replacement.
**My recommendation**: PostgreSQL only for v1; do not add a second datastore (e.g., Elasticsearch) pre-emptively — unjustified complexity at this scale (prompt §56 rule 7 spirit: no unnecessary duplicate systems either).

## ADR-04: Authentication — JWT + Rotating Refresh Tokens
**Problem**: choose session/auth strategy for a mobile-first app.
**Options**: server-side session cookies, stateless JWT only, JWT + refresh token rotation.
**Decision**: JWT (short-lived) + rotating refresh token (Doc 15.1).
**Reason**: stateless access token suits a REST API consumed by a mobile client without cookie-jar complexity; rotation + server-side `sessions` table gives revocability (pure stateless JWT alone cannot be revoked before expiry) and device/session management (FR requirement, Doc 7 screen 3).
**Consequences**: requires a `sessions` table and refresh endpoint; slightly more complex than pure stateless JWT.
**Alternatives rejected**: pure stateless JWT with long expiry (cannot revoke a stolen device's access promptly); server-side cookie sessions (poor fit for a native mobile client, CSRF model mismatch).
**My recommendation**: JWT + rotation as designed — this is the right default for this shape of system.

## ADR-05: RBAC Model — Role+Permission Tables vs Hardcoded Enum Roles
**Problem**: how configurable should roles/permissions be.
**Decision**: DB-backed `roles`/`permissions`/`role_permissions` with a fixed initial permission-code catalog defined in code (migration-seeded), editable by Super Admin at the role-to-permission mapping level, but the permission codes themselves are not end-user-definable in v1.
**Reason**: prompt §4 asks for proper RBAC enforced backend-side; full dynamic permission-code creation by admins is over-engineering for one organization's fixed set of ~12 roles — flexibility is needed in *who has which existing permission*, not in inventing new permission types at runtime.
**Consequences**: adding a genuinely new permission type requires a code change/migration, not just an admin UI action — acceptable trade-off for stability and testability (Doc 16.1 explicitly tests every role×resource case, which requires a bounded, known permission catalog).
**My recommendation**: as decided; resist pressure to make permissions fully dynamic in v1.

## ADR-06: File Storage — Object Storage, Not Database BLOBs
**Problem**: where to store attachments/photos/documents.
**Decision**: S3-compatible object storage (Doc 17.2), metadata only in PostgreSQL (`attachments`/`documents` tables).
**Reason**: prompt §30 explicitly warns against storing large files directly in PostgreSQL; object storage scales better for binary data, supports versioning/lifecycle policies, and keeps DB backups fast and small.
**Consequences**: requires signed-URL access pattern (Doc 15.4) and an extra infra component (bucket + credentials) vs. a pure-DB approach.
**My recommendation**: as decided, no change.

## ADR-07: Offline Strategy — Partial Offline, Not Full Offline-First
**Problem**: how much offline capability to build.
**Decision**: three-tier model — cached read-only, draftable-and-synced, online-only-blocked (Doc 12.5).
**Reason**: prompt §25 explicitly instructs analyzing which functions genuinely need offline support rather than blindly building full offline mode; financial/approval/commercial finalization actions carry integrity risk if allowed to queue offline (conflicting concurrent edits, stale authorization context) that outweighs the convenience.
**Consequences**: users in zero-connectivity factory settings cannot finalize approvals or confirm orders until reconnected — an accepted limitation, communicated clearly in the UI (Doc 12.7 "requires connection" state), not a silent failure.
**My recommendation**: as decided; do not expand online-only actions into offline-queueable later without re-running the integrity-risk analysis per action type.

## ADR-08: Approval Engine — Single Shared Table vs Per-Module Tables
**Problem**: model the repeated submit/approve/reject/history pattern across costing, quotation, sample, quality, shipment, documents.
**Decision**: one shared `approvals` table with polymorphic `(target_type, target_id)` (Doc 8.4).
**Reason**: identical state machine and history requirement across 6+ otherwise-unrelated modules; a shared implementation avoids duplicating state-machine logic, trigger-based immutability enforcement, and reporting queries 6+ times (direct application of prompt §56 rule 7: no unnecessary duplicate tables).
**Consequences**: `target_id` cannot be a true DB foreign key (polymorphic), so referential integrity for that link is enforced in application code + a periodic integrity-check job (Doc 16.6), not the database alone — an explicitly accepted trade-off.
**Alternatives rejected**: one approval table per target type (simpler FK integrity, but 6x logic/schema duplication and 6x the places a bug can hide).
**My recommendation**: keep the shared table; mitigate the FK trade-off with the periodic orphan-check job (already specified in Doc 16.6) rather than abandoning the pattern.

## ADR-09: Order Amendment — Append-Only Amendment Log vs Versioned Order Snapshots
**Problem**: how to preserve order change history.
**Options**: (a) append-only `order_amendments` log + mutable "current" fields on `orders`, (b) full immutable order version snapshots (like costing/quotation).
**Decision**: (a) append-only amendment log, per field changed (Doc 8.6).
**Reason**: order fields (qty/price/date/destination) change individually and incrementally far more often than costing/quotation are wholesale re-priced; a field-level log is more queryable ("show me every price change on this order") than diffing whole-record snapshots, and matches how merchandisers actually think about amendments (prompt Doc 2's description of amendments as routine, incremental events).
**Consequences**: the service layer must guarantee amendment-row-write and current-value-update happen atomically (Doc 9.4) — a discipline requirement, not purely schema-enforced.
**My recommendation**: as decided.

## ADR-10: Multi-Company / Multi-Unit — Schema-Ready, Application-Layer Isolation
**Problem**: how much to invest in multi-org support now.
**Decision**: every core table carries `organization_id`; no multi-org switching UI in v1, but — revised after a security review during Phase 2 implementation — every service-layer read/write IS scoped to the caller's `organization_id` (`findByIdAndOrganizationId`, `findByOrganizationId*`), not merely column-ready as originally decided.
**Reason**: prompt §37 explicitly warns against over-engineering for a future that may not materialize, while also warning against decisions that make future expansion impossible — the `organization_id` column is near-zero-cost now and prevents an expensive retrofit later. The original "not tested beyond the column existing" stance turned out to be a real IDOR the moment Phase 2 shipped actual CRUD: a role with full manage rights in one organization could read/edit/attach-children-to another organization's buyer/factory by id, since nothing checked tenancy. There was never a point at which "schema-ready but unenforced" was actually safe to ship, even for a nominally single-org v1 — the column existing creates the expectation of isolation, and partial/future rollout to a second org would otherwise inherit the hole silently.
**Consequences**: every new module's service layer must follow the same pattern established in `BuyerService`/`FactoryService` (`findInCurrentOrganization`, tenant-scoped list queries) from the start — this is now a standing requirement for Document 22's Definition of Done ("authorization implemented and tested"), not an optional hardening pass. Still no multi-org switching UI, connection-level RLS, or tenant-per-schema — those remain deferred until a second organization is actually onboarded (DB-level defense-in-depth beyond the application check is a reasonable later addition, not a v1 blocker since the application-layer check is enforced on every endpoint and covered by tests).
**My recommendation**: treat "scope every query to `organization_id`" as non-negotiable from Phase 3 onward, not something to retrofit after the fact — retrofitting it into Phase 2 cost real rework (service signatures, test helper changes) that writing it correctly the first time would have avoided.

## ADR-11: Integration with Existing Garments ERP
**Problem**: should RMGFlow integrate with the user's existing garments-industry ERP, and how (prompt §38).
**Options**: (1) fully independent, (2) shared backend, (3) REST integration between independent systems, (4) RMGFlow becomes a module inside the existing ERP.
**Decision**: **Option 3 — independent system with a defined REST integration boundary**, pending owner confirmation (classified **E** in Doc 3/4 — the existing ERP's architecture is unknown to this analysis).
**Reason**: option 2/4 (shared backend / becomes a module) risks destabilizing an existing production ERP and requires deep knowledge of its schema/auth model not available here; option 1 (fully independent, no integration) risks duplicate buyer/factory/style master data, which prompt §56 rule 7 and §38 explicitly want avoided. A REST integration boundary lets each system own its master data with one designated as source-of-truth per entity (recommendation below) and sync via API rather than merging codebases.
**My recommendation**: designate the **existing ERP as source of truth for factory/production master data** (since it likely already manages factory-floor specifics RMGFlow explicitly excludes, Doc 1.2) and **RMGFlow as source of truth for buyer/merchandising/commercial data** (its core domain) — sync overlapping entities (factories, styles) one-directionally from ERP → RMGFlow by default, with conflict resolution rules defined once the ERP's actual API surface is known. This is a recommendation, not a decision — final call requires owner input on the existing ERP's capabilities (Open Questions Doc, blocking question).

## ADR-12: Financial Scope — Operational Profitability Only, Not Full Accounting
**Problem**: how much financial functionality belongs in this system (prompt §19).
**Decision**: track operational profitability (costing vs. realized price/cost) and summary receivable/payable status; do not build a general ledger, chart of accounts, or tax reporting.
**Reason**: prompt §19 explicitly says not to pretend this is a complete accounting ERP unless justified; a buying house's accounting system of record is typically separate, specialized software — duplicating it here risks two "sources of truth" for money, a worse outcome than not having one at all.
**Consequences**: a true accounting integration boundary (export receivable/payable events to an accounting system) is a **D** future enhancement, not built in v1.
**My recommendation**: as decided; resist scope creep into full accounting even if requested mid-project without a clear business case, per development rule §56 discipline.

## ADR-13: T&A Architecture — Configurable Templates + Instance Milestones
**Problem**: how rigid vs. flexible should T&A/critical-path modeling be (prompt §13).
**Decision**: reusable `ta_templates`/`ta_template_milestones` (config) instantiated into per-order `ta_milestones` (mutable instances) at order confirmation, with dependency links and automatic status/delay derivation (Doc 8.7, 9.5, 10.3).
**Reason**: prompt explicitly forbids hardcoding the milestone list; buyers/styles need different critical paths; but once instantiated, an order's T&A must be independently editable (buyer-specific delays) without mutating the shared template.
**My recommendation**: as decided, plus implement the delay-cascade automation (A16, Doc 13) early — it is the single highest-leverage feature for daily operational value per Document 2's framing of T&A as the operational nerve center.

## ADR-14: Costing Architecture — Versioned, Immutable Post-Approval
**Decision**: `costings`/`costing_items` versioned by `version_no`, locked from editing once `APPROVED`, enforced by DB trigger + service guard (Doc 8.5, 9.1).
**Reason**: direct requirement (prompt §10, NFR-05) that historical costing used for an order remain immutable; a trigger-level enforcement (not just application discipline) protects against bugs or future direct-DB access bypassing the service layer.
**My recommendation**: keep both layers (trigger + service check) — defense in depth is cheap here and the cost of a silent bypass (a disputed margin figure years later) is high.

## ADR-15: Order Amendment / ERP Integration Boundary and Duplication Prevention
**Problem**: if ADR-11's integration path is chosen, how is duplication of buyers/factories/styles/orders prevented (prompt §38 explicit ask).
**Decision**: each shared entity type has exactly one declared source-of-truth system (per ADR-11); the non-authoritative system stores a `external_ref_id` column pointing to the authoritative system's id, synced via a scheduled or webhook-driven integration job, never independently editable in the non-authoritative system.
**My recommendation**: implement this boundary explicitly before any integration code is written, not organically — ad hoc two-way sync is the most common source of "which system is right" disputes in ERP integrations.
