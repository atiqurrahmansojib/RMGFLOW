# Document 12 — Flutter Architecture

## 12.1 Technology Recommendation (Flutter vs Native vs PWA)

| Criterion | Flutter | Native Android (Kotlin) | PWA |
|---|---|---|---|
| Dev speed for one team | High | Medium | High |
| Camera/offline/storage access | Good (plugins) | Best | Weak (browser sandboxing) |
| Push notifications | Good (FCM plugin) | Best | Weak/unreliable on Android background |
| Offline DB (SQLite/drift) | Good | Best | Weak |
| Low-bandwidth asset control | Good | Best | Medium |
| Future iOS option | Free (same codebase) | None (separate build) | Free but weaker overall |
| Matches prompt's stated assumption (§24) | Yes | — | — |

**Recommendation: Flutter**, confirming the prompt's default assumption (§24) — no evidence in this domain (camera capture, document upload, moderate offline needs, push notifications, single small internal dev team) justifies the added cost of native Android, and PWA's weaker background push/offline/camera story is a poor fit for factory-floor and low-connectivity field use (§24/§25). Revisit only if iOS is explicitly never needed AND the team has strong existing native Android expertise — neither is indicated here.

## 12.2 Feature-Based Architecture
```
lib/
  core/            -- theming, routing, networking (dio client, interceptors), error handling, constants
  common/          -- shared widgets (status badge, empty state, error state, offline banner, attachment picker)
  features/
    auth/
    buyers/
    factories/
    inquiries/
    styles/
    samples/
    costing/
    quotations/
    orders/
      presentation/  -- screens, widgets
      application/   -- state notifiers/controllers
      domain/        -- entities, repository interfaces
      data/          -- repository impl, API client, local cache (drift/sqflite)
    ta/
    production/
    quality/
    approvals/
    shipments/
    documents/
    financial/
    claims/
    activities/
    tasks/
    notifications/
    dashboards/
    reports/
    search/
```
Each feature follows the same four-layer split (presentation/application/domain/data) — consistent, predictable structure across ~25 features avoids the "giant monolithic Flutter codebase" the prompt explicitly warns against (§34).

## 12.3 State Management
**Recommendation: Riverpod** (over Bloc or plain Provider) — scoped, testable, good async/family-provider support for per-entity-id detail screens (e.g., `orderDetailProvider(orderId)`), less boilerplate than Bloc for a team shipping ~25 features, and strong offline-cache + optimistic-update composability needed here.

## 12.4 Networking & Auth
- `dio` HTTP client with interceptors: auth header injection, automatic refresh-token retry on 401, request/response logging gated to debug builds only.
- Access token held in memory; refresh token in `flutter_secure_storage` (Android Keystore-backed) — never SharedPreferences (plaintext-adjacent) for tokens (NFR-09, Doc 15).

## 12.5 Offline Cache & Sync Strategy
Per Document "Offline-First Analysis" (prompt §25), a strict split:

**Cached for offline viewing** (read-through local `drift` SQLite cache, refreshed on each successful fetch): buyer/style/order summaries, T&A milestone lists, recent activity.

**Draftable offline, synced when online** (written to a local outbox table, flagged `pending_sync`, pushed via idempotency-keyed requests on reconnect): follow-up notes/activities, production update entries, inspection draft entries, photo captures awaiting upload.

**Online-only, hard-blocked offline** (UI disables the action with an explicit "requires connection" state, never queues it): costing/quotation approval finalization, order confirmation/amendment/cancellation, shipment authorization, payment recording, any approval decision.

**Recommendation**: implement the outbox as a generic `(entity_type, payload_json, idempotency_key, status)` table rather than one bespoke queue per feature — mirrors the backend's polymorphic `approvals`/`activities` pattern (Doc 6/8) and keeps sync logic in one reusable service instead of duplicated per module.

## 12.6 Conflict Handling
On sync, a 409 (optimistic lock mismatch, Doc 11.3) surfaces a merge screen showing server vs. local draft value for the specific changed field — never silently overwrites either side.

## 12.7 Other Cross-Cutting Concerns
- **Error handling**: a sealed `Failure` type (network, validation, auth, server, unknown) mapped from API error shape (Doc 11.3) to user-facing messages via a single mapper, not per-screen try/catch duplication.
- **Loading/empty states**: shared widgets (`LoadingView`, `EmptyStateView`, `ErrorStateView`) used by every list/detail screen (Doc 7 §97-99) — not reimplemented per feature.
- **Form validation**: shared `FormX` wrapper using `reactive_forms` or manual `Form`/`TextFormField` validators mirroring backend Bean Validation rules (duplicated intentionally for UX responsiveness, never the authoritative check — Doc 11.3 backend validation remains final).
- **File uploads**: chunked/resumable upload for larger attachments (tech packs, inspection photo sets) over weak networks; client-side image compression before upload (NFR-04).
- **Push notifications**: Firebase Cloud Messaging; deep link from notification payload to the relevant entity detail screen via named routes (`go_router`).
- **Deep links**: supported for notification-driven navigation and potential future web admin companion; not a priority for v1 beyond that.
