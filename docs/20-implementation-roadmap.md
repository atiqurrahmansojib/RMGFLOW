# Document 20 — Implementation Roadmap

Sequence adjusted from the prompt's suggested order (prompt §53) based on dependency analysis (Doc 6.2) and risk prioritization (Doc 19, R1 adoption risk) — T&A pulled earlier relative to full Quality/Shipment depth, since T&A delivers value as soon as Orders exist, and is the highest-adoption-value module per Doc 19 recommendation.

## Phase 0 — Discovery & Architecture (this document set)
Deliverable: Documents 1-22 (this folder). **Status: complete.**

## Phase 1 — Foundation
Auth, users, roles, permissions, assignments, sessions, organizations, audit log infrastructure, base Flutter app shell (routing, theming, networking, secure storage), CI/CD skeleton (Doc 17.5).

## Phase 2 — Master Data
Buyers, buyer contacts, factories/vendors (typed), factory contacts, seasons, currencies/exchange rates, countries, Incoterms, payment terms, document types, defect types, milestone type library, factory-buyer approvals. Global search foundation (indexing these first, extend later).

## Phase 3 — Inquiry & Product Development
Inquiry lifecycle, factory candidate sourcing, styles + revisions, tech pack/attachment upload (Attachment module built here as the first cross-cutting module).

## Phase 4 — Costing & Quotation
Costing versions/items, margin calculation, approval engine (built here as the first instance of the shared engine, Doc 6.3/ADR-08), quotation versions referencing costing.

## Phase 5 — Sampling
Sample types/requests/revisions, reuse of approval engine for sample approval rounds (second consumer of the shared engine, validating its generality before Order/Quality depend on it).

## Phase 6 — Orders
Order creation (from quotation or direct), order items, factory-buyer approval gate enforcement, amendments, cancellation, split — this is the aggregate root the next three phases depend on.

## Phase 7 — T&A / Critical Path
Templates, milestone instantiation on order confirmation (A15), status derivation job, delay-cascade automation (A16), order progress %. **Pulled earlier than prompt's default ordering** given its outsized adoption value (Doc 19 recommendation) and that it only needs Orders (Phase 6), not Production/Quality/Shipment.

## Phase 8 — Production Follow-up
Daily production updates, cumulative rollups, planned-vs-actual.

## Phase 9 — Quality
Inspections, defects, CAPA, shipment-blocking rule (9.7) — depends on Production existing conceptually (inline/midline inspections reference production stage) though not strictly code-dependent.

## Phase 10 — Shipment & Commercial
Shipment records, partial-shipment authorization, documents (versioned), expiry tracking.

## Phase 11 — Financial & Claims
Order financials, receivables/payables, payment records, claims/disputes.

## Phase 12 — Communication, Tasks, Notifications, Dashboards, Reports
Activity timeline (generalized across all entities built so far), tasks, notification rules/dispatch (all automations from Doc 13 wired in incrementally as their dependent modules complete — not held entirely until this phase; e.g., A1-A4 T&A notifications ship with Phase 7), dashboards (Doc 14.8), reports (Doc 14.1-14.7).

## Phase 13 — Hardening
Security review (Doc 15 checklist), performance testing (NFR-03/04), backup/restore drill (Doc 17.6), full E2E scenario suite (Doc 16.5), data migration tooling finalized and run (if applicable), production deployment.

## Dependency Note
Notifications/automations (Doc 13) are **not** a single late phase in practice — each automation ships alongside the module it depends on (A1-A4 with Phase 7, A8 with Phase 8, A9 with Phase 9, etc.) so every phase delivers a working, notified slice rather than inert data entry until Phase 12. Document 13's table remains the single specification; Phase 12 above is where the *remaining* cross-cutting ones (task reminders, document expiry, payment overdue) land, since their underlying entities (tasks, documents, payments) complete earlier in Phases 3/10/11 respectively but their notification wiring is most efficiently batched together with the dashboard/reporting layer.

## My Recommendation on Sequencing
Ship **Phases 1-7 (through T&A) as the first real release**, even before Quality/Shipment/Financial are built — a merchandiser using Buyer/Style/Costing/Quotation/Order/T&A already has a materially better daily tool than Excel/WhatsApp, matching the "fastest path to adoption" risk mitigation in Document 19. Do not wait for all 13 phases to show the first working release to users.
