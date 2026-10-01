# Document 14 — Reporting & KPI Specification

Every metric below states: **Formula · Source · Period · Filters · Permission**.

## 14.1 Buyer Reports
- **Buyer Order Summary** — Formula: count/sum of `orders` grouped by buyer. Source: `orders`. Period: selectable date range. Filters: status, season. Permission: Merchandiser (own buyers), GM/Owner (all).
- **Buyer Performance** — On-time delivery % = `COUNT(orders WHERE actual_ship_date <= delivery_date) / COUNT(all closed orders)`. Source: `orders`, `shipments`. Period: trailing 12 months default. Permission: GM/Owner/Merchandiser (own).
- **Buyer Business History** — chronological list of orders/value/status. Source: `orders`. Permission: as above.

## 14.2 Merchandising Reports
- **Inquiry Pipeline** — count/value of inquiries by status (OPEN/QUOTED/WON/LOST/HOLD). Source: `inquiries`. Filters: merchandiser, buyer, season. Permission: Merchandiser (own), GM/Owner (all).
- **Sample Status** — count of samples by current_status and overdue flag. Source: `samples`, `sample_revisions`. Permission: Sampling, Merchandiser, GM.
- **Approval Status** — pending approvals aged by days-pending, grouped by target_type. Source: `approvals`. Permission: role-scoped to approval target type.
- **T&A Status** — milestones by status (UPCOMING/OVERDUE/CRITICAL_DELAY/BLOCKED) per order. Source: `ta_milestones`. Permission: scoped per assignment.
- **Merchandiser Workload** — open inquiries + active orders + pending tasks per merchandiser. Source: `inquiries`, `orders`, `tasks` joined on `assigned_to`/`merchandiser_id`. Permission: GM/Owner (team view), self (own).

## 14.3 Order Reports
- **Order Book** — all active orders with value, status, delivery date. Source: `orders`. Permission: scoped.
- **Order Value** — `SUM(order_items.quantity * order_items.unit_price)` by period/buyer/factory. Source: `order_items`. Permission: GM/Owner full, Merchandiser own-buyer (no margin).
- **Order Status** — distribution by status. Source: `orders`.
- **Order Amendments** — count/type of amendments per order/period, flags high-amendment-count orders (possible instability). Source: `order_amendments`.
- **Order Profitability** — `order_financials.operational_margin_percent`, flagged below-threshold. Source: `order_financials`. Permission: GM/Owner/Accounts only (financial-sensitive).

## 14.4 Production Reports
- **Planned vs Actual** — cumulative actual (Doc 9.6) vs. T&A-implied planned curve per order. Source: `production_updates`, `ta_milestones`. Permission: Production follow-up (own factory), Merchandiser, GM.
- **Factory Performance** — on-time milestone completion % per factory across orders. Source: `ta_milestones` joined `orders.factory via order_items`. Permission: GM/Owner, Factory Coordinator (own factory only).
- **Delayed Orders** — orders with any CRITICAL_DELAY milestone. Source: `ta_milestones`.
- **Production Progress** — % complete per order (Doc 9.5 weighted formula). Source: derived.

## 14.5 Quality Reports
- **Inspection Results** — pass/fail rate by period/factory/buyer. Source: `inspections`.
- **Defect Analysis** — defect count by `defect_types.category`/severity, trend over time. Source: `defects`.
- **Factory Quality Performance** — fail rate and CAPA closure time per factory. Source: `inspections`, `capa_records`. Permission: Quality, GM/Owner, Factory Coordinator (own).

## 14.6 Shipment Reports
- **Shipment Status** — distribution by status (BOOKED/IN_TRANSIT/DELIVERED/DELAYED). Source: `shipments`.
- **Pending Shipments** — orders ready-to-ship or approaching ETD without a shipment record. Source: `orders`, `shipments`, `ta_milestones`.
- **Delayed Shipments** — `etd` passed without `status` progressing. Source: `shipments`.

## 14.7 Financial Reports
- **Order Profitability** — see 14.3. 
- **Buyer Profitability** — aggregate `order_financials` by buyer over period. Permission: GM/Owner/Accounts only.
- **Factory Profitability** — meaningful only where buying house also earns margin on factory-side services (e.g., mark-up on sourced trims); otherwise this is cost tracking, not profitability — **Recommendation**: label this report "Factory Cost Analysis" rather than "Factory Profitability" to avoid implying a margin that may not exist for pure pass-through factory CM.
- **Receivables/Payables** — aging buckets (current/30/60/90+) from `receivables`/`payables`. Permission: Accounts, GM/Owner.
- **Payment Status** — received vs. due by buyer/order. Source: `payment_records`, `receivables`.

## 14.8 Dashboards (role-scoped composition of the above KPIs, per prompt §22)

**Management Dashboard**: active buyers, active styles, open/won/lost inquiries, order count/value, pending samples, pending approvals, production status rollup, shipment status rollup, delayed orders (14.4), critical T&A delays, quality issue count, buyer/factory performance highlights, order profitability summary, outstanding payments summary.

**Merchandiser Dashboard**: my orders, my samples, my pending approvals, my T&A deadlines (next 7 days + overdue), my overdue tasks, buyer follow-ups due.

**Factory Follow-up Dashboard**: production progress for assigned factory's orders, delayed milestones, pending approvals affecting those orders, open quality issues for that factory.

**Quality Dashboard**: pending inspections, recent fail rate trend, open CAPA records, defect category breakdown.

## 14.9 Business Questions → Data Mapping (prompt §47)
| Question | Data/Formula |
|---|---|
| Which orders are at risk? | Orders with CRITICAL_DELAY milestone OR failed FINAL inspection unresolved OR amendment count above threshold |
| Which T&A milestones are overdue? | `ta_milestones WHERE status IN (OVERDUE, CRITICAL_DELAY)` |
| Which samples are waiting for buyer approval? | `approvals WHERE target_type=SAMPLE_REVISION AND status=PENDING` |
| Which factories are behind schedule? | Factory performance report (14.4), filtered to below-threshold on-time % |
| Which buyers generated the most business? | Buyer Order Summary (14.1) sorted by value |
| Which orders are most/least profitable? | Order Profitability (14.3/14.7) sorted asc/desc |
| Which styles have repeated sample rejection? | `COUNT(sample_revisions) GROUP BY style_id HAVING count > threshold` |
| Which factories have repeated quality issues? | Factory Quality Performance (14.5) |
| Which shipments are at risk? | Shipments with `etd` approaching and order not ready, or `status=DELAYED` |
| Which payments are overdue? | Receivables/Payables aging (14.7) |
| What is each merchandiser currently handling? | Merchandiser Workload (14.2) |
| What needs attention today? | Union of: milestones due today/overdue (assigned), pending approvals (assigned), overdue tasks (assigned) — this is the single query behind the "My Day" view recommended below |

**Recommendation**: build a single cross-module "What needs attention today" endpoint/widget (union query above) as the landing screen after login for every operational role — directly answers the prompt's explicit framing in §47 and §60 ("how would a real buying house operate this every day"), rather than leaving users to check five separate screens each morning.
