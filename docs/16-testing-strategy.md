# Document 16 — Testing Strategy

## 16.1 Unit Tests (backend, business-rule-critical — mandatory per prompt §40 and development rule §56.10)
- Cost total/margin calculation (Doc 9.1) across component types, wastage, currency.
- Currency conversion correctness (captured rate-at-time, not live recompute).
- T&A date math: offset-from-ex-factory calculation, delay cascade (A16), status derivation (UPCOMING/OVERDUE/CRITICAL_DELAY/BLOCKED).
- Production cumulative sum correctness, over-order-quantity flag/block boundary conditions.
- Shipment quantity validation (cannot exceed order qty; partial authorization gate).
- Approval state machine transitions (every valid/invalid transition per Doc 8.4 enum, including the "rejected never becomes approved via edit" invariant).
- RBAC permission + object-level scope resolution logic (every role × resource combination from Doc 5.2 matrix, at least the denial cases).

## 16.2 Integration Tests (cross-module flows, DB-backed, e.g., Testcontainers + PostgreSQL)
- Inquiry → quotation: costing approval gate blocks quotation creation against a DRAFT costing.
- Costing → quotation: approved costing immutability enforced under concurrent update attempt (optimistic lock).
- Order → T&A: confirming an order generates correct milestone set from the resolved template (style > buyer > default precedence, Doc 8.7).
- Order → production: daily updates roll up correctly; packing cap enforced.
- Production → shipment: shipment blocked when final inspection fails; unblocked after passing re-inspection.
- Sample → approval: rejection creates new revision + new approval round without mutating the prior one.
- Order amendment: amendment + denormalized current-value update occur atomically (rollback test: simulate failure mid-transaction, assert no partial write).

## 16.3 API Tests
- Authorization: every endpoint tested for 200 (authorized role), 403 (wrong role), 403/404 (object-scope violation — e.g., Junior Merchandiser hitting another's buyer).
- Validation: malformed payloads return structured 400 with field errors (Doc 11.3 error shape).
- Error handling: optimistic-lock 409 returns current server state.
- Pagination/filtering: boundary tests (page size cap, invalid filter values rejected, not silently ignored).
- Idempotency-Key: duplicate request with same key returns the original result, does not create a duplicate record.

## 16.4 Flutter Tests
- Forms: validation rules mirror backend constraints (Doc 12.7); submit disabled until valid.
- Navigation: deep link from notification payload routes to correct entity detail.
- State management (Riverpod providers): unit tests for each controller's state transitions (loading/data/error).
- Offline behavior: outbox queues a draft when offline; online-only actions show disabled/blocked state offline (Doc 12.5) rather than silently failing.
- Sync: queued outbox item syncs on reconnect with idempotency key; 409 conflict surfaces the merge screen (Doc 12.6).
- Authentication: token refresh interceptor correctly retries a 401 once, then logs out on second failure.

## 16.5 End-to-End Scenarios (realistic business flows, run against a staging environment)
1. Full happy path: inquiry → costing → quotation → order → T&A auto-generated → daily production updates → final inspection pass → shipment → document upload → payment recorded → order closed.
2. Sample rejection loop: sample requested → rejected twice → approved on third revision → order proceeds; verify full revision/approval history retained and visible.
3. Order amendment under production: quantity reduced mid-production (above already-shipped floor) → T&A/production figures remain consistent; amendment history visible.
4. Partial shipment: two shipments against one order, second completes the order quantity → order status transitions CONFIRMED → PARTIALLY_SHIPPED → SHIPPED correctly.
5. Factory not buyer-approved: attempt to create order with unapproved factory → blocked; GM override path → order created with audit trail entry.
6. Quality failure path: final inspection fails → shipment blocked → CAPA opened/closed → re-inspection passes → shipment unblocked.
7. Post-shipment claim: buyer claim raised → resolved → original shipment/order records unchanged, claim trail independently visible.
8. Offline field use: production follow-up officer logs a production update offline in a factory with no signal → reconnects → update syncs without duplication.

## 16.6 Non-Functional / Quality Gates
- **Security review** (Document 15 checklist) before each release touching auth, file access, or financial data.
- **Performance smoke test**: list/dashboard endpoints under representative data volume (Doc 3 NFR-03) before production release.
- **Data integrity verification**: scripted check post-migration/release that immutable-record counts never decrease and no orphaned FK-less polymorphic references (`approvals`, `activities`, `documents` target rows) exist.

## 16.7 Recommendation
Treat **Doc 16.1 + 16.2 (unit + integration on financial/transactional logic)** as a release gate, not optional — this directly operationalizes development rule §56.10 ("do not skip tests for financial or transactional logic"). CI should fail the build if coverage on `costing`, `order`, `approvals`, and `ta` service-layer packages drops below an agreed threshold (e.g., 80% line coverage on business-rule methods specifically, not a vanity whole-repo number).
