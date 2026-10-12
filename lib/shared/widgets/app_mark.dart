import 'dart:math' as math;

import 'package:animal/core/theme/app_colors.dart';
import 'package:material_ui/material_ui.dart';

/// The app mark: a check made of linked nodes. The check is the tracking, the
/// chain of nodes is the list that is kept in step with the services it is
/// read from. It carries no logo of any service.
///
/// The geometry lives on a 1024 grid so the in-app mark and every launcher
/// icon size come from the same numbers (see `tool/render_app_icon.dart`).
class AppMarkPainter extends CustomPainter {
  const AppMarkPainter({
    this.scale = 1,
    this.glyph,
    this.accent,
    this.monochrome = false,
  });

  /// How much of the canvas the glyph fills. Launcher icons that get masked
  /// by the system draw it smaller to stay inside the safe zone.
  final double scale;

  /// Overrides the colour of the strokes and nodes, for single colour use.
  final Color? glyph;

  /// Overrides the colour of the highlighted node.
  final Color? accent;

  /// Draws the whole mark in [glyph] and leaves the highlighted node as a
  /// ring, for icons the system tints itself.
  final bool monochrome;

  static const grid = 1024.0;

  static const start = Offset(256, 552);
  static const joint = Offset(420, 716);
  static const end = Offset(744, 332);

  static const _link = 84.0;
  static const _smallNode = 80.0;
  static const _jointNode = 80.0;
  static const _endNode = 106.0;
  static const _ring = 22.0;

  /// The farthest any painted pixel is from the centre of the grid, at
  /// [scale] 1.
  static double get reach {
    double far(Offset o, double r) =>
        (o - const Offset(grid / 2, grid / 2)).distance + r;
    return math.max(
      far(start, _smallNode),
      math.max(far(joint, _jointNode), far(end, _endNode)),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide / grid;
    canvas
      ..save()
      ..translate(
        (size.width - grid * unit) / 2,
        (size.height - grid * unit) / 2,
      )
      ..scale(unit)
      ..translate(grid / 2, grid / 2)
      ..scale(scale)
      ..translate(-grid / 2, -grid / 2);

    final ink = glyph ?? AppColors.markGlyph;
    final highlight = accent ?? AppColors.markAccent;
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = _link
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final fill = Paint()
      ..color = ink
      ..isAntiAlias = true;

    if (monochrome) canvas.saveLayer(null, Paint());
    canvas
      ..drawPath(
        Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(joint.dx, joint.dy)
          ..lineTo(end.dx, end.dy),
        stroke,
      )
      ..drawCircle(start, _smallNode, fill)
      ..drawCircle(joint, _jointNode, fill)
      ..drawCircle(end, _endNode, fill)
      ..drawCircle(
        end,
        _endNode - _ring,
        Paint()
          ..color = highlight
          ..blendMode = monochrome ? BlendMode.clear : BlendMode.srcOver
          ..isAntiAlias = true,
      );
    if (monochrome) canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(AppMarkPainter old) =>
      old.scale != scale ||
      old.glyph != glyph ||
      old.accent != accent ||
      old.monochrome != monochrome;
}

/// The mark on the brand gradient, as a rounded square.
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 104});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'AniMAL',
      image: true,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.brandGradient,
          ),
          borderRadius: BorderRadius.circular(size * 36 / 104),
        ),
        child: SizedBox.square(
          dimension: size,
          child: const CustomPaint(painter: AppMarkPainter(scale: 0.86)),
        ),
      ),
    );
  }
}
