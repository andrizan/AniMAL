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
- All commit messages MUST be in English and follow Conventional Commits:
  `type(scope): subject` (scope optional, subject imperative, lowercase, no trailing period).
- Allowed types: `feat`, `fix`, `chore`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `style`, `revert`.
- Examples: `fix(anilist): cache empty extras to stop repeat fetches`, `feat(airing): throttle background schedule refresh`.
- **NEVER use `git mv`** — use the file tools (Write/Edit/Bash `mv`) instead. `git mv` stages immediately and risks unintended renames.

## Architecture

- **Feature-Based** with strict isolation: features never import from each other.
- Each feature: `data/` → `domain/` → `providers/` → `presentation/`.
- **State management**: `flutter_riverpod` only.
- **List edits**: go through `AnimeRepository.updateAnimeListStatus` /
  `deleteAnimeFromList`. They keep every SQLite snapshot of the personal status
  in sync (user lists, anime rows, stored airing week) and bump
  `animeListVersionProvider`. Do not `ref.invalidate` list providers after an edit.
- A provider that watches `animeListVersionProvider` must be rendered with
  `when(skipLoadingOnReload: true)` (or a `hasValue` check), otherwise an edit
  flashes a spinner and resets the scroll position.
- **Routing**: `go_router` with auth guard in `core/router/route_guards.dart`. The router is built once; the guard reads the live auth status and `AuthRefreshListenable` re-runs it, so never `watch` the auth state in `routerProvider`.
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

- **AniList works lists** (a character's appearances, a staff member's works, a studio's productions) load `AniListClient.worksPageSize` (50, AniList's maximum) per request. The detail carries page 1 and a cursor (`worksCursor`); every further page is appended to SQLite by `AniListCache.appendWorks`, so the next visit starts from everything already loaded and requests only the pages after it. Never change the page size without bumping the schema and dropping the stored details, as `_migrateV3ToV4` did.
- **Invalidate user list cache** on `updateAnimeListStatus` / `deleteAnimeFromList`.
- **Never make uncached API calls** in widget build methods — always go through a cached repository/provider.
- **Avoid per-request methods** when a batched/cached alternative exists (e.g., use cached `getWeeklyAiringSchedule` instead of per-day queries).

## Logging

- Use `appLogger` from `core/logger/app_logger.dart` (standardized `Logger` with PrettyPrinter).
- Providers that need logging inject via `ref.watch(loggerProvider)`.
- Do NOT create new `Logger()` instances — use the shared `appLogger`.

## UI / UX Rules

### Shared UI
- **Cards**: use plain `Card`; the look (radius `AppRadius.card` = 24, `surfaceContainerLow` fill, no border, a soft shadow in light mode only) comes from `cardTheme` in `core/theme/app_theme.dart`. `SectionCard` is the one exception: section blocks round to `AppRadius.hero` (28). Do not override colour or shape per screen. Layers are separated by tone, never by borders.
- **Error / empty states**: use `ErrorView` (message + optional Retry) and `EmptyView` (icon, message, optional hint/Retry) from `shared/widgets/`. Do not hand-roll icon + text + button columns.
- **Section titles**: use `SectionHeader` (`titleMedium` w700, optional trailing caption).
- **Loading**: a full-area load is a centred `CircularProgressIndicator`; inside a card use a skeleton or `LinearProgressIndicator`.
- **Chips**: `InfoChip` is the only pill (tonal by default, `dense` for cards). Status is never colour alone: `ListStatusChip` / `AiringStatusChip` in `shared/widgets/status_chip.dart` pair a tonal `StatusColors` container with an icon and a word; `CountdownBadge` switches to the alert icon and the dropped tint under six hours.
- **Tabs**: `PillTabBar` takes `labels` (and `icons`) and builds the `Tab`s itself: the selected tab is the primary pill from `tabBarTheme`, the others get their own tonal pill; `segmented` swaps that for a tonal track with a raised card pill. Tests find tabs with `find.widgetWithText(Tab, label)`.
- **Search**: no app bar; a tonal back button and the pill field share one row. Ranking cards carry `AnimeCard.rank` as a badge on the cover.
- **Focus**: keyboard focus draws a 3px ring (`_focusRing` in `app_theme.dart`) on buttons, chips and segments and a primary tint on tabs and ink surfaces. Primary-filled buttons ring in `primaryContainer`; `TonalButton` (not `FilledButton.tonal`) is the tonal variant with its own primary ring.
- **Motion**: every route is a 200 ms fade (`fadePage` in `core/router/app_router.dart`), zero when `MediaQuery.disableAnimations` is set; chart animations follow the same flag.
- **Buttons**: primary `FilledButton` 52px, `TonalButton` for secondary actions, `TextButton` for inline ones; sort and filter are tonal menu pills (`Title ↑`, `All airing ▾`).
- **Controls on imagery**: `ScrimIconButton` (48px circle on `AppColors.overlayDarker`).
- **Spacing and radius**: use `AppSpacing` (`xs` 4, `sm` 8, `md` 12, `lg` 16, `xl` 24, `xxl` 32; `page` = 20 is the horizontal gutter of every page and list card) and `AppRadius` (`sm` 8, `md` 12, `lg` 16 inputs, `cover` 18, `card` 24, `hero` 28, `sheet` 32, `pill`) from `core/theme/app_spacing.dart` for page, card and container paddings and corners. Micro offsets inside a component may stay literal.
- **Typography**: never set `fontSize`; pick a slot from `Theme.of(context).textTheme` and adjust only weight or colour with `copyWith`. `labelSmall` (12, w600) is the micro size for badges and chart labels; nothing is smaller than 12px. Tab labels come from `tabBarTheme`.
- **Targets and semantics**: every control has a 48px hit area (`IconButton` inside a 44–48px box, `SizedBox(height: 48)` buttons). Icon-only buttons carry a `tooltip`; progress bars carry a `semanticsLabel` (the value must stay numeric, Flutter validates it).
- `test/core/theme/design_rules_test.dart` fails on raw `fontSize`, `Colors.*`, `Color(0x...)` and hand-rolled error icons outside their allowed files.

### Cards
- **Unified card widget** (`anime_card.dart`) used across all pages.
- **Inset cover** (84×120, radius `AppRadius.cover`) on the left, info on the right. The card sizes to its content: never give lists a fixed `itemExtent`.
- Info rows: optional `header` line, title (2 lines) + ⋮, Japanese title, then `★ mean`, the `You 9` pill and the `ListStatusChip` (hidden with `showListStatus: false` on the Library tab, where the tab already says the status). A listed anime shows a progress bar with `watched / total`; a browse card shows `TV · 12 eps · Airing` instead. The footer holds the countdown, reminder bell and broadcast time; an optional `note` (why the card cannot open) goes under it. Genres, rating and media-type badges stay off the card.
- **Edit modal** on all cards: via ⋮ button or long press.
- Modal allows: change status (chips), edit episodes (plain `+`/`−` stepper + text input), change score (`ScorePicker`, tap the score again to clear). The reminder row names the lead time from `ApiConstants.notificationLeadMinutes`.
- **Broadcast time**: convert JST → local OS time via `core/utils/date_utils.dart` (`Fri 23:30` on cards, `Fridays, 23:30 your time` on the detail page).
- **Score**: `anime.mean` from MAL (`StatusColors.star`). Personal score from `myListStatus?.score` as the `You N` pill on `primaryContainer`.

### Tabs
- Tabs should be **scrollable** when there are many.
- Active tab defaults to **today** (for day-based tabs).
- Don't add badge counts unless requested.

### Calendar Page
- 4 seasons (Winter/Spring/Summer/Fall) + "Later" tab.
- "Later" lists upcoming anime that have no start date yet (MAL `upcoming` ranking, first 3 pages, filtered on `start_date`). It does not depend on the selected year.
- Year selector: current year - 50 to current year + 1.
- Default year: current year.
- Auto-scroll to selected year in picker dialog.
- Anime without broadcast info shown at bottom without header.
- Day headers are upper-cased visually (`semanticsLabel` keeps the plain word) and are semantic headers.
- **No summary text** above cards (e.g. "100 anime · Spring 2026").

### Airing Page
- Data from AniList schedule + MAL scores.
- Grouped by day (Mon–Sun).
- Each card carries the airing time and episode above the title (`AnimeCard.header`); the countdown pill below omits the episode.
- The refresh button lives in the home shell's header (Airing tab only). It and the page's pull-to-refresh share `airingRefreshProvider` in `shared/providers/airing_refresh_providers.dart`, which wraps `refreshWeeklySchedule`, invalidates `weeklyAiringProvider` and reports empty/failed results for the snackbar.
- Countdown timer: `2d 5h`, `3h 20m`, `45m` (via `core/utils/date_utils.dart`).
- Urgent (< 6h): dropped tint plus the alert icon, never colour alone.
- **No header info** above tabs.
- Sort by airing time (earliest first).

### Detail Page
- Cover image with gradient overlay (transparent top → surface bottom). The app bar title is hidden while the cover is expanded and fades in as it collapses (`_CollapsedTitle`), because the heading sits under the cover.
- Back button: visible circle with white arrow (`ScrimIconButton`).
- **Full-screen image viewer** on cover tap (zoom supported).
- **Order = importance**, one `SectionCard` per block, 12 apart:
  1. Header: `headlineMedium` title (a semantic header), Japanese title, `HeroPanel` with type/episodes/status/rating chips and score, rank, popularity.
  2. Your list: `MyListCard` (status and score picker buttons, `watched / total` with a progress bar, −/"Mark episode N watched"/+ row, remove) or the Add to Watching button. The page edits the list only through these; typing an episode number is done from a list card's edit sheet.
  3. Next episode (AniList, when airing) with the reminder `SwitchListTile`; there is no bell in the app bar.
  4. Synopsis with genres (long synopsis collapses behind Read more).
  5. Information: aired/airing, season, broadcast (`Fridays, 23:30 your time`), duration (`24 min per episode`), source, studios.
  6. Characters & voice actors, then staff (AniList).
  7. Related anime, alternative titles, external links.
- Broadcast is stored in JST by MAL; show it converted to the device zone (day included) via `convertJstBroadcastToLocal`.
- Characters & staff from **AniList** (not MAL).
- 4 items default, "See All" button to expand.
- Cards that have nothing to show are left out, never rendered empty.

### Profile Page
- Real data from MAL `/users/@me`.
- Header: avatar, name, one caption (`Member since March 2019 · Indonesia`), plus days watched, episodes and mean score. The connection state lives in Settings (the `Active` chip), not in the header.
- Library donut centred over 44px legend rows (dot, label, count, share); time invested as one bar per status sorted by days; then insight charts: score distribution and activity label only their highlighted bar, top genres, formats. Insights are computed from the cached user lists by `GetProfileInsights` (`profileInsightsProvider`), never from extra API calls.
- Settings: the theme is a `SegmentedButton<ThemeMode>` (Light | Dark), styled by `segmentedButtonTheme`.
- Charts are custom-painted widgets in `profile_charts.dart` (no chart dependency, to keep the APK small). Chart colours come from `AppColors` (`chartPalette`, status colours).

## Font

- **Primary**: Figtree (400 body, 500 label, 600 title, 700 heading).
- **Fallback**: platform system font (Japanese text uses the OS CJK font).
- Configured via `google_fonts` package in `core/theme/app_text_styles.dart`.
- Figtree is bundled in `assets/google_fonts/` (400/500/600/700) and runtime
  fetching is disabled in `main.dart`. Adding another weight requires adding
  its `Figtree-<Weight>.ttf` file there.

## Theme

- **Dark mode** by default (`ThemeMode.dark`).
- Material 3 with hand-tuned lavender neutrals and an indigo accent (`primary`); the schemes in `app_colors.dart` are explicit, not seeded.
- Theme built in `core/theme/app_theme.dart` (not hardcoded in `app.dart`).
- **Colors**: ALL colors MUST be defined in `lib/core/theme/app_colors.dart` — NEVER use raw `Colors.blue`, `Colors.green`, etc. Theme-aware colours come from `StatusColors.of(context)` (solid `list*` marks, `star`, and the `*Container` / `on*Container` pairs); static `AppColors.*` is only for overlays on imagery and the chart palettes.
- **WCAG 2.2 AA**: every text pair is at least 4.5:1 and every icon, border or chart mark at least 3:1. When adding a colour, check it with the same formula and keep the five chart colours as a set (they are validated for colour-vision deficiency together).

## App icon

- The mark is a check made of linked nodes (tracking, kept in step with its sources). It carries no logo of any service: never add MyAnimeList or AniList branding to it.
- `AppMarkPainter` (`shared/widgets/app_mark.dart`) is the only source of the geometry; the login page shows it through `AppMark`.
- Launcher icons are generated, not drawn by hand: `flutter test tool/render_app_icon.dart` rewrites the Android (legacy, adaptive background/foreground/monochrome) and iOS (opaque, no alpha) files. Add `--dart-define=PREVIEW_DIR=<dir>` to write a contact sheet instead.

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
