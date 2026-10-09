import 'dart:async';

import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/models/anilist/anilist_models.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/features/detail/presentation/screens/character_staff_page.dart';
import 'package:animal/features/detail/presentation/screens/studio_page.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:animal/shared/widgets/info_chip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Notifications extends Fake implements AnimeNotificationService {
  @override
  bool get permissionGranted => true;

  @override
  Set<int> get notificationIds => const {};
}

Future<void> _open(
  WidgetTester tester,
  Widget page,
  List<Override> overrides,
) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: noProviderRetry,
      overrides: [
        notificationServiceProvider.overrideWithValue(_Notifications()),
        ...overrides,
      ],
      child: MaterialApp(home: page),
    ),
  );
  await tester.pumpAndSettle();
}

AniListMediaAppearance _media(
  int id, {
  int? malId,
  String type = 'ANIME',
  String? english,
  String? role,
}) => AniListMediaAppearance(
  anilistId: id,
  malId: malId,
  title: 'Title $id',
  titleEnglish: english,
  type: type,
  role: role,
);

void main() {
  group('CharacterProfilePage', () {
    List<Override> character(
      FutureOr<AniListCharacterDetail> Function() make,
    ) => [
      anilistCharacterDetailProvider(7).overrideWith((ref) async => make()),
    ];

    const edward = AniListCharacterDetail(
      id: 7,
      name: 'Edward Elric',
      nativeName: 'エドワード・エルリック',
      description: 'A [b]state alchemist[/b] with ~!a secret!~. Tom &amp; Jerry<br>Line two',
      gender: 'Male',
      age: '16',
      birthMonth: 12,
      birthDay: 3,
      birthYear: 1899,
    );

    testWidgets('shows the loading spinner first', (tester) async {
      final gate = Completer<AniListCharacterDetail>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            anilistCharacterDetailProvider(7)
                .overrideWith((ref) => gate.future),
          ],
          child: const MaterialApp(home: CharacterProfilePage(characterId: 7)),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      gate.complete(edward);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the error and retries', (tester) async {
      var fail = true;
      await _open(
        tester,
        const CharacterProfilePage(characterId: 7),
        character(() {
          if (fail) throw Exception('offline');
          return edward;
        }),
      );
      expect(find.text('Failed to load character'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load character'), findsNothing);
      expect(find.text('Edward Elric'), findsWidgets);
    });

    testWidgets('shows names, chips and the cleaned description', (
      tester,
    ) async {
      await _open(
        tester,
        const CharacterProfilePage(characterId: 7),
        character(() => edward),
      );

      expect(find.text('Edward Elric'), findsWidgets);
      expect(find.text('エドワード・エルリック'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Age: 16'), findsOneWidget);
      expect(find.text('12/3/1899'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(
        find.text('A state alchemist with [Spoiler]. Tom & Jerry\nLine two'),
        findsOneWidget,
      );
    });

    testWidgets('leaves out everything that is unknown', (tester) async {
      await _open(
        tester,
        const CharacterProfilePage(characterId: 7),
        character(() => const AniListCharacterDetail(id: 7, name: 'Mystery')),
      );

      expect(find.text('About'), findsNothing);
      expect(find.text('Appears In'), findsNothing);
      expect(find.byType(InfoChip), findsNothing);
    });

    testWidgets('formats a partial birthday', (tester) async {
      await _open(
        tester,
        const CharacterProfilePage(characterId: 7),
        character(
          () => const AniListCharacterDetail(
            id: 7,
            name: 'X',
            birthMonth: 5,
            birthDay: 9,
          ),
        ),
      );

      expect(find.text('5/9'), findsOneWidget);
    });

    testWidgets(
      'lists MAL anime as cards and other media as unsupported tiles',
      (tester) async {
        await _open(tester, const CharacterProfilePage(characterId: 7), [
          ...character(
            () => AniListCharacterDetail(
              id: 7,
              name: 'X',
              mediaAppearances: [
                _media(1, malId: 5114),
                _media(2, malId: 777, type: 'MANGA', english: 'Manga Work'),
                _media(3),
              ],
            ),
          ),
          animeListProvider('5114').overrideWith(
            (ref) async => const [Anime(id: 5114, title: 'FMA Brotherhood')],
          ),
        ]);

        expect(find.text('Appears In'), findsOneWidget);
        expect(find.text('FMA Brotherhood'), findsOneWidget);
        expect(find.text('Manga Work'), findsOneWidget);
        expect(find.text('Title 3'), findsOneWidget);
        expect(find.byType(AnimeCard), findsNWidgets(3));

        await tester.ensureVisible(find.text('Manga Work'));
        await tester.tap(find.text('Manga Work'));
        await tester.pump();
        expect(
          find.text('This app does not support this media type'),
          findsOneWidget,
        );
      },
    );
  });

  group('StaffProfilePage', () {
    List<Override> staff(AniListStaffDetail Function() make) => [
      anilistStaffDetailProvider(8).overrideWith((ref) async => make()),
    ];

    testWidgets('shows the error and retries', (tester) async {
      var fail = true;
      await _open(
        tester,
        const StaffProfilePage(staffId: 8),
        staff(() {
          if (fail) throw Exception('offline');
          return const AniListStaffDetail(id: 8, name: 'Hiromu Arakawa');
        }),
      );
      expect(find.text('Failed to load staff info'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Hiromu Arakawa'), findsWidgets);
    });

    testWidgets('shows occupations, gender, age, hometown and description', (
      tester,
    ) async {
      await _open(
        tester,
        const StaffProfilePage(staffId: 8),
        staff(
          () => const AniListStaffDetail(
            id: 8,
            name: 'Hiromu Arakawa',
            nativeName: '荒川弘',
            gender: 'Female',
            age: 52,
            homeTown: 'Hokkaido',
            occupations: ['Mangaka', 'Novelist'],
            description: 'Wrote ~!the twist!~',
          ),
        ),
      );

      for (final label in [
        'Mangaka',
        'Novelist',
        'Female',
        'Age: 52',
        'Hokkaido',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('荒川弘'), findsOneWidget);
      expect(find.text('Wrote [Spoiler]'), findsOneWidget);
    });

    testWidgets('lists works', (tester) async {
      await _open(tester, const StaffProfilePage(staffId: 8), [
        ...staff(
          () => AniListStaffDetail(
            id: 8,
            name: 'X',
            mediaWorks: [_media(1, malId: 5114, role: 'Original Creator')],
          ),
        ),
        animeListProvider('5114').overrideWith(
          (ref) async => const [Anime(id: 5114, title: 'FMA Brotherhood')],
        ),
      ]);

      expect(find.text('Works'), findsOneWidget);
      expect(find.text('FMA Brotherhood'), findsOneWidget);
    });
  });

  group('StudioProfilePage', () {
    List<Override> studio(AniListStudioDetail Function() make) => [
      anilistStudioDetailProvider(9).overrideWith((ref) async => make()),
    ];

    testWidgets('shows the error and retries', (tester) async {
      var fail = true;
      await _open(
        tester,
        const StudioProfilePage(studioId: 9),
        studio(() {
          if (fail) throw Exception('offline');
          return const AniListStudioDetail(id: 9, name: 'Bones');
        }),
      );
      expect(find.text('Failed to load studio info'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Bones'), findsWidgets);
    });

    testWidgets('shows the studio chips', (tester) async {
      await _open(
        tester,
        const StudioProfilePage(studioId: 9),
        studio(
          () => const AniListStudioDetail(
            id: 9,
            name: 'Bones',
            isAnimationStudio: true,
            favourites: 1234,
          ),
        ),
      );

      expect(find.text('Animation Studio'), findsOneWidget);
      expect(find.text('1234 favourites'), findsOneWidget);
    });

    testWidgets('a non-animation studio without favourites has no chips', (
      tester,
    ) async {
      await _open(
        tester,
        const StudioProfilePage(studioId: 9),
        studio(() => const AniListStudioDetail(id: 9, name: 'Publisher')),
      );

      expect(find.byType(InfoChip), findsNothing);
    });

    testWidgets('lists only works that have a MAL id', (tester) async {
      await _open(tester, const StudioProfilePage(studioId: 9), [
        ...studio(
          () => AniListStudioDetail(
            id: 9,
            name: 'Bones',
            mediaWorks: [_media(1, malId: 5114), _media(2)],
          ),
        ),
        animeListProvider('5114').overrideWith(
          (ref) async => const [Anime(id: 5114, title: 'FMA Brotherhood')],
        ),
      ]);

      expect(find.text('Works'), findsOneWidget);
      expect(find.byType(AnimeCard), findsOneWidget);
      expect(find.text('Title 2'), findsNothing);
    });

    testWidgets('has no Works section when nothing has a MAL id', (
      tester,
    ) async {
      await _open(
        tester,
        const StudioProfilePage(studioId: 9),
        studio(
          () => AniListStudioDetail(
            id: 9,
            name: 'Bones',
            mediaWorks: [_media(2)],
          ),
        ),
      );

      expect(find.text('Works'), findsNothing);
    });
  });
}
