/// Environment configuration for the app.
///
/// Values are loaded from `--dart-define` at compile time.
abstract final class Env {
  /// MyAnimeList API Client ID.
  static const String malClientId = String.fromEnvironment('MAL_CLIENT_ID');

  /// MyAnimeList API Client Secret (optional, for confidential clients).
  static const String malClientSecret = String.fromEnvironment('MAL_CLIENT_SECRET');

  /// OAuth2 redirect URI registered in MyAnimeList.
  static const String malRedirectUri = String.fromEnvironment(
    'MAL_REDIRECT_URI',
    defaultValue: 'animal://oauth/callback',
  );

  /// MyAnimeList API base URL.
  static const String malBaseUrl = 'https://api.myanimelist.net/v2';

  /// MyAnimeList OAuth2 authorization endpoint.
  static const String malAuthUrl =
      'https://myanimelist.net/v1/oauth2/authorize';

  /// MyAnimeList OAuth2 token endpoint.
  static const String malTokenUrl =
      'https://myanimelist.net/v1/oauth2/token';

  /// GitHub repository URL.
  static const String githubRepoUrl = 'https://github.com/andrizan/AniMAL';
}
