import 'package:animal/core/providers.dart';
import 'package:animal/features/auth/presentation/login_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/fake_auth_repository.dart';

const _launcher = MethodChannel('plugins.flutter.io/url_launcher');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository auth;
  late List<MethodCall> launcherCalls;
  Object? launchResult;

  setUp(() {
    launcherCalls = [];
    launchResult = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_launcher, (call) async {
          launcherCalls.add(call);
          final result = launchResult;
          if (result is Exception) throw result;
          return result;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_launcher, null);
  });

  Future<void> open(WidgetTester tester) async {
    auth = FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [malAuthRepositoryProvider.overrideWithValue(auth)],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('introduces the app and offers both ways to log in', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('AniMAL'), findsOneWidget);
    expect(find.text('Unofficial MyAnimeList client'), findsOneWidget);
    expect(find.text('Login with MyAnimeList'), findsOneWidget);
    expect(find.text('Enter code manually'), findsOneWidget);
  });

  group('browser login', () {
    testWidgets('opens the authorization url', (tester) async {
      await open(tester);

      await tester.tap(find.text('Login with MyAnimeList'));
      await tester.pumpAndSettle();

      expect(launcherCalls.where((c) => c.method == 'launch'), hasLength(1));
      final args =
          launcherCalls.firstWhere((c) => c.method == 'launch').arguments
              as Map;
      expect(args['url'], 'https://auth.test/authorize');
      expect(find.text('Open URL'), findsNothing);
    });

    testWidgets('falls back to a copyable url when the browser cannot open', (
      tester,
    ) async {
      launchResult = false;
      await open(tester);

      await tester.tap(find.text('Login with MyAnimeList'));
      await tester.pumpAndSettle();

      expect(find.text('Open URL'), findsOneWidget);
      expect(find.text('https://auth.test/authorize'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Open URL'), findsNothing);
    });

    testWidgets('falls back the same way when launching throws', (
      tester,
    ) async {
      launchResult = PlatformException(code: 'ACTIVITY_NOT_FOUND');
      await open(tester);

      await tester.tap(find.text('Login with MyAnimeList'));
      await tester.pumpAndSettle();

      expect(find.text('Open URL'), findsOneWidget);
    });
  });

  group('manual code entry', () {
    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(find.text('Enter code manually'));
      await tester.pumpAndSettle();
    }

    testWidgets('submits the trimmed code and reports success', (tester) async {
      await open(tester);
      await openDialog(tester);

      await tester.enterText(find.byType(TextField), '  the-code  ');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(auth.exchanged, ['the-code']);
      expect(find.text('Login successful!'), findsOneWidget);
      expect(find.text('Enter Authorization Code'), findsNothing);
    });

    testWidgets('ignores an empty code and keeps the dialog open', (
      tester,
    ) async {
      await open(tester);
      await openDialog(tester);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(auth.exchanged, isEmpty);
      expect(find.text('Enter Authorization Code'), findsOneWidget);
    });

    testWidgets('reports a rejected code', (tester) async {
      await open(tester);
      auth.exchangeError = Exception('invalid_grant');
      await openDialog(tester);

      await tester.enterText(find.byType(TextField), 'bad');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Login failed'), findsOneWidget);
    });

    testWidgets('Cancel closes the dialog without logging in', (tester) async {
      await open(tester);
      await openDialog(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(auth.exchanged, isEmpty);
      expect(find.text('Enter Authorization Code'), findsNothing);
    });
  });
}
