# Document 21 — Detailed Development Backlog

Representative task breakdown per phase (Document 20). Each task is sized for a single implementation session by an AI coding agent or developer (prompt §54 requirement — no vague "Build order module" tasks). IDs are `P<phase>-T<n>`.

## Phase 1 — Foundation

**P1-T1 — Organization & User schema + migration**
- Module: Identity & Access
- Objective: create `organizations`, `users` tables with Flyway/Liquibase migration
- Dependencies: none
- Backend: JPA entities, repositories
- Database: migration script with constraints (Doc 8.1)
- API: none yet (internal only)
- Flutter: none
- Testing: repository integration test (save/find user)
- Acceptance: migration runs clean on empty DB; unique email constraint verified by test

**P1-T2 — Roles, permissions, role_permissions schema + seed data**
- Backend: entities + a migration-seeded permission catalog (Doc 5.2 derived list)
- Database: `roles`, `permissions`, `role_permissions` + seed migration
- Testing: unit test verifying seed data matches Doc 5.2 permission list count
- Acceptance: all 12 roles from Doc 5.1 exist with correct permission mappings seeded

**P1-T3 — JWT authentication (login/refresh/logout)**
- Backend: Spring Security config, JWT signing/validation, `/auth/login`, `/auth/refresh`, `/auth/logout`
- Database: `sessions` table
- API: 3 endpoints per Doc 11.2, error shape per Doc 11.3
- Testing: unit tests for token generation/validation; integration test for login→refresh→revoke flow
- Acceptance: valid login issues access+refresh token; expired access token rejected; refresh rotates and invalidates prior token (Doc 15.1)

**P1-T4 — Object-level authorization (assignments) framework**
- Backend: `assignments` table, a reusable `@RequireScope` annotation/aspect checking buyer/factory assignment
- Testing: unit test — Junior Merchandiser without assignment denied access to unassigned buyer's resource
- Acceptance: matches Doc 5.3 enforcement model

**P1-T5 — Audit log infrastructure**
- Backend: `AuditService` with a generic `record(action, entityType, entityId, previous, new, reason)` method; AOP or explicit calls from services
- Database: `audit_logs` table, DB grants restricting UPDATE/DELETE to no application role (Doc 15.7)
- Testing: verify a tracked action produces exactly one audit row with correct previous/new JSON
- Acceptance: attempting UPDATE/DELETE on `audit_logs` via the app DB role fails at the DB level

**P1-T6 — Flutter app shell**
- Flutter: project scaffold, `go_router` setup, Riverpod provider setup, `dio` client with auth interceptor, secure storage integration, base theme/design tokens
- Testing: widget test for login screen happy path (mocked API)
- Acceptance: app builds, login screen reachable, token stored in secure storage after successful mock login

## Phase 2 — Master Data

**P2-T1 — Reference tables (currencies, countries, Incoterms, payment terms, document types, defect types, milestone types)**
- Database: 7 tables + seed migrations with standard values (ISO currency/country codes, common Incoterms)
- Backend: simple CRUD repositories/services (Super Admin only writes)
- API: `/currencies`, `/countries`, `/incoterms`, `/payment-terms`, `/document-types`, `/defect-types`, `/milestone-types` (GET public to authenticated users, POST/PUT Super Admin)
- Flutter: dropdown/picker widgets backed by these endpoints, cached locally
- Testing: API test — non-admin cannot POST
- Acceptance: all 7 reference lists populated and selectable in any form needing them

**P2-T2 — Buyer master CRUD**
- Database: `buyers` table (Doc 8.2) + migration
- Backend: BuyerService with create/update/list/get, optimistic lock handling (Doc 8.12)
- API: `/buyers` CRUD per Doc 11.2
- Flutter: Buyer List, Buyer Detail (Overview tab), Buyer Create/Edit Form (Doc 7 #16-18)
- Testing: unit test for optimistic lock conflict → 409; API authorization test (Doc 5.2 matrix row)
- Acceptance: GM can create/edit any buyer; Junior Merchandiser can create/edit only their assigned buyers

**P2-T3 — Buyer contacts & requirements**
- Database: `buyer_contacts`, `buyer_requirements`
- Backend/API: nested resource endpoints under `/buyers/{id}`
- Flutter: Contacts tab, Requirements display on Buyer Detail
- Testing: multiple contacts per buyer supported, one marked primary (business rule: exactly one `is_primary=true` per buyer, enforced via partial unique index or service check)
- Acceptance: FR-02 satisfied

**P2-T4 — Factory/vendor master CRUD + typed partner_type**
- Database: `factories` table with `partner_type` enum (Doc 8.2)
- Backend/API/Flutter: mirrors P2-T2 pattern, with partner_type filter on list
- Testing: verify list filter by partner_type returns only matching rows
- Acceptance: FR-10/11 satisfied; UI clearly distinguishes factory types (Doc 7 #20)

**P2-T5 — Factory capabilities, certifications, buyer approvals**
- Database: `factory_capabilities`, `factory_certifications`, `factory_buyer_approvals`
- Backend: service enforcing `UNIQUE(factory_id, buyer_id)` on approvals, certification expiry flag computed at read-time
- API/Flutter: nested endpoints + Factory Detail tabs (Doc 7 #21)
- Testing: unit test for the order-creation-blocking rule placeholder (actual enforcement wired in Phase 6, but the approval status read API is built and tested here)
- Acceptance: FR-11/factory_buyer_approvals data correctly queryable per factory+buyer pair

## Phase 3 — Inquiry & Product Development

**P3-T1 — Inquiry lifecycle (CRUD + status transitions)**
- Database: `inquiries` table
- Backend: state machine enforcing valid transitions only (OPEN→QUOTED/LOST/HOLD, etc. per Doc 10.1), `lost_reason` required when status=LOST
- API/Flutter: Inquiry List/Detail/Form, Mark Won/Lost dialog (Doc 7 #24-27)
- Testing: unit test rejecting invalid transition (e.g., LOST→WON directly without going through QUOTED); API test for required lost_reason
- Acceptance: FR-20 satisfied, Doc 10.1 transitions enforced

**P3-T2 — Inquiry factory candidates**
- Database: `inquiry_factory_candidates`
- Backend/API/Flutter: nested CRUD, status CANDIDATE/SELECTED/REJECTED
- Acceptance: FR-21

**P3-T3 — Generic attachment module**
- Database: `attachments` table (polymorphic entity_type/entity_id)
- Backend: upload service — object storage client (S3-compatible), signed URL generation (Doc 15.4), content-type/size validation
- API: `POST /attachments` (multipart), `GET /attachments/{id}/url` (returns short-lived signed URL)
- Flutter: shared attachment picker widget (Doc 7 #100), used by every subsequent module needing files/photos
- Testing: upload rejects disallowed content-type/oversize file; signed URL expires after configured TTL (integration test with short TTL override)
- Acceptance: this is the FIRST cross-cutting module built — every later phase reuses it, not reimplements it (Doc 6.3 principle)

**P3-T4 — Style master + revisions**
- Database: `styles`, `style_revisions` (Doc 8.3)
- Backend: StyleService — creating a new revision never updates a prior revision row (enforced: revision table has no UPDATE path in the service beyond the create method, no update endpoint for existing revisions)
- API/Flutter: Style List/Detail/Form, Revision Compare View (Doc 7 #28-31)
- Testing: unit test — attempting to modify revision N after revision N+1 exists is rejected/not exposed via API
- Acceptance: FR-30/31 satisfied, immutable revision history verified

## Phase 4 — Costing & Quotation

**P4-T1 — Approval engine core**
- Database: `approvals` table (Doc 8.4) with trigger blocking UPDATE where `decided_at IS NOT NULL`
- Backend: generic `ApprovalService.submit(targetType, targetId)`, `.decide(approvalId, decision, comments)`
- API: `/approvals`, `/approvals/{id}/decide` (Doc 11.2)
- Testing: unit test for every state transition in Doc 8.4 enum; test that a decided approval's status cannot be changed (expect DB exception caught and mapped to a clean API error)
- Acceptance: ADR-08 implementation validated — this is the shared engine every later approval-gated module will call

**P4-T2 — Costing CRUD + versioning**
- Database: `costings`, `costing_items`, immutability trigger (Doc 9.1)
- Backend: margin/total calculation logic (unit-tested per Doc 16.1), version-on-revise logic
- API/Flutter: Costing List/Detail/Form/Revision/Approval screens (Doc 7 #37-41), wired to P4-T1's approval engine
- Testing: unit tests per Doc 16.1 costing bullet; integration test — approved costing rejects further item edits
- Acceptance: FR-50/51/52 satisfied

**P4-T3 — Quotation CRUD + versioning**
- Database: `quotations` table, immutability trigger
- Backend: enforce quotation can only reference an APPROVED costing (Doc 9.2)
- API/Flutter: Quotation screens (Doc 7 #42-46)
- Testing: integration test — quotation creation against DRAFT costing returns a typed business error (not a generic 500)
- Acceptance: FR-60/61/62, Doc 10.2 state machine verified

## Phase 5 — Sampling

**P5-T1 — Sample types + requests**
- Database: `sample_types`, `samples`
- Backend/API/Flutter: standard CRUD + list filters (Doc 7 #32-35)

**P5-T2 — Sample revisions + approval engine integration**
- Database: `sample_revisions`
- Backend: reuses `ApprovalService` (P4-T1) with `target_type=SAMPLE_REVISION`; rejection creates new revision row, never mutates prior
- API/Flutter: Sample Approval Response Form (Doc 7 #36)
- Testing: integration test reproducing Doc 16.5 scenario #2 (reject twice, approve third revision, full history visible)
- Acceptance: FR-40/41/42/43; validates approval engine's second real consumer (per Doc 20 Phase 5 rationale)

## Phase 6 — Orders

**P6-T1 — Order creation with factory-buyer approval gate**
- Database: `orders`, `order_items`
- Backend: order creation service enforcing Doc 9.4 factory-approval check, override path requiring `ORDER_FACTORY_OVERRIDE` permission + mandatory reason (audited)
- API/Flutter: Order Create Form (from quotation or direct), Order List/Detail (Doc 7 #47-49)
- Testing: unit test — creation with unapproved factory blocked without override, succeeds with override + audit row written (Doc 16.5 scenario #5)
- Acceptance: FR-70/71, Doc 9.4 enforced

**P6-T2 — Order amendments**
- Database: `order_amendments`
- Backend: atomic amendment-write + current-value-update transaction (Doc 9.4/ADR-09)
- API/Flutter: Amendment Request/Approval screens (Doc 7 #50-51)
- Testing: integration test simulating failure mid-transaction — verify no partial write (Doc 16.2 bullet)
- Acceptance: FR-72

**P6-T3 — Order cancellation & split**
- Backend: cancellation blocked if shipment exists beyond BOOKED (Doc 9.4), GM/Owner approval required via approval engine; split allocates order_items across multiple factories
- API/Flutter: Cancellation Form, Split Form (Doc 7 #52-53)
- Testing: unit test for cancellation-block condition
- Acceptance: FR-73/75

## Phase 7 — T&A

**P7-T1 — T&A templates (CRUD)**
- Database: `ta_templates`, `ta_template_milestones`
- Backend/API/Flutter: Template List/Create/Edit (Doc 7 #54-55)
- Acceptance: FR-80

**P7-T2 — Milestone instantiation on order confirmation (A15)**
- Database: `ta_milestones`
- Backend: template resolution (style > buyer > default precedence), planned_date calculation from `offset_days_from_exfactory`
- Testing: unit test for precedence resolution and date math (Doc 16.1)
- Acceptance: confirming an order in Phase 6 flow now auto-generates milestones

**P7-T3 — Status derivation job + dashboard surfacing**
- Backend: scheduled job computing UPCOMING/OVERDUE/CRITICAL_DELAY/BLOCKED (Doc 9.5)
- API/Flutter: T&A Calendar View, Milestone Update Form, Delay/Alert List (Doc 7 #56-58)
- Testing: unit tests for each status boundary condition
- Acceptance: FR-82

**P7-T4 — Delay cascade automation (A16)**
- Backend: cascade logic shifting dependent `revised_date`s, bounded recursion, full audit trail + per-affected-user notification
- Testing: unit test for cascade correctness and depth cap; integration test verifying notifications sent to every affected responsible user
- Acceptance: Doc 13 A16 implemented per its risk-aware design note (Doc 13.1)

*(Phases 8-13 follow the same granularity pattern — daily production update entry/rollup, inspection/defect/CAPA with shipment-blocking rule, shipment/document CRUD with partial-authorization gate, financial/claims tracking, activity/task/notification wiring per-phase as specified in Doc 20's dependency note, dashboards/reports per Doc 14, and the Phase 13 hardening checklist per Doc 16.6/17.6. Full task-level breakdown for these phases follows identical structure — generated at the start of each phase from its corresponding Document 3 FRs and Document 9 rules, rather than speculatively detailed now before Phases 1-7 are built and lessons incorporated.)*

## My Recommendation
Do not pre-write exhaustive task lists for Phases 8-13 today — task breakdowns for Phase 7+ should be regenerated just before each phase starts, incorporating whatever was learned building Phases 1-7 (e.g., whether the generic approval engine held up under a third/fourth real consumer, whether the attachment module's signed-URL pattern needs adjustment). Writing all ~13 phases to this level of detail now risks stale tasks that don't reflect decisions made during actual implementation.
