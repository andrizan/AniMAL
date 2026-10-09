import 'dart:async';

import 'package:animal/app.dart';
import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/core/router/app_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _method = MethodChannel('com.llfbandit.app_links/messages');
const _events = EventChannel('com.llfbandit.app_links/events');

class _Notifications extends Fake implements AnimeNotificationService {
  _Notifications({this.launchId});

  int? launchId;
  final taps = StreamController<int>.broadcast();

  @override
  int? consumeLaunchAnimeId() {
    final id = launchId;
    launchId = null;
    return id;
  }

  @override
  Stream<int> get onNotificationTapped => taps.stream;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String? initialLink;
  MockStreamHandlerEventSink? linkSink;
  late List<String> visited;

  setUp(() {
    initialLink = null;
    linkSink = null;
    visited = [];
    SharedPreferences.setMockInitialValues({});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      _method,
      (call) async => call.method == 'getInitialLink' ? initialLink : null,
    );
    messenger.setMockStreamHandler(
      _events,
      MockStreamHandler.inline(
        onListen: (_, sink) {
          linkSink = sink;
        },
      ),
    );
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_method, null);
    messenger.setMockStreamHandler(_events, null);
  });

  GoRouter fakeRouter() => GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, _) => const Scaffold(body: Text('START')),
      ),
      GoRoute(
        path: AppRoutes.animeDetail,
        name: 'animeDetail',
        builder: (context, state) {
          visited.add('anime/${state.pathParameters['id']}');
          return Scaffold(body: Text('DETAIL ${state.pathParameters['id']}'));
        },
      ),
      GoRoute(
        path: AppRoutes.oauthCallback,
        builder: (context, state) {
          visited.add('callback?${state.uri.query}');
          return const Scaffold(body: Text('CALLBACK'));
        },
      ),
    ],
  );

  Future<_Notifications> open(WidgetTester tester, {int? launchId}) async {
    final notifications = _Notifications(launchId: launchId);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWithValue(notifications),
          routerProvider.overrideWithValue(fakeRouter()),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
    return notifications;
  }

  testWidgets('shows the router content with the app title', (tester) async {
    await open(tester);

    expect(find.text('START'), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      'AniMAL',
    );
  });

  testWidgets('follows the saved theme, dark by default', (tester) async {
    await open(tester);

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });

  testWidgets('uses a saved light theme', (tester) async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
    await open(tester);
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
  });

  group('notifications', () {
    testWidgets('tapping one opens that anime', (tester) async {
      final notifications = await open(tester);

      notifications.taps.add(42);
      await tester.pumpAndSettle();

      expect(find.text('DETAIL 42'), findsOneWidget);
    });

    testWidgets(
      'an app launched from a notification opens that anime at once',
      (tester) async {
        await open(tester, launchId: 7);

        expect(find.text('DETAIL 7'), findsOneWidget);
      },
    );

    testWidgets('a normal launch stays on the start page', (tester) async {
      await open(tester);

      expect(find.text('START'), findsOneWidget);
      expect(visited, isEmpty);
    });
  });

  group('deep links', () {
    testWidgets(
      'the OAuth redirect that opened the app goes to the callback page',
      (tester) async {
        initialLink = 'animal://oauth/callback?code=abc%2B1&state=xyz';
        await open(tester);

        expect(find.text('CALLBACK'), findsOneWidget);
        expect(
          Uri.splitQueryString(visited.single.substring('callback?'.length)),
          {'code': 'abc+1', 'state': 'xyz'},
        );
      },
    );

    testWidgets('a redirect that arrives while running is handled too', (
      tester,
    ) async {
      await open(tester);

      linkSink!.success('animal://oauth/callback?code=live&state=s1');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('CALLBACK'), findsOneWidget);
    });

    testWidgets('a denied authorization still reaches the callback page', (
      tester,
    ) async {
      initialLink = 'animal://oauth/callback?error=access_denied&state=s1';
      await open(tester);

      expect(find.text('CALLBACK'), findsOneWidget);
    });

    testWidgets('unrelated links are ignored', (tester) async {
      await open(tester);

      linkSink!.success('https://example.com/whatever');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('START'), findsOneWidget);
    });
  });
}
