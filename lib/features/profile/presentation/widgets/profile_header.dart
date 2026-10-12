import 'package:animal/core/theme/app_colors.dart';
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
                child: Text(
                  user.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: onRefresh,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _InfoPill(
                  dotColor: StatusColors.of(context).listWatching,
                  text: 'Connected to MyAnimeList',
                ),
                if (joined != null)
                  _InfoPill(
                    icon: Icons.calendar_month_outlined,
                    text: 'Since $joined',
                  ),
                if (user.location != null)
                  _InfoPill(
                    icon: Icons.location_on_outlined,
                    text: user.location!,
                  ),
              ],
            ),
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.text, this.icon, this.dotColor});

  final String text;
  final IconData? icon;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          if (icon != null) Icon(icon, size: 14, color: muted),
          if (dotColor != null || icon != null) const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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
