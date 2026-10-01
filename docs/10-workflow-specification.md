# Document 10 — Workflow Specification (End-to-End)

Detailed state transitions for the core cross-module flows. Status enums reference Document 8.

## 10.1 Inquiry → Quotation
```
OPEN --(factory candidates identified, costing started)--> OPEN
OPEN --(costing approved, quotation sent)--> QUOTED
QUOTED --(buyer confirms PO)--> WON  [triggers Order creation]
QUOTED --(buyer declines / silence past follow-up window)--> LOST  [requires lost_reason]
OPEN/QUOTED --(paused)--> HOLD --(resume)--> OPEN/QUOTED
```
**Recommendation**: auto-suggest (not auto-set) HOLD after N days (configurable, default 21) of no activity on an OPEN inquiry, surfaced as a task/notification to the merchandiser rather than a silent status change — keeps a human in the loop on business-sensitive status.

## 10.2 Costing → Quotation → Order
```
Costing[DRAFT] --(edit cost items)--> Costing[DRAFT]
Costing[DRAFT] --(submit for approval)--> Approval round created (target_type=COSTING)
Approval[APPROVED] --(system)--> Costing[APPROVED]  (immutable from here)
Costing[APPROVED] --(create quotation)--> Quotation[DRAFT]
Quotation[DRAFT] --(send to buyer)--> Quotation[SENT]
Quotation[SENT] --(buyer negotiates)--> Quotation[NEGOTIATING] --(revise)--> new Quotation version[DRAFT]
Quotation[SENT/NEGOTIATING] --(buyer accepts)--> Quotation[APPROVED]  (immutable)
Quotation[APPROVED] --(buyer issues PO)--> Order[CONFIRMED]
```

## 10.3 Order → T&A
```
Order[CONFIRMED] --(system, on confirmation)--> T&A template resolved (style-specific > buyer-specific > org default)
  --> ta_milestones generated with planned_date = ex_factory_date - offset_days_from_exfactory (per template)
Each ta_milestone[PENDING] --(approaches planned_date)--> [UPCOMING] --(date passes w/o actual_date)--> [OVERDUE]
  --(configurable threshold exceeded)--> [CRITICAL_DELAY]
ta_milestone --(actual_date recorded)--> [DONE]
```
**Recommendation**: regenerate downstream *planned* dates (not actual/locked ones) automatically when an upstream milestone's `actual_date` lands later than planned, cascading the delay forward through dependencies — this is the single highest-value automation in the whole system (T&A is the operational nerve center per Document 2 §2.2 step 7) and should not be left as a manual re-plan exercise.

## 10.4 Order → Production
```
Order[CONFIRMED] --(cutting starts, first production_update)--> Order[IN_PROGRESS]
production_updates accumulate daily --> cumulative cutting/sewing/finishing/packing computed
Order[IN_PROGRESS] --(packing cumulative reaches order qty AND final inspection PASS)--> ready for shipment
```

## 10.5 Sample → Approval
```
Sample requested --> sample_revisions[1] created, approvals round 1 (SUBMITTED)
Approval round --(buyer reviews)--> PENDING --(decision)--> APPROVED | REJECTED | RETURNED
REJECTED/RETURNED --(merchandiser/factory revises)--> sample_revisions[2] created, approvals round 2 (SUBMITTED)
... repeats until APPROVED or sample abandoned (status set on `samples.current_status`, revisions preserved)
```

## 10.6 Quality → Corrective Action
```
Inspection created --(result=FAIL)--> defects recorded --> capa_records[OPEN] created
capa_records[OPEN] --(factory responds)--> [IN_PROGRESS] --(verified fixed)--> [CLOSED]
If inspection_type=FINAL and result=FAIL and no override --> Shipment creation blocked for this order
Re-inspection --(result=PASS)--> shipment unblocked
```

## 10.7 Production → Shipment
```
Order ready (9.8 conditions met) --> Shipment[BOOKED] created, quantity_shipped <= remaining order qty
Shipment[BOOKED] --(ETD passes)--> [IN_TRANSIT] --(ETA / POD confirmed)--> [DELIVERED]
If quantity_shipped < order remaining qty --> is_partial=true, requires authorization (9.8)
  --> order remains [PARTIALLY_SHIPPED] until cumulative shipped = order qty --> [SHIPPED] --> [CLOSED] 
      (CLOSED triggered after commercial docs finalized + payment reconciliation, not shipment alone)
```

## 10.8 Shipment → Claim (post-shipment exception path, gap-filled per Doc 4)
```
Shipment[DELIVERED] --(buyer reports issue)--> claims[OPEN] created, referencing shipment_id/order_id
claims[OPEN] --(investigation)--> [UNDER_REVIEW] --(outcome)--> [RESOLVED] | [REJECTED]
Resolution does NOT alter original shipment/order commercial records — claims are a separate append-only trail,
consistent with NFR-05 (immutability of historical commercial records).
```

## 10.9 Cross-Module Approval Gate Summary
| Gate | Blocks | Unblocked by |
|---|---|---|
| Costing approval | Quotation creation | `approvals` APPROVED for COSTING target |
| Quotation approval | Order creation (if order sourced from quotation) | `approvals` APPROVED for QUOTATION target |
| Factory-buyer approval | Order creation with that factory | `factory_buyer_approvals.status = APPROVED` or GM override |
| Final inspection pass | Shipment creation | `inspections.result = PASS` (FINAL) or GM override |
| Partial-shipment authorization | Shipment with `is_partial=true` | User with `SHIPMENT_PARTIAL_AUTHORIZE` permission |
| Order cancellation approval | Order status → CANCELLED | GM/Owner `approvals` APPROVED |
