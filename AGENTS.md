# AniMAL — Agents Guide

Rules and conventions for contributing to this project.

## Git Rules

- **NEVER commit without explicit permission** from the user.
- Never push, amend, or force-push unless asked.
- **NEVER run destructive git commands** unless explicitly asked:
  - `git reset --hard` — destroys all uncommitted work
  - `git clean -fd` — deletes all untracked files
  - `git checkout --` — overwrites files without recovery
  - `git restore` — same as above
- If a git operation goes wrong, use `git stash` or `git checkout -b` instead.
- Stage only intended files. Never commit secrets or keys.
- **NEVER use `git mv`** — use the file tools (Write/Edit/Bash `mv`) instead. `git mv` stages immediately and risks unintended renames.

## Architecture

- **Feature-Based** with strict isolation: features never import from each other.
- Each feature: `data/` → `domain/` → `providers/` → `presentation/`.
- **State management**: `flutter_riverpod` only.
- **Routing**: `go_router` with auth guard in `core/router/route_guards.dart`.
- **Codegen**: `freezed` + `json_serializable` for data layer DTOs only. Run `dart run build_runner build` after model changes.
- **Analysis**: `very_good_analysis` — run `flutter analyze` before reporting done.
- **Formatting**: run `dart format lib/` before commit to auto-format all Dart files.
- **Import ordering**: Dart has no built-in import sorter. Follow the order: `dart:` → `package:` → relative, alphabetically within each group. Use `directives_ordering` lint to catch violations.

### Layer contract

| Layer | Location | What goes there |
|-------|----------|-----------------|
| **Shared DTOs** | `data/models/` | `@freezed` classes matching MAL/AniList API JSON |
| **Shared API clients** | `data/mal/`, `data/anilist/` | Dio-based HTTP/GraphQL clients |
| **Domain entities** | `features/*/domain/entities/` | **Plain Dart classes** (NOT freezed) |
| **Abstract repos** | `features/*/domain/repositories/` | `abstract interface class` |
| **Use cases** | `features/*/domain/usecases/` | Single-purpose classes, named `get_*.dart` |
| **Repo impls** | `features/*/data/` | Implements abstract repo, maps DTO → entity |
| **Providers** | `features/*/providers/` | `@riverpod` providers, file named `*_providers.dart` |
| **Screens** | `features/*/presentation/screens/` | `*_page.dart` |
| **Widgets** | `features/*/presentation/widgets/` or `shared/widgets/` | Feature-specific or shared widgets |
| **Core infra** | `core/` | Logger, network, router, theme, storage, constants |

### Feature isolation rule
```dart
// ALLOWED — feature imports from shared layers
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/mal/mal_api_client.dart';
import 'package:animal/core/logger/app_logger.dart';

// FORBIDDEN — feature imports from another feature
import 'package:animal/features/home/...';  // NO
```

If two features need the same data, lift the provider to `core/providers.dart` or create shared providers.

## API Strategy

| Data | Source |
|------|--------|
| User list, anime detail, score, ranking, seasonal | MAL API |
| Characters, voice actors, staff | AniList GraphQL |
| Airing schedule (airingAt, episode, countdown) | AniList GraphQL |
| MAL score (mean) | MAL API |

- **MAL is primary** for anime info and user data.
- **AniList is supplementary** for schedule and people data.
- When merging, MAL data takes priority.
- Cache API responses to avoid rate limits (15 min).

### Rate-Limit Protection

- **MAL** allows ~60 req/min. **AniList** ~90 req/min. **Every API call MUST be cached** at the repository layer.
- Use `MemoryCache` from `data/local/memory_cache.dart` for in-memory caching with TTL.
- **Cache durations by data type:**

| Data | TTL | Reason |
|------|-----|--------|
| User anime list | 3 min | Changes on user action; invalidated on edit/delete |
| Search results | 1 min | Results change frequently; debounce 300ms at provider |
| Rankings | 10 min | Stable within a session |
| Seasonal anime | 15 min | Season data is static |
| Anime detail | 15 min | Rarely changes |
| MAL user info | 10 min | Rarely changes |
| AniList extra info | 15 min | Characters/staff stable |
| AniList character/staff | 30 min | Very stable data |
| Airing schedule | 15 min | Already cached in AiringRepository |

- **Invalidate user list cache** on `updateAnimeListStatus` / `deleteAnimeFromList`.
- **Never make uncached API calls** in widget build methods — always go through a cached repository/provider.
- **Avoid per-request methods** when a batched/cached alternative exists (e.g., use cached `getWeeklyAiringSchedule` instead of per-day queries).

## Logging

- Use `appLogger` from `core/logger/app_logger.dart` (standardized `Logger` with PrettyPrinter).
- Providers that need logging inject via `ref.watch(loggerProvider)`.
- Do NOT create new `Logger()` instances — use the shared `appLogger`.

## UI / UX Rules

### Cards
- **Unified card widget** (`anime_card.dart`) used across all pages.
- **Full-height image** (left side), info (right side).
- **Image radius**: left side only (`topLeft` + `bottomLeft`).
- **Edit modal** on all cards: via ⋮ button or long press.
- Modal allows: change status, edit episodes (text input + +/-), change score (dropdown 0–10).
- **Broadcast time**: convert JST → local OS time via `core/utils/date_utils.dart`.
- **Score**: `anime.mean` from MAL (star icon, amber). Personal score from `myListStatus?.score` (star icon, primary color).

### Tabs
- Tabs should be **scrollable** when there are many.
- Active tab defaults to **today** (for day-based tabs).
- Don't add badge counts unless requested.

### Calendar Page
- 4 seasons (Winter/Spring/Summer/Fall) + "Later" tab.
- Year selector: current year - 50 to current year + 1.
- Default year: current year.
- Auto-scroll to selected year in picker dialog.
- Anime without broadcast info shown at bottom without header.
- **No summary text** above cards (e.g. "100 anime · Spring 2026").

### Airing Page
- Data from AniList schedule + MAL scores.
- Grouped by day (Mon–Sun).
- Countdown timer: `2d 5h`, `3h 20m`, `45m` (via `core/utils/date_utils.dart`).
- Urgent (< 6h): red color.
- **No header info** above tabs.
- Sort by airing time (earliest first).

### Detail Page
- Cover image with gradient overlay (transparent top → surface bottom).
- Back button: visible circle with white arrow.
- **Full-screen image viewer** on cover tap (zoom supported).
- Info chips: score, rank, episodes, media type, status, rating.
- Sections: genres, broadcast, source, related anime, alternative titles, characters & staff.
- Characters & staff from **AniList** (not MAL).
- 4 items default, "See All" button to expand.

### Profile Page
- Real data from MAL `/users/@me`.
- Stats: days watched, mean score, total anime, episodes, per-status counts.

## Font

- **Primary**: Inter (400 body, 500 label, 600 title, 700 heading).
- **Fallback**: Noto Sans JP.
- Configured via `google_fonts` package in `core/theme/app_text_styles.dart`.

## Theme

- **Dark mode** by default (`ThemeMode.dark`).
- Material 3 with indigo seed color.
- Theme built in `core/theme/app_theme.dart` (not hardcoded in `app.dart`).
- **Colors**: ALL colors MUST be defined in `lib/core/theme/app_colors.dart` — NEVER use raw `Colors.blue`, `Colors.green`, etc. Use `AppColors.*` static constants (e.g., `AppColors.listWatching`, `AppColors.statusAiring`). For theme-aware colors, extend `StatusColors` with both light and dark variants.

## Environment

- Credentials via `--dart-define` compile-time constants, NOT `flutter_dotenv`.
- Loaded by `core/config/env.dart` using `String.fromEnvironment()`.
- Variables: `MAL_CLIENT_ID`, `MAL_CLIENT_SECRET`, `MAL_REDIRECT_URI`.
- `.env` file is gitignored (for local script convenience, NOT used by the app).

## File Naming

| Type | Pattern | Example |
|------|---------|---------|
| Pages/Screens | `*_page.dart` | `home_page.dart`, `login_page.dart` |
| Providers | `*_providers.dart` | `home_providers.dart`, `airing_providers.dart` |
| Data models (DTOs, freezed) | `*.dart` | `anime.dart`, `mal_user.dart` |
| Domain entities (plain) | `*_entity.dart` | `anime_entity.dart`, `airing_entry.dart` |
| Abstract repositories | `*_repository.dart` | `home_repository.dart` |
| Repo implementations | `*_repository_impl.dart` | `home_repository_impl.dart` |
| Use cases | `get_*.dart` | `get_trending_anime.dart` |
| Shared widgets | `*.dart` | `anime_card.dart`, `loading_shimmer.dart` |
| API clients | `*_client.dart` | `mal_api_client.dart`, `anilist_client.dart` |

## Don'ts

- Don't remove broadcast time from cards (needed for countdown).
- Don't add unnecessary info/headers above tab content.
- Don't use AniList external links for character/staff (not supported by API).
- **Don't import from other features** — use shared data layer or lift providers.
- **Don't put freezed models in domain layer** — domain entities are plain Dart.
- **Don't create new Logger()** — use `appLogger` from `core/logger/`.
- **Don't hardcode API endpoints** — use `core/constants/mal_endpoints.dart`.
- **Don't hardcode GraphQL queries** — use `core/constants/anilist_queries.dart`.
- Don't add comments unless asked.
- Don't use emojis unless asked.
- Don't commit without explicit permission.
