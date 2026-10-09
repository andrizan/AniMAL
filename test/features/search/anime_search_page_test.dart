import 'dart:async';

import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/features/search/presentation/screens/anime_search_page.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Repo extends Fake implements AnimeRepository {
  final searches = <String>[];
  Object? searchFailure;
  List<Anime> ranking = [const Anime(id: 100, title: 'Top Ranked')];
  Map<String, List<Anime>> results = {};
  Completer<List<Anime>>? gate;

  @override
  Future<List<Anime>> getAnimeRanking({
    String rankingType = 'all',
    int limit = 20,
  }) async => ranking;

  @override
  Future<List<Anime>> searchAnime(String query, {int limit = 20}) async {
    searches.add(query);
    final error = searchFailure;
    if (error != null) throw error;
    if (gate != null) return gate!.future;
    return results[query] ?? const <Anime>[];
  }
}

class _Notifications extends Fake implements AnimeNotificationService {
  @override
  bool get permissionGranted => true;

  @override
  Set<int> get notificationIds => const {};
}

void main() {
  late _Repo repo;

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: noProviderRetry,
        overrides: [
          notificationServiceProvider.overrideWithValue(_Notifications()),
          animeRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: AnimeSearchPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  setUp(() => repo = _Repo());

  testWidgets('starts with the ranking instead of an empty page', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Top Ranked'), findsOneWidget);
    expect(repo.searches, isEmpty);
  });

  testWidgets('shows the results of a submitted query', (tester) async {
    repo.results['frieren'] = [
      const Anime(id: 1, title: 'Sousou no Frieren'),
      const Anime(id: 2, title: 'Frieren Special'),
    ];
    await open(tester);

    await search(tester, 'frieren');

    expect(repo.searches, ['frieren']);
    expect(find.byType(AnimeCard), findsNWidgets(2));
    expect(find.text('Top Ranked'), findsNothing);
  });

  testWidgets('typing alone does not search until it is submitted', (
    tester,
  ) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), 'frieren');
    await tester.pump(const Duration(seconds: 1));

    expect(repo.searches, isEmpty);
  });

  testWidgets('says so when nothing matches', (tester) async {
    await open(tester);

    await search(tester, 'zzzz');

    expect(find.text('No results'), findsOneWidget);
  });

  testWidgets('shows a spinner while searching', (tester) async {
    repo.gate = Completer<List<Anime>>();
    await open(tester);

    await tester.enterText(find.byType(TextField), 'slow');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repo.gate!.complete([const Anime(id: 1, title: 'Late result')]);
    await tester.pumpAndSettle();
    expect(find.text('Late result'), findsOneWidget);
  });

  testWidgets('reports a failed search and retries it', (tester) async {
    repo.results['frieren'] = [const Anime(id: 1, title: 'Sousou no Frieren')];
    repo.searchFailure = Exception('offline');
    await open(tester);

    await search(tester, 'frieren');
    expect(find.text('Failed to load results'), findsOneWidget);

    repo.searchFailure = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Failed to load results'), findsNothing);
    expect(find.text('Sousou no Frieren'), findsOneWidget);
  });

  testWidgets('the clear button brings back the ranking', (tester) async {
    repo.results['frieren'] = [const Anime(id: 1, title: 'Sousou no Frieren')];
    await open(tester);
    await search(tester, 'frieren');
    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(find.text('Top Ranked'), findsOneWidget);
    expect(find.byIcon(Icons.clear), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('has no clear button before anything is searched', (
    tester,
  ) async {
    await open(tester);

    expect(find.byIcon(Icons.clear), findsNothing);
  });
}
