import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for the app.
///
/// Values are loaded from the `.env` file at app startup.
/// Falls back to `--dart-define` values if `.env` is not available.
abstract final class Env {
  /// MyAnimeList API Client ID.
  static final String malClientId =
      dotenv.env['MAL_CLIENT_ID'] ?? const String.fromEnvironment('MAL_CLIENT_ID');

  /// MyAnimeList API Client Secret (optional, for confidential clients).
  static final String malClientSecret =
      dotenv.env['MAL_CLIENT_SECRET'] ?? const String.fromEnvironment('MAL_CLIENT_SECRET');

  /// OAuth2 redirect URI registered in MyAnimeList.
  static final String malRedirectUri =
      dotenv.env['MAL_REDIRECT_URI'] ?? const String.fromEnvironment(
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
}
