# Deep Audit — AniMAL

Comprehensive audit of the Flutter 3.44 / Dart 3.12 codebase against `AGENTS.md`.  
**Date:** 2026-06-24  
**`flutter analyze`:** 0 errors, 0 warnings, **60 info**  
**`flutter test`:** all passed  
**`dart format lib/`:** clean (0 changed)

---

## Executive Summary

No critical security vulnerabilities, hardcoded secrets, or crash-inducing defects remain.  
All **HIGH** and **MEDIUM** findings from the initial audit have been resolved. Only a handful of **LOW** maintenance items remain.

| Severity | Initial | Resolved | Remaining |
|----------|---------|----------|-----------|
| CRITICAL | 0 | 0 | 0 |
| HIGH     | 4 | 4 | 0 |
| MEDIUM   | 7 | 7 | 0 |
| LOW      | 11 | 7 | 4 |
| Dead code | 6 | 6 | 0 |

---

## Fixes Applied

### HIGH

#### H1. Search debounce now uses a per-provider `Timer`

- **File:** `lib/features/search/providers/search_providers.dart`
- Removed the global `Timer? _debounceTimer`. Each provider instance owns its own `Timer`, cancelled via `ref.onDispose(timer.cancel)`. This prevents stuck `loading` states and invalid `ref` usage.

#### H2. Airing cards no longer navigate with an AniList ID

- **File:** `lib/features/airing/presentation/screens/anime_airing_page.dart`
- `_AiringCard` now checks `entry.malId`. When `malId` is missing, the card overrides `onTap` and shows a SnackBar instead of pushing to `/anime/:id` with a wrong ID.

#### H3. Episode +/- buttons in the edit modal update the controller correctly

- **File:** `lib/shared/widgets/anime_card.dart`
- Fixed the off-by-one controller text updates after `selectedEps--` / `selectedEps++`.

#### H4. Replaced `LogInterceptor` with a safe custom interceptor

- **File:** `lib/core/network/dio_client.dart`
- Added `_SafeLogInterceptor` that:
  - Never logs request/response bodies for the OAuth token endpoint.
  - Redacts the `Authorization` header in all logs.
  - Uses the injected `Logger` from `loggerProvider`/`appLogger`.

### MEDIUM

#### M1. `AnimeCard` now uses `select` for notification state

- **File:** `lib/shared/widgets/anime_card.dart`
- `ref.watch(animeNotificationProvider.select((s) => s.contains(anime.id)))` prevents every visible card from rebuilding when any notification toggles.

#### M2. `notificationServiceProvider` is no longer `autoDispose`

- **File:** `lib/core/providers.dart`
- Changed from `Provider.autoDispose` to `Provider` so the singleton notification service is not disposed when the last widget stops listening.

#### M3. OAuth callback now redirects to `/home`

- **File:** `lib/features/auth/presentation/oauth_callback_page.dart`
- `context.go('/')` → `context.go('/home')` to match the registered route.

#### M4. Anime list sort/filter moved to a memoized provider

- **Files:** `lib/shared/providers/anime_list_providers.dart`, `lib/features/home/presentation/widgets/anime_list_tab.dart`, `lib/features/home/presentation/widgets/anime_home_tab.dart`
- Moved `ListSort`, `AiringFilter`, `_sortAnimeList`, and `_filterAnimeList` to `anime_list_providers.dart`.
- Added `sortedUserAnimeListProvider` which memoizes the filtered/sorted list and returns it together with the airing map.
- `AnimeListTab` now simply watches the new provider instead of recomputing in `build()`.

#### M5. Seasonal schedule grouping moved to a memoized provider

- **Files:** `lib/features/seasonal/providers/seasonal_providers.dart`, `lib/features/seasonal/presentation/screens/anime_schedule_page.dart`
- Moved `_groupAnimeByDay` to `seasonal_providers.dart`.
- Added `groupedSeasonalAnimeProvider` that returns the grouped map and `noBroadcast` list.
- `_SeasonAnimeList` watches the grouped provider instead of grouping in `build()`.

#### M6. `fetchLatestRelease()` now has timeout and logging

- **File:** `lib/core/utils/github_check.dart`
- Added `BaseOptions` with 15-second connect/receive timeouts.
- Added typed `on DioException` / `on Exception` catch blocks that log via `appLogger`.

#### M7. `AniListExternalLink.displaySite` no longer crashes on invalid URLs

- **File:** `lib/data/models/anilist/anilist_models.dart`
- Wrapped `Uri.parse(url).host` in a `try/catch` and falls back to the raw URL.

### LOW

#### L4. AniList status strings now map to MAL status strings in the Airing card

- **File:** `lib/features/airing/presentation/screens/anime_airing_page.dart`
- Added `_mapAniListStatus` helper (`RELEASING` → `currently_airing`, `FINISHED` → `finished_airing`, `NOT_YET_RELEASED` → `not_yet_aired`, `CANCELLED` → `finished_airing`).

#### L5. Weekly airing schedule uses UTC boundaries

- **File:** `lib/data/anilist/anilist_client.dart`
- `getWeeklyAiringSchedule()` now computes the Monday-to-Monday window in UTC.

#### L6. `"Tomorrow"` prefix logic is now date-difference based

- **File:** `lib/core/utils/date_utils.dart`
- Replaced fragile `localDateTime.day > now.day` check with a proper `inDays` difference between calendar dates.

#### L8. `AuthRefreshListenable` closes its `ref.listen` subscription

- **File:** `lib/core/router/route_guards.dart`
- Stores the `ProviderSubscription<AuthStatus>` and closes it in `dispose()`.

#### L9. Theme mode storage moved from `FlutterSecureStorage` to `SharedPreferences`

- **File:** `lib/shared/providers/theme_providers.dart`
- Theme preference is not sensitive data, so `SharedPreferences` is the appropriate store.

### Dead Code Removed

| Symbol / File | Location | Action |
|---------------|----------|--------|
| `UserProfileEntity` | `lib/features/profile/domain/entities/user_profile_entity.dart` | Deleted (and empty parent dirs) |
| `ApiConstants.cacheDurationMinutes` | `lib/core/constants/mal_endpoints.dart` | Deleted |
| `ApiConstants.anilistPageLimit` | `lib/core/constants/mal_endpoints.dart` | Deleted |
| `ApiConstants.maxSeasonalResults` | `lib/core/constants/mal_endpoints.dart` | Deleted |
| `AniListQueries.nextAiring` | `lib/core/constants/anilist_queries.dart` | Deleted |

### Localization

- Replaced the Indonesian SnackBar text `"Detail hanya tersedia lewat MyAnimeList"` with `"Details only available through MyAnimeList"` in `lib/features/airing/presentation/screens/anime_airing_page.dart`.

---

## Remaining Findings

### CRITICAL — None

### HIGH — None

### MEDIUM — None

### LOW

#### L7. `MemoryCache` has unsafe casts and unbounded growth

**Location:** `lib/data/local/memory_cache.dart:6-14`

`entry.value as T` can throw `TypeError` if the wrong generic type is requested. Expired entries are only evicted on access, so the cache can grow unbounded during long sessions.

**Recommendation:** Add type tagging or use a safer cache implementation, and add periodic cleanup.

---

#### L10. `_AiringCard` allocates many objects on every rebuild

**Location:** `lib/features/airing/presentation/screens/anime_airing_page.dart:173-189`

Every rebuild creates a new `Anime`, `MainPicture`, `AlternativeTitles`, `Broadcast`, and `List<Genre>`.

**Recommendation:** Refactor `AnimeCard` to accept raw schedule data or memoize the constructed `Anime`.

---

#### L11. Repeated `CachedNetworkImage` boilerplate

Multiple screens duplicate placeholder/error widget patterns.

**Recommendation:** Introduce a shared `AppCachedImage` widget.

---

#### L12. Countdown badges are static

The Airing and Home countdown values are computed once per provider fetch. They do not tick down while the user stays on the screen.

**Recommendation:** Add a periodic `Timer`/`Stream` that rebuilds countdown chips every minute, or use a `TickerProvider`/`Timer` in the widget.

---

## AGENTS.md Compliance

| Rule | Status | Notes |
|------|--------|-------|
| Feature isolation | **PASS** | No imports between `features/*/`. Shared layers only import from `core`, `data`, or `shared`. |
| `@freezed` in `data/models` only | **PASS** | All freezed models live in `lib/data/models/`. Domain entities are plain Dart. |
| Logger: only `appLogger` | **PASS** | Only `app_logger.dart` constructs `Logger()`. |
| Colors in `app_colors.dart` | **PASS** | No raw `Colors.*`; all use `AppColors.*`. |
| API endpoints & GraphQL queries in constants | **PASS** | MAL endpoints and AniList queries are centralized. |
| Cache all API calls | **PASS** | All MAL/AniList calls are cached per TTL spec. GitHub check is out of scope. |
| `*_page.dart` screens | **PASS** | All screens follow convention. |
| `*_providers.dart` naming | **PARTIAL** | `lib/shared/providers/airing_entry.dart` still mixes entity/repository and does not end with `_providers.dart`. `anime_list_providers.dart` now follows the convention. |
| Layer architecture (data/domain/usecase/providers/presentation) | **PARTIAL** | MAL/Airing repositories live in `shared/providers/` instead of `features/*/data/`. No `get_*.dart` use cases exist. |
| Import ordering | **PASS** | `directives_ordering` reports no violations. |
| Search debounce 300 ms | **PASS** | Implemented correctly at the provider level. |
| `ListView.builder` | **PASS** | All long lists use builders. |
| TabBar `isScrollable: true` | **PASS** | All multi-tab `TabBar`s are scrollable. |

---

## Cache TTL Compliance

| Data | Location | TTL | Spec | OK |
|------|----------|-----|------|----|
| Search results | `lib/shared/providers/anime_providers.dart:28` | 1 min | 1 min | ✅ |
| User anime list | `:29` | 3 min | 3 min | ✅ |
| Rankings / user info | `:30-31` | 10 min | 10 min | ✅ |
| Seasonal / detail | `:32` | 15 min | 15 min | ✅ |
| AniList weekly schedule | `lib/data/anilist/anilist_client.dart:116` | 15 min | 15 min | ✅ |
| AniList anime extra | `:207` | 15 min | 15 min | ✅ |
| AniList character | `:255` | 30 min | 30 min | ✅ |
| AniList staff | `:310` | 30 min | 30 min | ✅ |
| AniList studio | `:417` | 30 min | 30 min | ✅ |
| Airing merged schedule | `lib/shared/providers/airing_entry.dart:76` | 15 min | 15 min | ✅ |

---

## Dead Code Summary

| Symbol / File | Location | Status |
|---------------|----------|--------|
| `UserProfileEntity` | `lib/features/profile/domain/entities/user_profile_entity.dart` | Deleted |
| `ApiConstants.cacheDurationMinutes` | `lib/core/constants/mal_endpoints.dart` | Deleted |
| `ApiConstants.anilistPageLimit` | `lib/core/constants/mal_endpoints.dart` | Deleted |
| `ApiConstants.maxSeasonalResults` | `lib/core/constants/mal_endpoints.dart` | Deleted |
| `AniListQueries.nextAiring` | `lib/core/constants/anilist_queries.dart` | Deleted |

---

## `flutter analyze` Summary

**Current:** 60 info. 0 errors, 0 warnings.

Most common remaining info categories:

| Lint | Frequency | Representative Files |
|------|-----------|----------------------|
| `avoid_redundant_argument_values` | ~9 | `anilist_client.dart`, `anime_providers.dart`, `anime_notification_service.dart` |
| `unnecessary_null_checks` | ~8 | `anime_detail_page.dart`, `anime_card.dart`, `my_list_status.g.dart` |
| `unnecessary_underscores` | ~8 | `anime_detail_page.dart`, `character_staff_page.dart`, `studio_page.dart` |
| `discarded_futures` | 6 | `app.dart`, `anime_notification_service.dart`, `anime_home_tab.dart` |
| `specify_nonobvious_property_types` | 5 | `anilist_providers.dart`, `anime_providers.dart`, `my_list_status.g.dart` |
| `curly_braces_in_flow_control_structures` | 3 | `auth_interceptor.dart`, `anime_notification_service.dart`, `mal_api_client.dart` |
| `prefer_const_constructors` | 3 | `anime_notification_service.dart`, `anime_card.dart` |
| `unnecessary_lambdas` | 3 | `home_page.dart`, `anime_profile_page.dart`, `anime_providers.dart` |
| `avoid_catches_without_on_clauses` | 2 | `auth_interceptor.dart`, `anime_providers.dart` |
| `use_null_aware_elements` | 2 | `anilist_client.dart`, `anime_card.dart` |

---

## Recommended Next Steps

1. **Address the 60 lint infos** — many are quick wins (`discarded_futures`, `curly_braces`, `prefer_const_constructors`).
2. **Improve `MemoryCache` safety** (L7).
3. **Introduce a shared `AppCachedImage` widget** (L11).
4. **Make countdowns tick live** (L12).
5. **Add unit/widget tests** for providers and repositories.
