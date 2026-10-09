import 'package:animal/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repo;
  late ProviderContainer container;

  ProviderContainer start({required bool signedIn}) {
    repo = FakeAuthRepository()..authenticated = signedIn;
    container = ProviderContainer(
      overrides: [malAuthRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(authControllerProvider, (_, __) {});
    return container;
  }

  AuthStatus status() => container.read(authControllerProvider);
  AuthController controller() =>
      container.read(authControllerProvider.notifier);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('on start', () {
    test('is unknown until the stored session has been checked', () async {
      start(signedIn: true);

      expect(status(), AuthStatus.unknown);

      await settle();
      expect(status(), AuthStatus.authenticated);
    });

    test('becomes unauthenticated without a stored session', () async {
      start(signedIn: false);

      await settle();

      expect(status(), AuthStatus.unauthenticated);
    });
  });

  group('login', () {
    test('a successful code exchange authenticates', () async {
      start(signedIn: false);
      await settle();

      await controller().exchangeCode('the-code');

      expect(repo.exchanged, ['the-code']);
      expect(status(), AuthStatus.authenticated);
    });

    test('a rejected code leaves the user signed out and rethrows', () async {
      start(signedIn: false);
      await settle();
      repo.exchangeError = Exception('invalid_grant');

      await expectLater(
        controller().exchangeCode('bad'),
        throwsA(isA<Exception>()),
      );

      expect(status(), AuthStatus.unauthenticated);
    });

    test('hands out the authorization url', () async {
      start(signedIn: false);

      expect((await controller().getAuthorizationUrl()).host, 'auth.test');
    });
  });

  group('logout', () {
    test('clears the session and signs out', () async {
      start(signedIn: true);
      await settle();

      await controller().logout();

      expect(repo.logouts, 1);
      expect(status(), AuthStatus.unauthenticated);
    });
  });

  group('refreshToken', () {
    test('reports whether a new token was obtained', () async {
      start(signedIn: true);

      expect(await controller().refreshToken(), isFalse);

      repo.refreshResult = fakeToken;
      expect(await controller().refreshToken(), isTrue);
    });
  });
}
