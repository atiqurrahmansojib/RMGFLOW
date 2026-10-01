# Document 23 — Consolidated Recommendations

Every explicit "My recommendation" from Documents 9-22, pulled into one place. Source doc noted for each so you can trace context/reasoning.

## Architecture & Stack
- **Flutter confirmed** over native/PWA — no reason found to deviate. (Doc 12, ADR-01)
- **Modular monolith**, not microservices — single org, modest scale, tightly coupled domain. Strongly held. (Doc 18, ADR-02)
- **PostgreSQL only** — don't add Elasticsearch/second datastore pre-emptively. (Doc 18, ADR-03)
- **JWT + rotating refresh token** as designed — right default for this system shape. (Doc 18, ADR-04)
- **Riverpod** for Flutter state management over Bloc/Provider. (Doc 12.3)
- **RFC 7807 Problem Details** error shape instead of fully custom envelope — Spring Boot 3 default, less bespoke client parsing. (Doc 11.4)
- **URI versioning** (`/api/v1/...`) over header versioning. (Doc 11.5)

## Data Model
- **Keep the shared `approvals` table** (ADR-08) despite its FK trade-off — mitigate with the periodic orphan-check job rather than splitting into per-module tables. (Doc 18)
- **Keep both DB trigger AND service-layer guard** on costing immutability — defense in depth is cheap, disputed margin figures years later are expensive. (Doc 18, ADR-14)
- **Treat "order merge" as effectively unsupported** in v1 — expose "link related orders" instead; true merge risks tangling two orders' commercial/shipment history. (Doc 9.4)
- **Schema-ready, not built** for multi-company — the `organization_id` column now is near-zero-cost; don't build multi-org UI/isolation until a second org is actually onboarded. (Doc 18, ADR-10)

## Business Rules
- **Margin floor should be a soft warning, not a hard block** — real negotiations sometimes accept thin/negative margin on strategic orders. (Doc 9.1)
- **Weight T&A progress % by shipment-criticality** of the milestone, not equal weighting — "50% done" is meaningless if the undone half is shipment-blocking. (Doc 9.5)
- **CAPA-must-close-before-milestone-complete should hard-stop only for FINAL inspections**, stay a soft reminder for INLINE/MIDLINE — avoid over-blocking early-stage work. (Doc 9.7)
- **Implement the T&A delay-cascade (A16) carefully**: bounded recursion, full audit trail, always notify every affected responsible user — highest business value in the whole system, also highest risk of surprising users if silent. (Doc 13.1, Doc 18 ADR-13)

## Security
- **Argon2id over bcrypt** for password hashing — stronger modern default, well-supported in current Spring Security. (Doc 15.1)
- **Add virus scanning on file uploads** (e.g., ClamAV in the pipeline) — real risk given how many external parties send files to a buying house, not theoretical. Recommended (C), not a v1 blocker. (Doc 15.4)

## Reporting
- **Rename "Factory Profitability" to "Factory Cost Analysis"** — avoids implying a margin that often doesn't exist on pure pass-through factory CM. (Doc 14.7)
- **Build one cross-module "What needs attention today" endpoint/widget** as the post-login landing view for every operational role — directly answers the prompt's own framing of daily operational value; don't leave users checking five screens each morning. (Doc 14.9)

## Deployment
- **Use managed PostgreSQL** (RDS/Cloud SQL) over self-hosting — cost delta is small versus the risk of a DIY backup process that's "never been restored successfully." (Doc 17.2)

## Integration
- **If ERP integration is pursued**: existing ERP as source of truth for factory/production master data, RMGFlow as source of truth for buyer/merchandising/commercial data, one-directional sync by default. This is a recommendation, not a final decision — needs your input on the existing ERP's actual API surface before it's locked in. (Doc 18, ADR-11)
- **Define the single-source-of-truth-per-entity boundary before writing any integration code**, not organically — ad hoc two-way sync is the most common source of "which system is right" disputes. (Doc 18, ADR-15)

## Scope Discipline
- **Resist scope creep into full accounting** even if requested mid-project without a clear business case. (Doc 18, ADR-12)
- **Don't pre-write exhaustive task breakdowns for Phases 8-13 today** — regenerate each phase's backlog just before it starts, incorporating lessons from Phases 1-7 (e.g., does the approval engine hold up under its 3rd/4th consumer). (Doc 21)

## Sequencing / Rollout
- **Ship Phases 1-7 (through T&A) as the first real release** — don't wait for all 13 phases. A merchandiser with Buyer/Style/Costing/Quotation/Order/T&A already beats Excel/WhatsApp; that's the fastest path to real adoption. (Doc 20)
- **Treat adoption risk (R1), not a technical risk, as the top practical risk** — a technically perfect system nobody uses is worth zero. Prioritize T&A + "What needs attention today" early for visible daily value. (Doc 19)

## Testing
- **Make financial/transactional-logic test coverage a CI release gate**, not optional — directly enforces the "never skip tests for financial logic" rule rather than leaving it to discipline alone. (Doc 16.7)
