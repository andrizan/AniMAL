# AniMAL

Unofficial MyAnimeList client built with Flutter.

## Tech Stack

| Layer | Package |
|-------|---------|
| State | `flutter_riverpod` |
| Routing | `go_router` |
| HTTP | `dio` |
| Codegen | `freezed` + `json_serializable` |
| Storage | `flutter_secure_storage` |
| Images | `cached_network_image` |
| Fonts | `google_fonts` (Inter + Noto Sans JP) |
| Env | `--dart-define` (compile-time) |

## APIs

| API | Usage |
|-----|-------|
| [MyAnimeList API v2](https://myanimelist.net/apiconfig) | User list, detail, search, ranking, seasonal, scores |
| [AniList GraphQL](https://anilist.gitbook.io/anilist-apiv2-docs/) | Characters, staff, airing schedule |

## Project Structure

```
lib/
├── core/
│   ├── config/         env.dart
│   ├── extensions/     StringCapitalize
│   ├── network/        dio_client, auth_interceptor, api_exception
│   ├── notification/   AnimeNotificationService
│   ├── router/         GoRouter + auth guard
│   ├── storage/        flutter_secure_storage
│   ├── theme/          ThemeMode.dark default
│   └── utils/          anime_labels (labels, cleanAniListDescription)
│
├── shared/widgets/     full_screen_image
│
└── features/
    ├── auth/           Login, OAuth callback
    ├── library/        Shared anime core: models, API clients, repository, anime_card
    ├── detail/         Anime detail page + character/staff pages
    ├── airing/         Weekly airing schedule
    ├── seasonal/       Seasonal calendar browser
    ├── search/         Search + rankings
    ├── home/           My anime lists (tabs)
    └── profile/        User profile + stats
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
