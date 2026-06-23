import 'package:animal/core/config/env.dart';
import 'package:animal/core/logger/app_logger.dart';
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
      _SafeLogInterceptor(logger ?? appLogger),
    ]);
  }

  final Dio _dio;

  /// The underlying [Dio] instance.
  Dio get dio => _dio;
}

/// Logging interceptor that redacts sensitive data.
///
/// Never logs the OAuth token endpoint body/headers and always redacts
/// the `Authorization` header to avoid leaking bearer tokens.
class _SafeLogInterceptor extends Interceptor {
  _SafeLogInterceptor(this._logger);

  final Logger _logger;

  bool _isTokenRequest(RequestOptions options) =>
      options.path == Env.malTokenUrl ||
      options.uri.toString() == Env.malTokenUrl;

  Map<String, dynamic> _redactHeaders(Map<String, dynamic> headers) {
    if (headers.containsKey('Authorization')) {
      return {...headers, 'Authorization': '***'};
    }
    return {...headers};
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final isToken = _isTokenRequest(options);
    _logger.d('${options.method} ${options.path}${isToken ? ' [token]' : ''}');
    if (!isToken) {
      _logger
        ..d('headers: ${_redactHeaders(options.headers)}')
        ..d('body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final isToken = _isTokenRequest(response.requestOptions);
    _logger.d(
      '${response.statusCode} ${response.requestOptions.path}${isToken ? ' [token]' : ''}',
    );
    if (!isToken) {
      _logger.d('body: ${response.data}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e(
      'DioError ${err.type} ${err.requestOptions.path} | ${err.message}',
    );
    handler.next(err);
  }
}
