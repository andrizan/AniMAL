import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/shared/widgets/app_mark.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _px = 256;

/// The pixels of [painter] drawn on a [_px] square.
Future<ByteData> _render(WidgetTester tester, AppMarkPainter painter) async {
  final data = await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    painter.paint(ui.Canvas(recorder), const Size(256, 256));
    final image = await recorder.endRecording().toImage(_px, _px);
    return image.toByteData();
  });
  return data!;
}

Color _at(ByteData rgba, Offset grid) {
  final x = (grid.dx / AppMarkPainter.grid * _px).round();
  final y = (grid.dy / AppMarkPainter.grid * _px).round();
  final i = (y * _px + x) * 4;
  return Color.fromARGB(
    rgba.getUint8(i + 3),
    rgba.getUint8(i),
    rgba.getUint8(i + 1),
    rgba.getUint8(i + 2),
  );
}

void main() {
  group('the glyph', () {
    testWidgets('is white nodes and links with a highlighted end node', (
      tester,
    ) async {
      final rgba = await _render(tester, const AppMarkPainter());

      expect(_at(rgba, AppMarkPainter.start), AppColors.markGlyph);
      expect(_at(rgba, AppMarkPainter.joint), AppColors.markGlyph);
      expect(_at(rgba, AppMarkPainter.end), AppColors.markAccent);
    });

    testWidgets('joins the nodes with links', (tester) async {
      final rgba = await _render(tester, const AppMarkPainter());
      final startToJoint = Offset.lerp(
        AppMarkPainter.start,
        AppMarkPainter.joint,
        0.5,
      )!;
      final jointToEnd = Offset.lerp(
        AppMarkPainter.joint,
        AppMarkPainter.end,
        0.5,
      )!;

      expect(_at(rgba, startToJoint), AppColors.markGlyph);
      expect(_at(rgba, jointToEnd), AppColors.markGlyph);
    });

    testWidgets('leaves the rest of the canvas clear', (tester) async {
      final rgba = await _render(tester, const AppMarkPainter());

      for (final corner in const [
        Offset(20, 20),
        Offset(1000, 20),
        Offset(20, 1000),
        Offset(1000, 1000),
      ]) {
        expect(_at(rgba, corner).a, 0, reason: '$corner');
      }
    });

    testWidgets('can be drawn in another colour', (tester) async {
      const ink = Color(0xFF123456);
      final rgba = await _render(
        tester,
        const AppMarkPainter(glyph: ink, accent: Color(0xFFABCDEF)),
      );

      expect(_at(rgba, AppMarkPainter.start), ink);
      expect(_at(rgba, AppMarkPainter.end), const Color(0xFFABCDEF));
    });

    testWidgets('a smaller scale pulls the glyph toward the centre', (
      tester,
    ) async {
      final rgba = await _render(tester, const AppMarkPainter(scale: 0.5));
      const centre = Offset(512, 512);
      final shrunkEnd = centre + (AppMarkPainter.end - centre) * 0.5;

      expect(_at(rgba, shrunkEnd), AppColors.markAccent);
      expect(_at(rgba, AppMarkPainter.end).a, 0);
    });

    testWidgets('stays centred when the canvas is not square', (tester) async {
      final data = await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        const AppMarkPainter().paint(ui.Canvas(recorder), const Size(512, 256));
        final image = await recorder.endRecording().toImage(512, 256);
        return image.toByteData();
      });

      int alphaAt(int x, int y) => data!.getUint8((y * 512 + x) * 4 + 3);

      expect(alphaAt(10, 128), 0);
      expect(alphaAt(500, 128), 0);
      // The glyph sits in the middle square, not against the left edge.
      expect(alphaAt(128 + 64, 138), isNonZero);
    });
  });

  group('monochrome', () {
    testWidgets('paints one colour and leaves the end node as a ring', (
      tester,
    ) async {
      const ink = Color(0xFF000000);
      final rgba = await _render(
        tester,
        const AppMarkPainter(glyph: ink, monochrome: true),
      );

      expect(_at(rgba, AppMarkPainter.start), ink);
      expect(_at(rgba, AppMarkPainter.joint), ink);
      expect(_at(rgba, AppMarkPainter.end).a, 0, reason: 'hole of the ring');
      expect(
        _at(rgba, AppMarkPainter.end + const Offset(0, 98)),
        ink,
        reason: 'the ring itself',
      );
    });

    testWidgets('never shows the accent colour', (tester) async {
      final rgba = await _render(
        tester,
        const AppMarkPainter(monochrome: true),
      );

      for (var i = 0; i < _px * _px * 4; i += 4) {
        final color = Color.fromARGB(
          rgba.getUint8(i + 3),
          rgba.getUint8(i),
          rgba.getUint8(i + 1),
          rgba.getUint8(i + 2),
        );
        if (color.a == 0) continue;
        expect(color.toARGB32(), isNot(AppColors.markAccent.toARGB32()));
      }
    });
  });

  group('launcher safe zones', () {
    test('an adaptive icon keeps the glyph inside the guaranteed circle', () {
      // Android only promises the middle 66dp of the 108dp canvas.
      const safeRadius = AppMarkPainter.grid * 33 / 108;

      expect(AppMarkPainter.reach * 0.76, lessThanOrEqualTo(safeRadius));
    });

    test('a full tile leaves a margin to the edge', () {
      expect(AppMarkPainter.reach * 0.92, lessThan(AppMarkPainter.grid * 0.4));
    });
  });

  group('repainting', () {
    test('only when something that is drawn changes', () {
      const base = AppMarkPainter();

      expect(base.shouldRepaint(const AppMarkPainter()), isFalse);
      expect(base.shouldRepaint(const AppMarkPainter(scale: 0.5)), isTrue);
      expect(
        base.shouldRepaint(const AppMarkPainter(glyph: Color(0xFF000000))),
        isTrue,
      );
      expect(
        base.shouldRepaint(const AppMarkPainter(accent: Color(0xFF000000))),
        isTrue,
      );
      expect(
        base.shouldRepaint(const AppMarkPainter(monochrome: true)),
        isTrue,
      );
    });
  });

  group('AppMark', () {
    Future<void> show(WidgetTester tester, Widget mark) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: mark)),
      ),
    );

    testWidgets('is announced as the app, not as a loose graphic', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await show(tester, const AppMark());

      expect(find.bySemanticsLabel('AniMAL'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('is 104 square unless told otherwise', (tester) async {
      await show(tester, const AppMark());

      expect(tester.getSize(find.byType(AppMark)), const Size(104, 104));
    });

    testWidgets('scales its size and its corner radius together', (
      tester,
    ) async {
      await show(tester, const AppMark(size: 52));

      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.byType(AppMark),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;

      expect(tester.getSize(find.byType(AppMark)), const Size(52, 52));
      expect(decoration.borderRadius, BorderRadius.circular(18));
    });

    testWidgets('sits on the brand gradient', (tester) async {
      await show(tester, const AppMark());

      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.byType(AppMark),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;

      expect(
        (decoration.gradient! as LinearGradient).colors,
        AppColors.brandGradient,
      );
    });

    testWidgets('draws the glyph at the in-app scale', (tester) async {
      await show(tester, const AppMark());

      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(AppMark),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as AppMarkPainter;

      expect(painter.scale, 0.86);
      expect(painter.monochrome, isFalse);
    });

    testWidgets('white reads on both ends of the gradient', (tester) async {
      double luminance(Color c) {
        double ch(double v) => v <= 0.03928
            ? v / 12.92
            : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
        return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
      }

      final white = luminance(AppColors.markGlyph);
      for (final end in AppColors.brandGradient) {
        final ratio = (white + 0.05) / (luminance(end) + 0.05);
        expect(ratio, greaterThanOrEqualTo(3), reason: '$end');
      }
    });
  });
}
