import 'dart:async';

import 'package:flutter/material.dart';

/// A live countdown badge that ticks every 30 seconds.
///
/// Shows the remaining time until [airingAt] together with the
/// [episode] number. Once the air time has passed it shows "Aired".
class CountdownBadge extends StatefulWidget {
  const CountdownBadge({
    required this.airingAt,
    required this.episode,
    super.key,
  });

  final DateTime airingAt;
  final int episode;

  @override
  State<CountdownBadge> createState() => _CountdownBadgeState();
}

class _CountdownBadgeState extends State<CountdownBadge> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) {
          setState(() => _now = DateTime.now());
        }
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.airingAt.difference(_now).inSeconds;
    final theme = Theme.of(context);

    if (remaining <= 0) {
      return _Badge(
        episode: widget.episode,
        label: 'Aired',
        color: theme.colorScheme.secondaryContainer,
        textColor: theme.colorScheme.onSecondaryContainer,
      );
    }

    final isUrgent = remaining < 21600;
    return _Badge(
      episode: widget.episode,
      label: _formatCountdown(remaining),
      color: isUrgent
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.primaryContainer,
      textColor: isUrgent
          ? theme.colorScheme.onErrorContainer
          : theme.colorScheme.onPrimaryContainer,
    );
  }

  String _formatCountdown(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.episode,
    required this.label,
    required this.color,
    required this.textColor,
  });

  final int episode;
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 12, color: textColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Ep $episode · $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
