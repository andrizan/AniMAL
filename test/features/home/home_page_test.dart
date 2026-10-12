import 'dart:async';

import 'package:animal/features/home/presentation/screens/home_page.dart';
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class _Airing extends Fake implements AiringRepository {
  int refreshes = 0;
  Object? failure;
  Map<String, List<AiringEntry>> result = {};
  Completer<void>? gate;

  @override
  Future<Map<String, List<AiringEntry>>> refreshWeeklySchedule() async {
    refreshes++;
    await gate?.future;
    final error = failure;
    if (error != null) throw error;
    return result;
  }
}

void main() {
  late GoRouter router;
  late _Airing airing;
  var searchOpened = false;

  Future<void> open(WidgetTester tester, {String initial = 'home'}) async {
    searchOpened = false;
    airing = _Airing();
    router = GoRouter(
      initialLocation: '/$initial',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => HomePage(navigationShell: shell),
          branches: [
            for (final name in ['home', 'airing', 'calendar', 'profile'])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/$name',
                    name: name,
                    builder: (context, _) => Center(child: Text('PAGE $name')),
                  ),
                ],
              ),
          ],
        ),
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, _) {
            searchOpened = true;
            return const Scaffold(body: Text('SEARCH PAGE'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [airingRepositoryProvider.overrideWithValue(airing)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the title and the four destinations', (tester) async {
    await open(tester);

    expect(find.text('Library'), findsOneWidget);
    for (final label in ['Home', 'Airing', 'Calendar', 'Profile']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('starts on the first destination', (tester) async {
    await open(tester);

    expect(find.text('PAGE home'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testWidgets('tapping a destination switches the page, selection and title', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    expect(find.text('PAGE calendar'), findsOneWidget);
    expect(find.text('Calendar'), findsNWidgets(2));
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('PAGE profile'), findsOneWidget);
  });

  testWidgets('the search button opens the search page', (tester) async {
    await open(tester);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(searchOpened, isTrue);
    expect(find.text('SEARCH PAGE'), findsOneWidget);
  });

  group('airing refresh button', () {
    testWidgets('is only shown on the Airing tab', (tester) async {
      await open(tester);
      expect(find.byTooltip('Refresh'), findsNothing);

      await tester.tap(find.text('Airing'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Refresh'), findsOneWidget);
    });

    testWidgets('refreshes the schedule', (tester) async {
      await open(tester, initial: 'airing');
      airing.result = {
        'monday': [
          AiringEntry(
            anilistId: 1,
            title: 'Show',
            airingAt: DateTime.now().toUtc(),
            episode: 1,
            timeUntilAiring: 0,
          ),
        ],
      };

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();

      expect(airing.refreshes, 1);
      expect(find.textContaining('empty'), findsNothing);
    });

    testWidgets('warns when the refreshed schedule is empty', (tester) async {
      await open(tester, initial: 'airing');

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Airing schedule is empty, try again later'),
        findsOneWidget,
      );
    });

    testWidgets('reports a failure', (tester) async {
      await open(tester, initial: 'airing');
      airing.failure = Exception('offline');

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Refresh failed, showing cached schedule'),
        findsOneWidget,
      );
    });

    testWidgets('shows a spinner and ignores taps while refreshing', (
      tester,
    ) async {
      await open(tester, initial: 'airing');
      airing.gate = Completer<void>();

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pump(const Duration(milliseconds: 50));

      final button = find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Refresh',
      );
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(tester.widget<IconButton>(button).onPressed, isNull);

      airing.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(airing.refreshes, 1);
    });
  });
}
