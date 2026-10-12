import 'dart:convert';
import 'dart:typed_data';

import 'package:animal/core/config/env.dart';
import 'package:animal/core/logger/app_logger.dart';
import 'package:animal/core/network/api_health_tracker.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/core/storage/secure_token_storage.dart';
import 'package:animal/core/utils/github_check.dart';
import 'package:animal/data/local/airing_cache.dart';
import 'package:animal/data/local/anilist_cache.dart';
import 'package:animal/data/local/app_database.dart';
import 'package:animal/data/local/sqlite_anime_cache.dart';
import 'package:animal/features/auth/data/repositories/mal_auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/fake_auth_repository.dart';

class _Storage implements SecureTokenStorage {
  int clears = 0;

  @override
  Future<String?> getAccessToken() async => 'access';

  @override
  Future<String?> getRefreshToken() async => 'refresh';

  @override
  Future<void> clear() async => clears++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Answers every API call with 401 and the token endpoint with [tokenStatus].
class _Adapter implements HttpClientAdapter {
  _Adapter(this.tokenStatus);

  final int tokenStatus;
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.uri.toString());
    final isToken = options.uri.toString() == Env.malTokenUrl;
    return ResponseBody.fromString(
      jsonEncode({'error': 'nope'}),
      isToken ? tokenStatus : 401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  ProviderContainer containerWith(List<Override> overrides) {
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    return container;
  }

  group('providers that main.dart must override', () {
    test('the notification service is not available by default', () {
      final container = containerWith([]);

      expect(
        () => container.read(notificationServiceProvider),
        throwsA(
          predicate((e) => e.toString().contains('Override this provider')),
        ),
      );
    });

    test('the database is not available by default', () {
      final container = containerWith([]);

      expect(
        () => container.read(appDatabaseProvider),
        throwsA(
          predicate((e) => e.toString().contains('Override this provider')),
        ),
      );
    });

    test('so none of the caches work without a database', () {
      final container = containerWith([]);

      for (final read in <void Function()>[
        () => container.read(animeCacheProvider),
        () => container.read(anilistCacheProvider),
        () => container.read(airingCacheProvider),
      ]) {
        expect(read, throwsA(anything));
      }
    });
  });

  group('caches', () {
    late AppDatabase db;

    setUp(() async {
      db = await AppDatabase.open(
        pathOverride: inMemoryDatabasePath,
        runMigrations: false,
      );
      addTearDown(db.close);
    });

    test('are the SQLite implementations on the one database', () {
      final container = containerWith([
        appDatabaseProvider.overrideWithValue(db),
      ]);

      expect(container.read(animeCacheProvider), isA<SqliteAnimeCache>());
      expect(container.read(anilistCacheProvider), isA<SqliteAniListCache>());
      expect(container.read(airingCacheProvider), isA<SqliteAiringCache>());
    });

    test('are each built once per container', () {
      final container = containerWith([
        appDatabaseProvider.overrideWithValue(db),
      ]);

      expect(
        container.read(anilistCacheProvider),
        same(container.read(anilistCacheProvider)),
      );
    });
  });

  group('defaults', () {
    test('the logger is the shared app logger', () {
      expect(containerWith([]).read(loggerProvider), same(appLogger));
    });

    test('release lookups use the GitHub check', () {
      expect(
        containerWith([]).read(latestReleaseProvider),
        same(fetchLatestRelease),
      );
    });

    test('tokens go to secure storage', () {
      expect(
        containerWith([]).read(tokenStorageProvider),
        isA<SecureTokenStorage>(),
      );
    });

    test('authentication is built on the token storage', () {
      expect(
        containerWith([tokenStorageProvider.overrideWithValue(_Storage())])
            .read(malAuthRepositoryProvider),
        isA<MalAuthRepository>(),
      );
    });
  });

  group('the MAL Dio', () {
    late _Storage storage;
    late FakeAuthRepository auth;
    late ProviderContainer container;

    setUp(() async {
      storage = _Storage();
      auth = FakeAuthRepository()..authenticated = true;
      container = containerWith([
        loggerProvider.overrideWithValue(Logger(level: Level.off)),
        tokenStorageProvider.overrideWithValue(storage),
        malAuthRepositoryProvider.overrideWithValue(auth),
      ]);
      container.read(authControllerProvider);
      await Future<void>.delayed(Duration.zero);
    });

    test('is the one Dio of the client', () {
      expect(
        container.read(dioProvider),
        same(container.read(dioClientProvider).dio),
      );
      expect(container.read(dioProvider).options.baseUrl, Env.malBaseUrl);
    });

    test('a refused refresh token signs the user out', () async {
      final adapter = _Adapter(400);
      container.read(dioProvider).httpClientAdapter = adapter;
      expect(container.read(authControllerProvider), AuthStatus.authenticated);

      await expectLater(
        container.read(dioProvider).get<dynamic>('/users/@me'),
        throwsA(isA<DioException>()),
      );

      expect(auth.logouts, 1);
      expect(storage.clears, 1);
      expect(
        container.read(authControllerProvider),
        AuthStatus.unauthenticated,
      );
      expect(adapter.paths, contains(Env.malTokenUrl));
    });

    test('every request is counted in the API health', () async {
      container.read(dioProvider).httpClientAdapter = _Adapter(500);
      expect(
        container.read(apiHealthTrackerProvider)[ApiSource.mal]?.totalErrors ??
            0,
        0,
      );

      await expectLater(
        container.read(dioProvider).get<dynamic>('/users/@me'),
        throwsA(isA<DioException>()),
      );

      final mal = container.read(apiHealthTrackerProvider)[ApiSource.mal]!;
      expect(mal.totalErrors, greaterThanOrEqualTo(1));
      expect(mal.lastStatusCode, 401);
    });

    test('a server error while refreshing keeps the user signed in', () async {
      container.read(dioProvider).httpClientAdapter = _Adapter(500);

      await expectLater(
        container.read(dioProvider).get<dynamic>('/users/@me'),
        throwsA(isA<DioException>()),
      );

      expect(auth.logouts, 0);
      expect(storage.clears, 0);
      expect(container.read(authControllerProvider), AuthStatus.authenticated);
    });
  });
}
