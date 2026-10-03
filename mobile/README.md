# RMGFlow Mobile (Flutter)

Android-first client for RMGFlow. See [`/docs/12-flutter-architecture.md`](../docs/12-flutter-architecture.md)
for the full architecture rationale this follows.

## ⚠️ Not yet verified to build

This scaffold was written in an environment **without the Flutter SDK installed**,
so none of it has been run through `flutter pub get`, `flutter analyze`, or
`flutter run`. Treat it as a reviewed-on-paper starting point, not working
software, until you've done the following locally:

```bash
# 1. Generate the native platform folders (android/, ios/, etc.) — these are
#    intentionally not committed from this environment (see .gitignore) since
#    they can't be verified without the SDK. This also writes a fresh
#    pubspec.yaml; immediately re-check it against the one in this repo and
#    re-apply the dependencies block below if `flutter create` overwrote it.
flutter create --project-name rmgflow_mobile --org com.rmgflow .

# 2. Install dependencies
flutter pub get

# 3. Static analysis — fix anything flagged before trusting the code compiles
flutter analyze

# 4. Run against the backend (see ../backend/README.md to start it locally)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

`10.0.2.2` is the Android emulator's alias for the host machine's `localhost`;
use the backend's real LAN/deployed URL for a physical device or non-emulator setup.

## What's implemented

**Phase 1 (P1-T6) — app shell:**
- `main.dart`, Riverpod `ProviderScope`, `go_router` with an auth-state-driven
  redirect (`core/router/app_router.dart`)
- Networking: two Dio instances — unauthenticated (`rawDioProvider`, used only
  by the auth feature) and authenticated (`apiDioProvider`, attaches the
  in-memory access token) — per Doc 12.4/12.5
- Auth feature end-to-end: login screen, `AuthController` (login/refresh/logout,
  session restore on launch, and `callAuthorized` — wraps a repository call,
  retries once after a silent refresh on 401), refresh token in
  `flutter_secure_storage` (Android Keystore-backed), access token in memory only
- Shared `LoadingView` / `EmptyStateView` / `ErrorStateView` widgets (Doc 7 #97-99)
- `Failure` type + Dio-error-to-Failure mapper (Doc 12.7) matching the
  backend's RFC 7807 Problem Details shape (Doc 11.3/11.4)

**Phase 2 — Master Data (buyers, factories):**
- `features/buyers/`: list (search), create/edit form sharing one screen
  (Doc 7 #16-18), optimistic-lock-aware (`version` round-trips on edit, a
  409 is surfaced via the Failure/SnackBar path)
- `features/factories/`: list (filterable by partner type), create/edit form
  (Doc 7 #20-22)
- Both follow the same `domain/data/application/presentation` structure as
  `features/auth/` (Doc 12.2) — a new feature's shape should look identical
**Phase 3 — Inquiry & Product Development:**
- `features/inquiries/`: list (filterable by status), create/edit form, and a
  status-change dialog offering the full `InquiryStatus` enum (Doc 7 #24-27) —
  the backend's state machine (Doc 10.1) is the real enforcement; an invalid
  transition picked here just surfaces as a 400 via the Failure/SnackBar path
- `features/styles/`: list (search by style no.) and a create-only form
  (Doc 7 #28-30) — see "What's deliberately NOT here yet" for the revision gap
- `HomeScreen` now links all four modules built so far

**Phase 4 — Costing, Quotation, Approval Engine:**
- `features/costing/`: list (filterable by style), itemized cost-entry form
  (one row per `CostingComponentType`, Doc 7 #38) shared between create/
  edit-draft/revise, and a detail screen showing the server-computed
  `totalCost`/`marginPercent` (Doc 9.1 — never recomputed client-side) plus
  the legal next action for the costing's current status (edit draft, submit
  for approval, or create a new version once APPROVED/SUPERSEDED)
- `features/quotation/`: list (filterable by buyer), create/revise form, and
  a detail screen with a status-change action strip (Doc 7 #42) — the backend
  enforces which status transitions are legal and that a quotation requires
  an APPROVED costing; invalid attempts surface as a 400 via Failure/SnackBar
- `features/approval/`: the **generic** Approval Engine UI (Doc ADR-08) — one
  Pending Approvals Inbox (#67) across every `ApprovalTargetType`, one
  Approval Detail/Action screen (#68, approve/reject/return with comments/
  rejection reason), and one history screen, all driven by the shared
  `/api/v1/approvals` endpoints. Costing and Quotation detail screens link
  into the history screen rather than duplicating approval UI; as later
  phases add Sample Revision/Lab Dip/Trim/PP Sample/Inspection/Shipment/
  Document approval gates, they reuse this same feature instead of building
  their own approve/reject screen.

**Phase 5 — Sampling:**
- `features/sample/`: list (filterable by the derived `SampleStatus` rollup,
  Doc 8.4), create-only request form (no edit endpoint exists server-side —
  Doc 9.3's invariant is "a rejected revision is never edited, only
  superseded"), and a detail screen with the append-only revision history,
  an "add revision" dialog (the backend auto-submits each new revision to
  the shared Approval Engine — no separate submit step here), a "sync status
  from latest approval" action (Doc 10.5, rolls a decided round's outcome
  onto the sample), and a link into the generic approval-history screen for
  the latest revision
- `HomeScreen` now links all six modules built through Phase 5

**Phase 6 — Orders & T&A:**
- `features/order/`: list (filterable by buyer/status), itemized create form
  (style/factory/color/size lines, Doc 7 #48-49) with an
  `overrideFactoryApproval` toggle for the Doc 9.4 gate (server-side is the
  real authorization check — a 400 for anyone lacking
  `ORDER_OVERRIDE_FACTORY_APPROVAL` surfaces the same as any other
  validation error), a detail screen with cancel/amendments/T&A-calendar
  entry points, and `OrderAmendmentsScreen` (request + approve/reject, Doc
  9.6 — every confirmed-order field change is a recorded, decided amendment,
  never a silent edit)
- `features/ta/`: the order's T&A calendar (Doc 7 #54-58) — status chips show
  the server-DERIVED status (Doc 9.5: DONE/BLOCKED/CRITICAL_DELAY/OVERDUE/
  DUE_TODAY/UPCOMING/PENDING, never recomputed on-device), tapping an
  un-completed milestone records its actual date (prompting for a delay
  reason when it's late — the backend's delay-cascade automation, Doc A16,
  then pushes every dependent milestone's revised date and this screen just
  reflects what comes back on refresh), and a manual "generate from
  template" action for templates added/corrected after order confirmation
- `HomeScreen` now links all seven modules built through Phase 6

**Phase 7 — Production Follow-up:**
- `features/production/`: a per-order progress screen (Doc 7 #52-53) showing
  the server's cumulative cutting/sewing/finishing/packing/rejection/
  alteration rollup and packing-progress percentage (Doc 9.6/14.4 — always
  computed from daily updates, never summed client-side) plus the full daily
  history, and a daily-update entry form; the packing-never-exceeds-order-
  quantity hard block (Doc 9.11 #5, no override exists) is enforced
  server-side and surfaces as a plain validation Failure here. Reached from
  `OrderDetailScreen` (order-scoped, no standalone top-level list)

**Phase 8 — Quality:**
- `features/quality/`: inspection history per order (inline/midline/final,
  Doc 7 #59-60) with a create form; defects logged per inspection (#60-61)
  via an add-defect dialog; CAPA records per defect (#63-64/Doc 9.9) with the
  full create → factory-response → close lifecycle. The shipment quality
  gate (Doc 9.7/9.8 — a FAIL/REINSPECT final inspection blocks shipment
  unless overridden by a permitted user) is enforced entirely server-side in
  the shipment module; this feature only records inspection/defect/CAPA data.
  Reached from `OrderDetailScreen`.

**Phase 9 — Shipment & Commercial Documents:**
- `features/shipment/`: one order's shipments including partials (Doc 7
  #65), a create form with a quality-gate override toggle (Doc 9.7/9.8 — the
  shipment-never-exceeds-order-quantity gate, Doc 9.11 #5, has NO override
  and is purely server-enforced), and a detail screen with a status-change
  action strip (BOOKED/IN_TRANSIT/DELIVERED/DELAYED)
- `features/document/`: the **generic** versioned Commercial Document UI
  (Doc 8.9/10.4) — one list+upload+approve screen reused for every
  `DocumentEntityType` (order/shipment/factory/style) via a typed
  `(entityType, entityId)` key, the same reuse pattern as the Phase 4
  approval feature. Upload takes a raw attachment ID (no file-picker/upload
  screen exists yet — see the Attachments gap below) since a
  `CommercialDocument` always wraps an already-uploaded `Attachment`.
  Reached from `OrderDetailScreen` (order docs) and `ShipmentDetailScreen`
  (shipment docs).

**Phase 10 — Financial Tracking & Claims:**
- `features/financial/`: one order's financial screen (Doc 7 #70-72) —
  margin (Doc 9.10: estimate vs realized, `isEstimate` flagging which basis
  the server used; the percentage itself is never computed client-side),
  receivables and payables with their server-derived status strings, and a
  record-payment dialog on each (Doc 9.12 — atomic write + balance update
  server-side)
- `features/claim/`: claims raised against an order, buyer or internal (Doc
  7 #73-74), tracked through to resolution. Doc 6.3's isolation — ClaimService
  never mutates Order/Shipment state — means this feature is purely tracking,
  with no cross-feature side effects to worry about
- Both reached from `OrderDetailScreen`

**Phase 11 — Communication, Tasks, Notifications, Dashboards:**
- `features/activity/`: a generic communication/activity log (call/email/
  meeting/note, Doc 7 #89-91) reused across every module via a plain
  `(entityType, entityId)` key, the same reuse pattern as Phase 4's approval
  feature and Phase 9's document feature. Wired into `OrderDetailScreen`;
  any future module can reuse the same screen by passing its own entity key.
- `features/task/`: tasks are ALWAYS entity-attached, never free-floating
  (Doc 21) — one screen serves both "My Open Tasks" (`target == null`,
  reached from `HomeScreen`) and "tasks for this entity" (reached from
  `OrderDetailScreen`), backed by the same two repository methods the
  backend exposes.
- `features/notification/`: the in-app notification feed (Doc 7 #88) — the
  dispatch sink for automation jobs like the T&A overdue scan (Doc 13 A2).
  Tapping an unread notification marks it read.
- `features/dashboard/`: the "My Day" screen (Doc 14.9) — the recommended
  post-login landing view, aggregating overdue T&A milestones, the
  organization's pending approvals, and the user's overdue tasks from one
  endpoint. Reached via an app-bar icon on `HomeScreen` rather than replacing
  it as the literal landing route, so the full module grid stays one tap away.

This completes mobile coverage for all 11 implementable phases of
`docs/20-implementation-roadmap.md` (Phase 12/"Hardening" has no UI
surface of its own). Every module built in Phases 1-11 now has a
corresponding screen.

## What's deliberately NOT here yet

Every module built in Phases 1-11 now has a corresponding screen (Phase
12/"Hardening" has no UI surface of its own). Remaining gaps are all
polish items within what IS covered, not missing modules:

- Buyer contacts/requirements and factory contacts/capabilities/
  certifications/buyer-approvals sub-resources — the backend supports all of
  them (Phase 2 P2-T3/T5), but the mobile UI only covers the parent Buyer/
  Factory CRUD so far.
- Inquiry factory candidates (Doc 7's "Factory Candidates" tab) — backend
  endpoints exist, no mobile screen yet.
- Style revisions (Doc 7 #31 "Revision Compare View") and style editing — the
  mobile Style form is create-only; the backend's revision endpoints
  (append-only, Doc FR-31) have no UI yet at all.
- Attachments (Doc 7's generic upload component, #100) — the backend module
  is built and tested (upload/signed-download/tenant-isolation), but no
  mobile screen calls it yet; the first feature that needs it (tech pack
  upload on styles, or Doc 12.7's camera-first attachment picker) should add
  a shared widget here rather than a one-off per screen. The Commercial
  Document upload dialog (Phase 9) takes a raw attachment ID for the same reason.
- Cross-module foreign keys (styleId, buyerId, factoryId, costingId, …) are
  entered as raw numeric ID fields throughout, same as every cross-module
  reference in this app (Doc 12.2's `presentation/application/domain/data`
  shape doesn't yet include a shared picker widget) — a lookup/search picker
  is a UI-polish item for a later pass, not a correctness gap.
- The Activity and Task features (Phase 11) are wired into `OrderDetailScreen`
  only so far; the backend supports attaching either to any entity type, so
  wiring the same screens into Buyer/Factory/Shipment/etc. detail screens is
  a follow-up, not a backend gap.

## Known risk

The offline-tiered strategy (Doc 12.5: cached / draftable-and-synced /
online-only) and the outbox sync mechanism are **not implemented** — every
feature through Phase 11, including Production Follow-up (daily updates
entered on a factory floor, the case Doc 12.5 specifically calls out), is
online-only. Build the outbox out per Doc 12.5's generic
`(entity_type, payload_json, idempotency_key, status)` recommendation before
relying on this app somewhere connectivity isn't guaranteed.
