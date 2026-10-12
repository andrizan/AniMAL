// Renders the README screenshots from the real screens.
//
//   flutter test tool/render_screenshots.dart
//
// Every screen is pumped with invented data and abstract generated covers, so
// no artwork or title of a real series is involved. The PNGs land in
// docs/screenshots/.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/theme/app_theme.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/broadcast.dart';
import 'package:animal/data/models/mal_user.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/season.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/features/airing/presentation/screens/anime_airing_page.dart';
import 'package:animal/features/detail/presentation/screens/anime_detail_page.dart';
import 'package:animal/features/home/presentation/screens/home_page.dart';
import 'package:animal/features/home/presentation/widgets/anime_home_tab.dart';
import 'package:animal/features/profile/domain/entities/profile_insights.dart';
import 'package:animal/features/profile/presentation/screens/anime_profile_page.dart';
import 'package:animal/features/profile/providers/profile_providers.dart';
import 'package:animal/features/seasonal/presentation/screens/anime_schedule_page.dart';
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/app_cached_image.dart';
import 'package:animal/shared/widgets/app_mark.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/support/fake_auth_repository.dart';

const _out = 'docs/screenshots';
const _phone = Size(392, 848);
const _ratio = 1.75;

const _palettes = <List<Color>>[
  [Color(0xFF7B6CF0), Color(0xFF2B1F6E), Color(0xFFFFD9A0)],
  [Color(0xFFFF8A80), Color(0xFF5B1F4F), Color(0xFFFFF1C2)],
  [Color(0xFF45D6C6), Color(0xFF14405A), Color(0xFFE6FFF5)],
  [Color(0xFFF5BE55), Color(0xFFB04A2F), Color(0xFFFFF6D6)],
  [Color(0xFF9AA1BC), Color(0xFF2D3250), Color(0xFFF4E3FF)],
  [Color(0xFF6FD6A3), Color(0xFF1D4D4F), Color(0xFFFFFBD0)],
  [Color(0xFFFF6F8C), Color(0xFF3A1C71), Color(0xFFFFE0B2)],
  [Color(0xFF5AA9FF), Color(0xFF1B2A6B), Color(0xFFFFF0C9)],
];

Future<Uint8List> _poster(int seed) async {
  const w = 420.0;
  const h = 588.0;
  final random = math.Random(seed * 7919 + 13);
  final palette = _palettes[seed % _palettes.length];
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const rect = ui.Rect.fromLTWH(0, 0, w, h);

  canvas.drawRect(
    rect,
    ui.Paint()
      ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, [
        palette[0],
        palette[1],
      ]),
  );

  final sun = ui.Offset(w * (0.3 + random.nextDouble() * 0.4), h * 0.3);
  final radius = w * (0.17 + random.nextDouble() * 0.07);
  canvas
    ..drawCircle(
      sun,
      radius * 1.7,
      ui.Paint()..color = palette[2].withValues(alpha: 0.18),
    )
    ..drawCircle(
      sun,
      radius * 1.3,
      ui.Paint()..color = palette[2].withValues(alpha: 0.28),
    )
    ..drawCircle(sun, radius, ui.Paint()..color = palette[2]);

  for (var i = 0; i < 14; i++) {
    canvas.drawCircle(
      ui.Offset(random.nextDouble() * w, random.nextDouble() * h * 0.55),
      0.8 + random.nextDouble() * 2.2,
      ui.Paint()
        ..color = const Color(0xFFFFFFFF)
            .withValues(alpha: 0.35 + random.nextDouble() * 0.5),
    );
  }

  for (var layer = 0; layer < 3; layer++) {
    final base = h * (0.62 + layer * 0.12);
    final amplitude = 18 + random.nextDouble() * 26;
    final phase = random.nextDouble() * math.pi * 2;
    final path = ui.Path()..moveTo(0, h);
    for (var x = 0.0; x <= w; x += 6) {
      path.lineTo(
        x,
        base +
            math.sin(x / w * math.pi * (1.4 + layer * 0.5) + phase) * amplitude,
      );
    }
    path
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      path,
      ui.Paint()
        ..color = Color.lerp(
          palette[1],
          const Color(0xFF000000),
          0.2 + layer * 0.22,
        )!.withValues(alpha: 0.78),
    );
  }

  final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

class _Notifications extends Fake implements AnimeNotificationService {
  @override
  bool get permissionGranted => true;

  @override
  Set<int> get notificationIds => const {};
}

class _Repo extends Fake implements AnimeRepository {
  _Repo(this.lists, this.seasonal);

  final Map<WatchStatus, List<Anime>> lists;
  final List<Anime> seasonal;

  @override
  Future<List<Anime>> getUserAnimeList({
    WatchStatus status = WatchStatus.watching,
  }) async => lists[status] ?? const [];

  @override
  Future<List<Anime>> getSeasonalAnime({
    required int year,
    required Season season,
    int limit = 100,
  }) async => seasonal;

  @override
  Future<List<Anime>> getUndatedUpcomingAnime() async => const [];
}

DateTime _snap(DateTime time) {
  const step = 30 * 60 * 1000;
  final snapped = (time.millisecondsSinceEpoch + step ~/ 2) ~/ step * step;
  return DateTime.fromMillisecondsSinceEpoch(snapped, isUtc: true);
}

MainPicture _cover(int id) => MainPicture(
  medium: 'https://covers.invalid/$id.jpg',
  large: 'https://covers.invalid/$id.jpg',
);

Anime _anime(
  int id,
  String title, {
  required double mean,
  int? episodes,
  String status = 'currently_airing',
  String type = 'tv',
  MyListStatus? list,
  String? day,
  String? time,
}) => Anime(
  id: id,
  title: title,
  mainPicture: _cover(id),
  mean: mean,
  numEpisodes: episodes,
  status: status,
  mediaType: type,
  myListStatus: list,
  broadcast: day == null ? null : Broadcast(dayOfWeek: day, startTime: time),
);

MyListStatus _list(WatchStatus status, int watched, int score) =>
    MyListStatus(status: status, numEpisodesWatched: watched, score: score);

AiringEntry _airing(
  int id,
  String title,
  Duration until,
  int episode, {
  required double mean,
  int? episodes,
  MyListStatus? list,
}) {
  final at = _snap(DateTime.now().toUtc().add(until));
  return AiringEntry(
    anilistId: id,
    malId: id,
    title: title,
    airingAt: at,
    episode: episode,
    timeUntilAiring: until.inSeconds,
    imageUrl: _cover(id).medium,
    malScore: mean,
    episodes: episodes,
    format: 'TV',
    status: 'RELEASING',
    myListStatus: list,
  );
}

const _dayNames = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 24,
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: [
              Text(
                '9:41',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(Icons.signal_cellular_alt, size: 16, color: color),
              const SizedBox(width: 4),
              Icon(Icons.wifi, size: 16, color: color),
              const SizedBox(width: 4),
              Icon(Icons.battery_full, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _wrap(
  ThemeMode mode, {
  required List<Override> overrides,
  required Key boundary,
  GoRouter? router,
  Widget? home,
  double textScale = 1,
}) {
  Widget builder(BuildContext context, Widget? child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: Stack(children: [child!, const _StatusBar()]),
  );

  final app = router != null
      ? MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: mode,
          routerConfig: router,
          builder: builder,
        )
      : MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: mode,
          home: home,
          builder: builder,
        );
  return ProviderScope(
    overrides: overrides,
    child: RepaintBoundary(key: boundary, child: app),
  );
}

GoRouter _shell(String initial) => GoRouter(
  initialLocation: initial,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => HomePage(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, _) => const AnimeHomeTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/airing',
              name: 'airing',
              builder: (context, _) => const AnimeAiringPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/calendar',
              name: 'calendar',
              builder: (context, _) => const AnimeSchedulePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, _) => const AnimeProfilePage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/search',
      name: 'search',
      builder: (context, _) => const SizedBox.shrink(),
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final posters = <Uint8List>[];
  final captured = <String, ui.Image>{};

  setUpAll(() async {
    for (var seed = 0; seed < 16; seed++) {
      posters.add(await _poster(seed));
    }
    final root = Platform.environment['FLUTTER_ROOT']!;
    final icons = File(
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    await (FontLoader(
          'MaterialIcons',
        )..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync()))))
        .load();
  });

  testWidgets('renders the README screenshots', (tester) async {
    // The hook only exists so these renders can show generated covers.
    // ignore: invalid_use_of_visible_for_testing_member
    AppCachedImage.debugImageProvider = (url) {
      final id =
          int.tryParse(RegExp(r'(\d+)\.jpg').firstMatch(url)?.group(1) ?? '') ??
          0;
      return MemoryImage(posters[id % posters.length]);
    };
    addTearDown(() {
      // ignore: invalid_use_of_visible_for_testing_member
      AppCachedImage.debugImageProvider = null;
    });

    buildLightTheme();
    buildDarkTheme();
    await tester.runAsync(GoogleFonts.pendingFonts);

    tester.view
      ..physicalSize = _phone * _ratio
      ..devicePixelRatio = _ratio
      ..padding = const FakeViewPadding(top: 48, bottom: 32)
      ..viewPadding = const FakeViewPadding(top: 48, bottom: 32);
    addTearDown(tester.view.reset);

    // Test-only mocks, used here because this file runs under flutter test.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    // ignore: invalid_use_of_visible_for_testing_member
    PackageInfo.setMockInitialValues(
      appName: 'AniMAL',
      packageName: 'com.example.animal',
      version: '2.10.0',
      buildNumber: '13',
      buildSignature: '',
    );

    final today = _dayNames[DateTime.now().weekday - 1];

    final watching = [
      _anime(
        101,
        'Clockwork Orchard',
        mean: 7.63,
        episodes: 13,
        list: _list(WatchStatus.watching, 3, 7),
        day: 'saturday',
        time: '01:30',
      ),
      _anime(
        102,
        'Moonlit Courier',
        mean: 8.42,
        episodes: 24,
        list: _list(WatchStatus.watching, 14, 9),
        day: 'friday',
        time: '23:30',
      ),
      _anime(
        103,
        'Paper Lantern Club',
        mean: 7.91,
        episodes: 12,
        list: _list(WatchStatus.watching, 7, 8),
        day: 'sunday',
        time: '17:00',
      ),
      _anime(
        104,
        'Salt and Sparrow',
        mean: 8.12,
        episodes: 11,
        list: _list(WatchStatus.watching, 9, 8),
        day: 'thursday',
        time: '22:00',
      ),
      _anime(
        105,
        'Tidebound',
        mean: 8.74,
        episodes: 26,
        status: 'finished_airing',
        list: _list(WatchStatus.watching, 19, 10),
      ),
      _anime(
        106,
        'Velvet Meridian',
        mean: 7.48,
        episodes: 12,
        status: 'finished_airing',
        list: _list(WatchStatus.watching, 5, 0),
      ),
    ];

    final airingMap = <int, AiringEntry>{
      101: _airing(
        101,
        'Clockwork Orchard',
        const Duration(days: 1, hours: 3, minutes: 12),
        4,
        mean: 7.63,
        episodes: 13,
      ),
      102: _airing(
        102,
        'Moonlit Courier',
        const Duration(days: 2, hours: 5, minutes: 40),
        15,
        mean: 8.42,
        episodes: 24,
      ),
      103: _airing(
        103,
        'Paper Lantern Club',
        const Duration(hours: 5, minutes: 20),
        8,
        mean: 7.91,
        episodes: 12,
      ),
      104: _airing(
        104,
        'Salt and Sparrow',
        const Duration(days: 3, hours: 1, minutes: 5),
        10,
        mean: 8.12,
        episodes: 11,
      ),
    };

    final schedule = <String, List<AiringEntry>>{
      for (final day in _dayNames) day: <AiringEntry>[],
      today: [
        _airing(
          103,
          'Paper Lantern Club',
          const Duration(hours: 1, minutes: 48),
          8,
          mean: 7.91,
          episodes: 12,
          list: _list(WatchStatus.watching, 7, 8),
        ),
        _airing(
          110,
          'Glass Harbor Nights',
          const Duration(hours: 3, minutes: 25),
          5,
          mean: 8.05,
          episodes: 12,
        ),
        _airing(
          111,
          'The Seventh Tram',
          const Duration(hours: 6, minutes: 40),
          9,
          mean: 7.77,
          episodes: 13,
        ),
        _airing(
          112,
          'Ember and Ash Cafe',
          const Duration(hours: 9, minutes: 5),
          3,
          mean: 7.34,
          episodes: 12,
        ),
        _airing(
          113,
          'Northbound Lanterns',
          const Duration(hours: 13, minutes: 30),
          6,
          mean: 8.31,
          episodes: 24,
        ),
      ],
    };

    final seasonal = [
      _anime(
        120,
        'Glass Harbor Nights',
        mean: 8.05,
        episodes: 12,
        day: 'monday',
        time: '22:30',
      ),
      _anime(
        121,
        'Orbit of Small Things',
        mean: 7.52,
        episodes: 12,
        day: 'monday',
        time: '23:30',
      ),
      _anime(
        122,
        'The Seventh Tram',
        mean: 7.77,
        episodes: 13,
        day: 'tuesday',
        time: '21:00',
      ),
      _anime(
        123,
        'Ember and Ash Cafe',
        mean: 7.34,
        episodes: 12,
        day: 'wednesday',
        time: '23:00',
      ),
      _anime(
        124,
        'Moonlit Courier',
        mean: 8.42,
        episodes: 24,
        day: 'friday',
        time: '23:30',
      ),
      _anime(
        125,
        'Northbound Lanterns',
        mean: 8.31,
        episodes: 24,
        day: 'saturday',
        time: '18:00',
      ),
    ];

    final repo = _Repo({WatchStatus.watching: watching}, seasonal);
    final common = <Override>[
      notificationServiceProvider.overrideWithValue(_Notifications()),
      animeRepositoryProvider.overrideWithValue(repo),
      airingByMalIdProvider.overrideWith((ref) async => airingMap),
      weeklyAiringProvider.overrideWith((ref) async => schedule),
    ];

    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
      }
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> shoot(String name, Widget app, GlobalKey key) async {
      await tester.pumpWidget(app);
      await settle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(key),
      );
      final image = (await tester.runAsync(
        () => boundary.toImage(pixelRatio: _ratio),
      ))!;
      captured[name] = image;
      await tester.runAsync(() async {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$_out/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(data!.buffer.asUint8List());
      });
      await tester.pumpWidget(const SizedBox.shrink());
    }

    GlobalKey key() => GlobalKey();

    var k = key();
    await shoot(
      'library',
      _wrap(
        ThemeMode.dark,
        overrides: common,
        boundary: k,
        router: _shell('/home'),
      ),
      k,
    );

    k = key();
    await shoot(
      'library_light',
      _wrap(
        ThemeMode.light,
        overrides: common,
        boundary: k,
        router: _shell('/home'),
      ),
      k,
    );

    k = key();
    await shoot(
      'airing',
      _wrap(
        ThemeMode.dark,
        overrides: common,
        boundary: k,
        router: _shell('/airing'),
      ),
      k,
    );

    k = key();
    await shoot(
      'calendar',
      _wrap(
        ThemeMode.dark,
        overrides: common,
        boundary: k,
        router: _shell('/calendar'),
      ),
      k,
    );

    final profile = <Override>[
      ...common,
      malAuthRepositoryProvider.overrideWithValue(
        FakeAuthRepository()..authenticated = true,
      ),
      userInfoProvider.overrideWith(
        (ref) async => const MalUser(
          id: 1,
          name: 'night_reader',
          location: 'Somewhere Warm',
          joinedAt: '2019-03-14T09:00:00+00:00',
          animeStatistics: AnimeStatistics(
            numDaysWatched: 41.8,
            numDaysWatching: 3.2,
            numDaysCompleted: 36.4,
            numDaysOnHold: 0.9,
            numDaysDropped: 1.3,
            meanScore: 7.9,
            numItems: 214,
            numEpisodes: 3120,
            numItemsWatching: 6,
            numItemsCompleted: 148,
            numItemsOnHold: 7,
            numItemsDropped: 11,
            numItemsPlanToWatch: 42,
          ),
        ),
      ),
      profileInsightsProvider.overrideWith(
        (ref) async => ProfileInsights(
          totalCount: 214,
          scoreCounts: const [1, 2, 4, 6, 14, 28, 52, 61, 30, 16],
          genres: const [
            CountEntry('Adventure', 88),
            CountEntry('Fantasy', 74),
            CountEntry('Slice of Life', 61),
            CountEntry('Drama', 52),
            CountEntry('Mystery', 33),
          ],
          formats: const [
            CountEntry('TV', 150),
            CountEntry('Movie', 31),
            CountEntry('OVA', 18),
            CountEntry('ONA', 15),
          ],
          activity: [
            for (var i = 0; i < 12; i++)
              MonthActivity(
                month: DateTime(
                  DateTime.now().year,
                  DateTime.now().month - 11 + i,
                ),
                count: const [5, 8, 12, 6, 9, 14, 11, 7, 16, 10, 13, 18][i],
              ),
          ],
        ),
      ),
    ];
    k = key();
    await shoot(
      'profile',
      _wrap(
        ThemeMode.dark,
        overrides: profile,
        boundary: k,
        router: _shell('/profile'),
      ),
      k,
    );

    final detail = <Override>[
      ...common,
      animeDetailProvider(102).overrideWith(
        (ref) async => AnimeDetail(
          id: 102,
          title: 'Moonlit Courier',
          mainPicture: _cover(102),
          mean: 8.42,
          rank: 214,
          popularity: 480,
          numEpisodes: 24,
          status: 'currently_airing',
          rating: 'pg_13',
          source: 'light_novel',
          synopsis:
              'Every night after the last tram, a quiet courier carries letters '
              'that people were too shy to send across a city of paper lanterns. '
              'Each delivery changes who reads it, and one unsigned envelope '
              'keeps finding its way back to her.',
          startDate: '2026-10-02',
          mediaType: 'tv',
          numScoringUsers: 182340,
          genres: const [
            Genre(id: 1, name: 'Drama'),
            Genre(id: 2, name: 'Fantasy'),
            Genre(id: 3, name: 'Slice of Life'),
          ],
          broadcast: const Broadcast(dayOfWeek: 'friday', startTime: '23:30'),
          alternativeTitles: const AlternativeTitles(
            en: 'Moonlit Courier',
            synonyms: ['Tsukiakari Haitatsu'],
          ),
          startSeason: StartSeason(year: DateTime.now().year, season: 'fall'),
          averageEpisodeDuration: 1440,
          myListStatus: _list(WatchStatus.watching, 14, 9),
        ),
      ),
      anilistAnimeExtraProvider(102).overrideWith(
        (ref) async => AniListAnimeExtra(
          nextAiring: AniListNextAiring(
            airingAt: _snap(
              DateTime.now().toUtc().add(
                const Duration(days: 2, hours: 5, minutes: 40),
              ),
            ),
            episode: 15,
            timeUntilAiring: const Duration(
              days: 2,
              hours: 5,
              minutes: 40,
            ).inSeconds,
          ),
          studios: const [
            AniListStudio(
              id: 1,
              name: 'Lantern Works',
              isAnimationStudio: true,
              isMain: true,
            ),
          ],
          people: AniListAnimePeople(
            characters: [
              for (final (i, name) in [
                'Mio Hanabata',
                'Ren Okamura',
                'Aiko Fujimoto',
                'Old Man Tsuji',
              ].indexed)
                AniListCharacter(
                  id: 10 + i,
                  name: name,
                  imageUrl: _cover(130 + i).medium,
                  role: i < 2 ? 'MAIN' : 'SUPPORTING',
                  voiceActors: [
                    AniListVoiceActor(
                      id: 50 + i,
                      name: [
                        'Sana Miyake',
                        'Haru Ishikawa',
                        'Nene Kuroda',
                        'Goro Sato',
                      ][i],
                      imageUrl: _cover(140 + i).medium,
                      language: 'JAPANESE',
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    ];
    k = key();
    await shoot(
      'detail',
      _wrap(
        ThemeMode.dark,
        overrides: detail,
        boundary: k,
        home: const AnimeDetailPage(animeId: 102),
      ),
      k,
    );

    await _hero(
      tester,
      captured['airing']!,
      captured['library']!,
      captured['detail']!,
    );
  });
}

Future<void> _hero(
  WidgetTester tester,
  ui.Image left,
  ui.Image center,
  ui.Image right,
) async {
  tester.view
    ..physicalSize = const Size(1600, 900)
    ..devicePixelRatio = 1
    ..padding = FakeViewPadding.zero
    ..viewPadding = FakeViewPadding.zero;

  const innerWidth = 300.0;
  final innerHeight = innerWidth * left.height / left.width;

  Widget phone(ui.Image image, double x, double y, {double opacity = 1}) =>
      Positioned(
        left: x,
        top: y,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0B0A12),
            borderRadius: BorderRadius.circular(46),
            boxShadow: const [
              BoxShadow(
                color: Color(0x47000000),
                blurRadius: 70,
                offset: Offset(0, 26),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(38),
            child: SizedBox(
              width: innerWidth,
              height: innerHeight,
              child: RawImage(image: image, fit: BoxFit.cover),
            ),
          ),
        ),
      );

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      home: RepaintBoundary(
        key: key,
        child: Scaffold(
          backgroundColor: AppColors.brandGradient.last,
          body: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.brandGradient,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -160,
                top: -200,
                child: Container(
                  width: 560,
                  height: 560,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.markGlyph.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                right: -120,
                bottom: -240,
                child: Container(
                  width: 640,
                  height: 640,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.markAccent.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Positioned(
                left: 96,
                top: 0,
                bottom: 0,
                width: 520,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox.square(
                      dimension: 132,
                      child: CustomPaint(painter: AppMarkPainter()),
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) => Text(
                        'AniMAL',
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              color: AppColors.markGlyph,
                              fontSize: 96,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Builder(
                      builder: (context) => Text(
                        'Your anime list, kept calm.\nLibrary, airing countdowns,\ncalendar and insights.',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.markGlyph.withValues(alpha: 0.88),
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              phone(left, 644, 176),
              phone(right, 1262, 176),
              phone(center, 953, 104),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 0.9);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/hero.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
}
