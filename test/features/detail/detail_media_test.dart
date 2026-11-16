import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/features/detail/presentation/widgets/detail_media.dart';
import 'package:animal/shared/widgets/app_cached_image.dart';
import 'package:animal/shared/widgets/full_screen_gallery.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _launcher = MethodChannel('plugins.flutter.io/url_launcher');

/// The viewer's spinner never stops, so `pumpAndSettle` would time out.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> launched;
  Object? launchResult;

  setUp(() {
    launched = [];
    launchResult = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_launcher, (call) async {
          launched.add(call);
          final result = launchResult;
          if (result is Exception) throw result;
          return result;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_launcher, null);
  });

  group('VideosCard', () {
    const videos = [
      AnimeVideo(
        id: 1,
        url: 'https://youtu.be/one',
        title: 'PV 1',
        thumbnail: 'https://img.test/one.jpg',
      ),
      AnimeVideo(id: 2, url: 'https://youtu.be/two', title: 'PV 2'),
    ];

    testWidgets('is titled Videos with how many there are', (tester) async {
      await tester.pumpWidget(_host(const VideosCard(videos: videos)));

      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('PV 1'), findsOneWidget);
      expect(find.text('PV 2'), findsOneWidget);
    });

    testWidgets('draws each thumbnail with a play mark', (tester) async {
      await tester.pumpWidget(_host(const VideosCard(videos: videos)));

      final images = tester.widgetList<AppCachedImage>(
        find.byType(AppCachedImage),
      );
      expect(images.map((i) => i.imageUrl), ['https://img.test/one.jpg', '']);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNWidgets(2));
    });

    testWidgets('a tap opens the video outside the app', (tester) async {
      await tester.pumpWidget(_host(const VideosCard(videos: videos)));

      await tester.tap(find.text('PV 2'));
      await tester.pump();

      final call = launched.single;
      expect(call.method, 'launch');
      expect((call.arguments as Map)['url'], 'https://youtu.be/two');
    });

    testWidgets('says so when the video cannot be opened', (tester) async {
      launchResult = false;
      await tester.pumpWidget(_host(const VideosCard(videos: videos)));

      await tester.tap(find.text('PV 1'));
      await tester.pump();

      expect(find.text('Could not open the video'), findsOneWidget);
    });

    testWidgets('says so when the platform fails to open it', (tester) async {
      launchResult = PlatformException(code: 'ACTIVITY_NOT_FOUND');
      await tester.pumpWidget(_host(const VideosCard(videos: videos)));

      await tester.tap(find.text('PV 1'));
      await tester.pump();

      expect(find.text('Could not open the video'), findsOneWidget);
    });

    testWidgets('opens only web links, since the address is not ours', (
      tester,
    ) async {
      const mixed = [
        AnimeVideo(id: 1, url: 'javascript:alert(1)', title: 'Script'),
        AnimeVideo(id: 2, url: 'intent://x#Intent;end', title: 'Intent'),
        AnimeVideo(id: 3, url: 'not a link', title: 'Broken'),
        AnimeVideo(id: 4, url: 'http://example.test/v', title: 'Plain'),
        AnimeVideo(id: 5, url: 'https://youtu.be/ok', title: 'Safe'),
      ];
      await tester.pumpWidget(_host(const VideosCard(videos: mixed)));

      expect(VideosCard.hasContent(mixed), isTrue);
      expect(find.text('Script'), findsNothing);
      expect(find.text('Intent'), findsNothing);
      expect(find.text('Broken'), findsNothing);
      expect(find.text('Plain'), findsOneWidget);
      expect(find.text('Safe'), findsOneWidget);
      expect(find.text('2'), findsOneWidget, reason: 'the count is of these');
    });

    test('has no content without a playable video', () {
      expect(VideosCard.hasContent(const []), isFalse);
      expect(
        VideosCard.hasContent(const [AnimeVideo(id: 1, url: 'ftp://x/v')]),
        isFalse,
      );
    });

    testWidgets('a video without a title is still named for screen readers', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const VideosCard(
            videos: [AnimeVideo(id: 1, url: 'https://youtu.be/a')],
          ),
        ),
      );

      expect(find.bySemanticsLabel('Play video'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a titled video is announced by its title', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_host(const VideosCard(videos: videos)));

      expect(find.bySemanticsLabel('Play PV 1'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a tile is far larger than the 48px target', (tester) async {
      await tester.pumpWidget(_host(const VideosCard(videos: videos)));

      expect(
        tester.getSize(find.byType(InkWell).first).shortestSide,
        greaterThanOrEqualTo(48),
      );
    });

    for (final (ratio, width) in [(2.0, 416), (3.0, 624)]) {
      testWidgets('decodes thumbnails at $width px on a $ratio× screen', (
        tester,
      ) async {
        tester.view.devicePixelRatio = ratio;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_host(const VideosCard(videos: videos)));

        final image = tester.widget<AppCachedImage>(
          find.byType(AppCachedImage).first,
        );
        expect(image.memCacheWidth, width);
      });
    }
  });

  group('GalleryCard', () {
    const pictures = [
      MainPicture(
        medium: 'https://img.test/1m.jpg',
        large: 'https://img.test/1l.jpg',
      ),
      MainPicture(
        medium: 'https://img.test/2m.jpg',
        large: 'https://img.test/2l.jpg',
      ),
      MainPicture(
        medium: 'https://img.test/3m.jpg',
        large: 'https://img.test/3l.jpg',
      ),
    ];

    testWidgets('is titled Gallery with how many there are', (tester) async {
      await tester.pumpWidget(_host(const GalleryCard(pictures: pictures)));

      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('draws the small size of each picture', (tester) async {
      await tester.pumpWidget(_host(const GalleryCard(pictures: pictures)));

      final urls = tester
          .widgetList<AppCachedImage>(find.byType(AppCachedImage))
          .map((i) => i.imageUrl);
      expect(
        urls,
        containsAll(['https://img.test/1m.jpg', 'https://img.test/2m.jpg']),
      );
    });

    testWidgets('a tap opens the viewer on that picture, in the large size', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const GalleryCard(pictures: pictures)));

      await tester.tap(find.byType(InkWell).at(1));
      await _settle(tester);

      final viewer = tester.widget<FullScreenGalleryViewer>(
        find.byType(FullScreenGalleryViewer),
      );
      expect(viewer.initialIndex, 1);
      expect(viewer.imageUrls, [
        'https://img.test/1l.jpg',
        'https://img.test/2l.jpg',
        'https://img.test/3l.jpg',
      ]);
      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('skips a picture with no address and keeps the index right', (
      tester,
    ) async {
      const sparse = [
        MainPicture(
          medium: 'https://img.test/a.jpg',
          large: 'https://img.test/al.jpg',
        ),
        MainPicture(),
        MainPicture(medium: 'https://img.test/c.jpg'),
      ];
      await tester.pumpWidget(_host(const GalleryCard(pictures: sparse)));

      expect(find.text('2'), findsOneWidget, reason: 'two have an address');
      await tester.tap(find.byType(InkWell).at(1));
      await _settle(tester);

      final viewer = tester.widget<FullScreenGalleryViewer>(
        find.byType(FullScreenGalleryViewer),
      );
      expect(viewer.initialIndex, 1);
      expect(viewer.imageUrls, [
        'https://img.test/al.jpg',
        'https://img.test/c.jpg',
      ]);
    });

    testWidgets('a picture with only a large size is still drawn', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const GalleryCard(
            pictures: [MainPicture(large: 'https://img.test/only-large.jpg')],
          ),
        ),
      );

      expect(
        tester.widget<AppCachedImage>(find.byType(AppCachedImage)).imageUrl,
        'https://img.test/only-large.jpg',
      );
    });

    test('has no content without a picture that has an address', () {
      expect(GalleryCard.hasContent(const []), isFalse);
      expect(GalleryCard.hasContent(const [MainPicture()]), isFalse);
      expect(GalleryCard.hasContent(const [MainPicture(large: 'l')]), isTrue);
    });

    testWidgets('each thumbnail is named for screen readers', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_host(const GalleryCard(pictures: pictures)));

      expect(find.bySemanticsLabel('Open picture 1 of 3'), findsOneWidget);
      expect(find.bySemanticsLabel('Open picture 2 of 3'), findsOneWidget);
      semantics.dispose();
    });

    for (final (ratio, width) in [(2.0, 224), (3.0, 336)]) {
      testWidgets('decodes thumbnails at $width px on a $ratio× screen', (
        tester,
      ) async {
        tester.view.devicePixelRatio = ratio;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_host(const GalleryCard(pictures: pictures)));

        final image = tester.widget<AppCachedImage>(
          find.byType(AppCachedImage).first,
        );
        expect(image.memCacheWidth, width);
      });
    }
  });
}
