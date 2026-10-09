import 'dart:convert';

import 'package:animal/core/config/env.dart';
import 'package:animal/core/network/auth_interceptor.dart';
import 'package:animal/core/storage/secure_token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import '../../support/fake_adapter.dart';

const _newToken = {
  'access_token': 'new-access',
  'refresh_token': 'new-refresh',
  'expires_in': 3600,
  'token_type': 'Bearer',
};

bool _isTokenCall(RequestOptions o) => o.uri.toString() == Env.malTokenUrl;

void main() {
  late SecureTokenStorage storage;
  late int authFailures;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    storage = const SecureTokenStorage();
    await storage.saveTokens(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
    authFailures = 0;
  });

  Dio build(FakeAdapter adapter) {
    final dio = fakeDio(adapter);
    dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: storage,
        dio: dio,
        onAuthFailure: () async => authFailures++,
        logger: Logger(level: Level.off),
      ),
    );
    return dio;
  }

  group('requests', () {
    test('attach the stored access token', () async {
      final adapter = FakeAdapter((_) => const FakeResponse.json({'ok': true}));

      await build(adapter).get<dynamic>('/anime');

      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer old-access',
      );
    });

    test('send no Authorization header when there is no token', () async {
      await storage.clear();
      final adapter = FakeAdapter((_) => const FakeResponse.json({'ok': true}));

      await build(adapter).get<dynamic>('/anime');

      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });
  });

  group('401 handling', () {
    FakeAdapter serverAcceptingOnly(String token) => FakeAdapter((o) {
      if (_isTokenCall(o)) return const FakeResponse.json(_newToken);
      return o.headers['Authorization'] == 'Bearer $token'
          ? const FakeResponse.json({'ok': true})
          : const FakeResponse.json({'error': 'invalid_token'}, status: 401);
    });

    test('refreshes the token and retries the request once', () async {
      final adapter = serverAcceptingOnly('new-access');

      final response = await build(adapter).get<dynamic>('/anime');

      expect((response.data as Map)['ok'], true);
      expect(adapter.count(_isTokenCall), 1);
      expect(adapter.count((o) => !_isTokenCall(o)), 2);
      expect(await storage.getAccessToken(), 'new-access');
      expect(await storage.getRefreshToken(), 'new-refresh');
    });

    test(
      'authenticates the token call with client credentials, not Bearer',
      () async {
        final adapter = serverAcceptingOnly('new-access');

        await build(adapter).get<dynamic>('/anime');

        final call = adapter.requests.firstWhere(_isTokenCall);
        final expected = 'Basic ${base64Credentials()}';
        expect(call.headers['Authorization'], expected);
        expect(call.data, {
          'grant_type': 'refresh_token',
          'refresh_token': 'old-refresh',
        });
      },
    );

    test('shares one refresh between concurrent 401s', () async {
      final adapter = serverAcceptingOnly('new-access');
      final dio = build(adapter);

      final results = await Future.wait([
        dio.get<dynamic>('/anime/1'),
        dio.get<dynamic>('/anime/2'),
        dio.get<dynamic>('/anime/3'),
      ]);

      expect(results.every((r) => (r.data as Map)['ok'] == true), isTrue);
      expect(adapter.count(_isTokenCall), 1);
    });

    test(
      'does not loop when the retried request is still unauthorized',
      () async {
        final adapter = FakeAdapter((o) {
          if (_isTokenCall(o)) return const FakeResponse.json(_newToken);
          if (o.uri.path.endsWith('/anime') && adapter0.requests.length > 20) {
            return const FakeResponse.json({}, status: 500);
          }
          return const FakeResponse.json({'error': 'forbidden'}, status: 401);
        });
        adapter0 = adapter;

        await expectLater(
          build(adapter).get<dynamic>('/anime'),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'status',
              401,
            ),
          ),
        );

        expect(adapter.count(_isTokenCall), 1);
        expect(adapter.count((o) => !_isTokenCall(o)), 2);
      },
    );

    test('forces logout when the refresh token is rejected', () async {
      final adapter = FakeAdapter((o) {
        if (_isTokenCall(o)) {
          return const FakeResponse.json({
            'error': 'invalid_grant',
          }, status: 400);
        }
        return const FakeResponse.json({'error': 'invalid_token'}, status: 401);
      });

      await expectLater(
        build(adapter).get<dynamic>('/anime'),
        throwsA(isA<DioException>()),
      );

      expect(authFailures, 1);
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });

    test('keeps the session when the token server is merely down', () async {
      final adapter = FakeAdapter((o) {
        if (_isTokenCall(o)) return const FakeResponse.json({}, status: 503);
        return const FakeResponse.json({'error': 'invalid_token'}, status: 401);
      });

      await expectLater(
        build(adapter).get<dynamic>('/anime'),
        throwsA(isA<DioException>()),
      );

      expect(authFailures, 0);
      expect(await storage.getRefreshToken(), 'old-refresh');
    });

    test('does not try to refresh without a refresh token', () async {
      await storage.clear();
      await storage.saveTokens(accessToken: 'old-access', refreshToken: '');
      final adapter = FakeAdapter(
        (_) => const FakeResponse.json({'error': 'invalid_token'}, status: 401),
      );

      await expectLater(
        build(adapter).get<dynamic>('/anime'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.count(_isTokenCall), 0);
    });

    test('other errors pass through untouched', () async {
      final adapter = FakeAdapter(
        (_) => const FakeResponse.json({'error': 'boom'}, status: 500),
      );

      await expectLater(
        build(adapter).get<dynamic>('/anime'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            500,
          ),
        ),
      );

      expect(adapter.count(_isTokenCall), 0);
    });
  });
}

late FakeAdapter adapter0;

String base64Credentials() =>
    base64Encode(utf8.encode('${Env.malClientId}:${Env.malClientSecret}'));
