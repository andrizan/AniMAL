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
- **When moving/renaming files**, use plain `mv` (not `git mv`) unless the user asks to preserve git history. Plain `mv` is safer — if something fails, files stay in place.

## Architecture

- **Clean architecture**: domain / data / presentation layers.
- **State management**: `flutter_riverpod` only.
- **Routing**: `go_router` with auth guard.
- **Codegen**: `freezed` + `json_serializable`. Run `dart run build_runner build` after model changes.
- **Analysis**: `very_good_analysis` — run `flutter analyze` before reporting done.

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

## UI / UX Rules

### Cards
- **Unified card widget** (`anime_card.dart`) used across all pages.
- **Full-height image** (left side), info (right side).
- **Image radius**: left side only (`topLeft` + `bottomLeft`).
- **Edit modal** on all cards: via ⋮ button or long press.
- Modal allows: change status, edit episodes (text input + +/-), change score (dropdown 0–10).
- **Broadcast time**: convert JST → local OS time. Keep for countdown.
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
- Countdown timer: `2d 5h`, `3h 20m`, `45m`.
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
- Configured via `google_fonts` package.

## Theme

- **Dark mode** by default (`ThemeMode.dark`).
- Material 3 with indigo seed color.

## Environment

- Credentials in `.env` file (gitignored).
- Loaded via `flutter_dotenv` in `main.dart`.
- `MAL_CLIENT_ID`, `MAL_CLIENT_SECRET`, `MAL_REDIRECT_URI`.

## File Naming

- Pages: `*_page.dart`
- Providers/controllers: `*_controller.dart` or `*_providers.dart`
- Domain models: `*.dart` (freezed)
- Shared widgets: `*.dart` (e.g. `anime_card.dart`)

## Don'ts

- Don't remove broadcast time from cards (needed for countdown).
- Don't add unnecessary info/headers above tab content.
- Don't use AniList external links for character/staff (not supported by API).
- Don't add comments unless asked.
- Don't use emojis unless asked.
- Don't commit without explicit permission.
