# Document 2 — Real Bangladesh Buying-House Workflow

This describes how a real Bangladesh RMG buying house actually operates, based on standard apparel-sourcing industry practice (merchandising, sampling, costing, T&A/critical path management, compliance, and commercial/export processes as practiced in the Bangladesh export garment sector). This is the reference model the system is built around — not a copy of generic PM/ERP software.

## 2.1 Who a Buying House Is

A buying house is an intermediary: it does not own factories. It sources from (or is affiliated with) garment factories and subcontracted vendors (fabric mills, trim suppliers, washing/printing/embroidery units, testing labs, inspection agencies) on behalf of international buyers (retailers/brands or their buying agents). Its core asset is **merchandising capability**: product development, costing, vendor coordination, quality assurance, and on-time delivery management — not production capacity itself.

Two organizational patterns exist in Bangladesh:
- **Liaison office of a buyer** — dedicated to one buyer/group, factory-sourcing and QA on their behalf.
- **Independent buying house** — sources for multiple buyers across multiple factories, which is the harder, more general case and the one this system targets (it subsumes the liaison-office case as a buyer count of one).

## 2.2 End-to-End Lifecycle (as practiced, not idealized)

1. **Business development / Inquiry** — Buyer or buying agent sends an inquiry (tech pack, sketch, reference sample, or simple spec) with target price/quantity/season. Often informal (email, WhatsApp) before being logged formally.
2. **Feasibility & factory sourcing** — Merchandiser checks which affiliated/partner factories can produce it (capability, capacity, compliance status, buyer-approval status — many buyers pre-approve factories via audit).
3. **Costing** — Built from fabric, trims, CM (cut-make, i.e., factory's making charge), wastage, overheads, commission, and buying-house margin. Multiple cost versions are normal as fabric/trim prices and factory CM quotes shift.
4. **Sample development** — Often starts *before* costing is finalized, iteratively: development sample → fit sample → size set → proto, then after order confirmation, PP (pre-production) sample and TOP (top-of-production) sample, and finally shipment sample. Buyers frequently reject and request revisions; rejection is common and must be tracked, not overwritten.
5. **Quotation** — Formal price offer to buyer referencing a costing version. Buyers negotiate; multiple quotation revisions per inquiry are normal.
6. **Order / PO** — Buyer issues a Purchase Order (their own PO number/format) once price, sample, and terms are agreed. A single buyer PO can and often does cover multiple styles/colors/sizes. The buying house raises its own internal order record referencing the buyer PO, which may itself be split across multiple factories.
7. **T&A / Critical path** — The single most operationally important internal tool. A time-and-action calendar works backward from the shipment date through all milestones (fabric booking, fabric in-house, lab dip approval, trim approval, PP meeting, PP sample approval, cutting, sewing, finishing, inspection, packing, ex-factory). Every delay anywhere cascades; this is why automatic overdue/delay detection has outsized value.
8. **Production follow-up** — Buying house staff (often resident in or near the factory) monitor daily cutting/sewing/finishing/packing quantities against plan. This is externally observed progress, not the factory's internal ERP data — expect manual daily updates, not system integration, in v1.
9. **Quality** — Inline, midline, and final inspections (commonly to AQL 2.5-type sampling standards used industry-wide, buyer-specific variations apply) before shipment. Buyer or third-party inspection agencies (e.g., independent QC firms) are often involved for final inspection sign-off, separate from the buying house's own QC.
10. **Buyer approvals** — A distinct, recurring gate that touches almost every stage above: lab dip, strike-off, trim, PP sample, and final inspection all require explicit buyer sign-off, each with its own approve/reject/revise cycle and history. This is modeled as a cross-cutting approval engine, not stage-specific flags.
11. **Shipment** — Once goods pass final inspection, cartons are packed, documents prepared, and the shipment is booked with a freight forwarder/shipping line. Partial and short shipments are common and must be explicitly authorized, not silently allowed.
12. **Commercial / documentation** — Commercial invoice, packing list, bill of lading/airway bill, certificate of origin, and (where relevant) test/inspection certificates are prepared and submitted — frequently against a Letter of Credit (L/C) or negotiated with the buyer's bank, which is why document version/status tracking matters commercially, not just administratively.
13. **Payment / settlement** — Buyer payment (per agreed payment term — L/C, TT, open account) is tracked against the shipment/invoice; buying-house commission or margin is realized once the deal settles. Factory payment (where the buying house handles it) is tracked separately as a payable.
14. **Post-order analysis** — Margin realized vs. quoted, on-time delivery performance, factory and buyer performance history feed back into future costing and factory-selection decisions.

## 2.3 Realities the Idealized Flow Misses (addressed in Gap Analysis, Doc 4)

- **Non-linearity**: Sampling and costing iterate in parallel, not strictly sequentially; an order can be confirmed with sampling still in progress (PP sample, TOP sample happen post-order).
- **Rework and rejection loops**: Sample rejection, lab dip rejection, and inspection failure all create rework cycles that must preserve history rather than being modeled as a single mutable status field.
- **Amendments are routine, not exceptional**: Buyers frequently amend quantity, price, ship date, or destination after order confirmation — this must be a first-class, audited transaction type, not an edit.
- **Partial/split shipments and multi-factory orders**: A single buyer PO is commonly split across factories or shipped in multiple partial lots; the data model must support PO → multiple internal orders → multiple shipments as a many-to-many-over-time relationship, not 1:1:1.
- **Claims and disputes**: Buyer short-shipment/quality claims and chargebacks happen after shipment and must be trackable against the order/shipment without altering the original commercial record.
- **Informal-to-formal lag**: Real communication (WhatsApp, email, phone) precedes formal system entry. The activity/communication log (Document 20/21 area) must support retroactive logging, not assume real-time capture.
