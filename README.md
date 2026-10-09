# AniMAL

> Unofficial [MyAnimeList](https://myanimelist.net) client built with Flutter — clean, fast, and offline-capable.

[![Quality Checks](https://github.com/andrizan/AniMAL/actions/workflows/quality.yml/badge.svg)](https://github.com/andrizan/AniMAL/actions/workflows/quality.yml)
[![Release APK](https://github.com/andrizan/AniMAL/actions/workflows/release-apk.yml/badge.svg)](https://github.com/andrizan/AniMAL/actions/workflows/release-apk.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.47-blue?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Track your anime, discover seasonal charts, follow weekly airing schedules, and dive into character / staff details. MAL is the source of truth for user data; AniList enriches it with schedule and people data.

---

## Features

- **Home** — Your lists by status (Watching / Plan to Watch / On Hold / Completed / Dropped) with sort and airing filter, one card UI everywhere, and an edit modal (status, episodes, score). Complete lists are fetched page by page, and editing keeps your scroll position.
- **Airing** — Weekly schedule grouped by day (Mon–Sun) with countdown (`2d 5h`, `45m`, urgent <6h in red), merged from AniList and MAL scores. Refresh fetches both sources.
- **Calendar** — Seasonal browser (Winter / Spring / Summer / Fall) with a year picker (current − 50 → current + 1). The **Later** tab lists upcoming anime that have no start date yet.
- **Search & Ranking** — Debounced full-text search and MAL rankings with local cache.
- **Detail** — Ordered by importance: score / rank / popularity summary, your list card (status, progress bar, episode stepper, score, remove) or *Add to Watching*, next episode, synopsis with genres, information (aired, season, broadcast in your local time, duration, source, studios), characters & voice actors, staff, related anime, alternative titles, external links. Cover with gradient and full-screen viewer.
- **Profile** — Header with your MAL stats, a status donut, time invested, and charts built from your own list: score distribution, top genres, formats and activity over the last 12 months. Also API health, theme, update check and logout.
- **Notifications** — Per-anime reminder 15 minutes before the next episode airs.
- **Auth** — MAL OAuth2 PKCE with a manual-code fallback, secure token storage, token refresh on 401 (retried once), `animal://` deep links.
- **Offline** — Persistent SQLite cache survives cold start; cached screens work offline.
- **Theme** — Material 3, dark by default, switchable and remembered.

---

## Tech Stack

| Layer | Package |
|-------|---------|
| State | `flutter_riverpod` 3.x |
| Routing | `go_router` (StatefulShellRoute, auth guard), `app_links` (deep links) |
| Network | `dio` 5.x |
| Persistence | `sqflite` + `path` (typed SQLite cache) |
| Codegen | `freezed` + `json_serializable` (DTOs only) |
| Auth | `flutter_secure_storage` |
| Prefs | `shared_preferences` |
| UI | `material_ui`, `cached_network_image`, custom-painted charts (no chart package) |
| Fonts | `google_fonts` with Inter 400/500/600/700 bundled in `assets/google_fonts/` (runtime fetching disabled) |
| Notifications | `flutter_local_notifications` + `timezone` |
| Misc | `url_launcher`, `share_plus`, `package_info_plus`, `logger` |
| Tests | `flutter_test`, `sqflite_common_ffi` (host SQLite) |

---

## APIs

| Source | Data |
|--------|------|
| **MyAnimeList API v2** | User list, detail, search, ranking, seasonal, scores (`mean`), auth |
| **AniList GraphQL** | Characters, staff, studios, airing schedule (`airingAt`, `episode`, `timeUntilAiring`) |
| **GitHub Releases** | Update check from the profile page |

MAL is primary; AniList is supplementary. On merge MAL wins.

---

## Architecture

**Feature-based, strict isolation** — features never import each other. Shared data lives in `data/`, `core/`, `shared/`.

```
feature/
├── data/           Repo impl, DTO → entity mappers            (when the feature needs them)
├── domain/         Plain Dart entities, abstract repos, use cases
├── providers/      Riverpod providers (*_providers.dart)
└── presentation/   Screens (*_page.dart) + widgets
```

Layers are added only when a feature needs them: most features are `presentation/` + `providers/`, `auth` also has `data/`, `profile` also has `domain/` (list insights).

### Project Structure

```
lib/
├── main.dart                          # binding + TZ + SQLite + notifications → runApp
├── app.dart                           # MaterialApp.router, deep links, notification taps
├── core/
│   ├── config/env.dart                # --dart-define (MAL_CLIENT_ID/SECRET/REDIRECT_URI)
│   ├── constants/                     # mal_endpoints, anilist_queries
│   ├── logger/app_logger.dart
│   ├── network/                       # DioClient, AuthInterceptor, ApiHealth*, ApiException
│   ├── notification/                  # airing reminders
│   ├── router/                        # app_router, route_guards, deep_links
│   ├── storage/secure_token_storage.dart
│   ├── theme/                         # app_colors, app_text_styles, app_spacing, app_theme
│   ├── utils/                         # date_utils (JST→local), format_utils, anime_labels, version_utils, github_check
│   └── providers.dart                 # logger, dio, appDatabase, caches, auth, retry policy
├── data/
│   ├── mal/mal_api_client.dart
│   ├── anilist/anilist_client.dart
│   ├── local/                         # SQLite cache
│   │   ├── app_database.dart          # single DB, versioned schema, startup prune
│   │   ├── cache_mappers.dart         # pure DTO ↔ row mappers
│   │   ├── anime_cache.dart           # interface
│   │   ├── sqlite_anime_cache.dart    # MAL caches (search/seasonal/ranking/detail/userList/userInfo)
│   │   ├── anilist_cache.dart         # AniList caches (schedule/extra/character/staff/studio)
│   │   └── airing_cache.dart          # merged weekly schedule
│   └── models/                        # @freezed DTOs (MAL) + plain Dart (AniList)
├── shared/
│   ├── providers/                     # AnimeRepository, user lists, airing, AniList, theme, notifications
│   └── widgets/                       # anime_card, section_card, section_header, hero_panel, stat_highlight,
│                                      # error_view, empty_view, info_chip, countdown_badge, app_cached_image, full_screen_image
└── features/
    ├── home/ airing/ seasonal/ profile/ auth/ detail/ search/
```

### Design system

One look across every screen, enforced by `test/core/theme/design_rules_test.dart`:

- **Colors** only from `core/theme/app_colors.dart` (`AppColors`, `StatusColors`, `chartPalette`) — never `Colors.*`.
- **Typography** only from the theme text styles; no raw `fontSize`. `labelSmall` (10) is the micro size.
- **Spacing and radius** from `AppSpacing` (`page` is the page gutter) and `AppRadius` in `core/theme/app_spacing.dart`.
- **Cards** are plain `Card`s styled once in `cardTheme`; use `SectionCard` for a titled block and `HeroPanel` for a highlighted one.
- **Error and empty states** use `ErrorView` / `EmptyView`; section titles use `SectionHeader`.

### Caching

Single `animal_cache.db` (SQLite). No raw JSON blobs — typed tables only.
SQLite is the source of truth: cached rows are served with zero network.
The network is hit only on a genuine cache miss (first open after install,
a never-opened anime detail) or via an explicit refresh. There is
no background revalidate — stale rows stay until the user refreshes. If a
refetch fails, the stored rows are served instead of an error.

| Endpoint | Key | Refresh |
|----------|-----|---------|
| Search | `search_<q>_<limit>` | Button only (300 ms debounce at provider) |
| Seasonal | `seasonal_<y>_<season>_<limit>` | Button only (empty seasons cached) |
| Ranking | `ranking_<type>_<limit>` | Button only |
| Undated upcoming (Later tab) | `ranking_upcoming_undated_500` | Button only (first 3 pages of the `upcoming` ranking, filtered on `start_date`) |
| Detail | `detail_<id>` | Pull to refresh |
| User list | `userlist_<status>_500_0` (one complete list per status) | Button only (invalidated on edit/delete) |
| User info | `userInfo` | Button only |
| AniList weekly | `weeklyAiringSchedule:<YYYY-MM-DD>` | Button only |
| Merged weekly | `weekly_schedule:<YYYY-MM-DD>` | Button only |
| Anime extra / character / staff / studio | `animeExtra_…` etc | Button only (empty extras cached) |

- **Cache-first** = serve SQLite immediately; one blocking fetch only on miss, deduped per key.
- **Rate limit** `429` → `ApiException.rateLimited` (no auto-retry), health tracked in `ApiHealthTracker`.
- **Provider errors surface at once**: Riverpod's default retry is disabled (`noProviderRetry`), so a failed load shows its error and a Retry button instead of an endless spinner.
- **Mutations** (`updateAnimeListStatus`/`deleteAnimeFromList`) update every stored snapshot of the personal status (user lists, `anime` rows, merged airing week) and bump `animeListVersionProvider`. Providers that watch it render with `skipLoadingOnReload` so an edit never flashes a spinner or resets scroll. The airing schedule itself is never refetched by list edits.

**Physical retention** (`app_database.dart::_runStartupCleanup` on `AppDatabase.open`):

| Scope | Condition | Retention |
|---|---|---|
| `cache_meta` `search_%` | `fetched_at < now-1h` | 1 hour |
| `cache_meta` `ranking_%` | `fetched_at < now-1d` | 1 day |
| `cache_meta` `seasonal_%` | `fetched_at < now-90d` | 90 days |
| `cache_meta` `userlist_%` | `fetched_at < now-1d` | 1 day |
| `cache_meta` `userInfo` | `fetched_at < now-1d` | 1 day |
| `cache_meta` `detail_%` | `fetched_at < now-30d` | 30 days |
| `cache_meta` `weeklyAiringSchedule:%` | `fetched_at < now-14d` | 14 days |
| `cache_meta` `weekly_schedule:%` | `fetched_at < now-14d` | 14 days |
| `cache_meta` `animeExtra_%` | `fetched_at < now-30d` | 30 days |
| `cache_meta` `character_%`/`staff_%`/`studio_%` | `fetched_at < now-90d` | 90 days |
| `airing_schedule` rows | `airing_at < now-14d` (epoch sec) | 14 days |
| `merged_airing_entry` rows | `week_key` not in `cache_meta` (`weekly_schedule:%`) | on next startup |
| `anime_query_item` / `user_anime_list_item` / `anime` | orphan (`cache_key` not in `cache_meta` / `mal_id` not referenced) | on next startup |

---

## Getting Started

### Prerequisites

- Flutter 3.47+ (`flutter --version`)
- Dart 3.13+
- Android SDK / Xcode for device builds
- MAL API credentials — create a client at https://myanimelist.net/apiconfig (Application Type: `web`, Non-Commercial: `yes`)

### Install

```bash
git clone https://github.com/andrizan/AniMAL.git
cd AniMAL
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Environment

Credentials are compile-time `--dart-define`, not `.env`:

| Variable | Description |
|----------|-------------|
| `MAL_CLIENT_ID` | From MAL apiconfig |
| `MAL_CLIENT_SECRET` | From MAL apiconfig (PKCE) |
| `MAL_REDIRECT_URI` | Must match apiconfig, e.g. `animal://oauth/callback` |

A local `.env` is gitignored and only for helper scripts — the app never reads it.

### Run

```bash
flutter run \
  --dart-define=MAL_CLIENT_ID=your_id \
  --dart-define=MAL_CLIENT_SECRET=your_secret \
  --dart-define=MAL_REDIRECT_URI=animal://oauth/callback
```

### Analyze / Format / Test

```bash
dart format lib test
flutter analyze
flutter test
# or with coverage
flutter test --coverage
```

`very_good_analysis` is enabled — `flutter analyze` must be 0 errors (infos are allowed unless `--fatal-infos`).

Tests live under `test/` and mirror `lib/`. They cover the pure logic (date and version helpers, insights), repositories and caches (real SQLite through `sqflite_common_ffi`, fake Dio adapters in `test/support/`), providers, and the pages and shared widgets.

### Build APK (debug)

```bash
flutter build apk --debug \
  --dart-define=MAL_CLIENT_ID=... \
  --dart-define=MAL_CLIENT_SECRET=... \
  --dart-define=MAL_REDIRECT_URI=...
```

Release APKs are built by CI on tag push (see `.github/workflows/release-apk.yml`); it signs with `KEYSTORE_BASE64` secrets and attaches three APKs to a GitHub Release: `arm64-v8a` for most phones, `armeabi-v7a` for older 32-bit phones, and `universal` (all ABIs including x86_64, the largest file). All three share the same `versionCode`.

---

## CI

| Workflow | Trigger | What |
|----------|---------|------|
| `quality.yml` | push `**` + PR | `pub get` → `build_runner` → `dart format --set-exit-if-changed` → `flutter analyze` → `flutter test` |
| `release-apk.yml` | tag `v*` + manual dispatch | quality → bump version → `flutter build apk --release --split-per-abi` + universal `flutter build apk --release` (both with `--dart-define=...`) → upload artifact → release notes and `CHANGELOG.md` via `git-cliff` → GitHub Release → bump `pubspec.yaml` and changelog on `main` |

The release job pushes a `chore: bump version … [skip ci]` commit to `main`, so pull or rebase before pushing.

---

## Conventions

- **Commits** follow Conventional Commits (`feat:`, `fix:`, `chore:`). No auto-commit without explicit instruction.
- **Codegen** — run `dart run build_runner build` after touching `*.dart` with `@freezed`/`@JsonSerializable`.
- **Formatting** — `dart format lib test` before every commit (CI enforces).
- **Analysis** — `flutter analyze` with `very_good_analysis`.
- **Imports** — `dart:` → `package:` → relative, alphabetically; `directives_ordering` lint.
- **UI** — follow the [design system](#design-system) above.
- **Logging** — use shared `appLogger`, never `Logger()` directly.

Longer contributor and agent rules live in [`AGENTS.md`](AGENTS.md).

---

## License

[MIT](LICENSE)
