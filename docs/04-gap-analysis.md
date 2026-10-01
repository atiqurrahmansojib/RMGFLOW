# Document 4 — Gap Analysis

Gaps between the prompt's literal ask and what a real system needs, identified from domain knowledge (Document 2) and requirement classification (Document 3).

## 4.1 Workflow Gaps (prompt's linear flow is incomplete)

| Gap | Why it matters | Resolution |
|---|---|---|
| No explicit **rework/rejection loop** modeling in the base flow | Sample and lab-dip rejection are the norm, not the exception; a flat status field loses history | Sample/approval modeled as append-only rounds (Doc 9, Doc 8) |
| No **order amendment** as first-class transaction | Buyers change qty/price/date constantly post-confirmation | `order_amendments` table, immutable order snapshot + amendment chain (Doc 8/9) |
| No **multi-factory / split order** modeling | One PO often fans out across factories/partial shipments | Order-to-factory and order-to-shipment are many-to-many over time (Doc 8) |
| No **claims/disputes** entity | Buyer short-shipment/quality claims occur post-shipment | Added `claims` entity referencing shipment/order (Doc 8, Doc 3 FR gap below) |
| No handling of **informal communication lag** | Real activity happens in WhatsApp/email before system entry | Activity log supports backdated entries (FR-151) |

## 4.2 Missing Entities Not in the Prompt's Initial List (§26)
- `claims` / `disputes` — buyer complaints post-shipment, referencing order/shipment, with resolution status.
- `partners` (generic supertype) — chosen approach: keep `factories` as a typed table with a `partner_type` enum rather than one generic polymorphic table (see ADR Doc 18) to avoid an overly generic, hard-to-query schema.
- `currencies`, `countries`, `incoterms`, `payment_terms` as reference/master tables rather than free-text (needed for FR-03, FR-70, reporting consistency).
- `t_and_a_templates` and `t_and_a_milestone_types` as separate configurable master data from the per-order `t_and_a_milestones` instances (prompt implies this in §13 but the initial entity list in §26 only has "T&A templates" and "T&A milestones" — clarified as 4 concepts: template, template milestone definition, instance, instance milestone).
- `exchange_rates` — needed because costing (FR-53) captures rate-at-time, not a live join to a current-rate table.
- `notification_rules` and `notification_log` — rules (config) vs. log (delivery tracking, Doc 15/§44 observability) are distinct; the initial entity list conflates them under "notifications."

## 4.3 Requirement Gaps the Prompt Didn't Ask For But the Domain Needs
- **Lost-business reason taxonomy** on inquiries (price/lead-time/capacity/quality/relationship) — needed for BD reporting (§47 "which buyers generated the most business" implies the inverse question too).
- **Factory buyer-approval status** (a factory can be approved by Buyer A but not Buyer B) — the prompt mentions "buyer approvals" for factories (§6) but doesn't connect it to order creation validation; added as a hard business rule (Doc 9).
- **Season/collection as master data**, not free text, for consistent style/order filtering and reporting.
- **Document expiry alerting** tied to factory certifications (compliance audits expire) in addition to shipment documents (§23 mentions "document expiry" generically; scoped explicitly to both).

## 4.4 Contradictions / Tensions Identified in the Prompt
1. **§25 (offline-first) vs. §5/§29 (data integrity, server-authoritative)**: resolved by strict online/offline boundary — financial and approval-finalizing actions are always online-only (Doc "Offline-First", folded into Doc 12).
2. **§37 (avoid over-engineering multi-company) vs. §26 (design schema to not block expansion)**: resolved by adding a nullable/defaulted `organization_id` scoping column now without building multi-org UI/workflow (ADR Doc 18).
3. **§38 (ERP integration) vs. §56 rule 7 (no duplicate entities)**: if integration is chosen, buyer/factory/style masters must be shared or synced, not duplicated — addressed by recommending REST integration boundary with shared master-data ownership rules (ADR Doc 18), not a merged backend, given no detail on the existing ERP's architecture (classified **E**, owner confirmation required).
4. **§36 ("do not hardcode business rules") vs. the need for backend-authoritative calculation integrity (§10, §29)**: resolved by making *configuration data* (milestone templates, document requirements, notification rules) data-driven, while *calculation logic and invariants* (margin formula, approval state machine) remain backend code — configurability applies to data, not to the integrity rules themselves.

## 4.5 Weak Areas Requiring Owner Input Before Build (summary; full list in Open Questions doc)
- Exact mandatory export-document list per destination/Incoterm (legal, time-sensitive, varies by country — should not be hardcoded by an AI without current legal verification).
- SMS/WhatsApp notification channel legality/cost.
- Existing ERP's integration surface (REST availability, auth model, data ownership) — unknown without owner input.
- Expected user count/data volume for infra sizing.
