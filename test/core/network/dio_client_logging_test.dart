import 'dart:convert';
import 'dart:typed_data';

import 'package:animal/core/config/env.dart';
import 'package:animal/core/network/api_health_interceptor.dart';
import 'package:animal/core/network/api_health_tracker.dart';
import 'package:animal/core/network/auth_interceptor.dart';
import 'package:animal/core/network/dio_client.dart';
import 'package:animal/core/storage/secure_token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

class _Storage implements SecureTokenStorage {
  _Storage([this.token]);

  final String? token;

  @override
  Future<String?> getAccessToken() async => token;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Adapter implements HttpClientAdapter {
  int status = 200;
  final seen = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen.add(options);
    return ResponseBody.fromString(
      jsonEncode({'echo': 'response-secret'}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Capture extends LogFilter {
  final events = <LogEvent>[];

  @override
  bool shouldLog(LogEvent event) {
    events.add(event);
    return false;
  }

  List<String> get texts => [
    for (final e in events)
      if (e.message is Function)
        (e.message as Function)().toString()
      else
        e.message.toString(),
  ];

  String get all => texts.join('\n');
}

void main() {
  late _Capture log;
  late _Adapter adapter;
  late DioClient client;

  setUp(() {
    log = _Capture();
    adapter = _Adapter();
    client = DioClient(
      tokenStorage: _Storage(),
      logger: Logger(filter: log),
    );
    client.dio.httpClientAdapter = adapter;
  });

  group('configuration', () {
    test('talks to the MyAnimeList API with its client id', () {
      final options = client.dio.options;

      expect(options.baseUrl, Env.malBaseUrl);
      expect(options.headers['X-MAL-CLIENT-ID'], Env.malClientId);
    });

    test('gives up on a silent server after fifteen seconds', () {
      final options = client.dio.options;

      expect(options.connectTimeout, const Duration(seconds: 15));
      expect(options.receiveTimeout, const Duration(seconds: 15));
    });

    test('has no health tracking without a Riverpod ref', () {
      expect(
        client.dio.interceptors.whereType<ApiHealthInterceptor>(),
        isEmpty,
      );
    });

    test('tracks health when given a ref', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = Provider<DioClient>(
        (ref) => DioClient(
          tokenStorage: _Storage(),
          ref: ref,
          logger: Logger(filter: _Capture()),
        ),
      );
      final withRef = container.read(provider)..dio.httpClientAdapter = adapter;

      await withRef.dio.get<dynamic>('/anime');
      adapter.status = 500;
      await expectLater(
        withRef.dio.get<dynamic>('/anime'),
        throwsA(isA<DioException>()),
      );

      final mal = container.read(apiHealthTrackerProvider)[ApiSource.mal]!;
      expect(mal.totalHits, greaterThanOrEqualTo(1));
      expect(mal.totalErrors, 1);
      expect(mal.lastStatusCode, 500);
    });
  });

  group('logging never leaks secrets', () {
    test('the stored token is sent but never logged', () async {
      final stored = DioClient(
        tokenStorage: _Storage('stored-token'),
        logger: Logger(filter: log),
      )..dio.httpClientAdapter = adapter;

      await stored.dio.get<dynamic>('/anime');

      expect(
        adapter.seen.single.headers['Authorization'],
        'Bearer stored-token',
      );
      expect(log.all, isNot(contains('stored-token')));
      expect(log.all, contains('Authorization: ***'));
    });

    test('a bearer token is redacted in the logged headers', () async {
      await client.dio.get<dynamic>(
        '/anime',
        options: Options(headers: {'Authorization': 'Bearer topsecret'}),
      );

      expect(log.all, isNot(contains('topsecret')));
      expect(log.all, contains('Authorization: ***'));
    });

    test('other headers are logged as they are', () async {
      await client.dio.get<dynamic>(
        '/anime',
        options: Options(headers: {'X-Trace': 'abc'}),
      );

      expect(log.all, contains('X-Trace: abc'));
      expect(log.all, contains('X-MAL-CLIENT-ID'));
    });

    test('the token endpoint is logged without headers or bodies', () async {
      await client.dio.post<dynamic>(
        Env.malTokenUrl,
        data: {'refresh_token': 'refresh-secret'},
        options: Options(headers: {'Authorization': 'Basic basic-secret'}),
      );

      expect(log.all, contains('[token]'));
      expect(log.all, isNot(contains('refresh-secret')));
      expect(log.all, isNot(contains('basic-secret')));
      expect(log.all, isNot(contains('response-secret')));
      expect(log.all, isNot(contains('headers:')));
      expect(log.all, isNot(contains('body:')));
      expect(log.events.map((e) => e.message).whereType<Function>(), isEmpty);
    });

    test('an ordinary request does log its response body', () async {
      await client.dio.get<dynamic>('/anime');

      expect(log.all, contains('response-secret'));
      expect(log.all, contains('200 /anime'));
      expect(log.all, isNot(contains('[token]')));
    });

    test('the method and path are always logged', () async {
      await client.dio.get<dynamic>('/anime/5');

      expect(log.all, contains('GET /anime/5'));
    });
  });

  group('errors', () {
    test('are logged with their type and path, then rethrown', () async {
      adapter.status = 500;

      await expectLater(
        client.dio.get<dynamic>('/anime'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            500,
          ),
        ),
      );

      expect(log.all, contains('DioError DioExceptionType.badResponse /anime'));
      expect(log.events.any((e) => e.level == Level.error), isTrue);
    });
  });
}
