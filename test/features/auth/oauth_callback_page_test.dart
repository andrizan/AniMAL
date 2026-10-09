import 'package:animal/core/providers.dart';
import 'package:animal/core/storage/secure_token_storage.dart';
import 'package:animal/features/auth/presentation/oauth_callback_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repo;

  Future<void> open(
    WidgetTester tester, {
    String? code,
    String? state,
    String? storedState,
  }) async {
    FlutterSecureStorage.setMockInitialValues({
      if (storedState != null) 'mal_oauth_state': storedState,
    });
    repo = FakeAuthRepository();
    final router = GoRouter(
      initialLocation: '/oauth/callback',
      routes: [
        GoRoute(
          path: '/oauth/callback',
          builder: (context, _) => OAuthCallbackPage(code: code, state: state),
        ),
        GoRoute(
          path: '/home',
          builder: (context, _) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: '/login',
          builder: (context, _) => const Scaffold(body: Text('LOGIN')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [malAuthRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a valid callback logs in and opens home', (tester) async {
    await open(tester, code: 'abc', state: 'xyz', storedState: 'xyz');

    expect(repo.exchanged, ['abc']);
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('Login successful!'), findsOneWidget);
  });

  testWidgets('the stored oauth state is consumed after a successful login', (
    tester,
  ) async {
    await open(tester, code: 'abc', state: 'xyz', storedState: 'xyz');

    expect(await const SecureTokenStorage().getOAuthState(), isNull);
  });

  testWidgets('a missing code returns to login without exchanging anything', (
    tester,
  ) async {
    await open(tester, state: 'xyz', storedState: 'xyz');

    expect(repo.exchanged, isEmpty);
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('No authorization code received'), findsOneWidget);
  });

  testWidgets('an empty code counts as missing', (tester) async {
    await open(tester, code: '', state: 'xyz', storedState: 'xyz');

    expect(find.text('LOGIN'), findsOneWidget);
    expect(repo.exchanged, isEmpty);
  });

  testWidgets('a state that does not match is rejected', (tester) async {
    await open(tester, code: 'abc', state: 'tampered', storedState: 'xyz');

    expect(repo.exchanged, isEmpty);
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('Invalid OAuth state'), findsOneWidget);
  });

  testWidgets('a missing returned state is rejected', (tester) async {
    await open(tester, code: 'abc', storedState: 'xyz');

    expect(repo.exchanged, isEmpty);
    expect(find.text('Invalid OAuth state'), findsOneWidget);
  });

  testWidgets('a callback without a stored state is rejected', (tester) async {
    await open(tester, code: 'abc', state: 'xyz');

    expect(repo.exchanged, isEmpty);
    expect(find.text('Invalid OAuth state'), findsOneWidget);
  });

  testWidgets(
    'a failed token exchange reports the error and returns to login',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({'mal_oauth_state': 'xyz'});
      repo = FakeAuthRepository()..exchangeError = Exception('invalid_grant');
      final router = GoRouter(
        initialLocation: '/oauth/callback',
        routes: [
          GoRoute(
            path: '/oauth/callback',
            builder: (context, _) =>
                const OAuthCallbackPage(code: 'abc', state: 'xyz'),
          ),
          GoRoute(
            path: '/home',
            builder: (context, _) => const Scaffold(body: Text('HOME')),
          ),
          GoRoute(
            path: '/login',
            builder: (context, _) => const Scaffold(body: Text('LOGIN')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [malAuthRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.textContaining('Login failed'), findsOneWidget);
      expect(find.text('HOME'), findsNothing);
    },
  );
}
