import 'package:animal/core/utils/anime_labels.dart';
import 'package:animal/core/utils/format_utils.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/shared/widgets/hero_panel.dart';
import 'package:animal/shared/widgets/info_chip.dart';
import 'package:animal/shared/widgets/stat_highlight.dart';
import 'package:material_ui/material_ui.dart';

class DetailHeader extends StatelessWidget {
  const DetailHeader({required this.detail, super.key});

  final AnimeDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final native = detail.alternativeTitles?.ja;

    final chips = <Widget>[
      if (detail.mediaType != null)
        InfoChip(label: AnimeLabels.mediaTypeLabel(detail.mediaType)),
      if (detail.numEpisodes != null && detail.numEpisodes != 0)
        InfoChip(
          icon: Icons.movie_outlined,
          label: '${detail.numEpisodes} eps',
        ),
      if (detail.status != null)
        InfoChip(
          label: AnimeLabels.statusLabel(detail.status),
          color: AnimeLabels.statusColor(detail.status),
        ),
      if (detail.rating != null)
        InfoChip(
          label: AnimeLabels.ratingLabel(detail.rating),
          color: scheme.error,
        ),
    ];

    final highlights = <Widget>[
      if (detail.mean != null)
        StatHighlight(
          icon: Icons.star_rounded,
          value: detail.mean!.toStringAsFixed(2),
          label: detail.numScoringUsers != null
              ? '${formatCount(detail.numScoringUsers!)} ratings'
              : 'Score',
        ),
      if (detail.rank != null)
        StatHighlight(value: '#${detail.rank}', label: 'Rank'),
      if (detail.popularity != null)
        StatHighlight(value: '#${detail.popularity}', label: 'Popularity'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (native != null && native.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: SelectableText(
              native,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        if (chips.isNotEmpty || highlights.isNotEmpty)
          HeroPanel(
            child: Column(
              children: [
                if (chips.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(spacing: 8, runSpacing: 8, children: chips),
                  ),
                if (chips.isNotEmpty && highlights.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(height: 1, color: scheme.outlineVariant),
                  const SizedBox(height: 16),
                ],
                if (highlights.isNotEmpty)
                  Row(
                    children: [
                      for (final highlight in highlights)
                        Expanded(child: highlight),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
