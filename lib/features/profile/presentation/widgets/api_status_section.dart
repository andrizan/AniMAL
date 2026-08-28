import 'package:animal/core/network/api_health_tracker.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class ApiStatusSection extends ConsumerWidget {
  const ApiStatusSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final healthMap = ref.watch(apiHealthTrackerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'API Status',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < ApiSource.values.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _ApiStatusRow(health: healthMap[ApiSource.values[i]]!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.network_check, size: 18),
            label: const Text('Test All'),
            onPressed: () async {
              await _pingAll(ref);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _pingAll(WidgetRef ref) async {
    final dio = ref.read(dioProvider);
    final anilist = ref.read(anilistApiProvider);

    Future<void> pingMal() async {
      try {
        await dio.get<dynamic>(
          '/anime/1',
          queryParameters: {'fields': 'id'},
        );
      } on DioException {
        // Health tracker already records the error.
      }
    }

    Future<void> pingAniList() async {
      try {
        await anilist.dio.post<dynamic>(
          '',
          data: {
            'query': '{ Media(id: 1) { id } }',
          },
        );
      } on DioException {
        // Health tracker already records the error.
      }
    }

    await Future.wait([pingMal(), pingAniList()]);
  }
}

class _ApiStatusRow extends ConsumerWidget {
  const _ApiStatusRow({required this.health});

  final ApiHealth health;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = _resolveStatus(health);
    return ListTile(
      leading: Icon(
        _iconFor(status),
        color: _colorFor(status, theme),
      ),
      title: Text(apiSourceLabel(health.source)),
      subtitle: Text(
        _subtitleFor(health),
        style: theme.textTheme.bodySmall?.copyWith(
          color: _colorFor(status, theme),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == ApiStatus.rateLimited && health.retryAfter != null) ...[
            Text(
              _formatRetryAfter(health.retryAfter!),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(Icons.network_check, size: 20),
            tooltip: 'Test connection',
            onPressed: () => _testOne(ref),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (value) {
              if (value == 'reset') {
                ref
                    .read(apiHealthTrackerProvider.notifier)
                    .reset(health.source);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt, size: 18),
                    SizedBox(width: 8),
                    Text('Reset stats'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _testOne(WidgetRef ref) async {
    switch (health.source) {
      case ApiSource.mal:
        final dio = ref.read(dioProvider);
        try {
          await dio.get<dynamic>(
            '/anime/1',
            queryParameters: {'fields': 'id'},
          );
        } on DioException {
          // Already recorded.
        }
      case ApiSource.anilist:
        final anilist = ref.read(anilistApiProvider);
        try {
          await anilist.dio.post<dynamic>(
            '',
            data: {
              'query': '{ Media(id: 1) { id } }',
            },
          );
        } on DioException {
          // Already recorded.
        }
    }
  }

  ApiStatus _resolveStatus(ApiHealth health) {
    final retryAfter = health.retryAfter;
    if (retryAfter != null && DateTime.now().isBefore(retryAfter)) {
      return ApiStatus.rateLimited;
    }
    return health.status;
  }

  IconData _iconFor(ApiStatus status) {
    return switch (status) {
      ApiStatus.healthy => Icons.check_circle,
      ApiStatus.error => Icons.error,
      ApiStatus.rateLimited => Icons.hourglass_top,
      ApiStatus.unknown => Icons.help_outline,
    };
  }

  Color _colorFor(ApiStatus status, ThemeData theme) {
    return switch (status) {
      ApiStatus.healthy => AppColors.statusHealthy,
      ApiStatus.error => theme.colorScheme.error,
      ApiStatus.rateLimited => AppColors.statusRateLimited,
      ApiStatus.unknown => theme.colorScheme.onSurfaceVariant,
    };
  }

  String _subtitleFor(ApiHealth health) {
    final status = _resolveStatus(health);
    if (status == ApiStatus.healthy) {
      final last = health.lastHit;
      return 'OK · ${health.totalHits} hits'
          '${last != null ? ' · last ${_formatRelative(last)}' : ''}';
    }
    if (status == ApiStatus.rateLimited) {
      return 'Rate limited (HTTP 429) · ${health.totalRateLimited} time(s)';
    }
    if (status == ApiStatus.error) {
      final code = health.lastStatusCode;
      final msg = health.lastErrorMessage ?? 'Unknown error';
      return 'Error ${code != null && code > 0 ? '($code) ' : ''}· $msg';
    }
    return 'No requests yet';
  }

  String _formatRelative(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatRetryAfter(DateTime retryAfter) {
    final diff = retryAfter.difference(DateTime.now());
    if (diff.isNegative) return 'now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }
}
