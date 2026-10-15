import 'dart:async';

import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/core/utils/anilist_mappings.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/shared/providers/anilist_works_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:animal/shared/widgets/section_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// How many items before the end of the list the next page is requested.
const _prefetchDistance = 3;

String _unsupportedNote(AniListMediaAppearance media) {
  final type = media.type;
  if (type == null || type == 'ANIME') return 'Not available on MyAnimeList';
  final label = '${type[0]}${type.substring(1).toLowerCase()}';
  return '$label is not supported in this app';
}

/// The works of a character, staff member or studio as a sliver: a header
/// and a lazy list that loads the next page as the user nears the end.
///
/// Each card is drawn from what AniList already said about the work, with
/// the MAL row stored for it on top when there is one, so no card ever asks
/// MyAnimeList over the network: that happens when the card is opened.
class WorksSliver extends ConsumerWidget {
  const WorksSliver({
    required this.title,
    required this.source,
    required this.id,
    super.key,
    this.onlyWithMalId = false,
  });

  final String title;
  final AniListWorksSource source;
  final int id;

  /// Leaves out works MyAnimeList does not know, for lists that only make
  /// sense as anime (a studio's productions).
  final bool onlyWithMalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (source: source, id: id);
    final state = ref.watch(worksPagerProvider(key));
    final notifier = ref.read(worksPagerProvider(key).notifier);
    final items = onlyWithMalId
        ? [
            for (final m in state.items)
              if (m.malId != null) m,
          ]
        : state.items;
    final hasFooter = state.hasMore || state.loadingMore || state.error != null;
    if (items.isEmpty && !hasFooter) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    void loadSoon(BuildContext context) {
      if (!state.canAutoLoad) return;
      scheduleMicrotask(() {
        if (context.mounted) unawaited(notifier.loadMore());
      });
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page + AppSpacing.xs,
              AppSpacing.xl,
              AppSpacing.page + AppSpacing.xs,
              2,
            ),
            child: SectionHeader(
              title,
              trailing: '${items.length}${state.hasMore ? '+' : ''} titles',
              bottomPadding: 2,
            ),
          ),
        ),
        SliverList.builder(
          itemCount: items.length + (hasFooter ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= items.length) {
              loadSoon(context);
              return _Footer(
                error: state.error,
                onRetry: () => unawaited(notifier.loadMore()),
              );
            }
            if (index >= items.length - _prefetchDistance) loadSoon(context);
            return _WorkTile(media: items[index]);
          },
        ),
      ],
    );
  }
}

class _WorkTile extends ConsumerWidget {
  const _WorkTile({required this.media});

  final AniListMediaAppearance media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final malId = media.malId;
    if (malId == null || media.type != 'ANIME') {
      return AnimeCard(
        anime: Anime(
          id: malId ?? media.anilistId,
          title: media.titleEnglish ?? media.title,
          mainPicture: media.imageUrl != null
              ? MainPicture(medium: media.imageUrl)
              : null,
          mediaType: media.type?.toLowerCase(),
        ),
        note: _unsupportedNote(media),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This app does not support this media type'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      );
    }

    // What AniList said is enough for the card. The MAL row stored for the
    // anime, when there is one, wins over it: its score, its list status.
    final fromAniList = Anime(
      id: malId,
      title: media.titleEnglish ?? media.title,
      mainPicture: media.imageUrl != null
          ? MainPicture(medium: media.imageUrl)
          : null,
      alternativeTitles: media.titleNative == null
          ? null
          : AlternativeTitles(ja: media.titleNative),
      mean: scoreOutOfTen(media.meanScore),
      numEpisodes: media.episodes,
      status: malStatusOf(media.status),
      mediaType: malMediaTypeOf(media.format),
    );
    final stored = ref.watch(cachedAnimeProvider(malId)).value;
    return AnimeCard(anime: stored ?? fromAniList);
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.page,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                "Couldn't load more titles",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            semanticsLabel: 'Loading more titles',
          ),
        ),
      ),
    );
  }
}
