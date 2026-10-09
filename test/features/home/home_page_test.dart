import 'package:animal/features/home/presentation/screens/home_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late GoRouter router;
  var searchOpened = false;

  Future<void> open(WidgetTester tester) async {
    searchOpened = false;
    router = GoRouter(
      initialLocation: '/home',
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
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the title and the four destinations', (tester) async {
    await open(tester);

    expect(find.text('AniMAL'), findsOneWidget);
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

  testWidgets('tapping a destination switches the page and the selection', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    expect(find.text('PAGE calendar'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );

    await tester.tap(find.text('Profile'));
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
}
