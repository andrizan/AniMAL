import 'dart:convert';

import 'package:animal/core/config/env.dart';
import 'package:animal/core/logger/app_logger.dart';
import 'package:animal/core/storage/secure_token_storage.dart';
import 'package:animal/data/models/auth_token.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class RefreshInterceptor extends Interceptor {
  RefreshInterceptor({
    required SecureTokenStorage tokenStorage,
    required Dio dio,
    Logger? logger,
  }) : _tokenStorage = tokenStorage,
       _dio = dio,
       _logger = logger ?? appLogger;

  final SecureTokenStorage _tokenStorage;
  final Dio _dio;
  final Logger _logger;
  Future<bool>? _refreshFuture;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      _logger.w('RefreshInterceptor: 401 — attempting token refresh');
      _refreshFuture ??= _refreshToken();
      final future = _refreshFuture!;
      _refreshFuture = null;
      final refreshed = await future;
      if (refreshed) {
        final token = await _tokenStorage.getAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $token';
        final response = await _dio.fetch<dynamic>(err.requestOptions);
        handler.resolve(response);
        return;
      }
    }
    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
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
    _logger.i('Token refreshed');
    return true;
  }
}
