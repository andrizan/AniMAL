import 'package:animal/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ScoreBadge extends StatelessWidget {
  const ScoreBadge({
    super.key,
    required this.score,
    this.isPersonal = false,
    this.size = 14,
  });

  final double score;
  final bool isPersonal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isPersonal ? theme.colorScheme.primary : AppColors.starColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPersonal ? Icons.star : Icons.star_rounded,
          size: size,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          score.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size - 2,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
