import 'package:animal/core/utils/format_utils.dart';
import 'package:animal/data/models/anilist/anilist_models.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/features/detail/presentation/widgets/detail_people.dart';
import 'package:animal/features/detail/presentation/widgets/detail_sections.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

AniListCharacter _character(
  int id, {
  List<AniListVoiceActor> voiceActors = const [],
  String? role,
}) => AniListCharacter(
  id: id,
  name: 'Character $id',
  role: role,
  voiceActors: voiceActors,
);

AniListVoiceActor _va(int id, [String? name]) =>
    AniListVoiceActor(id: id, name: name ?? 'Voice $id');

void main() {
  late List<String> opened;

  Future<void> show(WidgetTester tester, Widget child) async {
    opened = [];
    GoRoute stub(String name, String path, String label) => GoRoute(
      path: path,
      name: name,
      builder: (context, state) {
        opened.add('$label ${state.pathParameters['id']}');
        return Scaffold(
          body: Text('$label PAGE ${state.pathParameters['id']}'),
        );
      },
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) =>
              Scaffold(body: SingleChildScrollView(child: child)),
        ),
        stub('characterProfile', '/character/:id', 'character'),
        stub('staffProfile', '/staff/:id', 'staff'),
        stub('studioProfile', '/studio/:id', 'studio'),
        stub('animeDetail', '/anime/:id', 'anime'),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  group('characters and voice actors', () {
    testWidgets('tapping a character opens its profile', (tester) async {
      await show(
        tester,
        CharactersCard(
          characters: [
            _character(7, voiceActors: [_va(21)]),
          ],
        ),
      );

      await tester.tap(find.text('Character 7'));
      await tester.pumpAndSettle();

      expect(opened, ['character 7']);
      expect(find.text('character PAGE 7'), findsOneWidget);
    });

    testWidgets('tapping the voice actor opens the staff profile instead', (
      tester,
    ) async {
      await show(
        tester,
        CharactersCard(
          characters: [
            _character(7, voiceActors: [_va(21, 'Romi Park')]),
          ],
        ),
      );

      await tester.tap(find.text('Romi Park'));
      await tester.pumpAndSettle();

      expect(opened, ['staff 21']);
    });

    testWidgets('only the first voice actor is shown', (tester) async {
      await show(
        tester,
        CharactersCard(
          characters: [
            _character(
              7,
              voiceActors: [_va(21, 'First VA'), _va(22, 'Second VA')],
            ),
          ],
        ),
      );

      expect(find.text('First VA'), findsOneWidget);
      expect(find.text('Second VA'), findsNothing);
    });

    testWidgets('a character without a voice actor still opens its profile', (
      tester,
    ) async {
      await show(tester, CharactersCard(characters: [_character(7)]));

      await tester.tap(find.text('Character 7'));
      await tester.pumpAndSettle();
      expect(opened, ['character 7']);
    });

    testWidgets('five characters collapse to four behind See All', (
      tester,
    ) async {
      await show(
        tester,
        CharactersCard(
          characters: [for (var i = 1; i <= 5; i++) _character(i)],
        ),
      );

      expect(find.text('Character 4'), findsOneWidget);
      expect(find.text('Character 5'), findsNothing);
      expect(find.text('See All (5)'), findsOneWidget);

      await tester.tap(find.text('See All (5)'));
      await tester.pumpAndSettle();

      expect(find.text('Character 5'), findsOneWidget);
      expect(find.text('Show Less'), findsOneWidget);

      await tester.tap(find.text('Show Less'));
      await tester.pumpAndSettle();

      expect(find.text('Character 5'), findsNothing);
    });

    testWidgets('four characters have no See All', (tester) async {
      await show(
        tester,
        CharactersCard(
          characters: [for (var i = 1; i <= 4; i++) _character(i)],
        ),
      );

      expect(find.textContaining('See All'), findsNothing);
    });
  });

  group('staff', () {
    AniListStaff staff(int id) =>
        AniListStaff(id: id, name: 'Staff $id', role: 'Director');

    testWidgets('tapping a staff member opens their profile', (tester) async {
      await show(tester, StaffCard(staff: [staff(9)]));

      await tester.tap(find.text('Staff 9'));
      await tester.pumpAndSettle();

      expect(opened, ['staff 9']);
    });

    testWidgets('a long crew collapses behind See All and expands again', (
      tester,
    ) async {
      await show(
        tester,
        StaffCard(staff: [for (var i = 1; i <= 6; i++) staff(i)]),
      );

      expect(find.text('Staff 5'), findsNothing);
      await tester.tap(find.text('See All (6)'));
      await tester.pumpAndSettle();
      expect(find.text('Staff 6'), findsOneWidget);

      await tester.tap(find.text('Show Less'));
      await tester.pumpAndSettle();
      expect(find.text('Staff 5'), findsNothing);
      expect(find.text('Staff 4'), findsOneWidget);
    });
  });

  group('information card', () {
    AnimeDetail detail({
      String? start,
      String? end,
      int? seconds,
      String? source,
    }) => AnimeDetail(
      id: 1,
      title: 'Frieren',
      startDate: start,
      endDate: end,
      averageEpisodeDuration: seconds,
      source: source,
    );

    testWidgets('a studio opens its profile', (tester) async {
      await show(
        tester,
        InfoCard(
          detail: detail(start: '2023-09-29'),
          studios: const [
            AniListStudio(id: 5, name: 'Madhouse', isAnimationStudio: true),
            AniListStudio(id: 6, name: 'Bones', isAnimationStudio: true),
          ],
        ),
      );

      await tester.tap(find.text('Bones'));
      await tester.pumpAndSettle();

      expect(opened, ['studio 6']);
    });

    testWidgets('an anime that only has an end date says Ended', (
      tester,
    ) async {
      await show(
        tester,
        InfoCard(
          detail: detail(end: '2024-03-22'),
          studios: const [],
        ),
      );

      expect(find.text('Ended'), findsOneWidget);
      expect(find.text(formatDate('2024-03-22')), findsOneWidget);
      expect(find.text('Aired'), findsNothing);
      expect(find.text('Airing'), findsNothing);
    });

    testWidgets('start and end dates read as one range', (tester) async {
      await show(
        tester,
        InfoCard(
          detail: detail(start: '2023-09-29', end: '2024-03-22'),
          studios: const [],
        ),
      );

      expect(find.text('Aired'), findsOneWidget);
      expect(
        find.text('${formatDate('2023-09-29')} to ${formatDate('2024-03-22')}'),
        findsOneWidget,
      );
    });

    testWidgets('a start date alone is still airing', (tester) async {
      await show(
        tester,
        InfoCard(
          detail: detail(start: '2023-09-29'),
          studios: const [],
        ),
      );

      expect(find.text('Airing'), findsOneWidget);
    });

    testWidgets('a short episode is counted in minutes', (tester) async {
      await show(
        tester,
        InfoCard(
          detail: detail(start: '2023-09-29', seconds: 24 * 60),
          studios: const [],
        ),
      );

      expect(find.text('24 min per episode'), findsOneWidget);
    });

    testWidgets('a film length episode is counted in hours', (tester) async {
      await show(
        tester,
        InfoCard(
          detail: detail(start: '2023-09-29', seconds: 90 * 60),
          studios: const [],
        ),
      );

      expect(find.text('1h 30m per episode'), findsOneWidget);
    });

    group('hasContent', () {
      test('is false for an anime we know nothing about', () {
        expect(InfoCard.hasContent(detail(), const []), isFalse);
      });

      test('any single fact is enough', () {
        expect(
          InfoCard.hasContent(detail(start: '2023-09-29'), const []),
          isTrue,
        );
        expect(
          InfoCard.hasContent(detail(end: '2024-03-22'), const []),
          isTrue,
        );
        expect(InfoCard.hasContent(detail(seconds: 1500), const []), isTrue);
        expect(InfoCard.hasContent(detail(source: 'manga'), const []), isTrue);
        expect(
          InfoCard.hasContent(detail(), const [
            AniListStudio(id: 1, name: 'X', isAnimationStudio: true),
          ]),
          isTrue,
        );
        expect(
          InfoCard.hasContent(
            detail(),
            const [],
            nextAiringAt: DateTime.utc(2026, 10, 16),
          ),
          isTrue,
        );
      });

      test('a zero or missing duration is not a fact', () {
        expect(InfoCard.hasContent(detail(seconds: 0), const []), isFalse);
      });
    });
  });

  group('related anime', () {
    const related = [
      RelatedAnime(
        node: AnimeNode(id: 11, title: 'Frieren Season 2'),
        relationTypeFormatted: 'Sequel',
      ),
      RelatedAnime(
        node: AnimeNode(id: 12, title: 'Frieren Prequel'),
        relationTypeFormatted: 'Prequel',
      ),
    ];

    testWidgets('tapping one opens that anime', (tester) async {
      await show(tester, const RelatedCard(related: related));

      await tester.tap(find.text('Frieren Prequel'));
      await tester.pumpAndSettle();

      expect(opened, ['anime 12']);
      expect(find.text('anime PAGE 12'), findsOneWidget);
    });

    testWidgets('lists every entry with its relation and a count', (
      tester,
    ) async {
      await show(tester, const RelatedCard(related: related));

      expect(find.text('Related Anime'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Sequel'), findsOneWidget);
      expect(find.text('Prequel'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });
  });

  group('external links', () {
    const launcher = MethodChannel('plugins.flutter.io/url_launcher');
    late List<MethodCall> launched;

    setUp(() {
      launched = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(launcher, (call) async {
            launched.add(call);
            return true;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(launcher, null);
    });

    testWidgets('tapping a link opens its address', (tester) async {
      await show(
        tester,
        const LinksCard(
          links: [
            AniListExternalLink(
              id: 1,
              url: 'https://crunchyroll.test/frieren',
              site: 'Crunchyroll',
              type: 'STREAMING',
            ),
          ],
        ),
      );

      await tester.tap(find.text('Crunchyroll'));
      await tester.pumpAndSettle();

      final args = launched.single.arguments as Map;
      expect(launched.single.method, 'launch');
      expect(args['url'], 'https://crunchyroll.test/frieren');
    });

    testWidgets('links are announced as links', (tester) async {
      await show(
        tester,
        const LinksCard(
          links: [
            AniListExternalLink(
              id: 1,
              url: 'https://x.test',
              site: 'Official',
              type: 'INFO',
            ),
          ],
        ),
      );

      expect(
        find.ancestor(
          of: find.text('Official'),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.link == true,
          ),
        ),
        findsOneWidget,
      );
    });
  });
}
