import 'dart:async';

import 'package:animal/app.dart';
import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/core/router/app_router.dart';
import 'package:animal/core/router/route_guards.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth_repository.dart';

const _method = MethodChannel('com.llfbandit.app_links/messages');
const _events = EventChannel('com.llfbandit.app_links/events');

class _SlowAuth extends FakeAuthRepository {
  _SlowAuth({required bool signedIn}) {
    authenticated = signedIn;
  }

  @override
  Future<bool> get isAuthenticated async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return authenticated;
  }
}

class _Notifications extends Fake implements AnimeNotificationService {
  _Notifications({this.launchId});

  int? launchId;

  @override
  int? consumeLaunchAnimeId() {
    final id = launchId;
    launchId = null;
    return id;
  }

  @override
  Stream<int> get onNotificationTapped => const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String? initialLink;
  MockStreamHandlerEventSink? linkSink;

  setUp(() {
    initialLink = null;
    linkSink = null;
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(
        _method,
        (call) async => call.method == 'getInitialLink' ? initialLink : null,
      )
      ..setMockStreamHandler(
        _events,
        MockStreamHandler.inline(
          onListen: (_, sink) {
            linkSink = sink;
          },
        ),
      );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(_method, null)
      ..setMockStreamHandler(_events, null);
  });

  GoRouter guardedRouter(Ref ref) => GoRouter(
    initialLocation: '/home',
    refreshListenable: AuthRefreshListenable(ref),
    redirect: (context, state) =>
        authGuard(state, ref.read(authControllerProvider)),
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, _) => const Scaffold(body: Text('HOME')),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, _) => const Scaffold(body: Text('LOGIN')),
      ),
      GoRoute(
        path: AppRoutes.animeDetail,
        name: 'animeDetail',
        builder: (context, state) =>
            Scaffold(body: Text('DETAIL ${state.pathParameters['id']}')),
      ),
    ],
  );

  Future<void> coldStart(
    WidgetTester tester, {
    required bool signedIn,
    int? launchId,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          malAuthRepositoryProvider.overrideWithValue(
            _SlowAuth(signedIn: signedIn),
          ),
          notificationServiceProvider.overrideWithValue(
            _Notifications(launchId: launchId),
          ),
          routerProvider.overrideWith(guardedRouter),
          latestReleaseProvider.overrideWithValue(() async => null),
          appVersionProvider.overrideWithValue(() async => '2.10.0'),
        ],
        child: const App(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  void back(WidgetTester tester) =>
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();

  testWidgets('a MyAnimeList link that launched a signed-in app shows the '
      'anime, with Home underneath', (tester) async {
    initialLink = 'https://myanimelist.net/anime/5114/Fullmetal_Alchemist';

    await coldStart(tester, signedIn: true);

    expect(find.text('DETAIL 5114'), findsOneWidget);
    back(tester);
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('a notification that launched a signed-in app shows its '
      'anime, with Home underneath', (tester) async {
    await coldStart(tester, signedIn: true, launchId: 7);

    expect(find.text('DETAIL 7'), findsOneWidget);
    back(tester);
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('a link that launched a signed-out app leaves the login page', (
    tester,
  ) async {
    initialLink = 'https://myanimelist.net/anime/5114';

    await coldStart(tester, signedIn: false);

    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.textContaining('DETAIL'), findsNothing);
  });

  testWidgets('a link that arrives while the app is open goes straight on '
      'top of the current page', (tester) async {
    await coldStart(tester, signedIn: true);
    expect(find.text('HOME'), findsOneWidget);

    linkSink!.success('https://myanimelist.net/anime/21');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('DETAIL 21'), findsOneWidget);
    back(tester);
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });
}
