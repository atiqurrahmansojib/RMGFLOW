# Document 6 — Module Architecture

## 6.1 Module List and Responsibility

| Module | Responsibility | Depends On |
|---|---|---|
| **Identity & Access** | Auth, users, roles, permissions, assignments, sessions | — (foundation) |
| **Master Data** | Buyers, buyer contacts, factories/vendors, factory contacts, seasons, currencies, countries, Incoterms, payment terms, document types, defect types, milestone types | Identity |
| **Inquiry & BD** | Inquiry lifecycle, factory candidate sourcing, win/loss tracking | Master Data |
| **Product Development** | Style master, revisions, tech packs | Master Data |
| **Costing** | Costing versions, cost components, margin calc | Product Development, Master Data |
| **Quotation** | Quotation versions referencing costing | Costing |
| **Sampling** | Sample requests, revisions, approval rounds | Product Development, Approval Engine |
| **Order Management** | Orders, order items, amendments, cancellations, splits | Quotation (optional link), Product Development, Master Data |
| **T&A / Critical Path** | Templates, milestone instances, dependency graph, delay calc | Order Management |
| **Production Follow-up** | Daily production updates, planned-vs-actual | Order Management |
| **Quality** | Inspections, defects, CAPA | Order Management |
| **Approval Engine** | Generic approval workflow used by Costing, Quotation, Sampling, Quality gates, Shipment, Documents | Identity (approver roles) |
| **Shipment** | Shipment records, partial/split shipment validation | Order Management |
| **Commercial & Documents** | Document records, versioning, mandatory/optional classification | Order Management, Shipment |
| **Financial Tracking** | Operational profitability, receivable/payable summary | Order Management, Costing, Shipment |
| **Claims & Disputes** | Post-shipment claim tracking | Shipment, Order Management |
| **Communication & Activity** | Activity timeline on any entity | Cross-cutting (all modules) |
| **Task & Follow-up** | Tasks attached to entities, reminders, escalation | Cross-cutting |
| **Notifications** | Rules, dispatch, delivery log | Cross-cutting |
| **Reporting & Dashboards** | KPI computation, role-scoped views | Cross-cutting (reads all) |
| **Audit** | Immutable action log | Cross-cutting (writes from all) |
| **File/Attachment** | Upload, storage, metadata, access control | Cross-cutting |
| **Search** | Cross-entity indexed search | Cross-cutting (reads all) |

## 6.2 Dependency Graph (textual)

```
Identity & Access
   └─ Master Data
        ├─ Inquiry & BD
        ├─ Product Development ── Costing ── Quotation
        │                                        │
        └────────────────────── Order Management ┘
                                     │
                    ┌────────────────┼────────────────┬───────────────┐
                    ▼                ▼                ▼               ▼
                T&A / Critical   Production      Quality         Sampling
                Path             Follow-up       (+ Approval     (+ Approval
                                                   Engine)         Engine)
                    │                │                │
                    └────────────────┴────────┬───────┘
                                               ▼
                                          Shipment ── Commercial & Documents
                                               │
                                     Financial Tracking / Claims

Cross-cutting (attach to anything above): Communication & Activity,
Task & Follow-up, Notifications, Reporting, Audit, File/Attachment, Search
```

## 6.3 Design Rationale
- **Approval Engine is a shared service**, not duplicated per module, because the same submitted/pending/approved/rejected/returned/resubmitted/withdrawn state machine and round-history requirement (FR-110/111) recurs identically across costing, quotation, sampling, quality, shipment, and documents. One implementation, many attachment points (`approval_target_type`, `approval_target_id`).
- **T&A, Production, Quality, Sampling all depend on Order Management**, not on each other directly — avoids circular coupling; cross-module visibility (e.g., a quality failure delaying a T&A milestone) happens through the order as the shared aggregate root, with an explicit link (a quality failure can reference and flag a T&A milestone) rather than a hidden dependency.
- **Cross-cutting modules attach via a generic `(entity_type, entity_id)` pattern** (Activity, Tasks, Notifications, Audit, Attachments) to avoid N duplicate "comments/attachments" tables per module (anti-pattern explicitly warned against in prompt §56 rule 7).
- **Reporting/Search are read-only consumers** of all other modules' data — they do not own business state, preventing circular writes back into transactional modules.
