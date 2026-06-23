import 'dart:async';

import 'package:animal/features/anime/data/anilist_api.dart';
import 'package:animal/features/anime/presentation/anilist_providers.dart';
import 'package:animal/features/anime/presentation/full_screen_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Profile page for an AniList character.
class CharacterProfilePage extends ConsumerWidget {
  const CharacterProfilePage({required this.characterId, super.key});

  final int characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChar =
        ref.watch(anilistCharacterDetailProvider(characterId));
    final theme = Theme.of(context);

    return asyncChar.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              const Text('Failed to load character'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(
                  anilistCharacterDetailProvider(characterId),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (character) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // App bar with character image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                foregroundColor: Colors.white,
                backgroundColor: theme.colorScheme.surface,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: SelectableText(
                    character.name,
                    style: const TextStyle(
                      fontSize: 16,
                      shadows: [
                        Shadow(blurRadius: 8, color: Colors.black54),
                      ],
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(
                    left: 16,
                    bottom: 16,
                  ),
                  background: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (character.imageUrl != null) {
                        FullScreenImageViewer.show(
                          context,
                          imageUrl: character.imageUrl!,
                          heroTag: 'character',
                        );
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (character.imageUrl != null)
                          CachedNetworkImage(
                            imageUrl: character.imageUrl!,
                            fit: BoxFit.cover,
                          )
                        else
                          Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                theme.colorScheme.surface.withValues(alpha: 0.7),
                                theme.colorScheme.surface,
                              ],
                              stops: const [0.0, 0.4, 0.75, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Native name
                      if (character.nativeName != null)
                        SelectableText(
                          character.nativeName!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Info chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (character.gender != null)
                            _InfoChip(
                              icon: Icons.person_outline,
                              label: character.gender!,
                            ),
                          if (character.age != null)
                            _InfoChip(
                              icon: Icons.cake_outlined,
                              label: 'Age: ${character.age}',
                            ),
                          if (character.birthMonth != null)
                            _InfoChip(
                              icon: Icons.calendar_today,
                              label: _formatBirthday(character),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description
                      if (character.description != null &&
                          character.description!.isNotEmpty) ...[
                        Text('About',
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        SelectableText(
                          _cleanDescription(character.description!),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Media appearances
                      if (character.mediaAppearances.isNotEmpty) ...[
                        Text('Appears In',
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        ...character.mediaAppearances.map(
                          (media) => _MediaAppearanceTile(
                            media: media,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatBirthday(AniListCharacterDetail char) {
    final parts = <String>[];
    if (char.birthMonth != null) parts.add('${char.birthMonth}');
    if (char.birthDay != null) parts.add('${char.birthDay}');
    if (char.birthYear != null) parts.add('${char.birthYear}');
    return parts.join('/');
  }

  String _cleanDescription(String desc) {
    // Remove AniList markdown tags like [b], [i], [spoiler], etc.
    return desc
        .replaceAll(RegExp(r'\[/?[a-zA-Z]+\]'), '')
        .replaceAll(RegExp('~!.*?!~'), '[Spoiler]')
        .replaceAll('&#039;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n');
  }
}

/// Profile page for an AniList staff member.
class StaffProfilePage extends ConsumerWidget {
  const StaffProfilePage({required this.staffId, super.key});

  final int staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStaff = ref.watch(anilistStaffDetailProvider(staffId));
    final theme = Theme.of(context);

    return asyncStaff.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              const Text('Failed to load staff info'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(
                  anilistStaffDetailProvider(staffId),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (staff) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                foregroundColor: Colors.white,
                backgroundColor: theme.colorScheme.surface,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: SelectableText(
                    staff.name,
                    style: const TextStyle(
                      fontSize: 16,
                      shadows: [
                        Shadow(blurRadius: 8, color: Colors.black54),
                      ],
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(
                    left: 16,
                    bottom: 16,
                  ),
                  background: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (staff.imageUrl != null) {
                        FullScreenImageViewer.show(
                          context,
                          imageUrl: staff.imageUrl!,
                          heroTag: 'staff',
                        );
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (staff.imageUrl != null)
                          CachedNetworkImage(
                            imageUrl: staff.imageUrl!,
                            fit: BoxFit.cover,
                          )
                        else
                          Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                theme.colorScheme.surface.withValues(alpha: 0.7),
                                theme.colorScheme.surface,
                              ],
                              stops: const [0.0, 0.4, 0.75, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Native name
                      if (staff.nativeName != null)
                        SelectableText(
                          staff.nativeName!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Info chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (staff.occupations != null &&
                              staff.occupations!.isNotEmpty)
                            for (final occ in staff.occupations!)
                              _InfoChip(
                                icon: Icons.work_outline,
                                label: occ,
                              ),
                          if (staff.gender != null)
                            _InfoChip(
                              icon: Icons.person_outline,
                              label: staff.gender!,
                            ),
                          if (staff.age != null)
                            _InfoChip(
                              icon: Icons.cake_outlined,
                              label: 'Age: ${staff.age}',
                            ),
                          if (staff.homeTown != null)
                            _InfoChip(
                              icon: Icons.location_on_outlined,
                              label: staff.homeTown!,
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description
                      if (staff.description != null &&
                          staff.description!.isNotEmpty) ...[
                        Text('About',
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        SelectableText(
                          _cleanDescription(staff.description!),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Media works
                      if (staff.mediaWorks.isNotEmpty) ...[
                        Text('Works',
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        ...staff.mediaWorks.map(
                          (media) => _MediaAppearanceTile(
                            media: media,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _cleanDescription(String desc) {
    return desc
        .replaceAll(RegExp(r'\[/?[a-zA-Z]+\]'), '')
        .replaceAll(RegExp('~!.*?!~'), '[Spoiler]')
        .replaceAll('&#039;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n');
  }
}

/// Info chip widget.
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, this.icon});

  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16),
            const SizedBox(width: 4),
          ],
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

/// Media appearance tile (anime/manga).
class _MediaAppearanceTile extends StatelessWidget {
  const _MediaAppearanceTile({required this.media});

  final AniListMediaAppearance media;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeLabel = _formatMediaType(media.type);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 40,
            height: 56,
            child: media.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: media.imageUrl!,
                    fit: BoxFit.cover,
                  )
                : ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.movie,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        title: Text(
          media.titleEnglish ?? media.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
        subtitle: Row(
          children: [
            if (typeLabel != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              if (media.role != null) const SizedBox(width: 6),
            ],
            if (media.role != null)
              Expanded(
                child: Text(
                  media.role!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        dense: true,
        visualDensity: VisualDensity.compact,
        onTap: () {
          if (media.malId != null) {
            unawaited(context.pushNamed(
              'animeDetail',
              pathParameters: {'id': '${media.malId}'},
            ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'No MAL link available for "${media.titleEnglish ?? media.title}"',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  String? _formatMediaType(String? type) {
    return switch (type) {
      'ANIME' => 'Anime',
      'MANGA' => 'Manga',
      'NOVEL' => 'Novel',
      'ONE_SHOT' => 'One Shot',
      _ => null,
    };
  }
}
