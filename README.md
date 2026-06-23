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

Features never import from each other. Shared code lives in `data/` (models, API clients), `core/` (infrastructure), and `shared/` (widgets).

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
│   ├── notifications/     Local notification service, timezone helper
│   ├── router/            GoRouter, auth guard, refresh listenable
│   ├── storage/           Secure token storage, shared preferences
│   ├── theme/             App theme, colors, text styles
│   ├── utils/             Date/timezone utils, anime labels, extensions
│   └── providers.dart     Core providers (Dio, logger, tokens)
│
├── data/                  Shared data sources
│   ├── mal/               MAL API client, OAuth2 PKCE service
│   ├── anilist/           AniList GraphQL client + models
│   ├── local/             SharedPreferences cache service
│   └── models/            @freezed DTOs (Anime, MalUser, Season, etc.)
│
├── shared/widgets/        Anime card, compact card, shimmer, error/empty states, score badge
│
└── features/
    ├── home/              Trending, seasonal, user anime lists
    ├── airing/            Weekly schedule (AniList + MAL scores)
    ├── calendar/          Seasonal calendar browser
    ├── profile/           User profile + stats
    ├── notifications/     Episode airing notifications
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
