import 'dart:convert';

import 'package:animal/core/config/env.dart';
import 'package:animal/core/network/api_exception.dart';
import 'package:animal/core/storage/secure_token_storage.dart';
import 'package:animal/features/auth/data/repositories/mal_auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import '../../support/fake_adapter.dart';

const _tokenJson = {
  'access_token': 'access-1',
  'refresh_token': 'refresh-1',
  'expires_in': 3600,
  'token_type': 'Bearer',
};

void main() {
  late SecureTokenStorage storage;
  late FakeAdapter adapter;
  late MalAuthRepository repo;

  void useServer(FakeResponse Function(RequestOptions o) handler) {
    adapter = FakeAdapter(handler);
    repo = MalAuthRepository(
      tokenStorage: storage,
      dio: Dio()..httpClientAdapter = adapter,
      logger: Logger(level: Level.off),
    );
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = const SecureTokenStorage();
    useServer((_) => const FakeResponse.json(_tokenJson));
  });

  group('buildAuthorizationUrl', () {
    test(
      'builds a PKCE authorization url and remembers verifier and state',
      () async {
        final url = await repo.buildAuthorizationUrl();
        final q = url.queryParameters;

        expect(url.toString().startsWith(Env.malAuthUrl), isTrue);
        expect(q['response_type'], 'code');
        expect(q['client_id'], Env.malClientId);
        expect(q['redirect_uri'], Env.malRedirectUri);
        expect(q['code_challenge_method'], 'plain');
        expect(q['state'], hasLength(32));
        expect(q['state'], matches(RegExp(r'^[A-Za-z0-9]+$')));
        expect(q['code_challenge'], hasLength(128));
        expect(q['code_challenge'], matches(RegExp(r'^[A-Za-z0-9\-._~]+$')));
        expect(await storage.getCodeVerifier(), q['code_challenge']);
        expect(await storage.getOAuthState(), q['state']);
      },
    );

    test('generates fresh values on every login attempt', () async {
      final a = await repo.buildAuthorizationUrl();
      final b = await repo.buildAuthorizationUrl();

      expect(a.queryParameters['state'], isNot(b.queryParameters['state']));
      expect(
        a.queryParameters['code_challenge'],
        isNot(b.queryParameters['code_challenge']),
      );
    });
  });

  group('validateOAuthState', () {
    test('accepts only the state that was stored', () async {
      await storage.saveOAuthState('abc');

      expect(await repo.validateOAuthState('abc'), isTrue);
      expect(await repo.validateOAuthState('xyz'), isFalse);
      expect(await repo.validateOAuthState(null), isFalse);
    });

    test('rejects everything when no state was stored', () async {
      expect(await repo.validateOAuthState('abc'), isFalse);
      expect(await repo.validateOAuthState(null), isFalse);
    });

    test('rejects an empty stored state', () async {
      await storage.saveOAuthState('');

      expect(await repo.validateOAuthState(''), isFalse);
    });
  });

  group('exchangeCode', () {
    test('fails clearly when the code verifier is missing', () async {
      await expectLater(
        repo.exchangeCode('code'),
        throwsA(
          isA<UnauthorizedException>().having(
            (e) => e.message,
            'message',
            contains('Code verifier not found'),
          ),
        ),
      );
      expect(adapter.requests, isEmpty);
    });

    test('posts the code with the verifier, then stores tokens and drops the verifier', () async {
      await storage.saveCodeVerifier('verifier-xyz');

      final token = await repo.exchangeCode('auth-code');

      final call = adapter.requests.single;
      expect(call.uri.toString(), Env.malTokenUrl);
      expect(call.headers['Authorization'], startsWith('Basic '));
      expect(
        utf8.decode(
          base64.decode(
            (call.headers['Authorization']! as String).substring(6),
          ),
        ),
        '${Env.malClientId}:${Env.malClientSecret}',
      );
      expect(call.data, {
        'grant_type': 'authorization_code',
        'code': 'auth-code',
        'redirect_uri': Env.malRedirectUri,
        'code_verifier': 'verifier-xyz',
      });
      expect(token.accessToken, 'access-1');
      expect(await storage.getAccessToken(), 'access-1');
      expect(await storage.getRefreshToken(), 'refresh-1');
      expect(await storage.getCodeVerifier(), isNull);
    });

    test(
      'keeps the verifier and stores nothing when the server rejects the code',
      () async {
        await storage.saveCodeVerifier('verifier-xyz');
        useServer(
          (_) =>
              const FakeResponse.json({'error': 'invalid_grant'}, status: 400),
        );

        await expectLater(
          repo.exchangeCode('bad'),
          throwsA(isA<DioException>()),
        );

        expect(await storage.getAccessToken(), isNull);
        expect(await storage.getCodeVerifier(), 'verifier-xyz');
      },
    );
  });

  group('refreshToken', () {
    test(
      'returns null without calling the server when nothing is stored',
      () async {
        expect(await repo.refreshToken(), isNull);
        expect(adapter.requests, isEmpty);
      },
    );

    test('exchanges the stored refresh token and saves the new pair', () async {
      await storage.saveTokens(accessToken: 'old', refreshToken: 'old-refresh');

      final token = await repo.refreshToken();

      expect(adapter.requests.single.data, {
        'grant_type': 'refresh_token',
        'refresh_token': 'old-refresh',
      });
      expect(token!.refreshToken, 'refresh-1');
      expect(await storage.getAccessToken(), 'access-1');
      expect(await storage.getRefreshToken(), 'refresh-1');
    });
  });

  group('session', () {
    test('isAuthenticated follows the stored access token', () async {
      expect(await repo.isAuthenticated, isFalse);

      await storage.saveTokens(accessToken: 'a', refreshToken: 'r');
      expect(await repo.isAuthenticated, isTrue);

      await storage.saveTokens(accessToken: '', refreshToken: 'r');
      expect(await repo.isAuthenticated, isFalse);
    });

    test('logout wipes tokens, verifier and state', () async {
      await storage.saveTokens(accessToken: 'a', refreshToken: 'r');
      await storage.saveCodeVerifier('v');
      await storage.saveOAuthState('s');

      await repo.logout();

      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getCodeVerifier(), isNull);
      expect(await storage.getOAuthState(), isNull);
      expect(await repo.isAuthenticated, isFalse);
    });
  });
}
