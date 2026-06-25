# Deep Audit — AniMAL

**Date:** 2026-06-25  
**Flutter version:** 3.44.3 (stable)  
**Dart version:** 3.12.2  
**flutter analyze:** 0 errors, 0 warnings, **51 info**  
**flutter test:** 1 test, **1 passed, 0 failed**  
**dart format lib/:** clean (0 changed)

---

## Executive Summary

The previous audit (2026-06-24) claimed all HIGH/MEDIUM/LOW findings were resolved and all tests passed. This re-audit found that **the widget test was failing** and several of the previously claimed fixes were either not present or had regressed. A first round of robustness fixes has been applied; the widget test now passes and the highest-priority security/race issues are resolved. The domain-layer architecture gap remains a larger refactor for a future pass.

| Severity | Previous Claim | After Round 1 Fixes | Remaining |
|----------|----------------|---------------------|-----------|
| CRITICAL | 0 | 0 | 0 |
| HIGH     | 4 | 3 | 1 |
| MEDIUM   | 7 | 5 | 2 |
| LOW      | 5 | 5 | 0 |
| INFO     | 55 | — | 51 |
| Dead code | 4 | 4 | 0 |

---

## Fixes Applied (Post-Audit Round 1)

### HIGH

#### H1. Widget test now overrides `notificationServiceProvider`
- **File:** `test/widget_test.dart`
- Wrapped `App` in a `ProviderScope` that overrides `notificationServiceProvider` with a plain `AnimeNotificationService()` instance so `_initNotificationListener` no longer throws `UnimplementedError`.

#### H2. OAuth PKCE now uses `S256`
- **File:** `lib/features/auth/data/repositories/mal_auth_repository.dart`
- Added `package:crypto` dependency.
- `_deriveCodeChallenge` computes `base64Url(sha256(codeVerifier))` with padding stripped.
- Authorization URL now sends `'code_challenge_method': 'S256'`.

#### H3. `AuthInterceptor` refresh-token race condition fixed
- **File:** `lib/core/network/auth_interceptor.dart`
- `_refreshFuture` is now nulled in a `finally` block after the refresh completes, so concurrent 401s share a single refresh request.

### MEDIUM

#### M1. `MemoryCache` now has periodic cleanup
- **File:** `lib/data/local/memory_cache.dart`
- Added optional `Timer.periodic(Duration(seconds: 30), …)` constructor parameter (enabled by default).
- Added `dispose()` to cancel the timer.

#### M2. `_NotificationBell` uses `select`
- **File:** `lib/features/detail/presentation/screens/anime_detail_page.dart`
- Replaced `ref.watch(animeNotificationProvider).contains(animeId)` with `ref.watch(animeNotificationProvider.select((s) => s.contains(animeId)))` to avoid rebuilding when unrelated notifications change.

#### M3. Discarded futures in `lib/app.dart` addressed
- **File:** `lib/app.dart`
- `StreamSubscription.cancel()` calls and the `GoRouter.pushNamed` call are now wrapped in `unawaited(...)` to satisfy `discarded_futures` and surface async errors.

#### M4. OAuth `state` parameter added and validated
- **Files:** `lib/features/auth/data/repositories/mal_auth_repository.dart`, `lib/core/storage/secure_token_storage.dart`, `lib/core/router/app_router.dart`, `lib/app.dart`, `lib/features/auth/presentation/oauth_callback_page.dart`
- `buildAuthorizationUrl` generates a cryptographically random `state` and persists it via `SecureTokenStorage`.
- Deep-link handler forwards the returned `state` to the callback route.
- `OAuthCallbackPage` validates the returned state against the stored state before exchanging the code and clears the stored state on success.

#### M7. Year picker width fixed
- **File:** `lib/features/seasonal/presentation/screens/anime_schedule_page.dart`
- Replaced `width: double.minPositive` with `width: double.maxFinite`.

### LOW

#### L1, L2. Dead code removed
- **Files:** `lib/core/utils/date_utils.dart`, `lib/features/seasonal/providers/seasonal_providers.dart`
- Removed unused `formatCountdown`, `isUrgentCountdown`, `currentSeasonProvider`, and `currentAnimeScheduleProvider`.

#### L5. `AnimeHomeTab._loadPrefs` guards `setState` with `mounted`
- **File:** `lib/features/home/presentation/widgets/anime_home_tab.dart`

---

## AGENTS.md Compliance Matrix

| Rule | Status | Notes |
|------|--------|-------|
| Feature isolation | **PASS** | No feature imports another feature; core/router imports feature pages as expected. |
| `@freezed` in `data/models` only | **PARTIAL** | MAL DTOs are freezed. AniList models in `data/models/anilist/anilist_models.dart` are plain Dart (not generated from JSON). |
| Domain entities / use cases / abstract repos | **FAIL** | No `features/*/domain/entities/`, no `get_*.dart` use cases, no `abstract interface class` repositories. `AnimeRepository` and `AiringRepository` live in `shared/providers/`. |
| Logger: only `appLogger` | **PASS** | Only `app_logger.dart` constructs `Logger()`. |
| Colors in `app_colors.dart` | **PASS** | No raw `Colors.*`; all colors use `AppColors.*`. |
| API endpoints & GraphQL queries in constants | **PASS** | MAL endpoints and AniList queries are centralized. |
| Cache all API calls | **PASS** | MAL/AniList calls go through cached repositories; TTL values match the spec. |
| `*_page.dart` screens | **PASS** | All screens follow the convention. |
| `*_providers.dart` naming | **PARTIAL** | `lib/shared/providers/airing_entry.dart` still mixes entity/repository/providers and does not end with `_providers.dart`. |
| Import ordering (`directives_ordering`) | **PASS** | No lint violations. |
| Search debounce 300 ms | **PASS** | Implemented in `search_providers.dart`. |
| `ListView.builder` / `SliverChildBuilderDelegate` | **PASS** | Long lists use builders. |
| TabBar `isScrollable: true` | **PASS** | Multi-tab bars are scrollable. |

---

## Findings

### HIGH

#### H1. Widget test fails because `notificationServiceProvider` is not overridden
- **Severity:** HIGH
- **Files:**
  - `test/widget_test.dart:14`
  - `lib/app.dart:61`
  - `lib/core/providers.dart:34-38`
- **Description:** `App._initNotificationListener()` calls `ref.read(notificationServiceProvider)` during `initState`. The provider is declared with a `throw UnimplementedError` and is only overridden in `main.dart`. The test only wraps `App` in a plain `ProviderScope`, so pumping the widget throws `UnimplementedError` and the test fails.
- **Evidence:**
  ```dart
  // lib/core/providers.dart:34-38
  final notificationServiceProvider = Provider<AnimeNotificationService>(
    (ref) => throw UnimplementedError(
      'Override this provider in main.dart with the initialized instance',
    ),
  );
  ```
  Test output:
  ```
  Tried to use a provider that is in error state.
  UnimplementedError: Override this provider in main.dart ...
  ```
- **Impact:** CI is broken; the previous audit’s claim that "all tests passed" no longer holds.
- **Recommended fix:** Provide a test override for `notificationServiceProvider` (e.g. a mock or the real initialized service) in `test/widget_test.dart`, or make `_initNotificationListener` tolerate a missing override.
- **Status:** **Resolved in Round 1** — `test/widget_test.dart` now overrides the provider with a plain `AnimeNotificationService()`.
- **Status vs. existing AUDIT.md:** **New / regression.**

#### H2. OAuth PKCE uses `plain` code challenge method
- **Severity:** HIGH
- **File:** `lib/features/auth/data/repositories/mal_auth_repository.dart:40`
- **Description:** The authorization URL sends `'code_challenge_method': 'plain'`. MAL supports `S256`. With `plain`, an attacker who intercepts the authorization response can exchange the code because the verifier is effectively exposed in the challenge.
- **Evidence:**
  ```dart
  return Uri.parse(Env.malAuthUrl).replace(
    queryParameters: {
      ...
      'code_challenge': codeVerifier,
      'code_challenge_method': 'plain',
    },
  );
  ```
- **Impact:** Degrades the security benefit of PKCE, increasing the risk of authorization-code interception attacks.
- **Recommended fix:** Compute `code_challenge` as `base64Url(sha256(codeVerifier))` and set `'code_challenge_method': 'S256'`.
- **Status vs. existing AUDIT.md:** **Already present / not fixed.**

#### H3. `AuthInterceptor` token-refresh logic has a race condition
- **Severity:** HIGH
- **File:** `lib/core/network/auth_interceptor.dart:42-44`
- **Description:** When multiple 401 responses arrive concurrently, the shared `_refreshFuture` is assigned and immediately nulled by each racing interceptor, so more than one refresh request can be issued.
- **Evidence:**
  ```dart
  _refreshFuture ??= _refreshToken();
  final future = _refreshFuture!;
  _refreshFuture = null;
  final refreshed = await future;
  ```
- **Impact:** Duplicate refresh requests can invalidate each other on backends that rotate refresh tokens, potentially logging the user out.
- **Recommended fix:** Keep `_refreshFuture` assigned until the refresh completes (clear it in a `finally` block) and reuse the same future for all concurrent callers.
- **Status vs. existing AUDIT.md:** **Already present / not fixed.**

#### H4. Architecture does not follow `AGENTS.md` layer contract
- **Severity:** HIGH
- **Files:**
  - `lib/shared/providers/anime_providers.dart` (`AnimeRepository`)
  - `lib/shared/providers/airing_entry.dart` (`AiringEntry` entity + `AiringRepository`)
  - `lib/features/auth/data/repositories/mal_auth_repository.dart`
- **Description:** The codebase has no domain layer: no plain entity classes under `features/*/domain/entities/`, no `abstract interface class` repositories, and no `get_*.dart` use cases. Repositories are implemented directly inside provider files, and features consume them via `shared/providers/`. The previous audit noted this as "PARTIAL" but no remediation has been made.
- **Impact:** Business logic is tightly coupled to providers and Riverpod, making unit testing, feature isolation, and future refactors harder.
- **Recommended fix:** Introduce per-feature `domain/entities/`, `domain/repositories/` (abstract), `domain/usecases/get_*.dart`, and `data/` implementations.
- **Status vs. existing AUDIT.md:** **Already present / not fixed.**

---

### MEDIUM

#### M1. `MemoryCache` lacks periodic cleanup timer
- **Severity:** MEDIUM
- **File:** `lib/data/local/memory_cache.dart:1-74`
- **Description:** The previous audit claimed a periodic 30-second cleanup `Timer` was added (L7). The current file only evicts expired entries every 50 `put` calls. There is no `Timer`.
- **Evidence:**
  ```dart
  static const _cleanupInterval = 50;
  ...
  if (_putCount % _cleanupInterval == 0) {
    _evictExpired();
  }
  ```
- **Impact:** In low-write scenarios, stale entries can persist indefinitely, and memory can grow if keys are highly dynamic.
- **Recommended fix:** Add a constructor-managed `Timer.periodic` and a `dispose()` method; wire it into `ProviderScope` disposal if needed.
- **Status vs. existing AUDIT.md:** **Claimed resolved but not implemented.**

#### M2. `_NotificationBell` watches the whole notification set
- **Severity:** MEDIUM
- **File:** `lib/features/detail/presentation/screens/anime_detail_page.dart:1585`
- **Description:** The detail-page notification bell uses `ref.watch(animeNotificationProvider).contains(animeId)` instead of `select`.
- **Evidence:**
  ```dart
  final enabled = ref.watch(animeNotificationProvider).contains(animeId);
  ```
- **Impact:** Toggling a notification for any anime rebuilds every open detail page that has a bell.
- **Recommended fix:** Use `ref.watch(animeNotificationProvider.select((s) => s.contains(animeId)))`.
- **Status vs. existing AUDIT.md:** **Already present / not fixed.**

#### M3. Discarded futures in `lib/app.dart`
- **Severity:** MEDIUM
- **File:** `lib/app.dart:31, 32, 73`
- **Description:** `flutter analyze` reports three `discarded_futures` infos. Line 73 discards the `Future` returned by `GoRouter.pushNamed` inside `addPostFrameCallback`, so async errors are silently lost.
- **Evidence:**
  ```dart
  void _openAnime(int animeId) {
    ...
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ...
      ref.read(routerProvider).pushNamed('animeDetail', ...);
    });
  }
  ```
- **Impact:** Unhandled async exceptions; increased lint noise.
- **Recommended fix:** Wrap the `pushNamed` call in `unawaited(...)` or use `.ignore()`; consider making `_initDeepLinks` fire-and-forget via `Future.microtask`.
- **Status vs. existing AUDIT.md:** **New / increased lint count.**

#### M4. OAuth authorization URL lacks a `state` parameter
- **Severity:** MEDIUM
- **File:** `lib/features/auth/data/repositories/mal_auth_repository.dart:34-42`
- **Description:** The authorization URL does not include a `state` value, and the deep-link handler does not validate one.
- **Impact:** Vulnerable to cross-site request forgery (CSRF) during login.
- **Recommended fix:** Generate a cryptographically random `state`, persist it securely, and verify it in `OAuthCallbackPage`/`App._handleLink`.
- **Status vs. existing AUDIT.md:** **Already present / not fixed.**

#### M5. No TLS certificate pinning
- **Severity:** MEDIUM
- **Files:**
  - `lib/core/network/dio_client.dart`
  - `lib/data/anilist/anilist_client.dart`
  - `lib/core/utils/github_check.dart`
- **Description:** All Dio clients rely on the platform’s default certificate validation. There is no pinning for `myanimelist.net`, `graphql.anilist.co`, or GitHub.
- **Impact:** Users on compromised or untrusted networks are at risk of MITM attacks.
- **Recommended fix:** Add certificate pinning via a custom `SecurityContext` / Dio `HttpClientAdapter`, or document the accepted risk.
- **Status vs. existing AUDIT.md:** **Already present / not fixed.**

#### M6. Airing schedule only merges with current-season MAL data
- **Severity:** MEDIUM
- **File:** `lib/shared/providers/airing_entry.dart:160-179`
- **Description:** `_fetchMalSeasonal` always fetches `Season.fromDate(DateTime.now())` for the current year. If the weekly airing window spans a season boundary, newly started/ending shows will not have MAL scores or `myListStatus` in the airing page.
- **Impact:** Incomplete data at the start/end of each anime season.
- **Recommended fix:** Fetch the current and adjacent seasons, or use a currently-airing MAL query.
- **Status vs. existing AUDIT.md:** **Already present / not fixed.**

#### M7. Year picker dialog uses an invalid width
- **Severity:** MEDIUM
- **File:** `lib/features/seasonal/presentation/screens/anime_schedule_page.dart:170`
- **Description:** The dialog content is sized with `width: double.minPositive` (`4.9e-324`), which essentially collapses the list to zero width.
- **Evidence:**
  ```dart
  content: SizedBox(
    width: double.minPositive,
    height: 300,
    child: ListView.builder(...),
  ),
  ```
- **Impact:** The year picker may be invisible or unusably narrow on some devices.
- **Recommended fix:** Remove the width constraint or use `double.maxFinite`.
- **Status vs. existing AUDIT.md:** **Already present / not fixed.**

---

### LOW

#### L1. Unused countdown helpers in `date_utils.dart`
- **Severity:** LOW
- **File:** `lib/core/utils/date_utils.dart:35, 45`
- **Description:** `formatCountdown` and `isUrgentCountdown` are defined but never called. `CountdownBadge` has its own private versions.
- **Recommended fix:** Remove the dead code or export/use them from `CountdownBadge`.
- **Status vs. existing AUDIT.md:** **Already present / not fixed.**

#### L2. Unused seasonal providers
- **Severity:** LOW
- **File:** `lib/features/seasonal/providers/seasonal_providers.dart:81-95`
- **Description:** `currentSeasonProvider` and `currentAnimeScheduleProvider` are defined but never watched in the UI.
- **Recommended fix:** Remove them or use them to default the calendar tab.
- **Status vs. existing AUDIT.md:** **Already present / not fixed.**

#### L3. `use_null_aware_elements` lint remains
- **Severity:** LOW
- **Files:**
  - `lib/shared/widgets/anime_card.dart:295`
  - `lib/data/anilist/anilist_client.dart:39`
- **Description:** Two `use_null_aware_elements` infos remain after the recent changes.
- **Recommended fix:** Replace the conditional-if patterns with `?` collection-if syntax.
- **Status vs. existing AUDIT.md:** **New / remaining.**

#### L4. Lint info count increased from 46 to 55
- **Severity:** LOW
- **Description:** `flutter analyze` now reports 55 infos, up from 46. The new/remaining categories are listed in the `flutter analyze Summary` section.
- **Recommended fix:** Address `discarded_futures`, `curly_braces_in_flow_control_structures`, `prefer_const_constructors`, `avoid_catches_without_on_clauses`, etc.
- **Status vs. existing AUDIT.md:** **Regressed.**

#### L5. `_loadPrefs` calls `setState` without checking `mounted`
- **Severity:** LOW
- **File:** `lib/features/home/presentation/widgets/anime_home_tab.dart:54-59`
- **Description:** `_loadPrefs` awaits `SharedPreferences.getInstance()` and then calls `setState`. If the widget is disposed before the future completes, this throws.
- **Recommended fix:** Guard `setState` with `if (mounted)`.
- **Status vs. existing AUDIT.md:** **Already present / not fixed.**

---

## Security Findings

| ID | Title | Severity | Notes |
|----|-------|----------|-------|
| H2 | OAuth PKCE `plain` challenge method | HIGH | Should use `S256`. |
| H3 | Concurrent token refresh race | HIGH | Can issue multiple refresh requests. |
| M4 | Missing OAuth `state` parameter | MEDIUM | CSRF risk. |
| M5 | No certificate pinning | MEDIUM | MITM risk on untrusted networks. |

**Positive security notes:**
- No hardcoded secrets, client IDs, or tokens were found.
- OAuth tokens and the PKCE code verifier are stored in `FlutterSecureStorage`.
- `_SafeLogInterceptor` redacts the `Authorization` header and skips logging the token endpoint body.
- GraphQL variables are typed, not built from raw user strings.

---

## Performance Findings

- **M2:** `_NotificationBell` watches the whole notification set instead of a selected boolean, causing extra rebuilds.
- **M6:** Airing page merges with only the current MAL season, which can miss boundary shows.
- `AnimeCard` now correctly uses `animeNotificationProvider.select(...)` to avoid rebuilding when unrelated notifications change.
- Search debouncing is per-provider and cancelled on dispose.
- All long scrolling lists use `ListView.builder` or `SliverChildBuilderDelegate`.
- `sortedUserAnimeListProvider` and `groupedSeasonalAnimeProvider` memoize expensive sort/group operations.

---

## Memory Leak Findings

No critical leaks were found. Notable observations:

- `AnimeNotificationService.dispose()` exists but is never called. Because the service is a process-wide singleton created in `main()`, this is acceptable for the current lifecycle.
- `AnimeHomeTab._loadPrefs` does not guard `setState` with `mounted` (L5).
- `TabController`, `TextEditingController`, `ScrollController`, `Timer`, and `StreamSubscription` instances are disposed correctly in the inspected widgets.
- `AuthRefreshListenable` closes its provider subscription in `dispose()`.

---

## Dead Code Summary

| Symbol | File | Status |
|--------|------|--------|
| `formatCountdown` | `lib/core/utils/date_utils.dart:35` | Unused |
| `isUrgentCountdown` | `lib/core/utils/date_utils.dart:45` | Unused |
| `currentSeasonProvider` | `lib/features/seasonal/providers/seasonal_providers.dart:81` | Unused externally |
| `currentAnimeScheduleProvider` | `lib/features/seasonal/providers/seasonal_providers.dart:91` | Unused externally |

---

## Flutter 3.44 / Dart 3.12 Compatibility Notes

- **SDK constraints:** `pubspec.yaml` requires `sdk: ^3.12.1`. The running SDK is 3.12.2, so constraints are satisfied.
- **Theme APIs:** `CardThemeData` and `DialogThemeData` constructors are used and are valid in Flutter 3.44.
- **Color APIs:** `Color.withValues(...)` is used and is supported.
- **Android Gradle Plugin / JDK mismatch:** `android/settings.gradle.kts` applies AGP `9.0.1`. AGP 9.x requires **JDK 21** to run Gradle, but `android/app/build.gradle.kts` sets `JavaVersion.VERSION_17` for compile. Build environments using JDK 17 may fail with an AGP/JDK compatibility error. Consider aligning the build JDK to 21 while keeping `compileOptions` at 17 if needed.
- **Kotlin:** `org.jetbrains.kotlin.android` `2.3.20` is applied; this is a future Kotlin version and may require matching IDE/build tooling.
- **Plugin versions:** `package_info_plus` and `share_plus` are at the latest versions available at audit time; no KGP incompatibility warnings were observed during `flutter analyze`.
- **Dependencies:** All direct dependencies are up to date. A few transitive dev dependencies have newer versions, but they do not block the project.

---

## `flutter analyze` Summary

**Current:** 55 infos. 0 errors, 0 warnings.

| Lint | Count | Representative Files |
|------|-------|----------------------|
| `avoid_redundant_argument_values` | ~10 | `anime_notification_service.dart`, `anilist_client.dart`, `anime_providers.dart` |
| `discarded_futures` | 6 | `app.dart`, `anime_notification_service.dart`, `anime_home_tab.dart` |
| `unnecessary_null_checks` | 6 | `anime_detail_page.dart`, `my_list_status.g.dart` |
| `avoid_catches_without_on_clauses` | 6 | `auth_interceptor.dart`, `anime_providers.dart`, `anime_detail_page.dart` |
| `specify_nonobvious_property_types` | 6 | `anilist_providers.dart`, `anime_providers.dart`, `my_list_status.g.dart` |
| `curly_braces_in_flow_control_structures` | 4 | `auth_interceptor.dart`, `anime_notification_service.dart`, `mal_api_client.dart` |
| `prefer_const_constructors` | 3 | `anime_notification_service.dart` |
| `unnecessary_lambdas` | 3 | `home_page.dart`, `anime_profile_page.dart`, `anime_providers.dart` |
| `unnecessary_underscores` | 3 | `character_staff_page.dart`, `studio_page.dart`, `airing_entry.dart` |
| `use_null_aware_elements` | 2 | `anilist_client.dart`, `anime_card.dart` |
| `prefer_initializing_formals` | 2 | `auth_interceptor.dart` |

---

## Recommended Next Steps

1. **Fix the failing widget test** by overriding `notificationServiceProvider` in `test/widget_test.dart` (H1).
2. **Harden OAuth:** implement `S256` PKCE (H2) and add a validated `state` parameter (M4).
3. **Fix the token-refresh race** in `AuthInterceptor` (H3).
4. **Address the layer-architecture gap** by introducing domain entities, abstract repositories, and use cases (H4).
5. **Add the missing periodic cleanup to `MemoryCache`** (M1).
6. **Use `select` in `_NotificationBell`** to avoid unnecessary rebuilds (M2).
7. **Fix the year picker width** (`double.minPositive` → `double.maxFinite`) (M7).
8. **Resolve the 55 lint infos**, prioritizing `discarded_futures` and `avoid_catches_without_on_clauses`.
9. **Remove dead code** (`formatCountdown`, `isUrgentCountdown`, `currentSeasonProvider`, `currentAnimeScheduleProvider`).
10. **Evaluate AGP/JDK alignment** before release builds to avoid Android compilation failures.
