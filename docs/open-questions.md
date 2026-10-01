# Open Questions

## Blocking (must be answered before implementation of the affected area)
1. **ERP integration path** (ADR-11): what is the existing garments ERP's architecture — does it expose a REST API, what auth model, who owns buyer/factory/style master data today? Blocks: Phase 2 master-data design if integration is chosen before Phase 2 starts. *My recommendation if forced to decide now*: build RMGFlow fully independent for Phases 1-7 (none of which strictly require the ERP), revisit integration only once Phase 2+ data volume makes duplication actually painful — this avoids blocking early delivery on an unknown.
2. **Expected user count and data volume** (NFR-08): roughly how many staff will use this, how many active orders/season at peak? Blocks: final infra sizing decision (Doc 17.2) and confirms/refutes the "modular monolith" ADR-02 assumption. *My recommendation*: proceed with the modular monolith assumption (ADR-02) regardless — it is also the right choice at moderate scale, so this question is more about infra sizing than architecture.

## Important (should be answered before the affected module, not before starting at all)
3. **Mandatory export document list per destination/Incoterm** (FR-132): needs commercial/compliance team confirmation of current requirements. Blocks: Phase 10 document-type seed data accuracy, not Phase 10's build itself (schema is document-driven already).
4. **SMS/WhatsApp notification legality/cost/consent model** (FR-182): needs a decision on whether to pursue a WhatsApp Business API integration. Blocks: Phase 12 notification channel scope only — in-app/push ship regardless.
5. **Statutory document retention period** for commercial/export records (Doc 17.6 backup retention): may exceed the default 2-year assumption for legal/audit reasons in Bangladesh export trade. Blocks: final backup retention policy, not system build.
6. **Margin/cost visibility policy for Junior Merchandisers** (Doc 5.2 note): confirm the default-off assumption is correct for this organization's culture. Blocks: Phase 4 field-masking default, easily changed later via the existing per-user grant mechanism if wrong.

## Non-Blocking (can be decided later without rework)
7. Exact escalation thresholds (hours/days) for each notification rule (Doc 13) — defaults given, tunable via `notification_rules` data without code change.
8. Whether to add 2FA for login (Doc 15.10) — additive security enhancement, not architecturally blocking.
9. Whether factory-profitability reporting framing needs adjustment (Doc 14.7 "Factory Cost Analysis" rename) — cosmetic/reporting-label decision.
10. Multi-company activation timing (ADR-10) — schema already accommodates it; purely a future "when to build the UI" product decision.

## Per prompt §50 instruction
No further questions are being asked beyond this list — every other decision in this document set was made using a reasonable, documented, industry-standard assumption (Assumptions Register) rather than stalling on a question, per the prompt's own instruction not to ask dozens of unnecessary questions.
