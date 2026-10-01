# Document 3 — Complete Requirements Specification

Classification key (mandatory, per prompt §48): **A** Confirmed · **B** Strongly implied · **C** Recommended · **D** Future enhancement · **E** Requires owner confirmation.

## 3.1 Functional Requirements

### Buyer Management
- FR-01 (A) Maintain buyer master with code, group, contacts, currency, Incoterms, payment terms, compliance/quality requirements, active/inactive status.
- FR-02 (A) Support multiple contacts per buyer with department/role.
- FR-03 (B) Buyer-specific T&A templates, approval rules, document requirements, lead times.
- FR-04 (B) Buyer activity/communication timeline.
- FR-05 (C) Buyer performance history (on-time %, order value, sample approval rate) computed from transactional data, not manually entered.

### Factory / Vendor Management
- FR-10 (A) Factory/vendor master distinguishing type (garment factory, fabric supplier, trim supplier, washing, printing, embroidery, testing lab, inspection agency, freight forwarder).
- FR-11 (A) Factory capability (product categories, capacity), compliance/certification, buyer-approval status per buyer.
- FR-12 (B) Factory rating/history derived from production and quality transactional data.
- FR-13 (C) Factory bank/payment info only where the buying house handles factory payment.

### Inquiry
- FR-20 (A) Inquiry record: buyer, style/product reference, season, target qty/price, delivery requirement, status (open/won/lost/hold), lost reason.
- FR-21 (B) Link inquiry to one or more factory candidates for sourcing/feasibility.
- FR-22 (B) Inquiry → costing → quotation traceability.
- FR-23 (C) Follow-up/reminder scheduling on open inquiries.

### Style / Product Development
- FR-30 (A) Style master with buyer style number, category, season, spec fields (fabric, composition, GSM, color, size range), tech pack and reference image attachments.
- FR-31 (A) Style revisions preserved as immutable version history; never destructive overwrite.
- FR-32 (C) Style-level approval status distinct from sample approval status.

### Sample Management
- FR-40 (A) Sample types: development, proto, fit, size set, PP, TOP, shipment sample, plus buyer-specific types (configurable, not hardcoded).
- FR-41 (A) Sample request/response cycle with dates (request, required, submitted, approved/rejected) and revision chaining.
- FR-42 (A) Rejected sample creates a new revision; does not mutate into "approved." Approval history is append-only.
- FR-43 (B) Photo/document attachments per sample revision.

### Costing
- FR-50 (A) Costing built from itemized components (fabric, trims, CM, wash/print/embroidery, testing, inspection, packaging, freight, commission, bank charges, wastage, overhead, margin).
- FR-51 (A) Costing versioned; once referenced by an approved quotation or confirmed order, immutable except via new revision.
- FR-52 (A) All cost/margin calculations are backend-authoritative; Flutter never computes authoritative totals.
- FR-53 (B) Multi-currency costing with exchange rate captured per version (not recomputed retroactively from a live rate).

### Quotation
- FR-60 (A) Quotation references a costing version; versioned; revision history retained.
- FR-61 (A) Approved quotation cannot be edited in place — amendments require a new version referencing the prior one.
- FR-62 (B) Quotation validity period and status (draft/sent/negotiating/approved/rejected/expired).

### Order Management
- FR-70 (A) Order record: buyer PO reference, style(s), factory, quantity (size/color breakdown), price, dates, Incoterm, payment terms, destination.
- FR-71 (A) One buyer PO may map to multiple internal order lines across multiple styles and/or multiple factories (many-to-many over time).
- FR-72 (A) Order amendments (qty, price, date, destination) are tracked as append-only amendment records, never silent edits.
- FR-73 (B) Order split (single order fulfilled by multiple factories) and partial fulfillment supported.
- FR-74 (C) Order merge only where it does not destroy distinguishable commercial history (generally discouraged; see ADR Doc 18).
- FR-75 (A) Order cancellation preserves full history; does not delete the record.

### T&A / Critical Path
- FR-80 (A) Configurable milestone templates per buyer/style/order — no hardcoded fixed list.
- FR-81 (A) Each milestone: planned/revised/actual date, responsible person/factory, status, dependency link, delay days, reason.
- FR-82 (A) Automatic status computation (upcoming/due today/overdue/critical delay/blocked by dependency) — not manually set.
- FR-83 (B) Automatic overall order progress % derived from milestone completion.

### Production Follow-up
- FR-90 (A) Daily production update entry: cutting/sewing/finishing/packing quantities, rejection/alteration counts.
- FR-91 (B) Planned-vs-actual and cumulative production tracked automatically from daily entries (no duplicate manual totals).
- FR-92 (E) Whether/when direct factory-system integration replaces manual daily entry — out of scope for v1, revisit per ADR.

### Quality Management
- FR-100 (A) Inspection records (inline/midline/final) with AQL-style sampling data, pass/fail, defect categorization.
- FR-101 (B) Defect tracking with CAPA (corrective/preventive action) workflow and factory response.
- FR-102 (C) Buyer-configurable inspection requirements (which inspection types required per buyer).

### Buyer Approvals
- FR-110 (A) Generic approval engine covering costing, quotation, sample, lab dip, trim, PP sample, inspection, shipment, documents.
- FR-111 (A) Approval states: submitted/pending/approved/rejected/returned/resubmitted/withdrawn, with full round history retained.

### Shipment
- FR-120 (A) Shipment record linked to order(s): quantity, cartons, weights/volume, port, destination, ETD/ETA/actual date, forwarder, shipping line, container, BL/AWB reference.
- FR-121 (A) Partial/short shipment explicitly authorized (role-gated), not silently allowed past order quantity.
- FR-122 (B) Shipment status lifecycle (booked/in-transit/delivered/delayed).

### Commercial & Documents
- FR-130 (A) Document records (commercial invoice, packing list, BL/AWB, certificate of origin, test/inspection certificates, buyer-specific docs) with version, status, owner, upload date, approval, expiry where applicable.
- FR-131 (B) Document mandatory/buyer-required/factory-required/optional classification is data-driven per buyer/order, not hardcoded in code.
- FR-132 (E) Exact mandatory-document legal requirements per destination/Incoterm — requires compliance/commercial-team confirmation, not assumed by the system.

### Payment / Financial Tracking
- FR-140 (A) Operational profitability (quoted price vs. actual cost vs. realized price) per order — not statutory accounting.
- FR-141 (B) Buyer receivable and factory payable tracking at a summary level (amount due, due date, received/paid status).
- FR-142 (D) Full accounting ledger / tax reporting — explicitly out of scope; integration boundary only (ADR Doc 18).

### Communication & Activity
- FR-150 (A) Chronological activity timeline (calls, emails, meetings, comments) attachable to buyer, inquiry, style, sample, order, factory, shipment.
- FR-151 (B) Retroactive logging supported (activity date ≠ entry date) — see workflow realities in Doc 2.

### Task & Follow-up
- FR-160 (A) Tasks always attached to a business entity (never free-floating); assignment, priority, due date, status, reminders, escalation.

### Dashboards & KPIs
- FR-170 (A) Role-specific dashboards (management, merchandiser, factory follow-up) per Document 14.
- FR-171 (B) Every KPI has a documented formula, data source, and permission scope — no ad hoc numbers.

### Notifications & Automation
- FR-180 (A) Configurable in-app + push notifications for deadlines, overdue items, approvals pending, delays.
- FR-181 (C) Email notification channel. 
- FR-182 (E) SMS/WhatsApp channel — requires legal/cost confirmation (third-party API, consent, data residency) before commitment.

### Mobile / Android
- FR-190 (A) Android app (Flutter) covering all above modules with camera capture, document upload, search, push notifications.
- FR-191 (B) Partial offline support per Document "Offline-First Analysis" (view cached data, draft entries) — not full offline transactional parity.
- FR-192 (C) Barcode/QR support for carton/shipment identification.

### Search
- FR-200 (A) Global search across buyer, style, PO/order number, factory, sample number, shipment number, merchandiser, status.

### Reports
- FR-210 (A) Reports per Document 14 with defined formulas, filters, and permission scope.

### Security & Audit
- FR-220 (A) RBAC enforced server-side; object-level authorization (e.g., merchandiser sees only assigned buyers/orders where configured).
- FR-221 (A) Audit log for all critical business actions (who/what/when/entity/previous/new value).

### Multi-company
- FR-230 (D) Multi-company/multi-unit support — schema designed to not block it (tenant/org_id on core tables), but UI/workflow for it deferred.

## 3.2 Non-Functional Requirements

- NFR-01 (A) Backend is sole authority for business rules, calculations, and authorization; mobile client never trusted.
- NFR-02 (A) All monetary values stored as fixed-precision decimal (never float).
- NFR-03 (B) API p95 response time target < 500ms for list/detail endpoints under expected load (single buying house, tens of concurrent users).
- NFR-04 (B) Mobile app usable on a mid-range Android device over 3G/unstable wifi (pagination, image compression, no full-table loads).
- NFR-05 (A) All historical commercial records (costing, quotation, order, approval) immutable once finalized; changes only via new versions.
- NFR-06 (B) Soft delete only for master data referenced by historical transactions; hard delete permitted for draft-only, never-referenced records.
- NFR-07 (C) Database and file backups with tested restore procedure (Document 19/Deployment).
- NFR-08 (E) Expected concurrent user count and data volume at 1/3/5-year horizon — needed to size infra precisely; assumed small-to-mid (see Assumptions Register) pending owner confirmation.
- NFR-09 (A) HTTPS-only; no plaintext credentials or tokens in transit or client storage.
- NFR-10 (C) OpenAPI documentation maintained alongside API.

## 3.3 Explicitly Excluded From v1 Scope
- Buyer/factory self-service portals (D — future).
- Full statutory accounting/ERP (D — integration boundary only).
- Factory-floor machine/line-level production systems (out of scope entirely).
- SMS/WhatsApp notifications (E — pending legal/cost decision).
- Multi-company active use (D — schema-ready, not built).
