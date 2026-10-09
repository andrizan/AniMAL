import 'package:animal/core/storage/secure_token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SecureTokenStorage storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = const SecureTokenStorage();
  });

  test('returns null for everything on a fresh install', () async {
    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
    expect(await storage.getCodeVerifier(), isNull);
    expect(await storage.getOAuthState(), isNull);
  });

  test('stores access and refresh tokens independently', () async {
    await storage.saveTokens(accessToken: 'a', refreshToken: 'r');

    expect(await storage.getAccessToken(), 'a');
    expect(await storage.getRefreshToken(), 'r');
  });

  test('overwrites tokens on a later save', () async {
    await storage.saveTokens(accessToken: 'a1', refreshToken: 'r1');
    await storage.saveTokens(accessToken: 'a2', refreshToken: 'r2');

    expect(await storage.getAccessToken(), 'a2');
    expect(await storage.getRefreshToken(), 'r2');
  });

  test('code verifier and oauth state can be cleared one at a time', () async {
    await storage.saveCodeVerifier('v');
    await storage.saveOAuthState('s');

    await storage.clearCodeVerifier();
    expect(await storage.getCodeVerifier(), isNull);
    expect(await storage.getOAuthState(), 's');

    await storage.clearOAuthState();
    expect(await storage.getOAuthState(), isNull);
  });

  test('clear removes every stored secret', () async {
    await storage.saveTokens(accessToken: 'a', refreshToken: 'r');
    await storage.saveCodeVerifier('v');
    await storage.saveOAuthState('s');

    await storage.clear();

    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
    expect(await storage.getCodeVerifier(), isNull);
    expect(await storage.getOAuthState(), isNull);
  });
}
