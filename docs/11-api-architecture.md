# Document 11 — API Architecture

**Stack**: Spring Boot (Java/Kotlin), PostgreSQL, REST + JSON. Assumed per prompt §33; no evidence requiring deviation (see ADR Doc 18 for comparison).

## 11.1 Layering
```
Controller (DTO in/out, validation annotations) 
   → Service (business rules, transaction boundary, Doc 9 rules enforced here)
      → Repository (Spring Data JPA, domain entities)
         → PostgreSQL
```
- **DTOs only at the controller boundary** — domain entities never serialize directly to JSON (prevents accidental exposure of internal fields, lazy-loading issues, and couples API contract changes to a conscious DTO edit rather than an entity edit).
- **Service layer owns transaction boundaries** (`@Transactional`) and all Document 9 business rules — controllers contain no business logic.
- **Mapping** via a dedicated mapper layer (MapStruct or manual) — includes field-level masking (e.g., strip `costing.margin_percent` for roles without `COSTING_VIEW_MARGIN`, per Doc 5) at the mapper, not scattered across controllers.

## 11.2 Resource Structure (representative, versioned under `/api/v1`)
```
/api/v1/auth/login, /refresh, /logout
/api/v1/users, /roles, /permissions, /assignments
/api/v1/buyers, /buyers/{id}/contacts, /buyers/{id}/requirements, /buyers/{id}/activities
/api/v1/factories, /factories/{id}/contacts, /factories/{id}/certifications, /factories/{id}/buyer-approvals
/api/v1/inquiries, /inquiries/{id}/factory-candidates
/api/v1/styles, /styles/{id}/revisions
/api/v1/samples, /samples/{id}/revisions
/api/v1/costings, /costings/{id}/items
/api/v1/quotations
/api/v1/orders, /orders/{id}/items, /orders/{id}/amendments, /orders/{id}/split
/api/v1/orders/{id}/ta-milestones, /ta-templates
/api/v1/orders/{id}/production-updates
/api/v1/inspections, /inspections/{id}/defects, /capa-records
/api/v1/approvals, /approvals/{id}/decide
/api/v1/shipments
/api/v1/documents
/api/v1/orders/{id}/financials, /receivables, /payables, /payment-records
/api/v1/claims
/api/v1/activities, /tasks, /notifications
/api/v1/search
/api/v1/reports/{report-key}
/api/v1/audit-logs (restricted)
```

## 11.3 Cross-Cutting API Standards
- **Pagination**: `?page=&size=&sort=` on every list endpoint, default page size capped (e.g., 25, max 100) — never an unbounded list response (NFR-04).
- **Filtering**: query params per documented filterable field per resource (e.g., `/orders?status=IN_PROGRESS&buyerId=12`).
- **Consistent error shape**: `{ "timestamp", "status", "error", "message", "path", "fieldErrors": [...] }` via a global `@ControllerAdvice` exception handler — no raw stack traces returned to client.
- **Validation**: Bean Validation (`@NotNull`, `@Positive`, custom validators for business constraints like currency code format) at DTO level; business-rule validation (Doc 9) at service level returning typed error codes the Flutter app can map to messages.
- **Idempotency**: mutation endpoints that may be retried by a flaky mobile connection (order creation, production update submission) accept an optional `Idempotency-Key` header; server deduplicates within a time window — directly addresses the "prevent duplicate transactions" requirement from the offline/sync analysis (§25).
- **Optimistic locking**: PUT/PATCH on versioned entities require `version` in the request body; mismatch → HTTP 409 with current server state returned so the client can merge/retry.
- **Authentication**: JWT access token (short-lived, ~15 min) + refresh token (rotating, stored hashed server-side in `sessions`) — see Document 15 for full flow.
- **Authorization**: method-level `@PreAuthorize` checks against permission codes, plus explicit object-level scope checks in service methods using the `assignments` table (Doc 5.3) — never relying on `@PreAuthorize` role name alone for object-scoped resources.
- **Transaction boundaries**: each service method that writes to more than one table (e.g., order amendment: write `order_amendments` + update `orders.current_value`) is one `@Transactional` method — no partial writes possible.
- **API documentation**: springdoc-openapi generating OpenAPI 3 spec from controller annotations, published at `/v3/api-docs` and a Swagger UI restricted to non-production or authenticated internal access.

## 11.4 Recommendation
Use **Problem Details (RFC 7807)** shape (`application/problem+json`) rather than a fully custom error envelope — it is a Spring Boot 3 built-in default, reduces bespoke client-side error-parsing code in Flutter, and is a recognized standard a future integration (ERP, Doc 18 ADR) can rely on without bespoke docs.

## 11.5 Versioning Strategy
URI versioning (`/api/v1/...`) chosen over header versioning for simplicity and debuggability (cURL/Postman-friendly, easier for a small internal team to reason about) — a breaking v2 change gets a new prefix; additive/backward-compatible changes (new optional field) ship within v1 without a version bump.
