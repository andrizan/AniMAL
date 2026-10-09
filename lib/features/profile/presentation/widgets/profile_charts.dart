import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

const _chartAnimation = Duration(milliseconds: 650);

class ChartSegment {
  const ChartSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class BarDatum {
  const BarDatum({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final int value;
  final bool highlight;
}

class DonutChart extends StatelessWidget {
  const DonutChart({
    required this.segments,
    required this.size,
    super.key,
    this.strokeWidth = 14,
    this.center,
    this.semanticsLabel,
  });

  final List<ChartSegment> segments;
  final double size;
  final double strokeWidth;
  final Widget? center;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: _chartAnimation,
          curve: Curves.easeOutCubic,
          builder: (context, progress, child) => CustomPaint(
            painter: _DonutPainter(
              segments: segments,
              progress: progress,
              strokeWidth: strokeWidth,
              trackColor: track,
            ),
            child: child,
          ),
          child: Center(child: center),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
  });

  final List<ChartSegment> segments;
  final double progress;
  final double strokeWidth;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final arc = (Offset.zero & size).deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true
      ..color = trackColor;
    canvas.drawArc(arc, 0, math.pi * 2, false, paint);

    final visible = segments.where((s) => s.value > 0).toList();
    final total = visible.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    final gap = visible.length > 1 ? 0.07 : 0.0;
    var start = -math.pi / 2;
    for (final segment in visible) {
      final sweep = segment.value / total * math.pi * 2;
      final drawn = math.max(sweep - gap, 0.02) * progress;
      canvas.drawArc(
        arc,
        start + gap / 2,
        drawn,
        false,
        paint..color = segment.color,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress ||
      old.strokeWidth != strokeWidth ||
      old.trackColor != trackColor ||
      old.segments != segments;
}

class SegmentedBar extends StatelessWidget {
  const SegmentedBar({required this.segments, super.key, this.height = 12});

  final List<ChartSegment> segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(context).colorScheme.surfaceContainerHigh;
    final visible = segments.where((s) => s.value > 0).toList();
    final total = visible.fold<double>(0, (sum, s) => sum + s.value);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: total <= 0
            ? ColoredBox(color: track)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < visible.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      flex: math.max(
                        1,
                        (visible[i].value / total * 1000).round(),
                      ),
                      child: ColoredBox(color: visible[i].color),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class ChartLegendItem extends StatelessWidget {
  const ChartLegendItem({
    required this.color,
    required this.label,
    required this.value,
    super.key,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class BarChart extends StatelessWidget {
  const BarChart({
    required this.bars,
    required this.color,
    required this.highlightColor,
    super.key,
    this.height = 140,
  });

  final List<BarDatum> bars;
  final Color color;
  final Color highlightColor;
  final double height;

  static const _countHeight = 16.0;
  static const _labelHeight = 18.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final track = theme.colorScheme.surfaceContainerHigh;
    final peak = bars.fold<int>(0, (m, b) => math.max(m, b.value));
    final maxBar = height - _countHeight - _labelHeight;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontSize: 10,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: _chartAnimation,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final bar in bars)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: _countHeight,
                      child: bar.value > 0
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${bar.value}',
                                style: labelStyle?.copyWith(
                                  fontWeight: bar.highlight
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: bar.highlight
                                      ? theme.colorScheme.onSurface
                                      : null,
                                ),
                              ),
                            )
                          : null,
                    ),
                    FractionallySizedBox(
                      widthFactor: 0.6,
                      child: Container(
                        height: bar.value > 0 && peak > 0
                            ? math.max(4, maxBar * bar.value / peak * t)
                            : 3,
                        decoration: BoxDecoration(
                          color: bar.value == 0
                              ? track
                              : bar.highlight
                              ? highlightColor
                              : color,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                            bottom: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: _labelHeight,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            bar.label,
                            style: labelStyle?.copyWith(
                              fontWeight: bar.highlight
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: bar.highlight
                                  ? theme.colorScheme.onSurface
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HorizontalBars extends StatelessWidget {
  const HorizontalBars({
    required this.bars,
    required this.color,
    super.key,
    this.labelWidth = 96,
  });

  final List<BarDatum> bars;
  final Color color;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final track = theme.colorScheme.surfaceContainerHigh;
    final peak = bars.fold<int>(0, (m, b) => math.max(m, b.value));

    return Column(
      children: [
        for (final bar in bars)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: labelWidth,
                  child: Text(
                    bar.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Container(
                      height: 10,
                      color: track,
                      alignment: Alignment.centerLeft,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0,
                          end: peak > 0 ? bar.value / peak : 0,
                        ),
                        duration: _chartAnimation,
                        curve: Curves.easeOutCubic,
                        builder: (context, factor, _) => FractionallySizedBox(
                          widthFactor: factor,
                          child: ColoredBox(
                            color: color,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${bar.value}',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
