import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/shared/widgets/app_cached_image.dart';
import 'package:animal/shared/widgets/full_screen_gallery.dart';
import 'package:animal/shared/widgets/scrim_icon_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _urls = [
  'https://img.test/1.jpg',
  'https://img.test/2.jpg',
  'https://img.test/3.jpg',
];

/// The loading spinner never stops, so `pumpAndSettle` would time out.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Finder _picture(String url) => find.byWidgetPredicate(
  (widget) => widget is AppCachedImage && widget.imageUrl == url,
);

Finder _zoomArea(String url) =>
    find.ancestor(of: _picture(url), matching: find.byType(InteractiveViewer));

void main() {
  Future<void> open(
    WidgetTester tester, {
    int index = 0,
    List<String> urls = _urls,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => FullScreenGalleryViewer.show(
                  context,
                  imageUrls: urls,
                  initialIndex: index,
                ),
                child: const Text('PAGE'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('PAGE'));
    await _settle(tester);
  }

  Future<void> swipeLeft(WidgetTester tester) async {
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1500);
    await _settle(tester);
  }

  Future<void> swipeRight(WidgetTester tester) async {
    await tester.fling(find.byType(PageView), const Offset(400, 0), 1500);
    await _settle(tester);
  }

  void zoom(WidgetTester tester, String url, double scale) {
    tester
        .widget<InteractiveViewer>(_zoomArea(url))
        .transformationController!
        .value = Matrix4.diagonal3Values(
      scale,
      scale,
      1,
    );
  }

  group('opening', () {
    testWidgets('starts on the picture that was tapped', (tester) async {
      await open(tester, index: 1);

      expect(find.byType(FullScreenGalleryViewer), findsOneWidget);
      expect(_picture(_urls[1]), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('fits each whole picture instead of cropping it', (
      tester,
    ) async {
      await open(tester);

      final image = tester.widget<AppCachedImage>(_picture(_urls[0]));
      expect(image.fit, BoxFit.contain);
      expect(image.fallbackIcon, Icons.broken_image);
      expect(image.loadingWidget, isNotNull);
    });

    testWidgets('is a see-through, dismissible route on the app barrier', (
      tester,
    ) async {
      await open(tester);

      final route =
          ModalRoute.of(tester.element(find.byType(FullScreenGalleryViewer)))!
              as PageRoute<void>;

      expect(route.opaque, isFalse);
      expect(route.barrierDismissible, isTrue);
      expect(route.barrierColor, AppColors.barrier);
    });

    testWidgets('shows the page it was opened from underneath', (tester) async {
      await open(tester);

      expect(find.text('PAGE'), findsOneWidget);
    });
  });

  group('counter', () {
    testWidgets('is read as a sentence, not as symbols', (tester) async {
      await open(tester, index: 2);

      final text = tester.widget<Text>(find.text('3 / 3'));
      expect(text.semanticsLabel, 'Picture 3 of 3');
    });

    testWidgets('follows the swipe', (tester) async {
      await open(tester);

      await swipeLeft(tester);
      expect(find.text('2 / 3'), findsOneWidget);
      expect(_picture(_urls[1]), findsOneWidget);

      await swipeRight(tester);
      expect(find.text('1 / 3'), findsOneWidget);
    });
  });

  group('swiping', () {
    testWidgets('stops at the last picture', (tester) async {
      await open(tester, index: 2);

      await swipeLeft(tester);

      expect(find.text('3 / 3'), findsOneWidget);
    });

    testWidgets('stops at the first picture', (tester) async {
      await open(tester);

      await swipeRight(tester);

      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('a single picture shows 1 / 1 and stays put', (tester) async {
      await open(tester, urls: [_urls.first]);

      await swipeLeft(tester);

      expect(find.text('1 / 1'), findsOneWidget);
      expect(_picture(_urls.first), findsOneWidget);
    });
  });

  group('zoom', () {
    testWidgets('allows pinching up to four times', (tester) async {
      await open(tester);

      final viewer = tester.widget<InteractiveViewer>(_zoomArea(_urls[0]));

      expect(viewer.maxScale, 4);
    });

    testWidgets('a zoomed picture is panned, not swiped away', (tester) async {
      await open(tester);

      zoom(tester, _urls[0], 2);
      await tester.pump();

      expect(
        tester.widget<PageView>(find.byType(PageView)).physics,
        isA<NeverScrollableScrollPhysics>(),
      );
      await swipeLeft(tester);
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('swiping works again once the picture is back to full size', (
      tester,
    ) async {
      await open(tester);

      zoom(tester, _urls[0], 2);
      await tester.pump();
      zoom(tester, _urls[0], 1);
      await tester.pump();

      expect(tester.widget<PageView>(find.byType(PageView)).physics, isNull);
      await swipeLeft(tester);
      expect(find.text('2 / 3'), findsOneWidget);
    });
  });

  group('close button', () {
    testWidgets('is a labelled 48px button', (tester) async {
      await open(tester);

      expect(find.byType(ScrimIconButton), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);
      expect(
        tester.getSize(find.byType(ScrimIconButton)).shortestSide,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('closes the viewer and shows the page again', (tester) async {
      await open(tester);

      await tester.tap(find.byTooltip('Close'));
      await _settle(tester);

      expect(find.byType(FullScreenGalleryViewer), findsNothing);
      expect(find.text('PAGE'), findsOneWidget);
    });

    testWidgets('also closes with the system back button', (tester) async {
      await open(tester);

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(find.byType(FullScreenGalleryViewer), findsNothing);
    });
  });
}
