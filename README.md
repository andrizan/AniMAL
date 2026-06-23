# AniMAL

Unofficial MyAnimeList client built with Flutter.

## Tech Stack

| Layer | Package |
|-------|---------|
| State | `flutter_riverpod` |
| Routing | `go_router` |
| HTTP | `dio` |
| Codegen | `freezed` + `json_serializable` |
| Secure storage | `flutter_secure_storage` |
| Preferences | `shared_preferences` |
| Images | `cached_network_image` |
| Fonts | `google_fonts` (Inter + Noto Sans JP) |
| Notifications | `flutter_local_notifications` |
| Timezone | `timezone` |
| Env | `--dart-define` (compile-time) |

## APIs

| API | Usage |
|-----|-------|
| [MyAnimeList API v2](https://myanimelist.net/apiconfig) | User list, detail, search, ranking, seasonal, scores |
| [AniList GraphQL](https://anilist.gitbook.io/anilist-apiv2-docs/) | Characters, staff, airing schedule |

## Architecture

**Feature-Based** with strict isolation. Each feature has four layers:

```
feature/
├── data/          Repo implementations, maps DTO → entity
├── domain/        Entities (plain Dart), abstract repos, use cases
├── providers/     Riverpod providers
└── presentation/  Screens + widgets
```

Shared code: `data/` (models, API clients), `core/` (infrastructure), `shared/` (widgets, providers).

## Project Structure

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── config/            Environment (String.fromEnvironment)
│   ├── constants/         MAL endpoints, AniList GraphQL queries
│   ├── error/             Failure sealed class
│   ├── logger/            Standardized appLogger (PrettyPrinter)
│   ├── network/           Dio, auth interceptor, refresh interceptor
│   ├── notification/      Local notification service
│   ├── router/            GoRouter, auth guard, route guards
│   ├── storage/           Secure token storage, shared preferences
│   ├── theme/             ColorScheme, ThemeExtension, text styles, theme builder
│   ├── utils/             Date/timezone, anime labels, extensions
│   └── providers.dart     Core providers (Dio, logger, tokens, notification)
│
├── data/                  Shared data sources
│   ├── mal/               MAL API client, OAuth2 PKCE service
│   ├── anilist/           AniList GraphQL client + models
│   ├── local/             SharedPreferences cache service
│   └── models/            @freezed DTOs (Anime, MalUser, Season, etc.)
│
├── shared/
│   ├── providers/         Shared Riverpod providers
│   │   ├── anime_providers.dart
│   │   ├── anilist_providers.dart
│   │   └── anime_notification_providers.dart
│   └── widgets/           Shared widgets
│       ├── anime_card.dart
│       ├── anime_card_compact.dart
│       ├── loading_shimmer.dart
│       ├── error_state.dart
│       ├── empty_state.dart
│       ├── score_badge.dart
│       └── full_screen_image.dart
│
└── features/
    ├── home/              Trending, seasonal, user anime lists
    ├── airing/            Weekly schedule (AniList + MAL scores)
    ├── seasonal/          Seasonal calendar browser
    ├── profile/           User profile + stats
    ├── auth/              MAL OAuth2 login
    ├── detail/            Anime detail + character/staff pages
    └── search/            Search + rankings
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
