import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ApiSource { mal, anilist }

enum ApiStatus { healthy, error, rateLimited, unknown }

class ApiHealth {
  const ApiHealth({
    required this.source,
    required this.status,
    required this.totalHits,
    required this.totalErrors,
    required this.totalRateLimited,
    this.lastHit,
    this.lastError,
    this.lastErrorMessage,
    this.lastStatusCode,
    this.retryAfter,
  });

  final ApiSource source;
  final ApiStatus status;
  final int totalHits;
  final int totalErrors;
  final int totalRateLimited;
  final DateTime? lastHit;
  final DateTime? lastError;
  final String? lastErrorMessage;
  final int? lastStatusCode;
  final DateTime? retryAfter;

  ApiHealth copyWith({
    ApiStatus? status,
    int? totalHits,
    int? totalErrors,
    int? totalRateLimited,
    DateTime? lastHit,
    DateTime? lastError,
    String? lastErrorMessage,
    int? lastStatusCode,
    DateTime? retryAfter,
  }) {
    return ApiHealth(
      source: source,
      status: status ?? this.status,
      totalHits: totalHits ?? this.totalHits,
      totalErrors: totalErrors ?? this.totalErrors,
      totalRateLimited: totalRateLimited ?? this.totalRateLimited,
      lastHit: lastHit ?? this.lastHit,
      lastError: lastError ?? this.lastError,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
      lastStatusCode: lastStatusCode ?? this.lastStatusCode,
      retryAfter: retryAfter ?? this.retryAfter,
    );
  }
}

class ApiHealthTracker extends Notifier<Map<ApiSource, ApiHealth>> {
  @override
  Map<ApiSource, ApiHealth> build() {
    return {
      ApiSource.mal: ApiHealth(
        source: ApiSource.mal,
        status: ApiStatus.unknown,
        totalHits: 0,
        totalErrors: 0,
        totalRateLimited: 0,
      ),
      ApiSource.anilist: ApiHealth(
        source: ApiSource.anilist,
        status: ApiStatus.unknown,
        totalHits: 0,
        totalErrors: 0,
        totalRateLimited: 0,
      ),
    };
  }

  void recordSuccess(ApiSource source, {Map<String, List<String>>? headers}) {
    final current = state[source]!;
    final retryAfter = _parseRetryAfter(headers);
    state = {
      ...state,
      source: current.copyWith(
        status: ApiStatus.healthy,
        totalHits: current.totalHits + 1,
        lastHit: DateTime.now(),
        retryAfter: retryAfter,
      ),
    };
  }

  void recordError(
    ApiSource source, {
    required int statusCode,
    String? message,
    Map<String, List<String>>? headers,
  }) {
    final current = state[source]!;
    final isRateLimited = statusCode == 429;
    final retryAfter = _parseRetryAfter(headers);
    state = {
      ...state,
      source: current.copyWith(
        status: isRateLimited ? ApiStatus.rateLimited : ApiStatus.error,
        totalErrors: current.totalErrors + 1,
        totalRateLimited: isRateLimited
            ? current.totalRateLimited + 1
            : current.totalRateLimited,
        lastError: DateTime.now(),
        lastErrorMessage: message,
        lastStatusCode: statusCode,
        retryAfter: retryAfter,
      ),
    };
  }

  void reset(ApiSource source) {
    state = {
      ...state,
      source: ApiHealth(
        source: source,
        status: ApiStatus.unknown,
        totalHits: 0,
        totalErrors: 0,
        totalRateLimited: 0,
      ),
    };
  }

  DateTime? _parseRetryAfter(Map<String, List<String>>? headers) {
    if (headers == null) return null;
    final values = headers['retry-after'];
    if (values == null || values.isEmpty) return null;
    final seconds = int.tryParse(values.first);
    if (seconds == null) return null;
    return DateTime.now().add(Duration(seconds: seconds));
  }
}

final apiHealthTrackerProvider =
    NotifierProvider<ApiHealthTracker, Map<ApiSource, ApiHealth>>(
      ApiHealthTracker.new,
    );

String apiSourceLabel(ApiSource source) {
  return switch (source) {
    ApiSource.mal => 'MyAnimeList',
    ApiSource.anilist => 'AniList',
  };
}
