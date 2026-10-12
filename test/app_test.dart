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
const _launcher = MethodChannel('plugins.flutter.io/url_launcher');

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
  late List<MethodCall> launched;
  Future<Map<String, dynamic>?> Function() latestRelease = () async => null;
  var releaseLookups = 0;

  setUp(() {
    launched = [];
    releaseLookups = 0;
    latestRelease = () async => null;
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
    messenger
      ..setMockStreamHandler(
        _events,
        MockStreamHandler.inline(
          onListen: (_, sink) {
            linkSink = sink;
          },
        ),
      )
      ..setMockMethodCallHandler(_launcher, (call) async {
        launched.add(call);
        return true;
      });
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger
      ..setMockMethodCallHandler(_method, null)
      ..setMockMethodCallHandler(_launcher, null)
      ..setMockStreamHandler(_events, null);
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

  Future<_Notifications> open(
    WidgetTester tester, {
    int? launchId,
    String version = '2.10.0',
  }) async {
    final notifications = _Notifications(launchId: launchId);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWithValue(notifications),
          routerProvider.overrideWithValue(fakeRouter()),
          latestReleaseProvider.overrideWithValue(() {
            releaseLookups++;
            return latestRelease();
          }),
          appVersionProvider.overrideWithValue(() async => version),
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

  group('update notice', () {
    Map<String, dynamic> release(String tag) => {
      'tag_name': tag,
      'html_url': 'https://github.com/andrizan/AniMAL/releases/tag/$tag',
      'body': 'notes',
    };

    testWidgets('appears when a newer version is published', (tester) async {
      latestRelease = () async => release('v2.11.0');

      await open(tester);

      expect(find.text('AniMAL v2.11.0 is available'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
    });

    testWidgets('Download opens the release page in the browser', (
      tester,
    ) async {
      latestRelease = () async => release('v2.11.0');
      await open(tester);

      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();

      final call = launched.single;
      final args = call.arguments as Map;
      expect(call.method, 'launch');
      expect(
        args['url'],
        'https://github.com/andrizan/AniMAL/releases/tag/v2.11.0',
      );
      expect(args['useWebView'], isFalse);
    });

    testWidgets('does not appear on the latest version', (tester) async {
      latestRelease = () async => release('v2.10.0');

      await open(tester);

      expect(find.textContaining('is available'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('does not appear when the installed version is newer', (
      tester,
    ) async {
      latestRelease = () async => release('v2.9.0');

      await open(tester);

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('stays quiet when the check fails', (tester) async {
      latestRelease = () async => throw Exception('offline');

      await open(tester);

      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('START'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('stays quiet when GitHub has no answer', (tester) async {
      await open(tester);

      expect(find.byType(SnackBar), findsNothing);
      expect(releaseLookups, 1);
    });

    testWidgets('is checked once per launch, not on every rebuild', (
      tester,
    ) async {
      latestRelease = () async => release('v2.11.0');
      await open(tester);

      await tester.pump(const Duration(seconds: 20));
      await tester.pumpAndSettle();

      expect(releaseLookups, 1);
    });

    testWidgets('never holds up the first screen', (tester) async {
      final gate = Completer<Map<String, dynamic>?>();
      latestRelease = () => gate.future;

      await open(tester);

      expect(find.text('START'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      gate.complete(release('v2.11.0'));
      await tester.pump();
      await tester.pump();

      expect(find.text('AniMAL v2.11.0 is available'), findsOneWidget);
    });

    testWidgets('shows over the page that is open', (tester) async {
      latestRelease = () async => release('v2.11.0');

      await open(tester, launchId: 7);

      expect(find.text('DETAIL 7'), findsOneWidget);
      expect(find.text('AniMAL v2.11.0 is available'), findsOneWidget);
    });

    testWidgets('can be closed right away', (tester) async {
      latestRelease = () async => release('v2.11.0');
      await open(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('AniMAL v2.11.0 is available'), findsNothing);
      expect(launched, isEmpty);
    });

    testWidgets('names the version without a leading v', (tester) async {
      latestRelease = () async => release('v3.0.0');

      await open(tester);

      expect(find.text('AniMAL v3.0.0 is available'), findsOneWidget);
      expect(find.textContaining('vv'), findsNothing);
    });

    testWidgets('stays up long enough to read and goes away by itself', (
      tester,
    ) async {
      latestRelease = () async => release('v2.11.0');
      await open(tester);

      await tester.pump(const Duration(seconds: 6));
      expect(find.text('AniMAL v2.11.0 is available'), findsOneWidget);

      await tester.pump(const Duration(seconds: 13));
      await tester.pumpAndSettle();
      expect(find.text('AniMAL v2.11.0 is available'), findsNothing);
    });
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
