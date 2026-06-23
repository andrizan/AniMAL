import 'dart:convert';
import 'dart:math';

import 'package:animal/core/config/env.dart';
import 'package:animal/core/network/api_exception.dart';
import 'package:animal/core/storage/secure_token_storage.dart';
import 'package:animal/features/auth/data/models/auth_token.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class MalAuthRepository {
  MalAuthRepository({required this._tokenStorage, Dio? dio, Logger? logger})
      : _dio = dio ?? Dio(), _logger = logger ?? Logger();

  final SecureTokenStorage _tokenStorage;
  final Dio _dio;
  final Logger _logger;

  String _generateCodeVerifier([int length = 128]) {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  Future<Uri> buildAuthorizationUrl() async {
    final codeVerifier = _generateCodeVerifier();
    await _tokenStorage.saveCodeVerifier(codeVerifier);
    return Uri.parse(Env.malAuthUrl).replace(queryParameters: {
      'response_type': 'code', 'client_id': Env.malClientId, 'redirect_uri': Env.malRedirectUri,
      'code_challenge': codeVerifier, 'code_challenge_method': 'plain',
    });
  }

  Future<AuthToken> exchangeCode(String authorizationCode) async {
    final codeVerifier = await _tokenStorage.getCodeVerifier();
    if (codeVerifier == null || codeVerifier.isEmpty) {
      throw const ApiException.unauthorized(message: 'Code verifier not found. Please restart the login flow.');
    }
    _logger.i('Exchanging authorization code...');
    final response = await _dio.post<String>(Env.malTokenUrl,
      options: Options(contentType: Headers.formUrlEncodedContentType),
      data: {'client_id': Env.malClientId, 'client_secret': Env.malClientSecret, 'grant_type': 'authorization_code', 'code': authorizationCode, 'redirect_uri': Env.malRedirectUri, 'code_verifier': codeVerifier},
    );
    final token = AuthToken.fromJson(jsonDecode(response.data ?? '') as Map<String, dynamic>);
    await _tokenStorage.saveTokens(accessToken: token.accessToken, refreshToken: token.refreshToken);
    await _tokenStorage.clearCodeVerifier();
    _logger.i('Tokens saved');
    return token;
  }

  Future<AuthToken?> refreshToken() async {
    final currentRefresh = await _tokenStorage.getRefreshToken();
    if (currentRefresh == null) return null;
    _logger.i('Refreshing access token...');
    final response = await _dio.post<String>(Env.malTokenUrl,
      options: Options(contentType: Headers.formUrlEncodedContentType),
      data: {'client_id': Env.malClientId, 'client_secret': Env.malClientSecret, 'grant_type': 'refresh_token', 'refresh_token': currentRefresh},
    );
    final token = AuthToken.fromJson(jsonDecode(response.data ?? '') as Map<String, dynamic>);
    await _tokenStorage.saveTokens(accessToken: token.accessToken, refreshToken: token.refreshToken);
    _logger.i('Token refreshed');
    return token;
  }

  Future<void> logout() => _tokenStorage.clear();

  Future<bool> get isAuthenticated async {
    final token = await _tokenStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
