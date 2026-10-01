# Document 1 — Executive Product Definition

## 1.1 What This Application Is

**RMGFlow** is a production operations system for a Bangladesh garments **buying house** (a third-party merchandising/sourcing intermediary between international apparel buyers and local garment factories/vendors). It digitizes and enforces the real business lifecycle a buying house executes between receiving a buyer inquiry and closing out a shipped, paid order.

It is:

- A **merchandising operations system** — inquiry, style development, sampling, costing, quotation, order, T&A, production follow-up, quality, approvals, shipment, commercial documentation, and post-order analysis, modeled as connected business transactions, not isolated CRUD screens.
- A **coordination hub** between buyers, factories, vendors (fabric/trim/wash/print/embroidery), testing labs, inspection agencies, freight forwarders, banks, and internal teams.
- A **mobile-first Android application** (Flutter) backed by a Spring Boot + PostgreSQL REST API, built for merchandisers, production follow-up staff, quality inspectors, and management who work on the move, in factories, and in low-bandwidth conditions.
- An **audit-grade system of record** for commercial decisions: approved costing, approved quotations, approved samples, confirmed orders, and shipment/commercial documents are versioned and immutable once finalized.
- A **decision-support system** for management: dashboards and reports that answer real operational questions (at-risk orders, overdue milestones, factory performance, profitability) without manual reconciliation of spreadsheets.

## 1.2 What This Application Is NOT

- **Not a generic project-management or task-tracking tool.** Tasks exist only when attached to a real buying-house entity (buyer, order, sample, T&A milestone, etc.).
- **Not a full accounting/ERP system.** It tracks *operational* profitability (costing margin, order value, buyer/factory running balances) but does not replace a general ledger, tax filing, or statutory accounting system. A defined integration boundary exists for that (see Document 18, ADR on financial scope).
- **Not a factory production-floor ERP** (e.g., it does not do machine-level line balancing, payroll, or inventory/warehouse management for a factory). It tracks production **progress as reported/followed-up by the buying house**, not internal factory shop-floor operations.
- **Not a generic multi-industry SaaS product in v1.** It is purpose-built around Bangladesh RMG export workflows; configurability (buyer-specific T&A templates, document rules, approval flows) exists so the *data* is flexible, not so the *domain* is generic.
- **Not a demo or prototype.** Every financial, approval, and historical record is designed to be immutable/versioned and auditable from day one, even in the first shipped version.
- **Not a client-authoritative system.** The Flutter app never makes final decisions on authorization, approval state transitions, or financial calculations — the backend is the sole source of truth.

## 1.3 Primary Users

Internal buying-house staff: Owner/MD, GM, Senior/Junior Merchandisers, Marketing/BD, Sampling team, Production follow-up team, Quality team, Commercial team, Accounts, Factory coordinators. See Document 5 for full RBAC.

Buyers and factories are **data subjects** (represented as master/partner entities with contacts) in v1, not application users — they interact via email/communication captured into the system, not via login. (See ADR in Document 18 on buyer/factory portal deferral — classified as D, future enhancement.)

## 1.4 Core Value Proposition

1. Replace fragmented Excel/WhatsApp/email coordination with one connected transactional record per style/order.
2. Make T&A critical-path tracking and overdue detection automatic instead of manually chased.
3. Make costing, quotation, and order data immutable and auditable so profitability and pricing disputes can be resolved from history, not memory.
4. Let management see real-time answers to "what needs attention today" without compiling reports by hand.
5. Give field staff (production follow-up, quality) a fast, mobile-first tool usable one-handed, in a factory, over weak data connections.

## 1.5 Success Criteria (v1)

- A merchandiser can take a buyer inquiry through costing, quotation, sample approval, order confirmation, T&A setup, and see all of it on one connected record.
- No commercial figure (costing, quotation, order value) can be silently altered after approval — every change is a tracked revision.
- Overdue T&A milestones and pending approvals surface automatically on relevant dashboards without manual querying.
- Core actions (view order, log a follow-up, update production %, capture a photo) work on a mid-range Android phone on 3G/weak wifi.
- Every role sees only the data and actions its permission model allows, enforced server-side.
