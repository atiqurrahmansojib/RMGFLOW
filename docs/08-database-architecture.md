# Document 8 — Database Architecture (PostgreSQL)

Design principles applied throughout: proper normalization, explicit PK/FK, unique/check constraints, indexed lookup columns, `numeric` for all money/quantity, `timestamptz` everywhere, status via constrained reference tables or Postgres `enum` types (reference tables preferred where a UI needs to manage the list; `enum` where the set is fixed and rarely changes), soft delete only where historical transactions reference the row, and `version` integer column for optimistic locking on records with concurrent-edit risk (costing, quotation, order, T&A milestone).

## 8.1 Identity & Access

```
organizations(id PK, name, is_active, created_at)
users(id PK, organization_id FK, email UNIQUE, password_hash, full_name, phone, is_active, created_at, updated_at)
roles(id PK, name UNIQUE, description)
permissions(id PK, code UNIQUE, description)           -- e.g. 'ORDER_CREATE'
role_permissions(role_id FK, permission_id FK, PK(role_id, permission_id))
user_roles(user_id FK, role_id FK, PK(user_id, role_id))
assignments(id PK, user_id FK, scope_type CHECK IN ('BUYER','FACTORY'), scope_id, PK-equivalent UNIQUE(user_id, scope_type, scope_id))
sessions(id PK, user_id FK, refresh_token_hash, device_info, ip_address, created_at, expires_at, revoked_at)
```
Rationale: `assignments.scope_id` is polymorphic by design (buyer or factory id) — kept as a plain bigint with `scope_type` discriminator rather than two FK columns, since assignment is a lightweight access-grant record, not a domain entity; application layer validates scope_id existence, not a DB FK (documented trade-off, Doc 18 ADR).

## 8.2 Master Data

```
seasons(id PK, name, year, start_date, end_date, UNIQUE(name, year))
currencies(code PK CHAR(3), name)
exchange_rates(id PK, from_currency FK, to_currency FK, rate NUMERIC(18,6), rate_date DATE, UNIQUE(from_currency, to_currency, rate_date))
countries(code PK CHAR(2), name)
incoterms(code PK VARCHAR(3), name)                      -- FOB, CIF, EXW, etc.
payment_terms(id PK, name, description)
document_types(id PK, name, category, is_mandatory_default BOOLEAN)
defect_types(id PK, category, name, severity)
milestone_types(id PK, name, default_sequence, typical_offset_days)

buyers(id PK, organization_id FK, code UNIQUE, name, group_name, country FK, default_currency FK, 
       default_payment_terms_id FK, default_incoterm FK, is_active, created_at, updated_at, version)
buyer_contacts(id PK, buyer_id FK, name, department, email, phone, is_primary)
buyer_requirements(id PK, buyer_id FK, requirement_type CHECK IN ('COMPLIANCE','QUALITY','DOCUMENT','COSTING_RULE','LEAD_TIME'), 
                    detail JSONB, is_active)

factories(id PK, organization_id FK, code UNIQUE, name, partner_type CHECK IN 
          ('GARMENT_FACTORY','FABRIC_SUPPLIER','TRIM_SUPPLIER','WASHING','PRINTING','EMBROIDERY',
           'TESTING_LAB','INSPECTION_AGENCY','FREIGHT_FORWARDER','OTHER'),
          legal_entity_name, address, country FK, capacity_per_month INT, is_active, created_at, updated_at, version)
factory_contacts(id PK, factory_id FK, name, role, email, phone, is_primary)
factory_capabilities(id PK, factory_id FK, product_category, UNIQUE(factory_id, product_category))
factory_certifications(id PK, factory_id FK, cert_name, issued_date, expiry_date, document_id FK NULLABLE)
factory_buyer_approvals(id PK, factory_id FK, buyer_id FK, status CHECK IN ('PENDING','APPROVED','REJECTED','EXPIRED'), 
                         approved_date, expiry_date, UNIQUE(factory_id, buyer_id))
```
Rationale: `factory_buyer_approvals` directly enforces the real-world rule that a factory approved for Buyer A cannot be used for Buyer B's order without separate approval — referenced as a hard check at order creation (Doc 9).

## 8.3 Inquiry & Product Development

```
inquiries(id PK, organization_id FK, inquiry_no UNIQUE, buyer_id FK, season_id FK, merchandiser_id FK (users),
          target_quantity INT, target_price NUMERIC(14,4), target_currency FK, delivery_requirement DATE,
          status CHECK IN ('OPEN','QUOTED','WON','LOST','HOLD'), lost_reason TEXT, created_at, updated_at)
inquiry_factory_candidates(id PK, inquiry_id FK, factory_id FK, status CHECK IN ('CANDIDATE','SELECTED','REJECTED'))

styles(id PK, organization_id FK, style_no UNIQUE, buyer_id FK, buyer_style_no, product_category, 
       season_id FK, gender, description, current_revision_id FK NULLABLE, is_active, created_at, updated_at)
style_revisions(id PK, style_id FK, revision_no INT, fabric, composition, gsm NUMERIC(6,2), color, 
                 size_range, measurement_spec JSONB, created_by FK(users), created_at, 
                 UNIQUE(style_id, revision_no))
```
Rationale: `styles.current_revision_id` is a denormalized pointer for fast "latest" lookups; `style_revisions` is the append-only source of truth (never updated after creation, satisfying FR-31/NFR-05).

## 8.4 Sampling (with Approval Engine)

```
samples(id PK, organization_id FK, sample_no UNIQUE, style_id FK, buyer_id FK, factory_id FK,
        sample_type_id FK(milestone_types reused is wrong — separate table below), 
        request_date DATE, required_date DATE, current_status, created_at, updated_at)
sample_types(id PK, name, is_buyer_specific BOOLEAN, buyer_id FK NULLABLE)
sample_revisions(id PK, sample_id FK, revision_no INT, submitted_date DATE, comments TEXT,
                  created_at, UNIQUE(sample_id, revision_no))

approvals(id PK, target_type CHECK IN ('COSTING','QUOTATION','SAMPLE_REVISION','LAB_DIP','TRIM','PP_SAMPLE',
          'INSPECTION','SHIPMENT','DOCUMENT'), target_id BIGINT, round_no INT,
          status CHECK IN ('SUBMITTED','PENDING','APPROVED','REJECTED','RETURNED','RESUBMITTED','WITHDRAWN'),
          submitted_by FK(users), submitted_at, decided_by FK(users) NULLABLE, decided_at NULLABLE,
          comments TEXT, rejection_reason TEXT NULLABLE, UNIQUE(target_type, target_id, round_no))
```
Rationale: `approvals` is the single shared state-machine table for every approval gate in the system (Doc 6 rationale). `(target_type, target_id)` is an application-validated polymorphic reference, not a DB FK — the only pragmatic way to share one approval table across heterogeneous targets without 8 near-identical tables (explicit trade-off, documented in ADR Doc 18). A rejected sample_revision never becomes "approved" — a rejection creates a new `sample_revisions` row and a new `approvals` round; existing rows are never updated to flip status (enforced by application service layer + DB trigger disallowing UPDATE on `approvals.status` once `decided_at` is set).

## 8.5 Costing & Quotation

```
costings(id PK, organization_id FK, style_id FK, inquiry_id FK NULLABLE, version_no INT, 
         currency FK, exchange_rate NUMERIC(18,6), quantity INT, status CHECK IN ('DRAFT','APPROVED','SUPERSEDED'),
         target_price NUMERIC(14,4), total_cost NUMERIC(14,4), margin_percent NUMERIC(6,3),
         created_by FK(users), created_at, approved_at NULLABLE, version INT DEFAULT 1,
         UNIQUE(style_id, version_no))
costing_items(id PK, costing_id FK, component_type CHECK IN ('FABRIC','KNITTING','DYEING','FINISHING','TRIMS',
              'CM','WASHING','PRINTING','EMBROIDERY','TESTING','INSPECTION','PACKAGING','FREIGHT',
              'COMMISSION','BANK_CHARGE','WASTAGE','OVERHEAD','OTHER'), description, unit_cost NUMERIC(14,4),
              consumption NUMERIC(14,4), wastage_percent NUMERIC(5,2), total_cost NUMERIC(14,4))

quotations(id PK, organization_id FK, costing_id FK, quotation_no UNIQUE, version_no INT, buyer_id FK, 
           style_id FK, quantity INT, unit_price NUMERIC(14,4), currency FK, incoterm FK, payment_terms_id FK,
           validity_date DATE, lead_time_days INT, status CHECK IN ('DRAFT','SENT','NEGOTIATING','APPROVED',
           'REJECTED','EXPIRED','SUPERSEDED'), created_at, version INT DEFAULT 1, UNIQUE(buyer_id, quotation_no, version_no))
```
Rationale: once `costings.status = 'APPROVED'` or referenced by a non-draft `quotations` row, a DB trigger + service-layer guard blocks further UPDATE to cost fields — any change requires inserting a new `version_no` row referencing `superseded_costing_id` (FR-51, NFR-05). Same pattern for quotations.

## 8.6 Order Management

```
orders(id PK, organization_id FK, order_no UNIQUE, buyer_po_no, buyer_id FK, quotation_id FK NULLABLE,
       status CHECK IN ('CONFIRMED','IN_PROGRESS','PARTIALLY_SHIPPED','SHIPPED','CLOSED','CANCELLED'),
       order_date DATE, ex_factory_date DATE, delivery_date DATE, incoterm FK, payment_terms_id FK, 
       destination_country FK, total_value NUMERIC(16,4), currency FK, created_at, updated_at, version INT DEFAULT 1)
order_items(id PK, order_id FK, style_id FK, factory_id FK, color, size, quantity INT, unit_price NUMERIC(14,4),
            UNIQUE(order_id, style_id, factory_id, color, size))
order_amendments(id PK, order_id FK, amendment_no INT, field_changed, old_value TEXT, new_value TEXT,
                  reason TEXT, requested_by FK(users), approved_by FK(users) NULLABLE, 
                  status CHECK IN ('REQUESTED','APPROVED','REJECTED'), created_at, UNIQUE(order_id, amendment_no))
```
Rationale: a single buyer PO can map to several `orders` rows (one per factory split, FR-71/73) all sharing `buyer_po_no` — intentionally not a unique constraint on `buyer_po_no` alone, only on `order_no` (the buying house's own internal number). `order_items` carries the size/color breakdown as the normalized grain instead of JSON, enabling accurate quantity-vs-shipment math (needed for FR-121 partial-shipment validation). Amendments never mutate `orders` fields directly except via a service method that also writes the amendment row in the same transaction — enforced in code, not purely by schema, since blocking all UPDATEs via trigger would be too blunt for legitimate system-maintained fields like `status`/`total_value` recompute.

## 8.7 T&A / Critical Path

```
ta_templates(id PK, organization_id FK, name, buyer_id FK NULLABLE, style_id FK NULLABLE, is_default BOOLEAN)
ta_template_milestones(id PK, template_id FK, milestone_type_id FK, sequence INT, offset_days_from_exfactory INT,
                        depends_on_milestone_id FK NULLABLE(self), UNIQUE(template_id, sequence))
ta_milestones(id PK, order_id FK, milestone_type_id FK, sequence INT, planned_date DATE, revised_date DATE NULLABLE,
              actual_date DATE NULLABLE, responsible_user_id FK NULLABLE, responsible_factory_id FK NULLABLE,
              status CHECK IN ('PENDING','UPCOMING','DUE_TODAY','OVERDUE','CRITICAL_DELAY','BLOCKED','DONE'),
              depends_on_milestone_id FK NULLABLE(self), delay_days INT GENERATED derived at read-time (not stored),
              delay_reason TEXT, created_at, updated_at)
```
Rationale: `ta_templates` are reusable configuration (buyer-specific or style-specific, resolved by specificity at order-creation time — style-specific wins over buyer-specific wins over organization default), while `ta_milestones` are the per-order instantiated, mutable-by-actual-date rows (clarifies the Doc 4 gap on template-vs-instance). `status` is computed by a scheduled job + on-read function comparing `planned_date`/`revised_date` to current date and `depends_on_milestone_id` completion — not manually set by users except via `actual_date` entry and `delay_reason`.

## 8.8 Production, Quality, Shipment, Documents, Financial, Claims

```
production_updates(id PK, order_id FK, update_date DATE, cutting_qty INT, sewing_qty INT, finishing_qty INT,
                    packing_qty INT, rejection_qty INT, alteration_qty INT, entered_by FK(users), created_at,
                    UNIQUE(order_id, update_date))

inspections(id PK, order_id FK, inspection_type CHECK IN ('INLINE','MIDLINE','FINAL'), inspection_date DATE,
            inspected_qty INT, aql_level VARCHAR(10), result CHECK IN ('PASS','FAIL','REINSPECT'),
            inspector_id FK(users), created_at)
defects(id PK, inspection_id FK, defect_type_id FK, quantity INT, severity, photo_document_id FK NULLABLE)
capa_records(id PK, defect_id FK NULLABLE, inspection_id FK NULLABLE, description, corrective_action TEXT,
             preventive_action TEXT, factory_response TEXT, status CHECK IN ('OPEN','IN_PROGRESS','CLOSED'),
             created_at, closed_at NULLABLE)

shipments(id PK, order_id FK, shipment_no UNIQUE, shipment_date DATE, etd DATE, eta DATE, 
          quantity_shipped INT, cartons INT, gross_weight NUMERIC(10,2), net_weight NUMERIC(10,2), 
          volume_cbm NUMERIC(10,3), port_of_loading, port_of_discharge, forwarder_id FK(factories), 
          shipping_line, container_no, bl_awb_no, status CHECK IN ('BOOKED','IN_TRANSIT','DELIVERED','DELAYED'),
          is_partial BOOLEAN, authorized_by FK(users) NULLABLE WHEN is_partial, created_at)

documents(id PK, entity_type CHECK IN ('ORDER','SHIPMENT','FACTORY','STYLE'), entity_id BIGINT,
          document_type_id FK, version_no INT, file_attachment_id FK, status CHECK IN ('DRAFT','SUBMITTED',
          'APPROVED','EXPIRED'), owner_id FK(users), uploaded_at, expiry_date NULLABLE,
          UNIQUE(entity_type, entity_id, document_type_id, version_no))

order_financials(id PK, order_id FK UNIQUE, quoted_unit_price NUMERIC(14,4), actual_cost_unit NUMERIC(14,4),
                  realized_unit_price NUMERIC(14,4) NULLABLE, operational_margin_percent NUMERIC(6,3) GENERATED)
receivables(id PK, order_id FK, buyer_id FK, amount NUMERIC(16,4), currency FK, due_date DATE,
            status CHECK IN ('PENDING','PARTIAL','RECEIVED','OVERDUE'), received_amount NUMERIC(16,4) DEFAULT 0)
payables(id PK, order_id FK, factory_id FK, amount NUMERIC(16,4), currency FK, due_date DATE,
         status CHECK IN ('PENDING','PARTIAL','PAID','OVERDUE'), paid_amount NUMERIC(16,4) DEFAULT 0)
payment_records(id PK, receivable_id FK NULLABLE, payable_id FK NULLABLE, amount NUMERIC(16,4), 
                 paid_date DATE, method, reference_no, recorded_by FK(users), created_at)

claims(id PK, order_id FK, shipment_id FK NULLABLE, raised_by CHECK IN ('BUYER','INTERNAL'), 
       claim_type CHECK IN ('SHORT_SHIPMENT','QUALITY','DELAY','OTHER'), description, 
       claimed_amount NUMERIC(14,4) NULLABLE, status CHECK IN ('OPEN','UNDER_REVIEW','RESOLVED','REJECTED'),
       resolution TEXT, created_at, resolved_at NULLABLE)
```

## 8.9 Cross-Cutting

```
activities(id PK, entity_type, entity_id, activity_type CHECK IN ('CALL','EMAIL','MEETING','NOTE'),
           occurred_at TIMESTAMPTZ, logged_by FK(users), content TEXT, created_at)
tasks(id PK, entity_type, entity_id, title, description, assigned_to FK(users), priority CHECK IN 
      ('LOW','MEDIUM','HIGH','URGENT'), due_date DATE, status CHECK IN ('OPEN','IN_PROGRESS','DONE','CANCELLED'),
      created_by FK(users), created_at, updated_at)
notification_rules(id PK, event_type, channel CHECK IN ('IN_APP','PUSH','EMAIL'), is_active, 
                    escalation_after_hours INT NULLABLE)
notifications(id PK, user_id FK, rule_id FK NULLABLE, entity_type, entity_id, message, is_read BOOLEAN, 
              channel, delivered_at, created_at)
attachments(id PK, entity_type, entity_id, file_name, storage_key, content_type, size_bytes, 
            uploaded_by FK(users), uploaded_at, checksum)
audit_logs(id PK, user_id FK NULLABLE, action, entity_type, entity_id, previous_value JSONB, 
           new_value JSONB, reason TEXT NULLABLE, ip_address, occurred_at TIMESTAMPTZ, 
           -- append-only: no UPDATE/DELETE grants on this table at the DB role level)
```

## 8.10 Indexing Strategy (representative, not exhaustive)
- All FK columns indexed by default (Postgres does not auto-index FKs — explicit `CREATE INDEX` required on every FK used in joins/filters: `orders(buyer_id)`, `orders(status)`, `ta_milestones(order_id, status)`, `samples(status, required_date)`, etc.
- Composite index `ta_milestones(status, planned_date)` for the overdue-detection scheduled job.
- `GIN` index on `documents` and `activities` if free-text search extends there (paired with Document 31 search strategy — likely Postgres full-text `tsvector` columns on `buyers.name`, `styles.style_no`/`description`, `orders.order_no`/`buyer_po_no`, `factories.name`).
- Partial index on `orders(status) WHERE status NOT IN ('CLOSED','CANCELLED')` to speed the dominant "active orders" dashboard query.

## 8.11 Soft Delete / Immutability Policy
- Soft delete (`is_active` flag or `deleted_at`) applies to: buyers, factories, styles, sample_types, ta_templates — master data that may be referenced by historical transactions.
- Hard delete permitted only for: draft-only rows never referenced elsewhere (e.g., a `costings` row with status DRAFT and no child `costing_items` beyond the editing session, or a draft `tasks` row).
- Never deletable, update-restricted to append-only: `audit_logs`, `approvals` (post-decision), `order_amendments`, `style_revisions`, `sample_revisions`, `costing`/`quotation` versions once non-DRAFT.

## 8.12 Optimistic Locking
`version` integer column on `buyers`, `factories`, `costings`, `quotations`, `orders` — every UPDATE includes `WHERE version = :expected` and increments `version`; a mismatch returns HTTP 409 to the client (relevant given multiple merchandisers/mobile devices may edit concurrently).
