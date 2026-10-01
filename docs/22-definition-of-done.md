# Document 22 — Definition of Done

A feature/task (Document 21 granularity) is **not** complete until every applicable item below is true. Not every item applies to every task (e.g., a reference-data CRUD task has no T&A/financial business rules) — apply judgment, but do not skip an applicable item silently.

## Per-Task Checklist
- [ ] Database schema implemented with constraints matching Document 8 (PK/FK/unique/check, correct types, indexes)
- [ ] Backend service implemented with business rules from Document 9 applied (not just CRUD)
- [ ] Validation implemented (Bean Validation + business-rule validation, Doc 11.3)
- [ ] Authorization implemented and tested (role permission + object-level scope + **tenant/organization scope**, Doc 5/11.3/18 ADR-10) — every `findById`-style lookup goes through an organization-scoped query, not a bare id lookup; not deferred "for later"
- [ ] Audit requirements implemented where the action is in the mandatory list (Doc 15.8)
- [ ] API implemented per Document 11 standards (pagination, filtering, error shape, idempotency where applicable, OpenAPI annotated)
- [ ] Flutter UI implemented per the relevant screen(s) in Document 7
- [ ] Loading state implemented (shared widget, Doc 12.7)
- [ ] Empty state implemented (shared widget)
- [ ] Error handling implemented (shared Failure mapping, no raw exceptions surfaced to the user)
- [ ] Unit tests implemented for all business-rule/calculation logic touched (Doc 16.1)
- [ ] Integration tests implemented for any cross-table/cross-module transaction (Doc 16.2)
- [ ] API tests implemented for authorization/validation/error paths (Doc 16.3)
- [ ] E2E scenario updated/passing if the task is part of one of Document 16.5's scenarios
- [ ] Security reviewed: no new unauthenticated endpoint, no new client-trusted authorization decision, no secret/PII in logs
- [ ] Data integrity verified: immutability/versioning rules (if applicable) actually enforced at the DB level, not only in application code
- [ ] Documentation updated: Document 8/9/11 updated if the implementation diverged from what was specified here, so docs stay synchronized with reality (prompt §56 rule 15)

## Release-Level (Phase) Definition of Done
A phase (Document 20) is done only when, in addition to every task above being individually done:
- [ ] All E2E scenarios (Doc 16.5) that depend on this phase's modules pass in staging
- [ ] Performance smoke test run against representative data volume (Doc 16.6/NFR-03)
- [ ] Security checklist (Doc 15) re-run for anything touching auth/files/financial data in this phase
- [ ] Backup/restore unaffected (schema migration doesn't break the existing restore drill procedure)
- [ ] Staged Android rollout plan ready if this phase ships a mobile-visible feature (Doc 17.7)

## Explicit Non-Negotiables (from prompt §55 and development rules §56)
- A feature is NOT done merely because "the screen works."
- No demo data disguised as production functionality.
- No business transaction hardcoded in place of real data-driven logic.
- No duplicated business logic between Flutter and backend (Flutter validation is UX-only, backend is authoritative, Doc 12.7/11.3).
- No client-side-only authoritative financial calculation.
- No silent overwrite of historical records.
- No authorization bypass, even temporarily, even in a demo branch.
- No incomplete functionality marked complete in task tracking.
- No skipped tests for financial or transactional logic (Doc 16.1/16.2 are gates, not suggestions, per Doc 16.7).
