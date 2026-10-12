import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/core/utils/format_utils.dart';
import 'package:animal/data/models/mal_user.dart';
import 'package:animal/shared/widgets/hero_panel.dart';
import 'package:animal/shared/widgets/stat_highlight.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.user, required this.onRefresh, super.key});

  final MalUser user;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stats = user.animeStatistics;
    final joined = formatMonthYear(user.joinedAt);
    final caption = [
      if (joined != null) 'Member since $joined',
      ?user.location,
    ].join(' · ');

    return HeroPanel(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: scheme.primaryContainer,
                backgroundImage: user.picture != null
                    ? CachedNetworkImageProvider(user.picture!)
                    : null,
                child: user.picture == null
                    ? Icon(
                        Icons.person,
                        size: 36,
                        color: scheme.onPrimaryContainer,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (caption.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: onRefresh,
              ),
            ],
          ),
          if (stats != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Divider(
              height: 1,
              color: scheme.onPrimaryContainer.withValues(alpha: 0.18),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: StatHighlight(
                    value: stats.numDaysWatched?.toStringAsFixed(1) ?? '0',
                    label: 'Days watched',
                  ),
                ),
                Expanded(
                  child: StatHighlight(
                    value: formatCount(stats.numEpisodes ?? 0),
                    label: 'Episodes',
                  ),
                ),
                Expanded(
                  child: StatHighlight(
                    value: stats.meanScore?.toStringAsFixed(2) ?? '-',
                    label: 'Mean score',
                    icon: Icons.star_rounded,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class ProfileHeaderPlaceholder extends StatelessWidget {
  const ProfileHeaderPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final block = scheme.surfaceContainerHigh;

    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: block,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );

    return Semantics(
      label: 'Loading profile',
      child: HeroPanel(
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(radius: 36, backgroundColor: block),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(140, 18),
                      const SizedBox(height: AppSpacing.md),
                      bar(200, 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Divider(
              height: 1,
              color: scheme.onPrimaryContainer.withValues(alpha: 0.18),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [bar(60, 22), bar(60, 22), bar(60, 22)],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileHeaderError extends StatelessWidget {
  const ProfileHeaderError({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.hero),
        color: scheme.errorContainer,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: scheme.error,
            child: Icon(Icons.error, color: scheme.onError),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Failed to load profile',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Check your connection',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Retry',
            color: scheme.onErrorContainer,
            icon: const Icon(Icons.refresh),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
