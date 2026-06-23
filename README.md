# AniMAL

Unofficial MyAnimeList client built with Flutter.

## Tech Stack

| Layer | Package |
|-------|---------|
| State | `flutter_riverpod` |
| Routing | `go_router` (StatefulShellRoute for tab navigation) |
| HTTP | `dio` |
| Codegen | `freezed` + `json_serializable` (data layer DTOs only) |
| Secure storage | `flutter_secure_storage` |
| Preferences | `shared_preferences` |
| Images | `cached_network_image` |
| Fonts | `google_fonts` (Inter + Noto Sans JP) |
| Notifications | `flutter_local_notifications` |
| Timezone | `timezone` |

## APIs

| API | Usage |
|-----|-------|
| [MyAnimeList API v2](https://myanimelist.net/apiconfig) | User list, detail, search, ranking, seasonal, scores |
| [AniList GraphQL](https://anilist.gitbook.io/anilist-apiv2-docs/) | Characters, staff, studios, airing schedule |

## Architecture

**Feature-Based** with strict isolation. No cross-feature imports.

```
feature/
├── data/          Repo implementations, maps DTO → entity
├── domain/        Entities (plain Dart), abstract repos, use cases
├── providers/     Riverpod providers (*_providers.dart)
└── presentation/  Screens (*_page.dart) + widgets
```

Shared layers: `data/` (models, API clients), `core/` (infrastructure), `shared/` (widgets, providers).

## Project Structure

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── config/            Environment (--dart-define)
│   ├── constants/         MAL endpoints, AniList GraphQL queries
│   ├── logger/            Standardized appLogger (PrettyPrinter)
│   ├── network/           Dio, auth/refresh interceptors, ApiException
│   ├── notification/      Local notification service
│   ├── router/            GoRouter, auth guard, route guards
│   ├── storage/           Secure token storage
│   ├── theme/             AppColors, StatusColors, text styles, theme builder
│   ├── utils/             Date/timezone, anime labels, github check
│   └── providers.dart     Dio, logger, tokens, notification, auth
│
├── data/                  Shared data layer
│   ├── mal/               MAL API client, MAL OAuth client
│   ├── anilist/           AniList GraphQL client
│   ├── local/             In-memory cache (MemoryCache)
│   └── models/            @freezed DTOs
│       └── anilist/       AniList plain Dart models
│
├── shared/
│   ├── providers/         Shared Riverpod providers
│   │   ├── airing_entry.dart (AiringEntry + airingByMalIdProvider)
│   │   ├── anime_providers.dart (AnimeRepository + detail/ranking providers)
│   │   ├── anilist_providers.dart (AniList character/staff/studio/extra)
│   │   ├── anime_list_providers.dart (userAnimeListProvider)
│   │   ├── anime_notification_providers.dart
│   │   └── theme_providers.dart (themeModeProvider)
│   └── widgets/           Shared widgets
│       ├── anime_card.dart (unified card with list status badge)
│       ├── info_chip.dart
│       └── full_screen_image.dart
│
└── features/
    ├── home/              Anime lists (Watching/Completed/etc.)
    │   └── presentation/  (composed via StatefulShellRoute)
    ├── airing/            Weekly schedule (AniList + MAL scores)
    │   ├── providers/
    │   └── presentation/
    ├── seasonal/          Seasonal calendar browser
    │   ├── providers/
    │   └── presentation/
    ├── profile/           User profile + stats
    │   ├── domain/
    │   ├── providers/
    │   └── presentation/
    ├── auth/              MAL OAuth2 PKCE login
    │   ├── data/
    │   ├── providers/
    │   └── presentation/
    ├── detail/            Anime detail, character, staff, studio pages
    │   └── presentation/
    └── search/            Search + rankings
        ├── providers/
        └── presentation/
```

## Getting Started

```bash
git clone https://github.com/andrizan/AniMAL.git
cd AniMAL
flutter pub get
dart run build_runner build
```

### Run

```bash
flutter run \
  --dart-define=MAL_CLIENT_ID=xxx \
  --dart-define=MAL_CLIENT_SECRET=xxx
```

## License

[MIT](LICENSE)
