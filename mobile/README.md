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

## What's implemented (Phase 1 / P1-T6 only)

- App shell: `main.dart`, Riverpod `ProviderScope`, `go_router` with an
  auth-state-driven redirect (`core/router/app_router.dart`)
- Networking: two Dio instances — unauthenticated (`rawDioProvider`, used only
  by the auth feature) and authenticated (`apiDioProvider`, attaches the
  in-memory access token) — per Doc 12.4/12.5
- Auth feature end-to-end: login screen, `AuthController` (login/refresh/logout,
  session restore on launch), refresh token in `flutter_secure_storage`
  (Android Keystore-backed), access token kept in memory only
- Shared `LoadingView` / `EmptyStateView` / `ErrorStateView` widgets (Doc 7 #97-99)
- `Failure` type + Dio-error-to-Failure mapper (Doc 12.7) matching the
  backend's RFC 7807 Problem Details shape (Doc 11.3/11.4)

## What's deliberately NOT here yet

Every other feature module (buyers, factories, styles, orders, T&A, …) per
Document 7's screen inventory — those land in their respective roadmap phases
(Document 20), each following the same `presentation/application/domain/data`
structure already established in `features/auth/`.

## Known risk

The offline-tiered strategy (Doc 12.5: cached / draftable-and-synced /
online-only) and the outbox sync mechanism are **not implemented yet** — this
shell only covers the online-only auth flow. Build that out when the first
feature needing offline support (likely Production Follow-up, Phase 8) lands,
per Doc 12.5's generic `(entity_type, payload_json, idempotency_key, status)`
outbox recommendation.
