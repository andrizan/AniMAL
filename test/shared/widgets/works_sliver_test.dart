import 'dart:async';

import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:animal/shared/widgets/works_sliver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

AniListMediaAppearance _work(
  int n, {
  int? malId,
  String type = 'ANIME',
  bool noMal = false,
  String? native,
  String? format,
  int? episodes,
  String? status,
  double? meanScore,
}) => AniListMediaAppearance(
  anilistId: n + 500,
  malId: noMal ? null : malId ?? n,
  title: 'Work $n',
  titleNative: native,
  type: type,
  format: format,
  episodes: episodes,
  status: status,
  meanScore: meanScore,
);

List<AniListMediaAppearance> _works(int from, int count) => [
  for (var i = from; i < from + count; i++) _work(i),
];

class _Api extends Fake implements AniListClient {
  final requested = <int>[];
  final pages = <int, AniListWorksPage>{};
  final failing = <int>{};
  Completer<void>? gate;

  @override
  Future<AniListWorksPage> getWorksPage(
    AniListWorksSource source,
    int id,
    int page,
  ) async {
    requested.add(page);
    await gate?.future;
    if (failing.contains(page)) throw Exception('offline');
    return pages[page] ?? const AniListWorksPage(items: [], hasNextPage: false);
  }
}

/// The MAL rows already in SQLite: every anime unless listed as missing.
class _Repo extends Fake implements AnimeRepository {
  final requested = <int>[];
  final missing = <int>{};
  Completer<void>? gate;

  @override
  Future<Anime?> getCachedAnime(int malId) async {
    requested.add(malId);
    await gate?.future;
    if (missing.contains(malId)) return null;
    return Anime(id: malId, title: 'Anime $malId');
  }
}

class _Notifications extends Fake implements AnimeNotificationService {
  @override
  bool get permissionGranted => true;

  @override
  Set<int> get notificationIds => const {};
}

void main() {
  late _Api api;
  late _Repo repo;

  Future<void> show(
    WidgetTester tester, {
    required List<AniListMediaAppearance> first,
    AniListWorksSource source = AniListWorksSource.staff,
    bool onlyWithMalId = false,
    String title = 'Works',
    bool? hasMore,
  }) async {
    final cursor = AniListWorksCursor(hasMore: hasMore ?? first.length >= 10);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWithValue(_Notifications()),
          anilistApiProvider.overrideWithValue(api),
          animeRepositoryProvider.overrideWithValue(repo),
          anilistStaffDetailProvider(8).overrideWith(
            (ref) async => AniListStaffDetail(
              id: 8,
              name: 'S',
              mediaWorks: first,
              worksCursor: cursor,
            ),
          ),
          anilistStudioDetailProvider(8).overrideWith(
            (ref) async => AniListStudioDetail(
              id: 8,
              name: 'Bones',
              mediaWorks: first,
              worksCursor: cursor,
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                WorksSliver(
                  title: title,
                  source: source,
                  id: 8,
                  onlyWithMalId: onlyWithMalId,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> scrollToEnd(WidgetTester tester, String lastTitle) =>
      tester.dragUntilVisible(
        find.text(lastTitle),
        find.byType(CustomScrollView),
        const Offset(0, -300),
        maxIteration: 200,
      );

  Future<void> scrollToTop(WidgetTester tester) async {
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 100000),
      20000,
    );
    await tester.pumpAndSettle();
  }

  AnimeCard cardOf(WidgetTester tester, String title) => tester.widget(
    find.ancestor(of: find.text(title), matching: find.byType(AnimeCard)),
  );

  setUp(() {
    api = _Api();
    repo = _Repo();
  });

  group('first page', () {
    testWidgets('shows the header and the works of the first page', (
      tester,
    ) async {
      await show(tester, first: _works(1, 3));

      expect(find.text('Works'), findsOneWidget);
      expect(find.text('3 titles'), findsOneWidget);
      expect(find.byType(AnimeCard), findsNWidgets(3));
      expect(find.text('Anime 1'), findsOneWidget);
      expect(api.requested, isEmpty);
    });

    testWidgets('a short list shows no spinner and asks for nothing', (
      tester,
    ) async {
      await show(tester, first: _works(1, 4));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(api.requested, isEmpty);
    });

    testWidgets('uses the title it is given', (tester) async {
      await show(tester, first: _works(1, 2), title: 'Appears In');

      expect(find.text('Appears In'), findsOneWidget);
      expect(find.text('Works'), findsNothing);
    });

    testWidgets('renders nothing at all without any work', (tester) async {
      await show(tester, first: const []);

      expect(find.text('Works'), findsNothing);
      expect(find.byType(AnimeCard), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a full page is marked as possibly continuing', (tester) async {
      api.gate = Completer<void>();
      await show(tester, first: _works(1, 10));

      expect(find.text('10+ titles'), findsOneWidget);
    });
  });

  group('the stored MAL row', () {
    testWidgets('is looked up only for the cards near the screen', (
      tester,
    ) async {
      api.gate = Completer<void>();
      await show(tester, first: _works(1, 10));

      expect(repo.requested, isNotEmpty);
      expect(repo.requested.length, lessThan(10));
      expect(repo.requested.toSet().length, repo.requested.length);
    });

    testWidgets('is looked up once a card scrolls into view', (tester) async {
      api.gate = Completer<void>();
      await show(tester, first: _works(1, 10));
      expect(repo.requested, isNot(contains(10)));

      await scrollToEnd(tester, 'Anime 10');

      expect(repo.requested, contains(10));
    });

    testWidgets("is looked up by the work's own MAL id", (tester) async {
      await show(tester, first: [_work(1, malId: 5114), _work(2, malId: 777)]);

      expect(repo.requested, containsAll([5114, 777]));
      expect(find.text('Anime 5114'), findsOneWidget);
    });

    testWidgets('wins over what AniList said', (tester) async {
      await show(tester, first: [_work(1, meanScore: 70, episodes: 24)]);

      final card = cardOf(tester, 'Anime 1');
      expect(card.anime.title, 'Anime 1');
      expect(card.anime.mean, isNull);
      expect(find.text('Work 1'), findsNothing);
    });

    testWidgets('is drawn from AniList while it is being read', (tester) async {
      repo.gate = Completer<void>();
      await show(tester, first: _works(1, 2));

      expect(find.text('Work 1'), findsOneWidget);
      expect(find.byType(AnimeCard), findsNWidgets(2));

      repo.gate!.complete();
      await tester.pump();
      await tester.pump();

      expect(find.text('Anime 1'), findsOneWidget);
      expect(find.text('Work 1'), findsNothing);
    });
  });

  group('a work MAL does not know yet', () {
    testWidgets("is drawn from what AniList said, on MAL's scale", (
      tester,
    ) async {
      repo.missing.add(2);
      await show(
        tester,
        first: [
          _work(1),
          _work(
            2,
            native: 'ワーク',
            format: 'TV',
            episodes: 12,
            status: 'FINISHED',
            meanScore: 85,
          ),
          _work(3),
        ],
      );

      expect(find.text('Anime 1'), findsOneWidget);
      expect(find.text('Anime 3'), findsOneWidget);
      final card = cardOf(tester, 'Work 2');
      expect(card.anime.id, 2);
      expect(card.anime.alternativeTitles?.ja, 'ワーク');
      expect(card.anime.mean, 8.5);
      expect(card.anime.numEpisodes, 12);
      expect(card.anime.status, 'finished_airing');
      expect(card.anime.mediaType, 'tv');
      expect(find.text('8.5'), findsOneWidget);
      expect(find.text('TV · 12 eps · Finished'), findsOneWidget);
    });

    testWidgets('shows no score or meta line when AniList has none', (
      tester,
    ) async {
      repo.missing.add(1);
      await show(tester, first: [_work(1)]);

      final card = cardOf(tester, 'Work 1');
      expect(card.anime.mean, isNull);
      expect(card.anime.mediaType, isNull);
      expect(card.anime.status, isNull);
    });
  });

  group('infinite scroll', () {
    testWidgets('loads the next page when the end comes near', (tester) async {
      api.pages[2] = AniListWorksPage(items: _works(11, 10), hasNextPage: true);
      await show(tester, first: _works(1, 10));
      expect(api.requested, isEmpty);

      await scrollToEnd(tester, 'Anime 10');
      await tester.pump();
      await tester.pump();

      expect(api.requested, [2]);
      await scrollToEnd(tester, 'Anime 20');
      expect(find.text('Anime 20'), findsOneWidget);
    });

    testWidgets('keeps loading until every work is shown', (tester) async {
      api.pages[2] = AniListWorksPage(items: _works(11, 10), hasNextPage: true);
      api.pages[3] = AniListWorksPage(items: _works(21, 10), hasNextPage: true);
      api.pages[4] = AniListWorksPage(items: _works(31, 5), hasNextPage: false);
      await show(tester, first: _works(1, 10));

      await scrollToEnd(tester, 'Anime 35');

      expect(find.text('Anime 35'), findsOneWidget);
      expect(api.requested, [2, 3, 4]);
      await scrollToTop(tester);
      expect(find.text('35 titles'), findsOneWidget);
    });

    testWidgets('lists every work exactly once, in order', (tester) async {
      api.pages[2] = AniListWorksPage(items: _works(11, 10), hasNextPage: true);
      api.pages[3] = AniListWorksPage(items: _works(21, 4), hasNextPage: false);
      await show(tester, first: _works(1, 10));
      await scrollToEnd(tester, 'Anime 24');

      final shown = tester
          .widgetList<AnimeCard>(find.byType(AnimeCard))
          .map((c) => c.anime.id)
          .toList();
      expect(shown, [...shown]..sort());
      expect(shown.toSet().length, shown.length);
      await scrollToTop(tester);
      expect(find.text('24 titles'), findsOneWidget);
    });

    testWidgets('stops asking once the last page arrived', (tester) async {
      api.pages[2] = AniListWorksPage(items: _works(11, 3), hasNextPage: false);
      await show(tester, first: _works(1, 10));
      await scrollToEnd(tester, 'Anime 13');

      await tester.pump(const Duration(seconds: 1));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
      await tester.pump();

      expect(api.requested, [2]);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('does not ask again while a page is on its way', (
      tester,
    ) async {
      api.gate = Completer<void>();
      api.pages[2] = AniListWorksPage(items: _works(11, 10), hasNextPage: true);
      await show(tester, first: _works(1, 10));
      await scrollToEnd(tester, 'Anime 10');
      await tester.pump();

      for (var i = 0; i < 3; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
        await tester.pump();
      }

      expect(api.requested, [2]);
      api.gate!.complete();
      await tester.pump();
    });

    testWidgets('shows a spinner while a page loads', (tester) async {
      api.gate = Completer<void>();
      api.pages[2] = AniListWorksPage(items: _works(11, 10), hasNextPage: true);
      final handle = tester.ensureSemantics();
      await show(tester, first: _works(1, 10));
      await scrollToEnd(tester, 'Anime 10');
      await tester.pump();
      await tester.pump();

      expect(find.bySemanticsLabel('Loading more titles'), findsOneWidget);

      api.gate!.complete();
      await tester.pump();
      await tester.pump();
      await scrollToEnd(tester, 'Anime 20');
      handle.dispose();
    });

    testWidgets('loads on its own when the list is too short to scroll', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 12000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      api.pages[2] = AniListWorksPage(items: _works(11, 2), hasNextPage: false);

      await show(tester, first: _works(1, 10));
      await tester.pump();
      await tester.pump();

      expect(api.requested, [2]);
      expect(find.text('Anime 12'), findsOneWidget);
    });
  });

  group('failures', () {
    testWidgets('keep the works and offer a retry instead of looping', (
      tester,
    ) async {
      api.failing.add(2);
      await show(tester, first: _works(1, 10));
      await scrollToEnd(tester, 'Anime 10');
      await tester.pump();
      await tester.pump();

      expect(find.text("Couldn't load more titles"), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Anime 10'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(api.requested, [2]);
    });

    testWidgets('Retry asks again and then shows the page', (tester) async {
      api.failing.add(2);
      await show(tester, first: _works(1, 10));
      await scrollToEnd(tester, 'Anime 10');
      await tester.pump();
      await tester.pump();

      api.failing.clear();
      api.pages[2] = AniListWorksPage(items: _works(11, 2), hasNextPage: false);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();

      expect(api.requested, [2, 2]);
      expect(find.text("Couldn't load more titles"), findsNothing);
      await scrollToEnd(tester, 'Anime 12');
      expect(find.text('Anime 12'), findsOneWidget);
    });
  });

  group('kinds of work', () {
    testWidgets('media MyAnimeList cannot show says why, without a lookup', (
      tester,
    ) async {
      await show(
        tester,
        first: [
          _work(1),
          _work(2, type: 'MANGA'),
          _work(3, noMal: true),
        ],
      );

      expect(find.text('Manga is not supported in this app'), findsOneWidget);
      expect(find.text('Not available on MyAnimeList'), findsOneWidget);
      expect(repo.requested, [1]);
    });

    testWidgets('tapping an unsupported work explains it', (tester) async {
      await show(tester, first: [_work(2, type: 'MANGA')]);

      await tester.tap(find.text('Work 2'));
      await tester.pump();

      expect(
        find.text('This app does not support this media type'),
        findsOneWidget,
      );
    });

    testWidgets('only-anime lists leave out works MAL does not know', (
      tester,
    ) async {
      await show(
        tester,
        source: AniListWorksSource.studio,
        onlyWithMalId: true,
        first: [_work(1), _work(2, noMal: true), _work(3)],
      );

      expect(find.byType(AnimeCard), findsNWidgets(2));
      expect(find.text('Work 2'), findsNothing);
      expect(find.text('2 titles'), findsOneWidget);
    });

    testWidgets('an only-anime list with nothing to show has no header', (
      tester,
    ) async {
      await show(
        tester,
        source: AniListWorksSource.studio,
        onlyWithMalId: true,
        first: [_work(1, noMal: true)],
      );

      expect(find.text('Works'), findsNothing);
    });
  });
}
