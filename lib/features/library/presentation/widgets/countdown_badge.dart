import 'package:flutter/material.dart';

class CountdownBadge extends StatelessWidget {
  const CountdownBadge({
    required this.episode,
    required this.countdown,
    required this.isUrgent,
    super.key,
  });

  final int episode;
  final String countdown;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isUrgent
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.primaryContainer;
    final fg = isUrgent
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 12, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Ep $episode · $countdown',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
