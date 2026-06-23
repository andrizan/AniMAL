import 'package:animal/core/config/env.dart';
import 'package:animal/core/network/auth_interceptor.dart';
import 'package:animal/core/storage/secure_token_storage.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Configured [Dio] instance for communicating with the MyAnimeList API.
class DioClient {
  DioClient({
    required SecureTokenStorage tokenStorage,
    Logger? logger,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: Env.malBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'X-MAL-CLIENT-ID': Env.malClientId,
            },
          ),
        ) {
    _dio.interceptors.addAll([
      AuthInterceptor(
        tokenStorage: tokenStorage,
        dio: _dio,
        logger: logger,
      ),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => (logger ?? Logger()).d(o),
      ),
    ]);
  }

  final Dio _dio;

  /// The underlying [Dio] instance.
  Dio get dio => _dio;
}
