# Document 9 — Business Rules

All rules below are backend-enforced (service layer + DB constraints/triggers where noted). Flutter may pre-validate for UX but is never trusted (NFR-01).

## 9.1 Costing & Margin
- **Total cost** = Σ `costing_items.total_cost` where `total_cost = unit_cost * consumption * (1 + wastage_percent/100)`.
- **Margin %** = `(target_price - total_cost) / target_price * 100`, computed backend-side on save, stored denormalized for fast reporting, recomputed on every costing_item change pre-approval.
- Once `costings.status = 'APPROVED'`, no UPDATE to `costing_items` or price fields is permitted; a new version (`version_no + 1`) must be created referencing the prior as `superseded_from`. Enforced by a BEFORE UPDATE trigger raising an exception if `OLD.status = 'APPROVED'` and a financial column changed.
- **Recommendation:** default margin floor (e.g., warn below configurable X%) as a soft validation, not a hard block — real negotiations sometimes accept thin or negative margin on strategic orders; a hard block would fight the business rather than help it.

## 9.2 Quotation
- A quotation must reference exactly one `costings` row with `status = 'APPROVED'`; creating a quotation against a DRAFT costing is blocked server-side.
- An `APPROVED` quotation is immutable; buyer counter-offers create a new `version_no` with `supersedes_quotation_id` set.
- Quotation `validity_date` expiry is computed at read-time (not a stored status flip) to avoid stale-data mismatches; a scheduled job may batch-update `status = 'EXPIRED'` nightly for reporting convenience only.

## 9.3 Sampling
- A sample revision cannot have its `approvals` row's `status` updated after `decided_at` is set — rejection → new revision → new approval round. Enforced by trigger disallowing UPDATE on `approvals` where `decided_at IS NOT NULL`.
- Sample `required_date` in the past with no `submitted_date` auto-flags as overdue (computed, not stored).

## 9.4 Order Creation & Amendment
- **Factory-buyer approval check**: an order cannot be created with a `factory_id` lacking an `APPROVED` row in `factory_buyer_approvals` for that `buyer_id`, unless an authorized override (GM/Owner permission) is explicitly recorded with reason — this is a real buying-house compliance gate, not a courtesy check.
- Order amendments (qty, price, date, destination) never UPDATE the order row directly in application code; the service method writes an `order_amendments` row and only then updates the denormalized current value, inside one transaction — ensures no amendment is ever lost even if only the "current" field is later queried.
- Order quantity reduction below already-shipped quantity is blocked.
- Order cancellation requires GM/Owner approval (per RBAC Doc 5) and is blocked if any shipment exists with `status != 'BOOKED'`-reversible state — i.e., cannot cancel an order already substantially shipped; must use claims/returns process instead.
- **Recommendation:** treat "order merge" (FR-74) as effectively unsupported in v1 — real commercial history rarely benefits from merging, and the integrity risk (two orders' amendment/shipment histories tangled) outweighs the convenience. Expose "link related orders" (informational) instead of true merge.

## 9.5 T&A
- Milestone `status` is derived, not set by users: `OVERDUE` if `COALESCE(revised_date, planned_date) < today AND actual_date IS NULL`; `CRITICAL_DELAY` if overdue by more than a configurable threshold (default 3 days) or if a downstream milestone's planned date is now unachievable given the delay; `BLOCKED` if `depends_on_milestone_id`'s `actual_date IS NULL` and its own planned date has arrived.
- Changing a milestone's `planned_date` after order confirmation requires a `revised_date` field (append, not overwrite) with a mandatory `delay_reason` once a revision pushes past the original by more than 0 days.
- Order-level progress % = weighted average of completed milestone sequence vs. total, weight configurable per milestone type (default: equal weight) — **Recommendation**: weight shipment-blocking milestones (fabric in-house, PP sample approval, final inspection) higher than administrative ones, since "50% of milestones done" is meaningless if the two undone ones are both shipment-critical.

## 9.6 Production
- Cumulative cutting/sewing/finishing/packing quantities are computed as a running SUM over `production_updates` for the order — never manually entered as a running total (prevents the classic "forgot to update the cumulative field" bug).
- Any daily quantity that would push a cumulative total above `order_items` total ordered quantity is flagged (warning, not hard block — real production sometimes legitimately runs slightly over to cover rejections) **unless** it's the `packing_qty` cumulative exceeding order quantity, which IS hard-blocked (packed/shippable quantity must not exceed the order).

## 9.7 Quality
- `result = 'FAIL'` on a `FINAL` inspection blocks shipment creation for the corresponding order/quantity until a `REINSPECT` with `result = 'PASS'` exists, or an explicit management override with reason is recorded (mirrors real-world buyer-driven exceptions, e.g., accepted with concession).
- A `capa_records` row must exist and be `CLOSED` before a `FAIL` defect's related order milestone can be marked complete, where the defect was linked to a T&A-gating inspection — **Recommendation**: only enforce this hard-stop for `FINAL` inspections, keep it a soft reminder for `INLINE`/`MIDLINE` to avoid over-blocking early-stage work.

## 9.8 Shipment
- `SUM(shipments.quantity_shipped) FOR order_id` must not exceed `SUM(order_items.quantity)` unless `is_partial` logic is actually about *less* than full (partial under, not over) — an attempt to ship *more* than ordered is **hard-blocked**, no override, since it indicates a data error or unauthorized overproduction being shipped.
- A shipment with `is_partial = true` requires `authorized_by` populated with a user holding `SHIPMENT_PARTIAL_AUTHORIZE` permission (FR-121) — enforced server-side, not just a UI checkbox.
- Shipment cannot be created if the linked order's final inspection (9.7) has not passed, unless override recorded.

## 9.9 Documents
- A document with `expiry_date` in the past is surfaced on dashboards and blocks any workflow step that explicitly requires it as a *mandatory* gate for that buyer/order (e.g., an expired certificate of origin blocks marking a shipment `DELIVERED`-ready for commercial submission) — but does not block unrelated system use.
- New document upload for an `(entity_type, entity_id, document_type_id)` combination always increments `version_no`; it never overwrites a prior version's file (FR-130).

## 9.10 Financial
- `order_financials.operational_margin_percent` is a generated/computed column: `(realized_unit_price - actual_cost_unit) / realized_unit_price * 100`, falls back to quoted price if realized price not yet recorded (pre-shipment estimate vs. post-shipment actual, clearly flagged as which in the UI).
- Receivable `status = 'OVERDUE'` computed when `due_date < today AND received_amount < amount` — never manually set.

## 9.11 Cross-Cutting Invariants (from prompt §27, with additions)
1. Approved quotation cannot silently change. *(9.2)*
2. Historical costing cannot change without revision. *(9.1)*
3. Approved sample cannot be edited as the same version; rejection creates a new revision. *(9.3)*
4. Order amendments must preserve history. *(9.4)*
5. Shipment quantity cannot exceed available order quantity unless explicitly authorized (and never exceed total order quantity at all, even with authorization — authorization covers *partial*, not *over-shipment*). *(9.8)*
6. Production cannot exceed valid order quantity without a defined business rule (soft-flag mid-stream, hard-block at packing). *(9.6)*
7. Approval history must be immutable. *(DB trigger, 9.3/8.4)*
8. Audit history must be tamper-resistant (append-only grants, no UPDATE/DELETE role privilege on `audit_logs`). *(8.9)*
9. Deleted master data must not destroy historical transactions (soft delete policy, 8.11).
10. **(Added)** A factory not approved by a buyer cannot be assigned to that buyer's order without explicit override. *(9.4)*
11. **(Added)** A failed final inspection blocks shipment without explicit override. *(9.7/9.8)*
12. **(Added)** Cumulative production/packing figures are always derived, never directly editable as a running total. *(9.6)*
