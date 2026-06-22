import 'dart:convert';

import 'package:animal/core/config/env.dart';
import 'package:animal/core/storage/secure_token_storage.dart';
import 'package:animal/features/auth/domain/auth_token.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Dio interceptor that attaches the Bearer token to every request
/// and handles 401 responses by attempting a token refresh.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureTokenStorage tokenStorage,
    required Dio dio,
    Logger? logger,
  })  : _tokenStorage = tokenStorage,
        _dio = dio,
        _logger = logger ?? Logger();

  final SecureTokenStorage _tokenStorage;
  final Dio _dio;
  final Logger _logger;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      _logger.d('AuthInterceptor: token attached to ${options.uri}');
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _logger.w('AuthInterceptor: received 401 – attempting token refresh');
      _isRefreshing = true;

      try {
        final refreshed = await _refreshToken();
        _isRefreshing = false;

        if (refreshed) {
          // Retry the original request with new token
          final token = await _tokenStorage.getAccessToken();
          err.requestOptions.headers['Authorization'] = 'Bearer $token';

          final response = await _dio.fetch<dynamic>(err.requestOptions);
          handler.resolve(response);
          return;
        }
      } on Exception catch (e) {
        _logger.e('AuthInterceptor: token refresh failed', error: e);
        _isRefreshing = false;
        // Clear tokens on refresh failure
        await _tokenStorage.clear();
      }
    }

    handler.next(err);
  }

  /// Attempt to refresh the access token using the stored refresh token.
  Future<bool> _refreshToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

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
      jsonDecode(response.data!) as Map<String, dynamic>,
    );

    await _tokenStorage.saveTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
    );

    _logger.i('Token refreshed successfully');
    return true;
  }
}
