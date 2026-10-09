# AniMAL

> Unofficial [MyAnimeList](https://myanimelist.net) client built with Flutter — clean, fast, and offline-capable.

[![Quality Checks](https://github.com/andrizan/AniMAL/actions/workflows/quality.yml/badge.svg)](https://github.com/andrizan/AniMAL/actions/workflows/quality.yml)
[![Release APK](https://github.com/andrizan/AniMAL/actions/workflows/release-apk.yml/badge.svg)](https://github.com/andrizan/AniMAL/actions/workflows/release-apk.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.47-blue?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Track your anime, discover seasonal charts, follow weekly airing schedules, and dive into character / staff details. MAL is the source of truth for user data; AniList enriches it with schedule and people data.

---

## Features

- **Home** — User anime lists by status (Watching / Plan to Watch / On Hold / Completed / Dropped) with sort & airing filter, unified card UI, inline status edit
- **Airing** — Weekly schedule grouped by day (Mon–Sun) with countdown (`2d 5h`, `45m`, urgent <6h in red), merged from AniList + MAL scores
- **Calendar** — Seasonal browser (Winter/Spring/Summer/Fall + Later) with year picker (current-50 → current+1)
- **Search & Ranking** — Full-text search and MAL rankings with local cache
- **Detail** — Cover with gradient overlay & full-screen viewer, chips, genres, broadcast, related anime, staff & characters (4 + See All)
- **Profile** — Real MAL user stats (`/users/@me`), days watched, mean score, per-status counts
- **Auth** — MAL OAuth2 PKCE, secure token storage, auto refresh on 401
- **Offline** — Persistent SQLite cache survives cold start; works offline for cached screens

---

## Tech Stack

| Layer | Package |
|-------|---------|
| State | `flutter_riverpod` 3.x |
| Routing | `go_router` (StatefulShellRoute, auth guard) |
| Network | `dio` 5.x |
| Persistence | `sqflite` + `path` (typed SQLite cache) |
| Data | `sqflite_common_ffi` (host tests) |
| Codegen | `freezed` + `json_serializable` (DTOs only) |
| Auth | `flutter_secure_storage` |
| Prefs | `shared_preferences` |
| Images | `cached_network_image` |
| Fonts | `google_fonts` (Inter 400/500/600/700, fallback Noto Sans JP) |
| Notifications | `flutter_local_notifications` + `timezone` |
| Logging | `logger` (PrettyPrinter) |

---

## APIs

| Source | Data |
|--------|------|
| **MyAnimeList API v2** | User list, detail, search, ranking, seasonal, scores (`mean`), auth |
| **AniList GraphQL** | Characters, staff, studios, airing schedule (`airingAt`, `episode`, `timeUntilAiring`) |

MAL is primary; AniList is supplementary. On merge MAL wins.

---

## Architecture

**Feature-based, strict isolation** — features never import each other. Shared data lives in `data/`, `core/`, `shared/`.

```
feature/
├── data/           Repo impl, DTO → entity mappers
├── domain/         Entities (plain Dart), abstract repos, use cases
├── providers/      Riverpod providers (*_providers.dart)
└── presentation/   Screens (*_page.dart) + widgets
```

### Project Structure

```
lib/
├── main.dart                          # WidgetsFlutterBinding + TZ + SQLite + notifications → runApp
├── app.dart
├── core/
│   ├── config/env.dart               # --dart-define (MAL_CLIENT_ID/SECRET/REDIRECT_URI)
│   ├── constants/                     # mal_endpoints, anilist_queries
│   ├── logger/app_logger.dart
│   ├── network/                       # DioClient, AuthInterceptor, ApiHealth*, ApiException (incl. RateLimit)
│   ├── notification/
│   ├── router/                        # GoRouter + AuthRefreshListenable + guards
│   ├── storage/secure_token_storage.dart
│   ├── theme/                         # AppColors/StatusColors, AppTextStyles, app_theme (M3, indigo, dark)
│   ├── utils/date_utils.dart          # JST→local, countdown
│   └── providers.dart                 # logger, dio, appDatabase, caches, auth
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
│   ├── providers/
│   │   ├── anime_providers.dart       # AnimeRepository (cache-first, dedup, mutations)
│   │   ├── anime_list_providers.dart  # userAnimeListProvider, sortedUserAnimeListProvider
│   │   ├── airing_entry.dart          # AiringEntry, AiringRepository, weeklyAiringProvider
│   │   ├── anilist_providers.dart
│   │   └── theme_providers.dart
│   └── widgets/                       # anime_card, loading_shimmer, app_cached_image, etc.
└── features/
    ├── home/ airing/ seasonal/ profile/ auth/ detail/ search/
```

### Caching

Single `animal_cache.db` (SQLite). No raw JSON blobs — typed tables only.
SQLite is the source of truth: cached rows are served with zero network.
The network is hit only on a genuine cache miss (first open after install,
a never-opened anime detail) or via an explicit refresh button. There is
no background revalidate — stale rows stay until the user refreshes.

| Endpoint | Key | Refresh |
|----------|-----|---------|
| Search | `search_<q>_<limit>` | Button only (1 min debounce at provider) |
| Seasonal | `seasonal_<y>_<season>_<limit>` | Button only (empty seasons cached) |
| Ranking | `ranking_<type>_<limit>` | Button only |
| Detail | `detail_<id>` | Button only |
| User list | `userlist_<status>_<limit>_<offset>` | Button only (3 min data, invalidated on edit/delete) |
| User info | `userInfo` | Button only |
| AniList weekly | `weeklyAiringSchedule:<YYYY-MM-DD>` | Button only |
| Merged weekly | `weekly_schedule:<YYYY-MM-DD>` | Button only |
| Anime extra / character / staff / studio | `animeExtra_…` etc | Button only (empty extras cached) |

- **Cache-first** = serve SQLite immediately; one blocking fetch only on miss, deduped per key.
- **Rate limit** `429` → `ApiException.rateLimited` (no auto-retry), health tracked in `ApiHealthTracker`.
- **Mutations** (`updateAnimeListStatus`/`deleteAnimeFromList`) update the embedded `my_list_status` in the shared `anime` row and bump `animeListVersionProvider` for user lists/detail only — the airing schedule is never invalidated by list edits.

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

### Build APK (debug)

```bash
flutter build apk --debug \
  --dart-define=MAL_CLIENT_ID=... \
  --dart-define=MAL_CLIENT_SECRET=... \
  --dart-define=MAL_REDIRECT_URI=...
```

Release APKs are built by CI on tag push (see `.github/workflows/release-apk.yml`); it signs with `KEYSTORE_BASE64` secrets and attaches one APK per ABI to a GitHub Release: `arm64-v8a` for most phones, `armeabi-v7a` for older 32-bit phones.

---

## CI

| Workflow | Trigger | What |
|----------|---------|------|
| `quality.yml` | push `**` + PR | `pub get` → `build_runner` → `dart format --set-exit-if-changed` → `flutter analyze` → `flutter test` |
| `release-apk.yml` | tag `v*` + manual dispatch | quality → bump version → `flutter build apk --release --split-per-abi --dart-define=...` → upload artifact → GitHub Release → bump `pubspec.yaml` on `main` |

---

## Conventions

- **Commits** follow Conventional Commits (`feat:`, `fix:`, `chore:`). No auto-commit without explicit instruction.
- **Codegen** — run `dart run build_runner build` after touching `*.dart` with `@freezed`/`@JsonSerializable`.
- **Formatting** — `dart format lib test` before every commit (CI enforces).
- **Analysis** — `flutter analyze` with `very_good_analysis`.
- **Imports** — `dart:` → `package:` → relative, alphabetically; `directives_ordering` lint.
- **Colors** — never raw `Colors.*`, use `AppColors.*` / `StatusColors` in `core/theme/app_colors.dart`.
- **Logging** — use shared `appLogger`, never `Logger()` directly.

---

## License

[MIT](LICENSE)
