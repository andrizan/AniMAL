import 'package:animal/features/anime/domain/anime.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A card widget displaying an anime's cover image, title, and
/// optional progress / score info. Used in grid layouts.
class AnimeCard extends StatelessWidget {
  const AnimeCard({
    required this.anime, super.key,
    this.onTap,
    this.onDismissed,
  });

  final Anime anime;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget card = Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: anime.mainPicture?.medium != null
                  ? CachedNetworkImage(
                      imageUrl:
                          anime.mainPicture!.large ?? anime.mainPicture!.medium!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      errorWidget: (_, _, _) => Icon(
                        Icons.broken_image,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.movie,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (anime.myListStatus != null)
                    Text(
                      '${anime.myListStatus!.numEpisodesWatched ?? 0}'
                      ' / ${anime.numEpisodes ?? '?'} eps',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else if (anime.mean != null)
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          anime.mean!.toStringAsFixed(2),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (onDismissed != null) {
      card = Dismissible(
        key: ValueKey(anime.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          onDismissed!();
          return true;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: theme.colorScheme.error,
          child: Icon(Icons.delete, color: theme.colorScheme.onError),
        ),
        child: card,
      );
    }

    return card;
  }
}
