import 'dart:typed_data';

import 'package:animal/shared/widgets/app_cached_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _url = 'https://img.test/cover.jpg';

Future<void> _show(WidgetTester tester, Widget image) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: image)),
    ),
  );
  await tester.pump();
}

CachedNetworkImage _network(WidgetTester tester) =>
    tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));

Widget _placeholder(WidgetTester tester) {
  final image = _network(tester);
  return image.placeholder!(
    tester.element(find.byType(CachedNetworkImage)),
    _url,
  );
}

Widget _error(WidgetTester tester) {
  final image = _network(tester);
  return image.errorWidget!(
    tester.element(find.byType(CachedNetworkImage)),
    _url,
    Exception('404'),
  );
}

Future<Icon> _iconIn(WidgetTester tester, Widget built) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SizedBox(width: 100, height: 100, child: built)),
    ),
  );
  return tester.widget<Icon>(find.byType(Icon));
}

void main() {
  group('the picture', () {
    testWidgets('loads the given address with the given box', (tester) async {
      await _show(
        tester,
        const AppCachedImage(
          imageUrl: _url,
          width: 84,
          height: 120,
          fit: BoxFit.contain,
          memCacheWidth: 200,
          memCacheHeight: 300,
        ),
      );

      final image = _network(tester);
      expect(image.imageUrl, _url);
      expect(image.width, 84);
      expect(image.height, 120);
      expect(image.fit, BoxFit.contain);
      expect(image.memCacheWidth, 200);
      expect(image.memCacheHeight, 300);
    });

    testWidgets('covers its box by default', (tester) async {
      await _show(tester, const AppCachedImage(imageUrl: _url));

      expect(_network(tester).fit, BoxFit.cover);
    });

    testWidgets('has no rounding unless asked', (tester) async {
      await _show(tester, const AppCachedImage(imageUrl: _url));

      expect(find.byType(ClipRRect), findsNothing);
    });

    testWidgets('rounds its corners when given a radius', (tester) async {
      const radius = BorderRadius.all(Radius.circular(18));
      await _show(
        tester,
        const AppCachedImage(imageUrl: _url, borderRadius: radius),
      );

      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clip.borderRadius, radius);
      expect(
        find.descendant(
          of: find.byType(ClipRRect),
          matching: find.byType(CachedNetworkImage),
        ),
        findsOneWidget,
      );
    });
  });

  group('while it loads and when it fails', () {
    testWidgets('a loading widget stands in while loading', (tester) async {
      await _show(
        tester,
        const AppCachedImage(imageUrl: _url, loadingWidget: Text('LOADING')),
      );

      final holder = _placeholder(tester);

      expect(holder, isA<Text>());
      expect((holder as Text).data, 'LOADING');
    });

    testWidgets('without one, the fallback is shown while loading', (
      tester,
    ) async {
      await _show(tester, const AppCachedImage(imageUrl: _url));

      final holder = _placeholder(tester);

      expect(holder, isA<ColoredBox>());
      expect((await _iconIn(tester, holder)).icon, Icons.movie);
    });

    testWidgets('a failure shows the fallback even with a loading widget', (
      tester,
    ) async {
      await _show(
        tester,
        const AppCachedImage(
          imageUrl: _url,
          loadingWidget: Text('LOADING'),
          fallbackIcon: Icons.broken_image,
        ),
      );

      final failed = _error(tester);

      expect(failed, isA<ColoredBox>());
      expect((await _iconIn(tester, failed)).icon, Icons.broken_image);
    });

    testWidgets('the fallback sits on the theme surface', (tester) async {
      await _show(tester, const AppCachedImage(imageUrl: _url));

      final box = _error(tester) as ColoredBox;

      expect(
        box.color,
        Theme.of(tester.element(find.byType(CachedNetworkImage)))
            .colorScheme
            .surfaceContainerHighest,
      );
    });

    testWidgets('the fallback icon uses the given colour', (tester) async {
      await _show(
        tester,
        const AppCachedImage(imageUrl: _url, fallbackColor: Color(0xFF123456)),
      );

      expect(
        (await _iconIn(tester, _error(tester))).color,
        const Color(0xFF123456),
      );
    });

    testWidgets('otherwise the fallback icon is muted', (tester) async {
      await _show(tester, const AppCachedImage(imageUrl: _url));
      final muted = Theme.of(tester.element(find.byType(CachedNetworkImage)))
          .colorScheme
          .onSurfaceVariant;

      expect((await _iconIn(tester, _error(tester))).color, muted);
    });
  });

  group('fallback icon size', () {
    testWidgets('is 24 when the box is unknown', (tester) async {
      await _show(tester, const AppCachedImage(imageUrl: _url));

      expect((await _iconIn(tester, _error(tester))).size, 24);
    });

    testWidgets('is 35% of the shorter side of a known box', (tester) async {
      await _show(
        tester,
        const AppCachedImage(imageUrl: _url, width: 84, height: 120),
      );

      expect(
        (await _iconIn(tester, _error(tester))).size,
        closeTo(84 * 0.35, 0.001),
      );
    });

    testWidgets('follows the height when the box is wider than tall', (
      tester,
    ) async {
      await _show(
        tester,
        const AppCachedImage(imageUrl: _url, width: 200, height: 100),
      );

      expect((await _iconIn(tester, _error(tester))).size, closeTo(35, 0.001));
    });

    testWidgets('one known side is not enough to scale', (tester) async {
      await _show(tester, const AppCachedImage(imageUrl: _url, width: 200));

      expect((await _iconIn(tester, _error(tester))).size, 24);
    });

    testWidgets('an explicit size wins', (tester) async {
      await _show(
        tester,
        const AppCachedImage(
          imageUrl: _url,
          width: 84,
          height: 120,
          fallbackSize: 48,
        ),
      );

      expect((await _iconIn(tester, _error(tester))).size, 48);
    });
  });

  group('debugImageProvider', () {
    tearDown(() => AppCachedImage.debugImageProvider = null);

    final pixel = Uint8List.fromList(const [
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9C,
      0x63,
      0xF8,
      0xFF,
      0xFF,
      0x3F,
      0x00,
      0x05,
      0xFE,
      0x02,
      0xFE,
      0xA7,
      0x35,
      0x81,
      0x84,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ]);

    testWidgets('replaces the network image with the provided one', (
      tester,
    ) async {
      final asked = <String>[];
      AppCachedImage.debugImageProvider = (url) {
        asked.add(url);
        return MemoryImage(pixel);
      };

      await _show(
        tester,
        const AppCachedImage(
          imageUrl: _url,
          width: 84,
          height: 120,
          fit: BoxFit.contain,
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(asked, [_url]);
      expect(image.width, 84);
      expect(image.height, 120);
      expect(image.fit, BoxFit.contain);
    });

    testWidgets('still rounds the corners', (tester) async {
      AppCachedImage.debugImageProvider = (_) => MemoryImage(pixel);
      const radius = BorderRadius.all(Radius.circular(18));

      await _show(
        tester,
        const AppCachedImage(imageUrl: _url, borderRadius: radius),
      );

      expect(
        tester.widget<ClipRRect>(find.byType(ClipRRect)).borderRadius,
        radius,
      );
    });

    testWidgets('shows the fallback when the image cannot be read', (
      tester,
    ) async {
      AppCachedImage.debugImageProvider = (_) => MemoryImage(Uint8List(0));

      await _show(
        tester,
        const AppCachedImage(imageUrl: _url, fallbackIcon: Icons.broken_image),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.broken_image), findsOneWidget);
    });

    testWidgets('is off by default', (tester) async {
      expect(AppCachedImage.debugImageProvider, isNull);

      await _show(tester, const AppCachedImage(imageUrl: _url));

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });
  });
}
