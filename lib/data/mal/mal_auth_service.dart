import 'dart:convert';
import 'dart:math';

import 'package:animal/core/config/env.dart';
import 'package:animal/core/storage/secure_token_storage.dart';
import 'package:animal/features/auth/data/models/auth_token.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class MalAuthService {
  MalAuthService({
    required SecureTokenStorage tokenStorage,
    required Dio dio,
    Logger? logger,
  })  : _tokenStorage = tokenStorage,
        _dio = dio,
        _logger = logger ?? Logger();

  final SecureTokenStorage _tokenStorage;
  final Dio _dio;
  final Logger _logger;

  static const _charset =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  String _generateCodeVerifier() {
    final random = Random.secure();
    return List.generate(128, (_) => _charset[random.nextInt(_charset.length)])
        .join();
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = base64Url.encode(bytes).replaceAll('=', '');
    return digest;
  }

  Future<Uri> buildAuthorizationUrl() async {
    final codeVerifier = _generateCodeVerifier();
    await _tokenStorage.saveCodeVerifier(codeVerifier);

    final codeChallenge = _generateCodeChallenge(codeVerifier);

    return Uri.parse(Env.malAuthUrl).replace(queryParameters: {
      'response_type': 'code',
      'client_id': Env.malClientId,
      'redirect_uri': Env.malRedirectUri,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'plain',
      'state': DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }

  Future<void> exchangeCode(String code) async {
    final codeVerifier = await _tokenStorage.getCodeVerifier();
    if (codeVerifier == null) throw Exception('Code verifier not found');

    final response = await _dio.post<String>(
      Env.malTokenUrl,
      options: Options(contentType: Headers.formUrlEncodedContentType),
      data: {
        'client_id': Env.malClientId,
        'client_secret': Env.malClientSecret,
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': Env.malRedirectUri,
        'code_verifier': codeVerifier,
      },
    );

    final token = AuthToken.fromJson(
      jsonDecode(response.data ?? '') as Map<String, dynamic>,
    );
    await _tokenStorage.saveTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
    );
    await _tokenStorage.clearCodeVerifier();
    _logger.i('OAuth2 code exchanged successfully');
  }

  Future<bool> get isAuthenticated async {
    final token = await _tokenStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<AuthToken?> refreshToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await _dio.post<String>(
        Env.malTokenUrl,
        options: Options(contentType: Headers.formUrlEncodedContentType),
        data: {
          'client_id': Env.malClientId,
          'client_secret': Env.malClientSecret,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      );
      final token = AuthToken.fromJson(
        jsonDecode(response.data ?? '') as Map<String, dynamic>,
      );
      await _tokenStorage.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );
      return token;
    } on Exception catch (e) {
      _logger.e('Token refresh failed', error: e);
      return null;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    _logger.i('User logged out');
  }
}
