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

## What's deliberately NOT here yet

Everything past Phase 7 per Document 7's screen inventory (quality, shipment,
financial, claims, tasks, dashboard, …) — those land in their respective
roadmap phases (Document 20), each following the same
`presentation/application/domain/data` structure already established.

Gaps within what IS covered:
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
  a shared widget here rather than a one-off per screen.
- Costing/Quotation foreign keys (styleId, inquiryId, buyerId, costingId) are
  entered as raw numeric ID fields, same as every other cross-module
  reference in this app so far (Doc 12.2's `presentation/application/domain/
  data` shape doesn't yet include a shared picker widget) — a lookup/search
  picker is a UI-polish item for a later pass, not a correctness gap.

## Known risk

The offline-tiered strategy (Doc 12.5: cached / draftable-and-synced /
online-only) and the outbox sync mechanism are **not implemented yet** — this
shell only covers the online-only auth flow. Build that out when the first
feature needing offline support (likely Production Follow-up, Phase 8) lands,
per Doc 12.5's generic `(entity_type, payload_json, idempotency_key, status)`
outbox recommendation.
