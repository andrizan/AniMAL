import 'package:animal/core/network/api_health_tracker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiHealthInterceptor extends Interceptor {
  ApiHealthInterceptor(this._ref);

  final Ref _ref;

  ApiSource _sourceForUri(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host.contains('myanimelist.net')) return ApiSource.mal;
    if (host.contains('anilist.co')) return ApiSource.anilist;
    return ApiSource.mal;
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final source = _sourceForUri(response.requestOptions.uri);
    _ref
        .read(apiHealthTrackerProvider.notifier)
        .recordSuccess(
          source,
          headers: response.headers.map,
        );
    _ref
        .read(apiHealthTrackerProvider.notifier)
        .recordRateLimitHeaders(source, response.headers.map);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final source = _sourceForUri(err.requestOptions.uri);
    _ref
        .read(apiHealthTrackerProvider.notifier)
        .recordError(
          source,
          statusCode: err.response?.statusCode ?? 0,
          message: err.message,
          headers: err.response?.headers.map,
        );
    _ref
        .read(apiHealthTrackerProvider.notifier)
        .recordRateLimitHeaders(source, err.response?.headers.map);
    handler.next(err);
  }
}
