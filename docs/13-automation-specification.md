# Document 13 — Automation Specification

Format per prompt §45: **Trigger → Logic → Action → Recipient → Audit**.

| # | Automation | Trigger | Logic | Action | Recipient | Audit |
|---|---|---|---|---|---|---|
| A1 | T&A milestone upcoming | Scheduled job (hourly) | `planned_date - today <= 3 days (configurable)` and `actual_date IS NULL` | In-app + push notification | Responsible user (`ta_milestones.responsible_user_id`) | `notifications` row |
| A2 | T&A milestone overdue | Scheduled job | `planned_date < today AND actual_date IS NULL` | Status set to OVERDUE (derived); notification | Responsible user + assigned merchandiser | `notifications` row |
| A3 | T&A critical delay | Scheduled job | Overdue by > threshold OR cascades to block ex-factory date | Notification escalated to GM | Merchandiser + GM | `notifications` row, escalation flag |
| A4 | T&A dependency blocked | On milestone status recompute | Upstream `depends_on_milestone_id.actual_date IS NULL` and own planned date reached | Status set BLOCKED; notification | Responsible user | `notifications` row |
| A5 | Sample deadline reminder | Scheduled job | `required_date - today <= 2 days` and no `submitted_date` | Notification | Sampling coordinator | `notifications` row |
| A6 | Sample overdue | Scheduled job | `required_date < today` and no `submitted_date` | Notification, surfaced on dashboard | Sampling coordinator + merchandiser | `notifications` row |
| A7 | Buyer approval pending too long | Scheduled job | `approvals.status='PENDING'` and `submitted_at` older than buyer-specific SLA (default 5 days) | Escalation notification | Merchandiser + GM | `notifications` row |
| A8 | Production behind plan | Daily job after production_update cutoff | Cumulative actual < planned-to-date by threshold % | Notification | Production follow-up officer + merchandiser | `notifications` row |
| A9 | Quality failure | On `inspections.result='FAIL'` save | Immediate (not batched) | Notification + shipment-block flag set | Quality lead + merchandiser + GM | `notifications` row, `audit_logs` entry on block |
| A10 | Shipment deadline approaching | Scheduled job | `etd - today <= 3 days` and order not ready (9.8 gate) | Notification | Commercial executive + merchandiser | `notifications` row |
| A11 | Payment overdue | Daily job | `receivables.due_date < today AND status != RECEIVED` | Notification | Accounts + GM | `notifications` row |
| A12 | Document expiry | Daily job | `documents.expiry_date - today <= 30 days` | Notification | Document owner + commercial | `notifications` row |
| A13 | Task overdue | Daily job | `tasks.due_date < today AND status NOT IN (DONE,CANCELLED)` | Notification; escalate to assigner after +2 days | Assignee, then assigner | `notifications` row |
| A14 | Critical order delay (rollup) | Scheduled job | Any CRITICAL_DELAY milestone on an order | Order flagged "at risk" on dashboards | GM, Owner | Dashboard read-model, no separate write beyond A3 |
| A15 | T&A auto-generation | On order confirmation | Resolve template (style > buyer > default), instantiate milestones with computed planned dates | `ta_milestones` rows created | System; visible to merchandiser | `audit_logs` entry (order→T&A link) |
| A16 | Downstream T&A re-plan cascade | On milestone `actual_date` saved later than `planned_date` | Shift dependent milestones' `revised_date` forward by the delay delta, respecting their own dependency chain | Update `revised_date` on affected milestones; notify responsible users of each shifted milestone | Each affected responsible user | `audit_logs` entry per shifted milestone (old/new revised_date) |
| A17 | Production/packing progress rollup | On production_update save | Recompute cumulative sums, order progress % | Update derived fields (not stored running totals, computed on read + cached) | Visible to merchandiser/GM dashboards | None needed (derived, not a discrete event) |
| A18 | Escalation generic rule | Any notification unacknowledged past `notification_rules.escalation_after_hours` | Re-check `is_read` | Re-notify + CC next role up (configurable per rule) | Escalation target per rule config | `notifications` row (escalated=true) |

## 13.1 Design Notes
- All scheduled jobs run server-side (Spring `@Scheduled` or a lightweight job scheduler like `Quartz` if clustering is needed later) — never client-triggered, so detection doesn't depend on the app being open.
- **Recommendation**: implement A16 (T&A cascade) carefully as a bounded recursive shift with a hard depth/iteration cap and full audit trail — this is the automation with the highest business value (Document 10.3 recommendation) but also the highest risk of surprising users if it silently re-plans dates; always notify every affected responsible person, never a silent background shift.
- Notification fan-out respects `notification_rules.channel` and user preference (Doc 7 screen 89) — do not spam every channel for every event; default new events to IN_APP only, let users opt into PUSH per category.
- SMS/WhatsApp intentionally excluded from this table (classified **E** in Doc 3) pending legal/cost confirmation.
