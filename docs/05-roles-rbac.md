# Document 5 — User Roles & RBAC

RBAC enforced **server-side only** (NFR-01, FR-220). Flutter UI hides controls as a UX convenience; it is never the authorization boundary.

## 5.1 Finalized Role List

Investigated from the prompt's candidate list (§4); **Marketing/BD** merged into Merchandiser-family with a BD flag rather than a separate role (its permission needs are a subset of Senior Merchandiser); **Management/Viewer** kept as a distinct read-only role since its needs are strictly narrower than GM.

| Role | Rationale |
|---|---|
| Super Admin | System configuration, user/role management, no business-transaction involvement |
| Owner / Managing Director | Full visibility, approval override authority, no direct data entry expected |
| General Manager | Cross-buyer/cross-factory operational oversight, approval authority |
| Senior Merchandiser | Owns buyer relationships, costing/quotation approval initiation, order management |
| Junior Merchandiser | Executes under senior merchandiser; limited approval/financial rights |
| Sampling Coordinator | Manages sample lifecycle across styles/orders |
| Production Follow-up Officer | Factory-based daily production entry, T&A updates for production milestones |
| Quality Inspector | Inspection records, defect entry, CAPA tracking |
| Commercial Executive | Shipment and document management |
| Accounts / Finance | Payment/receivable/payable tracking, operational profitability views |
| Factory Coordinator | Liaison for one or more factories; limited to assigned factory's orders |
| Management Viewer | Read-only dashboards/reports, no transactional access |

## 5.2 Permission Matrix (summary; full matrix enforced via permission table in DB, Doc 8)

| Capability | Super Admin | Owner/MD | GM | Sr. Merch | Jr. Merch | Sampling | Prod. Follow-up | Quality | Commercial | Accounts | Factory Coord. | Mgmt Viewer |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| User/role management | Full | — | — | — | — | — | — | — | — | — | — | — |
| Create/edit buyers | — | View | Full | Full | Create/Edit own | — | — | — | — | View | — | View |
| Create/edit factories | — | View | Full | Create | View | — | — | — | — | View | View own | View |
| Inquiry create/edit | — | View | Full | Full | Full | — | — | — | — | — | — | View |
| Costing create | — | View | Full | Full | Create (needs approval) | — | — | — | — | View | — | View |
| Costing approve | — | Full | Full | Approve own team's | — | — | — | — | — | — | — | — |
| Quotation create/send | — | View | Full | Full | Create (needs approval) | — | — | — | — | View | — | View |
| Order confirm | — | View | Full | Full | — | — | — | — | — | View | — | View |
| Order amend/cancel | — | Approve | Full | Request | — | — | — | — | — | — | — | View |
| Sample request/record | — | — | View | Full | Full | Full | — | — | — | — | View own | View |
| Sample approval recording (buyer response) | — | — | View | Full | Edit | Full | — | — | — | — | — | View |
| T&A template config | — | — | Full | Edit | — | — | — | — | — | — | — | — |
| T&A milestone update | — | — | View | Edit | Edit | Edit (sample-related) | Edit (production-related) | Edit (QC-related) | Edit (shipment-related) | — | Edit own factory | View |
| Production daily update | — | — | View | View | View | — | Full | — | — | — | Full own factory | View |
| Quality inspection entry | — | — | View | View | View | — | View | Full | — | — | View own factory | View |
| Approval engine (submit) | — | — | Full | Full | Full | Full (sample) | Full (production gates) | Full (QC gates) | Full (shipment/doc) | — | — | — |
| Approval engine (finalize/override) | — | Full | Full | — | — | — | — | — | — | — | — | — |
| Shipment create/manage | — | View | View | View | — | — | — | — | Full | View | — | View |
| Document upload/manage | — | View | View | View | — | Edit (sample docs) | Edit (production photos) | Edit (QC reports) | Full | View | Edit own factory docs | View |
| Payment/financial record | — | View | View | View summary | — | — | — | — | View | Full | — | View (if granted) |
| Financial figures (cost, margin) visibility | — | Full | Full | Own buyers | Own buyers (no margin) | — | — | — | — | Full | — | Per Owner grant |
| Reports/dashboards | Full | Full | Full | Scoped (own buyers) | Scoped | Scoped | Scoped (own factory) | Scoped | Scoped | Full financial | Scoped (own factory) | Full read |
| Audit log access | Full | Full | View | — | — | — | — | — | — | — | — | — |

Notes:
- "Scoped" means object-level authorization: a merchandiser's default visibility is buyers/orders assigned to them; GM/Owner can see all. Enforced via an `assignment` relation (user ↔ buyer, user ↔ factory), not row-level hacks in the client.
- Junior Merchandiser margin visibility is **off by default** (margin is sensitive) — a GM/Owner-level setting can grant it per user; this is a **C** recommendation, not hardcoded.
- Delete/cancel rights are intentionally narrow: Senior Merchandiser can *request* amendment/cancellation; Owner/GM *approves* it — mirrors real buying-house authority (junior/senior staff don't unilaterally cancel confirmed orders).

## 5.3 RBAC Enforcement Model
- Roles map to a fixed set of **permissions** (e.g., `ORDER_CREATE`, `ORDER_AMEND_APPROVE`, `COSTING_VIEW_MARGIN`) stored in a `permissions` table, assigned to roles via `role_permissions` (Doc 8).
- **Object-level checks** layer on top via an `assignments` table (user-to-buyer, user-to-factory) — a Junior Merchandiser with `ORDER_CREATE` can only create orders for buyers they're assigned to.
- Every API endpoint resolves: (1) does the authenticated user's role have the permission, (2) does the object-level assignment allow access to this specific buyer/factory/order. Both checks happen server-side in the service layer (Doc 11, Doc 15) — never trusted from client-supplied role claims alone beyond JWT identity.
- Financial field-level masking (e.g., hiding cost/margin from Junior Merchandiser) is enforced in the DTO-mapping layer server-side, not by the client choosing not to display a field.
