import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/utils/format_utils.dart';
import 'package:animal/data/models/mal_user.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

BoxDecoration _heroDecoration(ColorScheme scheme) => BoxDecoration(
  borderRadius: BorderRadius.circular(24),
  border: Border.all(color: scheme.outlineVariant),
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [scheme.primaryContainer, scheme.surfaceContainer],
  ),
);

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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _heroDecoration(scheme),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.primary, width: 2),
                ),
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: scheme.primaryContainer,
                  backgroundImage: user.picture != null
                      ? CachedNetworkImageProvider(user.picture!)
                      : null,
                  child: user.picture == null
                      ? Icon(
                          Icons.person,
                          size: 34,
                          color: scheme.onPrimaryContainer,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  user.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
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
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                const _InfoPill(
                  dotColor: AppColors.statusAiring,
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
            const SizedBox(height: 18),
            Divider(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Highlight(
                    value: stats.numDaysWatched?.toStringAsFixed(1) ?? '0',
                    label: 'Days watched',
                  ),
                ),
                Expanded(
                  child: _Highlight(
                    value: formatCount(stats.numEpisodes ?? 0),
                    label: 'Episodes',
                  ),
                ),
                Expanded(
                  child: _Highlight(
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null)
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          if (icon != null) Icon(icon, size: 13, color: muted),
          if (dotColor != null || icon != null) const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({required this.value, required this.label, this.icon});

  final String value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppColors.starColor),
              const SizedBox(width: 3),
            ],
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
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
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _heroDecoration(scheme),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(radius: 37, backgroundColor: block),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(140, 18),
                      const SizedBox(height: 12),
                      bar(200, 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.errorContainer.withValues(alpha: 0.35),
        border: Border.all(color: scheme.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: scheme.error,
            child: const Icon(Icons.error, color: AppColors.iconLight),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Failed to load profile',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check your connection',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Retry',
            icon: const Icon(Icons.refresh),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
