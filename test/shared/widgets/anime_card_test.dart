import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/core/utils/date_utils.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart' show Genre;
import 'package:animal/data/models/broadcast.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/features/detail/presentation/widgets/detail_sections.dart'
    show broadcastLabel;
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class _Notifications extends Fake implements AnimeNotificationService {
  _Notifications(this.ids);

  final Set<int> ids;

  @override
  bool get permissionGranted => true;

  @override
  Set<int> get notificationIds => Set.unmodifiable(ids);
}

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    Anime anime, {
    Widget? header,
    Widget? trailing,
    AiringEntry? nextAiring,
    int? rank,
    String? note,
    bool showListStatus = true,
    VoidCallback? onTap,
    Set<int> notifying = const {},
    GoRouter? router,
  }) async {
    final card = AnimeCard(
      anime: anime,
      header: header,
      trailing: trailing,
      nextAiring: nextAiring,
      rank: rank,
      note: note,
      showListStatus: showListStatus,
      onTap: onTap,
    );
    final app = router != null
        ? MaterialApp.router(routerConfig: router)
        : MaterialApp(home: Scaffold(body: card));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWithValue(
            _Notifications(notifying),
          ),
        ],
        child: app,
      ),
    );
    await tester.pump();
  }

  Anime anime({
    String title = 'Frieren',
    String? status,
    String? mediaType,
    String? rating,
    double? mean,
    int? episodes,
    List<Genre> genres = const [],
    MyListStatus? list,
    Broadcast? broadcast,
    AlternativeTitles? alt,
    int id = 1,
  }) => Anime(
    id: id,
    title: title,
    status: status,
    mediaType: mediaType,
    rating: rating,
    mean: mean,
    numEpisodes: episodes,
    genres: genres,
    myListStatus: list,
    broadcast: broadcast,
    alternativeTitles: alt,
  );

  group('title area', () {
    testWidgets('shows the title and the Japanese title when present', (
      tester,
    ) async {
      await pumpCard(
        tester,
        anime(alt: const AlternativeTitles(ja: '葬送のフリーレン')),
      );

      expect(find.text('Frieren'), findsOneWidget);
      expect(find.text('葬送のフリーレン'), findsOneWidget);
    });

    testWidgets('hides an empty Japanese title', (tester) async {
      await pumpCard(tester, anime());
      final withoutTitles = find.byType(Text).evaluate().length;

      await pumpCard(tester, anime(alt: const AlternativeTitles(ja: '')));

      expect(find.byType(Text).evaluate().length, withoutTitles);
    });
  });

  group('meta line', () {
    testWidgets('joins the media type, episodes and airing status', (
      tester,
    ) async {
      await pumpCard(
        tester,
        anime(status: 'currently_airing', mediaType: 'tv', episodes: 12),
      );

      expect(find.text('TV · 12 eps · Airing'), findsOneWidget);
    });

    testWidgets('leaves out what is unknown', (tester) async {
      await pumpCard(
        tester,
        anime(status: 'finished_airing', mediaType: 'movie'),
      );
      expect(find.text('Movie · Finished'), findsOneWidget);

      await pumpCard(tester, anime(status: 'not_yet_aired'));
      expect(find.text('Upcoming'), findsOneWidget);
    });

    testWidgets('keeps the rating and genres off the card', (tester) async {
      await pumpCard(
        tester,
        anime(
          rating: 'pg_13',
          genres: const [Genre(id: 1, name: 'Action')],
        ),
      );

      expect(find.text('PG-13'), findsNothing);
      expect(find.text('Action'), findsNothing);
    });
  });

  group('scores and progress', () {
    testWidgets('shows the MAL score with one decimal', (tester) async {
      await pumpCard(tester, anime(mean: 9.3));

      expect(find.text('9.3'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('shows the personal score only when it is above zero', (
      tester,
    ) async {
      await pumpCard(
        tester,
        anime(
          mean: 8,
          list: const MyListStatus(status: WatchStatus.completed, score: 9),
        ),
      );
      expect(find.text('You 9'), findsOneWidget);

      await pumpCard(
        tester,
        anime(
          mean: 8,
          list: const MyListStatus(status: WatchStatus.completed, score: 0),
        ),
      );
      expect(find.textContaining('You'), findsNothing);
    });

    testWidgets('shows a progress bar with watched over total episodes', (
      tester,
    ) async {
      await pumpCard(
        tester,
        anime(
          episodes: 28,
          list: const MyListStatus(
            status: WatchStatus.watching,
            numEpisodesWatched: 12,
          ),
        ),
      );

      expect(find.text('12 / 28'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(12 / 28, 0.001));
      expect(bar.semanticsLabel, '12 of 28 episodes watched');
    });

    testWidgets('shows only the episode count when not in the list', (
      tester,
    ) async {
      await pumpCard(tester, anime(episodes: 28));

      expect(find.text('28 eps'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('shows no episode text when the count is unknown', (
      tester,
    ) async {
      await pumpCard(tester, anime());

      expect(find.textContaining('ep'), findsNothing);
    });

    testWidgets('shows the personal list status chip', (tester) async {
      await pumpCard(
        tester,
        anime(list: const MyListStatus(status: WatchStatus.onHold)),
      );

      expect(find.text('On Hold'), findsOneWidget);
    });

    testWidgets('has no list chip when the anime is not in the list', (
      tester,
    ) async {
      await pumpCard(tester, anime());

      for (final s in WatchStatus.values) {
        expect(find.text(s.label), findsNothing);
      }
    });

    testWidgets('the list chip can be left out where the list is implied', (
      tester,
    ) async {
      await pumpCard(
        tester,
        anime(list: const MyListStatus(status: WatchStatus.onHold)),
        showListStatus: false,
      );

      expect(find.text('On Hold'), findsNothing);
    });
  });

  testWidgets('lines up with the page gutter', (tester) async {
    await pumpCard(tester, anime());

    expect(
      tester.widget<Card>(find.byType(Card)).margin,
      const EdgeInsets.symmetric(
        vertical: AppSpacing.md / 2,
        horizontal: AppSpacing.page,
      ),
    );
  });

  group('broadcast time', () {
    testWidgets('shows a converted time when the broadcast has a start time', (
      tester,
    ) async {
      await pumpCard(
        tester,
        anime(
          broadcast: const Broadcast(dayOfWeek: 'monday', startTime: '23:00'),
        ),
      );

      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('shows nothing without a broadcast time', (tester) async {
      await pumpCard(
        tester,
        anime(broadcast: const Broadcast(dayOfWeek: 'monday')),
      );

      expect(find.byIcon(Icons.access_time), findsNothing);
    });
  });

  group('air time', () {
    // 2026-10-16 14:00 UTC, a Friday evening in Japan.
    final airingAt = DateTime.utc(2026, 10, 16, 14, 26);
    const malSlot = Broadcast(dayOfWeek: 'monday', startTime: '04:13');

    AiringEntry next() => AiringEntry(
      anilistId: 1,
      malId: 1,
      title: 'Frieren',
      airingAt: airingAt,
      episode: 5,
      timeUntilAiring: 90000,
    );

    String shown(WidgetTester tester) {
      final footer = find.byIcon(Icons.access_time);
      expect(footer, findsOneWidget);
      final row = find.ancestor(of: footer, matching: find.byType(Row)).first;
      return tester
          .widgetList<Text>(
            find.descendant(of: row, matching: find.byType(Text)),
          )
          .single
          .data!;
    }

    testWidgets('the next AniList airing wins over the MAL slot', (
      tester,
    ) async {
      await pumpCard(tester, anime(broadcast: malSlot), nextAiring: next());

      final fromAniList = shortAirSlotLabel(
        resolveAirSlot(nextAiringAt: airingAt)!,
      );
      final fromMal = shortAirSlotLabel(
        convertJstBroadcastToLocal('monday', '04:13')!,
      );
      expect(fromAniList, isNot(fromMal));
      expect(shown(tester), fromAniList);
      expect(find.text(fromMal), findsNothing);
    });

    testWidgets('shows the same time as the detail page would', (tester) async {
      await pumpCard(tester, anime(broadcast: malSlot), nextAiring: next());

      final slot = resolveAirSlot(nextAiringAt: airingAt)!;
      expect(shown(tester), shortAirSlotLabel(slot));
      expect(
        broadcastLabel(malSlot, nextAiringAt: airingAt),
        weeklyAirSlotLabel(slot),
      );
    });

    testWidgets('shows the AniList time even without a MAL broadcast', (
      tester,
    ) async {
      await pumpCard(tester, anime(), nextAiring: next());

      expect(
        shown(tester),
        shortAirSlotLabel(resolveAirSlot(nextAiringAt: airingAt)!),
      );
    });

    testWidgets('falls back to the MAL slot without an AniList airing', (
      tester,
    ) async {
      await pumpCard(tester, anime(broadcast: malSlot));

      expect(
        shown(tester),
        shortAirSlotLabel(convertJstBroadcastToLocal('monday', '04:13')!),
      );
    });

    testWidgets('a start time without a weekday still shows a time', (
      tester,
    ) async {
      await pumpCard(
        tester,
        anime(broadcast: const Broadcast(startTime: '23:00')),
      );

      expect(shown(tester), convertJstToLocal('23:00'));
    });

    testWidgets('shows no time at all without either source', (tester) async {
      await pumpCard(tester, anime());

      expect(find.byIcon(Icons.access_time), findsNothing);
    });
  });

  group('notification bell', () {
    testWidgets('shows for an airing anime that has a reminder', (
      tester,
    ) async {
      await pumpCard(tester, anime(status: 'currently_airing'), notifying: {1});

      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    });

    testWidgets('is hidden once the anime has finished airing', (tester) async {
      await pumpCard(tester, anime(status: 'finished_airing'), notifying: {1});

      expect(find.byIcon(Icons.notifications_active), findsNothing);
    });

    testWidgets('is hidden without a reminder', (tester) async {
      await pumpCard(tester, anime(status: 'currently_airing'));

      expect(find.byIcon(Icons.notifications_active), findsNothing);
    });
  });

  group('trailing and next airing', () {
    testWidgets('renders a trailing widget', (tester) async {
      await pumpCard(tester, anime(), trailing: const Text('TRAILING'));

      expect(find.text('TRAILING'), findsOneWidget);
    });
  });

  group('header, rank and note', () {
    testWidgets('a header goes above the title and keeps the edit button', (
      tester,
    ) async {
      await pumpCard(tester, anime(), header: const Text('HEADER'));

      expect(find.text('HEADER'), findsOneWidget);
      expect(find.text('Frieren'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('HEADER')).dy,
        lessThan(tester.getTopLeft(find.text('Frieren')).dy),
      );
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('a rank is shown as a badge on the cover', (tester) async {
      await pumpCard(tester, anime(), rank: 3);

      expect(find.text('#3'), findsOneWidget);
    });

    testWidgets('a note is shown under the footer', (tester) async {
      await pumpCard(tester, anime(), note: 'Not on MyAnimeList yet');

      expect(find.text('Not on MyAnimeList yet'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });
  });

  group('interaction', () {
    testWidgets(
      'a custom onTap replaces navigation and hides the edit button',
      (tester) async {
        var taps = 0;
        await pumpCard(tester, anime(), onTap: () => taps++);

        await tester.tap(find.byType(InkWell));

        expect(taps, 1);
        expect(find.byIcon(Icons.more_vert), findsNothing);
      },
    );

    testWidgets('a custom onTap disables the long-press edit modal', (
      tester,
    ) async {
      await pumpCard(tester, anime(), onTap: () {});

      await tester.longPress(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsNothing);
    });

    testWidgets('tapping opens the detail route of that anime', (tester) async {
      String? opened;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) =>
                Scaffold(body: AnimeCard(anime: anime(id: 77))),
          ),
          GoRoute(
            path: '/anime/:id',
            name: 'animeDetail',
            builder: (context, state) {
              opened = state.pathParameters['id'];
              return const Scaffold(body: Text('DETAIL'));
            },
          ),
        ],
      );
      await pumpCard(tester, anime(id: 77), router: router);

      await tester.tap(find.text('Frieren'));
      await tester.pumpAndSettle();

      expect(find.text('DETAIL'), findsOneWidget);
      expect(opened, '77');
    });

    testWidgets(
      'the more button opens the edit modal with the current values',
      (tester) async {
        await pumpCard(
          tester,
          anime(
            episodes: 12,
            list: const MyListStatus(
              status: WatchStatus.watching,
              numEpisodesWatched: 5,
              score: 7,
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Episodes Watched'), findsOneWidget);
        expect(find.text('7'), findsWidgets);
      },
    );
  });
}
