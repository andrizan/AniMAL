import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/core/utils/anime_labels.dart';
import 'package:animal/core/utils/date_utils.dart';
import 'package:animal/core/utils/format_utils.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/broadcast.dart';
import 'package:animal/shared/widgets/app_cached_image.dart';
import 'package:animal/shared/widgets/section_card.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

const _longSynopsis = 280;

String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

String broadcastLabel(Broadcast broadcast) {
  final day = broadcast.dayOfWeek!;
  final time = broadcast.startTime;
  if (time == null) return _capitalize(day);
  final local = convertJstBroadcastToLocal(day, time);
  if (local == null) return '${_capitalize(day)} at $time JST';
  return '${_capitalize(local.day)} at ${local.time}';
}

class AboutCard extends StatefulWidget {
  const AboutCard({required this.detail, super.key});

  final AnimeDetail detail;

  static bool hasContent(AnimeDetail detail) =>
      (detail.synopsis?.isNotEmpty ?? false) || detail.genres.isNotEmpty;

  @override
  State<AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<AboutCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = widget.detail;
    final synopsis = detail.synopsis ?? '';
    final collapsible = synopsis.length > _longSynopsis;

    return SectionCard(
      title: synopsis.isNotEmpty ? 'Synopsis' : 'Genres',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (synopsis.isNotEmpty) ...[
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: SelectableText(
                synopsis,
                maxLines: collapsible && !_expanded ? 5 : null,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
            if (collapsible)
              TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 40),
                  alignment: Alignment.centerLeft,
                ),
                child: Text(_expanded ? 'Show less' : 'Read more'),
              ),
          ],
          if (synopsis.isNotEmpty && detail.genres.isNotEmpty)
            const SizedBox(height: AppSpacing.md),
          if (detail.genres.isNotEmpty)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final genre in detail.genres)
                  Chip(
                    label: Text(genre.name),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({required this.detail, required this.studios, super.key});

  final AnimeDetail detail;
  final List<AniListStudio> studios;

  List<({IconData icon, String label, Widget value})> _facts(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    Widget text(String value) => Text(value, style: theme.textTheme.bodyMedium);

    final start = detail.startDate;
    final end = detail.endDate;
    final season = detail.startSeason;
    final duration = detail.averageEpisodeDuration;
    final source = detail.source;

    return [
      if (start != null)
        (
          icon: Icons.calendar_today,
          label: end != null ? 'Aired' : 'Airing',
          value: text(
            end != null
                ? '${formatDate(start)} to ${formatDate(end)}'
                : formatDate(start),
          ),
        )
      else if (end != null)
        (
          icon: Icons.calendar_today,
          label: 'Ended',
          value: text(formatDate(end)),
        ),
      if (season != null)
        (
          icon: Icons.calendar_month,
          label: 'Season',
          value: text(
            '${AnimeLabels.seasonLabel(season.season)} ${season.year}',
          ),
        ),
      if (detail.broadcast?.dayOfWeek != null)
        (
          icon: Icons.access_time,
          label: 'Broadcast',
          value: text(broadcastLabel(detail.broadcast!)),
        ),
      if (duration != null && duration > 0)
        (
          icon: Icons.timer_outlined,
          label: 'Duration',
          value: text(AnimeLabels.durationLabel(duration)),
        ),
      if (source != null && source.isNotEmpty)
        (
          icon: Icons.book_outlined,
          label: 'Source',
          value: text(AnimeLabels.sourceLabel(source)),
        ),
      if (studios.isNotEmpty)
        (
          icon: Icons.business,
          label: 'Studios',
          value: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [for (final studio in studios) _StudioLink(studio)],
          ),
        ),
    ];
  }

  static bool hasContent(AnimeDetail detail, List<AniListStudio> studios) =>
      detail.startDate != null ||
      detail.endDate != null ||
      detail.startSeason != null ||
      detail.broadcast?.dayOfWeek != null ||
      (detail.averageEpisodeDuration ?? 0) > 0 ||
      (detail.source?.isNotEmpty ?? false) ||
      studios.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final facts = _facts(context);

    return SectionCard(
      title: 'Information',
      child: Column(
        children: [
          for (final (i, fact) in facts.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  fact.icon,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                SizedBox(
                  width: 84,
                  child: Text(
                    fact.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(child: fact.value),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StudioLink extends StatelessWidget {
  const _StudioLink(this.studio);

  final AniListStudio studio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => context.pushNamed(
        'studioProfile',
        pathParameters: {'id': '${studio.id}'},
      ),
      child: Text(
        studio.name,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class NextEpisodeCard extends StatelessWidget {
  const NextEpisodeCard({required this.next, super.key});

  final AniListNextAiring next;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final urgent = next.isUrgent;
    final background = urgent
        ? scheme.errorContainer
        : scheme.primaryContainer.withValues(alpha: 0.5);
    final foreground = urgent
        ? scheme.onErrorContainer
        : scheme.onPrimaryContainer;
    final local = next.airingAt.toLocal();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    final date = '${local.day}/${local.month} at $time';

    return SectionCard(
      color: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next Episode',
            style: theme.textTheme.titleSmall?.copyWith(color: foreground),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.upcoming, size: 20, color: foreground),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Episode ${next.episode}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$date · ${next.countdown}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RelatedCard extends StatelessWidget {
  const RelatedCard({required this.related, super.key});

  final List<RelatedAnime> related;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      title: 'Related Anime',
      trailing: '${related.length}',
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          for (final (i, item) in related.indexed) ...[
            if (i > 0) const Divider(height: 1),
            InkWell(
              onTap: () => context.pushNamed(
                'animeDetail',
                pathParameters: {'id': '${item.node.id}'},
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    AppCachedImage(
                      imageUrl: item.node.mainPicture?.medium ?? '',
                      width: 40,
                      height: 56,
                      borderRadius: BorderRadius.circular(AppRadius.sm / 2),
                      fallbackSize: 16,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.node.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                          if ((item.relationTypeFormatted ?? '').isNotEmpty)
                            Text(
                              item.relationTypeFormatted!,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AltTitlesCard extends StatelessWidget {
  const AltTitlesCard({required this.titles, super.key});

  final AlternativeTitles titles;

  static bool hasContent(AlternativeTitles? titles) =>
      titles != null &&
      ((titles.en?.isNotEmpty ?? false) ||
          titles.synonyms.any((s) => s.isNotEmpty));

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, String title})>[
      if (titles.en != null && titles.en!.isNotEmpty)
        (label: 'English', title: titles.en!),
      for (final synonym in titles.synonyms)
        if (synonym.isNotEmpty) (label: 'Synonym', title: synonym),
    ];
    final theme = Theme.of(context);

    return SectionCard(
      title: 'Alternative Titles',
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      row.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      row.title,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class LinksCard extends StatelessWidget {
  const LinksCard({required this.links, super.key});

  final List<AniListExternalLink> links;

  static const _groups = ['INFO', 'STREAMING', 'SOCIAL'];

  static bool hasContent(List<AniListExternalLink> links) =>
      links.any((l) => _groups.contains(l.type));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = {
      'INFO': (
        icon: Icons.language,
        color: scheme.primaryContainer,
        text: scheme.onPrimaryContainer,
      ),
      'STREAMING': (
        icon: Icons.play_circle_outline,
        color: scheme.tertiaryContainer,
        text: scheme.onTertiaryContainer,
      ),
      'SOCIAL': (
        icon: Icons.public,
        color: scheme.secondaryContainer,
        text: scheme.onSecondaryContainer,
      ),
    };

    return SectionCard(
      title: 'External Links',
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final group in _groups)
            for (final link in links.where((l) => l.type == group))
              _LinkChip(
                label: link.displaySite,
                url: link.url,
                icon: style[group]!.icon,
                color: style[group]!.color,
                textColor: style[group]!.text,
              ),
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({
    required this.label,
    required this.url,
    required this.icon,
    required this.color,
    required this.textColor,
  });

  final String label;
  final String url;
  final IconData icon;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async => launchUrl(Uri.parse(url)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
