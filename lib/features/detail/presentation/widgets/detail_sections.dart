import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/core/utils/anime_labels.dart';
import 'package:animal/core/utils/date_utils.dart';
import 'package:animal/core/utils/format_utils.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/broadcast.dart';
import 'package:animal/shared/providers/anime_notification_providers.dart';
import 'package:animal/shared/widgets/app_cached_image.dart';
import 'package:animal/shared/widgets/info_chip.dart';
import 'package:animal/shared/widgets/section_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

const _longSynopsis = 280;

String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

/// "Fridays, 23:30 your time", or the JST text when it cannot be converted.
///
/// The slot comes from [resolveAirSlot], the function the cards use too, so
/// the page agrees with every card: [nextAiringAt] (AniList) wins over the
/// MAL [broadcast].
String broadcastLabel(Broadcast? broadcast, {DateTime? nextAiringAt}) {
  final slot = resolveAirSlot(
    nextAiringAt: nextAiringAt,
    jstDay: broadcast?.dayOfWeek,
    jstTime: broadcast?.startTime,
  );
  if (slot != null) return weeklyAirSlotLabel(slot);

  final day = broadcast?.dayOfWeek;
  if (day == null) return '';
  final time = broadcast?.startTime;
  if (time == null) return '${_capitalize(day)}s';
  return '${_capitalize(day)}s, $time JST';
}

String _durationLabel(int seconds) {
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '$minutes min per episode';
  return '${AnimeLabels.durationLabel(seconds)} per episode';
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
          if (detail.genres.isNotEmpty)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final genre in detail.genres) InfoChip(label: genre.name),
              ],
            ),
          if (synopsis.isNotEmpty && detail.genres.isNotEmpty)
            const SizedBox(height: AppSpacing.md),
          if (synopsis.isNotEmpty) ...[
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: SelectableText(
                synopsis,
                maxLines: collapsible && !_expanded ? 5 : null,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ),
            if (collapsible)
              TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  alignment: Alignment.centerLeft,
                ),
                child: Text(_expanded ? 'Show less' : 'Read more'),
              ),
          ],
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.detail,
    required this.studios,
    super.key,
    this.nextAiringAt,
  });

  final AnimeDetail detail;
  final List<AniListStudio> studios;

  /// The next AniList airing, when known; it decides the broadcast row.
  final DateTime? nextAiringAt;

  List<({String label, Widget value})> _facts(BuildContext context) {
    final theme = Theme.of(context);
    Widget text(String value) => Text(
      value,
      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
    );

    final start = detail.startDate;
    final end = detail.endDate;
    final season = detail.startSeason;
    final duration = detail.averageEpisodeDuration;
    final source = detail.source;

    return [
      if (start != null)
        (
          label: end != null ? 'Aired' : 'Airing',
          value: text(
            end != null
                ? '${formatDate(start)} to ${formatDate(end)}'
                : formatDate(start),
          ),
        )
      else if (end != null)
        (label: 'Ended', value: text(formatDate(end))),
      if (season != null)
        (
          label: 'Season',
          value: text(
            '${AnimeLabels.seasonLabel(season.season)} ${season.year}',
          ),
        ),
      if (detail.broadcast?.dayOfWeek != null || nextAiringAt != null)
        (
          label: 'Broadcast',
          value: text(
            broadcastLabel(detail.broadcast, nextAiringAt: nextAiringAt),
          ),
        ),
      if (duration != null && duration > 0)
        (label: 'Duration', value: text(_durationLabel(duration))),
      if (source != null && source.isNotEmpty)
        (label: 'Source', value: text(AnimeLabels.sourceLabel(source))),
      if (studios.isNotEmpty)
        (
          label: 'Studios',
          value: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [for (final studio in studios) _StudioLink(studio)],
          ),
        ),
    ];
  }

  static bool hasContent(
    AnimeDetail detail,
    List<AniListStudio> studios, {
    DateTime? nextAiringAt,
  }) =>
      detail.startDate != null ||
      detail.endDate != null ||
      detail.startSeason != null ||
      detail.broadcast?.dayOfWeek != null ||
      nextAiringAt != null ||
      (detail.averageEpisodeDuration ?? 0) > 0 ||
      (detail.source?.isNotEmpty ?? false) ||
      studios.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final facts = _facts(context);

    return SectionCard(
      title: 'Information',
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Column(
        children: [
          for (final (i, fact) in facts.indexed) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      fact.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: fact.value),
                ],
              ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              studio.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: theme.colorScheme.primary,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class NextEpisodeCard extends ConsumerWidget {
  const NextEpisodeCard({
    required this.next,
    required this.animeId,
    required this.title,
    super.key,
  });

  final AniListNextAiring next;
  final int animeId;
  final String title;

  Future<void> _toggleReminder(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(animeNotificationProvider.notifier)
        .toggle(
          animeId: animeId,
          title: title,
          episode: next.episode,
          airingAt: next.airingAt,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message(next.episode)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = StatusColors.of(context);
    final urgent = next.isUrgent;
    final date = nextAirSlotLabel(resolveAirSlot(nextAiringAt: next.airingAt)!);
    final reminderOn = ref.watch(
      animeNotificationProvider.select((s) => s.contains(animeId)),
    );

    return SectionCard(
      title: 'Next Episode',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Episode ${next.episode}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              InfoChip(
                icon: urgent
                    ? Icons.warning_amber_rounded
                    : Icons.schedule_rounded,
                label: 'in ${next.countdown}',
                color: urgent
                    ? colors.onDroppedContainer
                    : scheme.onPrimaryContainer,
                background: urgent
                    ? colors.droppedContainer
                    : scheme.primaryContainer,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            value: reminderOn,
            onChanged: (_) => _toggleReminder(context, ref),
            tileColor: scheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card - 4),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            secondary: Icon(
              reminderOn
                  ? Icons.notifications_active
                  : Icons.notifications_none,
              color: reminderOn ? colors.star : scheme.onSurfaceVariant,
            ),
            title: Text(
              reminderOn
                  ? 'Reminder on for episode ${next.episode}'
                  : 'Remind me before it airs',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
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
                      width: 44,
                      height: 60,
                      borderRadius: BorderRadius.circular(AppRadius.md),
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
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
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
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      row.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: SelectableText(
                      row.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
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
        color: scheme.surfaceContainer,
        text: scheme.onSurface,
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
    return Semantics(
      link: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: () async => launchUrl(Uri.parse(url)),
        child: InfoChip(
          label: label,
          icon: icon,
          color: textColor,
          background: color,
        ),
      ),
    );
  }
}
