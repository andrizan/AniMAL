import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart' show Genre;
import 'package:animal/data/models/broadcast.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/watch_status.dart';
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
    Widget? trailing,
    AiringEntry? nextAiring,
    VoidCallback? onTap,
    Set<int> notifying = const {},
    GoRouter? router,
  }) async {
    final card = AnimeCard(
      anime: anime,
      trailing: trailing,
      nextAiring: nextAiring,
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

  group('badges', () {
    testWidgets('maps the airing status to a compact badge', (tester) async {
      await pumpCard(
        tester,
        anime(status: 'currently_airing', mediaType: 'tv'),
      );

      expect(find.text('AIRING'), findsOneWidget);
      expect(find.text('TV'), findsOneWidget);
    });

    testWidgets('shows finished and upcoming badges', (tester) async {
      await pumpCard(
        tester,
        anime(status: 'finished_airing', mediaType: 'movie'),
      );
      expect(find.text('FINISHED'), findsOneWidget);
      expect(find.text('MOVIE'), findsOneWidget);

      await pumpCard(tester, anime(status: 'not_yet_aired'));
      expect(find.text('UPCOMING'), findsOneWidget);
    });

    testWidgets('shows the age rating compactly', (tester) async {
      await pumpCard(tester, anime(rating: 'pg_13'));

      expect(find.text('PG-13'), findsOneWidget);
    });
  });

  group('genres', () {
    testWidgets('shows at most three genres', (tester) async {
      await pumpCard(
        tester,
        anime(
          genres: const [
            Genre(id: 1, name: 'Action'),
            Genre(id: 2, name: 'Drama'),
            Genre(id: 3, name: 'Fantasy'),
            Genre(id: 4, name: 'Romance'),
          ],
        ),
      );

      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Fantasy'), findsOneWidget);
      expect(find.text('Romance'), findsNothing);
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
      expect(find.text('9'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);

      await pumpCard(
        tester,
        anime(
          mean: 8,
          list: const MyListStatus(status: WatchStatus.completed, score: 0),
        ),
      );
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('shows watched over total episodes for a listed anime', (
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

      expect(find.text('12/28 ep'), findsOneWidget);
    });

    testWidgets('shows only the episode count when not in the list', (
      tester,
    ) async {
      await pumpCard(tester, anime(episodes: 28));

      expect(find.text('28ep'), findsOneWidget);
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
