import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/shared/widgets/app_cached_image.dart';
import 'package:animal/shared/widgets/full_screen_image.dart';
import 'package:animal/shared/widgets/scrim_icon_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _url = 'https://img.test/cover.jpg';

/// The loading spinner never stops, so `pumpAndSettle` would time out.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  Future<void> open(
    WidgetTester tester, {
    String? heroTag,
    EdgeInsets padding = EdgeInsets.zero,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(padding: padding),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => FullScreenImageViewer.show(
                  context,
                  imageUrl: _url,
                  heroTag: heroTag,
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

  AppCachedImage image(WidgetTester tester) =>
      tester.widget<AppCachedImage>(find.byType(AppCachedImage));

  group('opening', () {
    testWidgets('shows the picture over the page it was opened from', (
      tester,
    ) async {
      await open(tester);

      expect(find.byType(FullScreenImageViewer), findsOneWidget);
      expect(image(tester).imageUrl, _url);
      expect(find.text('PAGE'), findsOneWidget, reason: 'route is see-through');
    });

    for (final tag in <String?>[null, 'cover-1']) {
      testWidgets('fits the whole picture instead of cropping it '
          '(${tag == null ? 'no hero' : 'with hero'})', (tester) async {
        await open(tester, heroTag: tag);

        expect(image(tester).fit, BoxFit.contain);
        expect(image(tester).fallbackIcon, Icons.broken_image);
        expect(image(tester).loadingWidget, isNotNull);
      });
    }

    testWidgets('is a see-through, dismissible route on the app barrier', (
      tester,
    ) async {
      await open(tester);

      final route =
          ModalRoute.of(tester.element(find.byType(FullScreenImageViewer)))!
              as PageRoute<void>;

      expect(route.opaque, isFalse);
      expect(route.barrierDismissible, isTrue);
      expect(route.barrierColor, AppColors.barrier);
    });

    testWidgets('fades in rather than sliding', (tester) async {
      await open(tester);

      expect(
        find.ancestor(
          of: find.byType(FullScreenImageViewer),
          matching: find.byType(FadeTransition),
        ),
        findsWidgets,
      );
    });

    testWidgets('shares a hero with the thumbnail when given a tag', (
      tester,
    ) async {
      await open(tester, heroTag: 'cover-1');

      final hero = tester.widget<Hero>(find.byType(Hero));

      expect(hero.tag, 'cover-1');
      expect(
        find.descendant(
          of: find.byType(Hero),
          matching: find.byType(AppCachedImage),
        ),
        findsOneWidget,
      );
    });

    testWidgets('has no hero without a tag', (tester) async {
      await open(tester);

      expect(find.byType(Hero), findsNothing);
      expect(find.byType(AppCachedImage), findsOneWidget);
    });
  });

  group('zoom', () {
    testWidgets('allows pinching from half size up to four times', (
      tester,
    ) async {
      await open(tester);

      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );

      expect(viewer.minScale, 0.5);
      expect(viewer.maxScale, 4);
    });

    testWidgets('the picture is inside the zoomable area', (tester) async {
      await open(tester);

      expect(
        find.descendant(
          of: find.byType(InteractiveViewer),
          matching: find.byType(AppCachedImage),
        ),
        findsOneWidget,
      );
    });
  });

  group('close button', () {
    testWidgets('is a labelled 48px button', (tester) async {
      await open(tester);

      final button = find.byType(ScrimIconButton);

      expect(button, findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(tester.getSize(button).shortestSide, greaterThanOrEqualTo(48));
    });

    testWidgets('closes the viewer and shows the page again', (tester) async {
      await open(tester);

      await tester.tap(find.byTooltip('Close'));
      await _settle(tester);

      expect(find.byType(FullScreenImageViewer), findsNothing);
      expect(find.text('PAGE'), findsOneWidget);
    });

    testWidgets('sits at the top right below the status bar', (tester) async {
      await open(tester, padding: const EdgeInsets.only(top: 40));

      final topRight = tester.getTopRight(find.byType(ScrimIconButton));
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;

      expect(topRight.dy, 40 + 8);
      expect(screen.width - topRight.dx, 16);
    });

    testWidgets('also closes with the system back button', (tester) async {
      await open(tester);

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(find.byType(FullScreenImageViewer), findsNothing);
    });
  });
}
