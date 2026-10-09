import 'package:animal/core/network/api_health_interceptor.dart';
import 'package:animal/core/network/api_health_tracker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  ApiHealthTracker tracker() =>
      container.read(apiHealthTrackerProvider.notifier);
  ApiHealth health(ApiSource s) => container.read(apiHealthTrackerProvider)[s]!;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('starts unknown with zero counters for both sources', () {
    for (final source in ApiSource.values) {
      expect(health(source).status, ApiStatus.unknown);
      expect(health(source).totalHits, 0);
      expect(health(source).totalErrors, 0);
      expect(health(source).totalRateLimited, 0);
    }
  });

  group('recordSuccess', () {
    test('marks healthy, counts hits and stamps the time', () {
      tracker()
        ..recordSuccess(ApiSource.mal)
        ..recordSuccess(ApiSource.mal);

      expect(health(ApiSource.mal).status, ApiStatus.healthy);
      expect(health(ApiSource.mal).totalHits, 2);
      expect(health(ApiSource.mal).lastHit, isNotNull);
      expect(health(ApiSource.anilist).totalHits, 0);
    });

    test('keeps the Retry-After deadline from the response headers', () {
      tracker().recordSuccess(
        ApiSource.anilist,
        headers: {
          'retry-after': ['30'],
        },
      );

      final retry = health(ApiSource.anilist).retryAfter!;
      expect(
        retry.difference(DateTime.now()).inSeconds,
        inInclusiveRange(28, 30),
      );
    });

    test('clears an old Retry-After once a request succeeds', () {
      tracker()
        ..recordError(
          ApiSource.mal,
          statusCode: 429,
          headers: {
            'retry-after': ['60'],
          },
        )
        ..recordSuccess(ApiSource.mal);

      expect(health(ApiSource.mal).status, ApiStatus.healthy);
      expect(health(ApiSource.mal).retryAfter, isNull);
    });
  });

  group('recordError', () {
    test('counts a normal error without touching the rate-limit counter', () {
      tracker().recordError(ApiSource.mal, statusCode: 500, message: 'boom');

      final h = health(ApiSource.mal);
      expect(h.status, ApiStatus.error);
      expect(h.totalErrors, 1);
      expect(h.totalRateLimited, 0);
      expect(h.lastStatusCode, 500);
      expect(h.lastErrorMessage, 'boom');
      expect(h.lastError, isNotNull);
    });

    test('treats 429 as rate limited and parses Retry-After', () {
      tracker().recordError(
        ApiSource.anilist,
        statusCode: 429,
        headers: {
          'retry-after': ['45'],
        },
      );

      final h = health(ApiSource.anilist);
      expect(h.status, ApiStatus.rateLimited);
      expect(h.totalRateLimited, 1);
      expect(h.totalErrors, 1);
      expect(h.retryAfter!.isAfter(DateTime.now()), isTrue);
    });

    test('ignores a Retry-After that is not a number', () {
      tracker().recordError(
        ApiSource.mal,
        statusCode: 429,
        headers: {
          'retry-after': ['Wed, 21 Oct 2026 07:28:00 GMT'],
        },
      );

      expect(health(ApiSource.mal).retryAfter, isNull);
    });

    test('drops a stale Retry-After when a later error has none', () {
      tracker()
        ..recordError(
          ApiSource.mal,
          statusCode: 429,
          headers: {
            'retry-after': ['60'],
          },
        )
        ..recordError(ApiSource.mal, statusCode: 500);

      expect(health(ApiSource.mal).retryAfter, isNull);
      expect(health(ApiSource.mal).status, ApiStatus.error);
    });
  });

  group('recordRateLimitHeaders', () {
    test('reads remaining and reset (case-insensitive header names)', () {
      tracker().recordRateLimitHeaders(ApiSource.anilist, {
        'X-RateLimit-Remaining': ['87'],
        'X-RateLimit-Reset': ['1800000000'],
      });

      final h = health(ApiSource.anilist);
      expect(h.rateLimitRemaining, 87);
      expect(
        h.rateLimitReset,
        DateTime.fromMillisecondsSinceEpoch(1800000000 * 1000),
      );
    });

    test('keeps previous values when the headers are absent or invalid', () {
      tracker()
        ..recordRateLimitHeaders(ApiSource.mal, {
          'x-ratelimit-remaining': ['10'],
        })
        ..recordRateLimitHeaders(ApiSource.mal, {
          'x-ratelimit-remaining': ['nope'],
        })
        ..recordRateLimitHeaders(ApiSource.mal, null);

      expect(health(ApiSource.mal).rateLimitRemaining, 10);
    });

    test('does nothing for null headers', () {
      tracker().recordRateLimitHeaders(ApiSource.mal, null);

      expect(health(ApiSource.mal).rateLimitRemaining, isNull);
    });
  });

  test('reset returns one source to its initial state only', () {
    tracker()
      ..recordSuccess(ApiSource.mal)
      ..recordError(ApiSource.anilist, statusCode: 500)
      ..reset(ApiSource.mal);

    expect(health(ApiSource.mal).status, ApiStatus.unknown);
    expect(health(ApiSource.mal).totalHits, 0);
    expect(health(ApiSource.anilist).totalErrors, 1);
  });

  test('apiSourceLabel gives display names', () {
    expect(apiSourceLabel(ApiSource.mal), 'MyAnimeList');
    expect(apiSourceLabel(ApiSource.anilist), 'AniList');
  });

  group('ApiHealthInterceptor', () {
    late _RecordingHandler handler;

    setUp(() => handler = _RecordingHandler());

    ApiHealthInterceptor interceptor() => container.read(_interceptorProvider);

    Response<dynamic> response(
      String url, {
      Map<String, List<String>>? headers,
    }) => Response<dynamic>(
      requestOptions: RequestOptions(path: url),
      statusCode: 200,
      headers: Headers.fromMap(headers ?? const {}),
    );

    test('attributes responses to the right source by host', () {
      interceptor()
        ..onResponse(response('https://api.myanimelist.net/v2/anime'), handler)
        ..onResponse(response('https://graphql.anilist.co'), handler);

      expect(health(ApiSource.mal).totalHits, 1);
      expect(health(ApiSource.anilist).totalHits, 1);
      expect(handler.passed, 2);
    });

    test('defaults unknown hosts to MyAnimeList', () {
      interceptor().onResponse(response('https://example.test/x'), handler);

      expect(health(ApiSource.mal).totalHits, 1);
    });

    test('records rate-limit headers from successful responses', () {
      interceptor().onResponse(
        response(
          'https://graphql.anilist.co',
          headers: {
            'x-ratelimit-remaining': ['59'],
          },
        ),
        handler,
      );

      expect(health(ApiSource.anilist).rateLimitRemaining, 59);
    });

    test('records a 429 error with its Retry-After and passes it on', () {
      final err = DioException(
        requestOptions: RequestOptions(path: 'https://graphql.anilist.co'),
        message: 'Too many',
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: 'https://graphql.anilist.co'),
          statusCode: 429,
          headers: Headers.fromMap({
            'retry-after': ['20'],
          }),
        ),
      );

      interceptor().onError(err, _RecordingErrorHandler(handler));

      final h = health(ApiSource.anilist);
      expect(h.status, ApiStatus.rateLimited);
      expect(h.lastErrorMessage, 'Too many');
      expect(handler.errorsPassed, 1);
    });

    test('records a connection error without a response as status 0', () {
      final err = DioException(
        requestOptions: RequestOptions(
          path: 'https://api.myanimelist.net/v2/x',
        ),
        type: DioExceptionType.connectionError,
      );

      interceptor().onError(err, _RecordingErrorHandler(handler));

      expect(health(ApiSource.mal).lastStatusCode, 0);
      expect(health(ApiSource.mal).status, ApiStatus.error);
    });
  });
}

final _interceptorProvider = Provider<ApiHealthInterceptor>(
  ApiHealthInterceptor.new,
);

class _RecordingHandler extends ResponseInterceptorHandler {
  int passed = 0;
  int errorsPassed = 0;

  @override
  void next(Response<dynamic> response) => passed++;
}

class _RecordingErrorHandler extends ErrorInterceptorHandler {
  _RecordingErrorHandler(this._owner);

  final _RecordingHandler _owner;

  @override
  void next(DioException err) => _owner.errorsPassed++;
}
