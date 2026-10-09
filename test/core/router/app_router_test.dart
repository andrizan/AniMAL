import 'package:animal/core/providers.dart';
import 'package:animal/core/router/app_router.dart';
import 'package:animal/core/router/route_guards.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeAuthRepository()..authenticated = true;
    container = ProviderContainer(
      overrides: [malAuthRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  AuthController auth() => container.read(authControllerProvider.notifier);

  group('routerProvider', () {
    test('is one router for the whole session', () async {
      final router = container.read(routerProvider);
      await settle();
      expect(container.read(authControllerProvider), AuthStatus.authenticated);

      await auth().logout();
      expect(
        container.read(authControllerProvider),
        AuthStatus.unauthenticated,
      );
      await auth().exchangeCode('code');

      expect(container.read(routerProvider), same(router));
    });

    test('can be disposed together with its container', () async {
      container.read(routerProvider);
      await settle();

      expect(container.dispose, returnsNormally);
    });
  });

  group('AuthRefreshListenable', () {
    final listenableProvider = Provider<AuthRefreshListenable>(
      AuthRefreshListenable.new,
    );

    test('notifies on every auth status change', () async {
      final listenable = container.read(listenableProvider);
      var notified = 0;
      listenable.addListener(() => notified++);

      await settle();
      expect(notified, 1);

      await auth().logout();
      expect(notified, 2);
    });

    test('stops listening once disposed', () async {
      final listenable = container.read(listenableProvider);
      await settle();

      listenable.dispose();

      await expectLater(auth().logout(), completes);
    });
  });
}
