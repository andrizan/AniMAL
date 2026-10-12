import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/core/utils/format_utils.dart';
import 'package:animal/data/models/mal_user.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/features/profile/domain/entities/profile_insights.dart';
import 'package:animal/features/profile/presentation/widgets/profile_charts.dart';
import 'package:animal/features/profile/providers/profile_providers.dart';
import 'package:animal/shared/providers/anime_list_providers.dart';
import 'package:animal/shared/widgets/section_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _topGenreCount = 6;

Color _statusColor(BuildContext context, WatchStatus status) {
  final colors = StatusColors.of(context);
  return switch (status) {
    WatchStatus.watching => colors.listWatching,
    WatchStatus.completed => colors.listCompleted,
    WatchStatus.onHold => colors.listOnHold,
    WatchStatus.dropped => colors.listDropped,
    WatchStatus.planToWatch => colors.listPlanToWatch,
  };
}

int _statusCount(AnimeStatistics stats, WatchStatus status) =>
    switch (status) {
      WatchStatus.watching => stats.numItemsWatching,
      WatchStatus.completed => stats.numItemsCompleted,
      WatchStatus.onHold => stats.numItemsOnHold,
      WatchStatus.dropped => stats.numItemsDropped,
      WatchStatus.planToWatch => stats.numItemsPlanToWatch,
    } ??
    0;

class LibrarySection extends StatelessWidget {
  const LibrarySection({required this.stats, super.key});

  final AnimeStatistics stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = {
      for (final status in WatchStatus.values)
        status: _statusCount(stats, status),
    };
    final sum = counts.values.fold<int>(0, (a, b) => a + b);
    final total = stats.numItems ?? sum;

    return SectionCard(
      title: 'Library',
      trailing: '${formatCount(total)} anime',
      child: Column(
        children: [
          Center(
            child: DonutChart(
              size: 168,
              strokeWidth: 22,
              semanticsLabel: [
                for (final s in WatchStatus.values) '${s.label} ${counts[s]}',
              ].join(', '),
              segments: [
                for (final status in WatchStatus.values)
                  ChartSegment(
                    label: status.label,
                    value: counts[status]!.toDouble(),
                    color: _statusColor(context, status),
                  ),
              ],
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatCount(total),
                    style: theme.textTheme.headlineMedium,
                  ),
                  Text(
                    'anime',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final (i, status) in WatchStatus.values.indexed) ...[
            if (i > 0) const Divider(height: 1),
            _LegendRow(
              color: _statusColor(context, status),
              label: status.label,
              count: counts[status]!,
              percent: sum > 0 ? counts[status]! * 100 / sum : 0,
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.percent,
  });

  final Color color;
  final String label;
  final int count;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(formatCount(count), style: theme.textTheme.labelLarge),
          SizedBox(
            width: 48,
            child: Text(
              '${percent.round()}%',
              textAlign: TextAlign.end,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimeInvestedSection extends StatelessWidget {
  const TimeInvestedSection({required this.stats, super.key});

  final AnimeStatistics stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = <WatchStatus, double>{
      WatchStatus.completed: stats.numDaysCompleted ?? 0,
      WatchStatus.watching: stats.numDaysWatching ?? 0,
      WatchStatus.onHold: stats.numDaysOnHold ?? 0,
      WatchStatus.dropped: stats.numDaysDropped ?? 0,
    };
    final sum = days.values.fold<double>(0, (a, b) => a + b);
    if (sum <= 0) return const SizedBox.shrink();
    final hours = ((stats.numDaysWatched ?? sum) * 24).round();
    final rows = days.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final peak = rows.first.value;

    return SectionCard(
      title: 'Time invested',
      trailing: '${formatCount(hours)} hours',
      child: Column(
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.key.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  '${row.value.toStringAsFixed(1)} days',
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Semantics(
              label: '${row.key.label}, ${row.value.toStringAsFixed(1)} days',
              child: Container(
                height: 10,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: FractionallySizedBox(
                  widthFactor: (row.value / peak).clamp(0.02, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _statusColor(context, row.key),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class InsightsSection extends ConsumerWidget {
  const InsightsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(profileInsightsProvider);

    return insights.when(
      skipLoadingOnReload: true,
      loading: () => const SectionCard(
        title: 'Insights',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(),
            SizedBox(height: 12),
            Text('Analyzing your list...'),
          ],
        ),
      ),
      error: (error, _) => SectionCard(
        title: 'Insights',
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text("Couldn't load your list insights")),
            TextButton(
              onPressed: () => _reloadLists(ref),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (data) {
        if (data.totalCount == 0) {
          return const SectionCard(
            title: 'Insights',
            child: Text(
              'Add anime to your lists to see score, genre and activity '
              'charts.',
            ),
          );
        }
        return Column(
          children: [
            _ScoreCard(insights: data),
            if (data.genres.isNotEmpty) ...[
              const SizedBox(height: 12),
              _GenresCard(insights: data),
            ],
            if (data.formats.isNotEmpty) ...[
              const SizedBox(height: 12),
              _FormatsCard(insights: data),
            ],
            if (data.activityTotal > 0) ...[
              const SizedBox(height: 12),
              _ActivityCard(insights: data),
            ],
          ],
        );
      },
    );
  }

  void _reloadLists(WidgetRef ref) {
    for (final status in WatchStatus.values) {
      ref.invalidate(userAnimeListProvider(status));
    }
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.insights});

  final ProfileInsights insights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rated = insights.ratedCount;
    final top = insights.mostGivenScore;

    return SectionCard(
      title: 'Score distribution',
      trailing: '${formatCount(rated)} rated',
      child: rated == 0
          ? Text(
              'Rate anime to see how you score them.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BarChart(
                  color: theme.colorScheme.primary,
                  highlightColor: StatusColors.of(context).star,
                  labelHighlightOnly: true,
                  bars: [
                    for (var i = 0; i < insights.scoreCounts.length; i++)
                      BarDatum(
                        label: '${i + 1}',
                        value: insights.scoreCounts[i],
                        highlight: top == i + 1,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Most given score: $top '
                  '(${insights.scoreCounts[top! - 1]} titles)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
    );
  }
}

class _GenresCard extends StatelessWidget {
  const _GenresCard({required this.insights});

  final ProfileInsights insights;

  @override
  Widget build(BuildContext context) {
    final top = insights.genres.take(_topGenreCount);
    return SectionCard(
      title: 'Top genres',
      trailing: '${insights.genres.length} genres',
      child: HorizontalBars(
        color: Theme.of(context).colorScheme.primary,
        bars: [for (final g in top) BarDatum(label: g.label, value: g.count)],
      ),
    );
  }
}

class _FormatsCard extends StatelessWidget {
  const _FormatsCard({required this.insights});

  final ProfileInsights insights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.brightness == Brightness.dark
        ? AppColors.chartPaletteDark
        : AppColors.chartPalette;
    Color colorAt(int i) => i < palette.length
        ? palette[i]
        : theme.colorScheme.surfaceContainerHighest;

    return SectionCard(
      title: 'Formats',
      trailing: '${insights.formats.length} types',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedBar(
            segments: [
              for (var i = 0; i < insights.formats.length; i++)
                ChartSegment(
                  label: insights.formats[i].label,
                  value: insights.formats[i].count.toDouble(),
                  color: colorAt(i),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (var i = 0; i < insights.formats.length; i++)
                ChartLegendItem(
                  color: colorAt(i),
                  label: insights.formats[i].label,
                  value: formatCount(insights.formats[i].count),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.insights});

  final ProfileInsights insights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final months = insights.activity;
    var busiest = 0;
    for (var i = 1; i < months.length; i++) {
      if (months[i].count > months[busiest].count) busiest = i;
    }

    return SectionCard(
      title: 'Activity',
      trailing: 'Last 12 months',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BarChart(
            height: 130,
            color: theme.colorScheme.secondary,
            highlightColor: StatusColors.of(context).star,
            labelHighlightOnly: true,
            bars: [
              for (var i = 0; i < months.length; i++)
                BarDatum(
                  label: shortMonthName(months[i].month.month),
                  value: months[i].count,
                  highlight: i == busiest,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Titles by last update · busiest: '
            '${shortMonthName(months[busiest].month.month)} '
            '(${months[busiest].count})',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
