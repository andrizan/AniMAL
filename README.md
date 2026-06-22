# AniMAL

Unofficial MyAnimeList client built with Flutter. Track your anime, view schedules, and manage your watchlist.

## Features

- **Home** — My anime lists: Watching, Plan to Watch, On Hold, Completed, Dropped
- **Airing** — Weekly airing schedule from AniList (Monday–Sunday)
- **Calendar** — Seasonal anime browser by year/season (up to 50 years back)
- **Profile** — MAL user stats, settings, logout
- **Search** — Search anime or browse top rankings
- **Detail** — Anime info, synopsis, genres, broadcast, related anime, characters & staff (from AniList)
- **List Management** — Add, update score/episodes/status, and remove anime
- **MAL Login** — OAuth2 PKCE authentication with MyAnimeList

## Tech Stack

| Layer | Package |
|-------|---------|
| State Management | `flutter_riverpod` |
| Routing | `go_router` |
| HTTP Client | `dio` |
| Code Generation | `freezed` + `json_serializable` |
| Secure Storage | `flutter_secure_storage` |
| Image Caching | `cached_network_image` |
| Fonts | `google_fonts` (Inter + Noto Sans JP) |
| Env Config | `flutter_dotenv` |

## APIs

| API | Usage |
|-----|-------|
| [MyAnimeList API v2](https://myanimelist.net/apiconfig) | User list, anime detail, search, ranking, seasonal |
| [AniList GraphQL](https://anilist.gitbook.io/anilist-apiv2-docs/) | Characters, voice actors, staff, weekly airing schedule |

## Project Structure

```
lib/
├── core/
│   ├── config/env.dart              # MAL API credentials (reads .env)
│   ├── network/                     # Dio client, interceptors, exceptions
│   ├── router/app_router.dart       # GoRouter config with auth guard
│   └── storage/                     # Secure token storage (PKCE code verifier)
├── features/
│   ├── anime/
│   │   ├── data/
│   │   │   ├── anilist_api.dart     # AniList GraphQL client
│   │   │   ├── anime_repository.dart
│   │   │   └── mal_anime_api.dart   # MAL REST client
│   │   ├── domain/                  # Freezed models
│   │   └── presentation/
│   │       ├── anime_airing_page.dart
│   │       ├── anime_card.dart
│   │       ├── anime_detail_page.dart
│   │       ├── anime_home_tab.dart
│   │       ├── anime_list_card.dart
│   │       ├── anime_list_tab.dart
│   │       ├── anime_profile_page.dart
│   │       ├── anime_schedule_page.dart
│   │       ├── anime_search_page.dart
│   │       ├── full_screen_image.dart
│   │       ├── home_page.dart
│   │       └── ...
│   └── auth/
│       ├── data/mal_auth_repository.dart
│       ├── domain/auth_token.dart
│       └── presentation/
│           ├── auth_controller.dart
│           ├── login_page.dart
│           └── oauth_callback_page.dart
├── app.dart
└── main.dart
```

## Getting Started

### Prerequisites

- Flutter 3.44+ (Dart 3.12+)
- MyAnimeList API key — [Register here](https://myanimelist.net/apiconfig)

### Setup

1. Clone the repo:
   ```bash
   git clone https://github.com/andrizan/AniMAL.git
   cd animal
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate code:
   ```bash
   dart run build_runner build
   ```

4. Create `.env` file from the example:
   ```bash
   cp .env.example .env
   ```

5. Fill in your MAL API credentials in `.env`:
   ```env
   MAL_CLIENT_ID=your_client_id
   MAL_CLIENT_SECRET=
   MAL_REDIRECT_URI=animal://oauth/callback
   ```

6. Run the app:
   ```bash
   flutter run
   ```

### Build

```bash
# Android
flutter build apk

# iOS
flutter build ios
```

The `.env` file is bundled with the app and read at startup. No `--dart-define` flags needed.

## MAL API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /users/@me/animelist` | User's anime list (by status) |
| `GET /anime/{id}` | Anime detail |
| `GET /anime` | Search anime |
| `GET /anime/season/{year}/{season}` | Seasonal schedule |
| `GET /anime/ranking` | Top anime ranking |
| `GET /users/@me` | User profile + stats |
| `PUT /anime/{id}/my_list_status` | Update list entry |
| `DELETE /anime/{id}/my_list_status` | Remove from list |

## AniList GraphQL Queries

| Query | Description |
|-------|-------------|
| `Media` (by `idMal`) | Characters + voice actors |
| `Character` | Character detail + media appearances |
| `Staff` | Staff detail + works |
| `Page.airingSchedules` | Weekly airing schedule |

## License
[MIT License](LICENSE)
