import 'package:animal/core/network/api_health_tracker.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/local/anilist_cache.dart';
import 'package:animal/features/profile/presentation/widgets/api_status_section.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/fake_adapter.dart';

class _NoCache extends Fake implements AniListCache {}

void main() {
  late ProviderContainer container;
  late FakeAdapter mal;
  late FakeAdapter anilist;

  Future<void> open(WidgetTester tester) async {
    mal = FakeAdapter((_) => const FakeResponse.json({'id': 1}));
    anilist = FakeAdapter(
      (_) => const FakeResponse.json(<String, Object?>{
        'data': <String, Object?>{},
      }),
    );
    final anilistClient = AniListClient(cache: _NoCache())
      ..dio.httpClientAdapter = anilist;
    container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(fakeDio(mal)),
        anilistApiProvider.overrideWithValue(anilistClient),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ApiStatusSection()),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  ApiHealthTracker tracker() =>
      container.read(apiHealthTrackerProvider.notifier);

  testWidgets('lists both sources, untouched at first', (tester) async {
    await open(tester);

    expect(find.text('API Status'), findsOneWidget);
    expect(find.text('MyAnimeList'), findsOneWidget);
    expect(find.text('AniList'), findsOneWidget);
    expect(find.text('No requests yet'), findsNWidgets(2));
    expect(find.byIcon(Icons.help_outline), findsNWidgets(2));
  });

  group('subtitles', () {
    testWidgets('a healthy source shows hits and when it was last used', (
      tester,
    ) async {
      await open(tester);

      tracker()
        ..recordSuccess(ApiSource.mal)
        ..recordSuccess(ApiSource.mal)
        ..recordSuccess(ApiSource.mal);
      await tester.pump();

      expect(find.textContaining('OK · 3 hits · last'), findsOneWidget);
      expect(find.textContaining('s ago'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('an error shows its code and message', (tester) async {
      await open(tester);

      tracker().recordError(
        ApiSource.anilist,
        statusCode: 500,
        message: 'Boom',
      );
      await tester.pump();

      expect(find.text('Error (500) · Boom'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('a connection error without a code omits it', (tester) async {
      await open(tester);

      tracker().recordError(
        ApiSource.mal,
        statusCode: 0,
        message: 'Connection failed',
      );
      await tester.pump();

      expect(find.text('Error · Connection failed'), findsOneWidget);
    });

    testWidgets('an error without a message says unknown', (tester) async {
      await open(tester);

      tracker().recordError(ApiSource.mal, statusCode: 503);
      await tester.pump();

      expect(find.text('Error (503) · Unknown error'), findsOneWidget);
    });

    testWidgets('rate limiting shows the count and the wait', (tester) async {
      await open(tester);

      tracker()
        ..recordError(
          ApiSource.anilist,
          statusCode: 429,
          headers: {
            'retry-after': ['90'],
          },
        )
        ..recordError(
          ApiSource.anilist,
          statusCode: 429,
          headers: {
            'retry-after': ['90'],
          },
        );
      await tester.pump();

      expect(find.text('Rate limited (HTTP 429) · 2 time(s)'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
      expect(find.text('1m'), findsOneWidget);
    });

    testWidgets('a short wait is shown in seconds, a long one in hours', (
      tester,
    ) async {
      await open(tester);

      tracker().recordError(
        ApiSource.mal,
        statusCode: 429,
        headers: {
          'retry-after': ['45'],
        },
      );
      tracker().recordError(
        ApiSource.anilist,
        statusCode: 429,
        headers: {
          'retry-after': ['7500'],
        },
      );
      await tester.pump();

      expect(find.textContaining(RegExp(r'^4[3-5]s$')), findsOneWidget);
      expect(find.text('2h 4m'), findsOneWidget);
    });

    testWidgets('a success after rate limiting shows healthy again', (
      tester,
    ) async {
      await open(tester);
      tracker().recordError(
        ApiSource.mal,
        statusCode: 429,
        headers: {
          'retry-after': ['60'],
        },
      );
      await tester.pump();

      tracker().recordSuccess(ApiSource.mal);
      await tester.pump();

      expect(find.textContaining('OK · 1 hits'), findsOneWidget);
      expect(find.textContaining('Rate limited'), findsNothing);
    });
  });

  group('testing connections', () {
    testWidgets('Test All pings both services', (tester) async {
      await open(tester);

      await tester.tap(find.text('Test All'));
      await tester.pumpAndSettle();

      expect(mal.requests.single.path, '/anime/1');
      expect(mal.requests.single.queryParameters, {'fields': 'id'});
      expect(anilist.requests.single.method, 'POST');
    });

    testWidgets('a row pings only its own service', (tester) async {
      await open(tester);

      await tester.tap(find.byTooltip('Test connection').first);
      await tester.pumpAndSettle();

      expect(mal.requests, hasLength(1));
      expect(anilist.requests, isEmpty);

      await tester.tap(find.byTooltip('Test connection').last);
      await tester.pumpAndSettle();
      expect(anilist.requests, hasLength(1));
    });

    testWidgets('a failing ping does not crash the page', (tester) async {
      await open(tester);
      mal = FakeAdapter((_) => const FakeResponse.json({}, status: 500));
      container.read(dioProvider).httpClientAdapter = mal;

      await tester.tap(find.text('Test All'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('Reset stats clears one source only', (tester) async {
    await open(tester);
    tracker()
      ..recordSuccess(ApiSource.mal)
      ..recordSuccess(ApiSource.anilist);
    await tester.pump();

    await tester.tap(find.byTooltip('More').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset stats'));
    await tester.pumpAndSettle();

    expect(find.text('No requests yet'), findsOneWidget);
    expect(find.textContaining('OK · 1 hits'), findsOneWidget);
  });
}
