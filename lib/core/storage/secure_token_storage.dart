import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure wrapper around [FlutterSecureStorage] for persisting OAuth tokens
/// and PKCE code verifier.
class SecureTokenStorage {
  const SecureTokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'mal_access_token';
  static const _refreshTokenKey = 'mal_refresh_token';
  static const _codeVerifierKey = 'mal_code_verifier';

  /// Persist both tokens.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Read the stored access token.
  Future<String?> getAccessToken() =>
      _storage.read(key: _accessTokenKey);

  /// Read the stored refresh token.
  Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  /// Persist the PKCE code verifier.
  Future<void> saveCodeVerifier(String codeVerifier) async {
    await _storage.write(key: _codeVerifierKey, value: codeVerifier);
  }

  /// Read the stored PKCE code verifier.
  Future<String?> getCodeVerifier() =>
      _storage.read(key: _codeVerifierKey);

  /// Clear the stored PKCE code verifier.
  Future<void> clearCodeVerifier() async {
    await _storage.delete(key: _codeVerifierKey);
  }

  /// Delete all stored tokens and code verifier (logout).
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _codeVerifierKey);
  }
}
