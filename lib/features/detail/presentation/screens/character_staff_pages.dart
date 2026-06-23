import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/utils/anime_labels.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:animal/shared/widgets/full_screen_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Profile page for an AniList character.
class CharacterProfilePage extends ConsumerWidget {
  const CharacterProfilePage({required this.characterId, super.key});

  final int characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChar = ref.watch(anilistCharacterDetailProvider(characterId));
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
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
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
                foregroundColor: AppColors.iconLight,
                backgroundColor: theme.colorScheme.surface,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.overlayDarker,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.iconLight,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: SelectableText(
                    character.name,
                    style: const TextStyle(
                      fontSize: 16,
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
                            errorWidget: (_, __, ___) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
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
                                AppColors.transparent,
                                AppColors.transparent,
                                theme.colorScheme.surface.withValues(
                                  alpha: 0.7,
                                ),
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
                        Text('About', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        SelectableText(
                          cleanAniListDescription(character.description!),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Media appearances
                      if (character.mediaAppearances.isNotEmpty) ...[
                        Text('Appears In', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        _WorksList(
                          malIds: character.mediaAppearances
                              .where((m) => m.malId != null && m.type == 'ANIME')
                              .map((m) => m.malId!)
                              .toList(),
                          otherMedia: character.mediaAppearances
                              .where((m) => m.malId == null || m.type != 'ANIME')
                              .toList(),
                        ),
                        const SizedBox(height: 12),
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
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
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
                foregroundColor: AppColors.iconLight,
                backgroundColor: theme.colorScheme.surface,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.overlayDarker,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.iconLight,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: SelectableText(
                    staff.name,
                    style: const TextStyle(
                      fontSize: 16,
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
                            errorWidget: (_, __, ___) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
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
                                AppColors.transparent,
                                AppColors.transparent,
                                theme.colorScheme.surface.withValues(
                                  alpha: 0.7,
                                ),
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
                        Text('About', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        SelectableText(
                          cleanAniListDescription(staff.description!),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Media works
                      if (staff.mediaWorks.isNotEmpty) ...[
                        Text('Works', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        _WorksList(
                          malIds: staff.mediaWorks
                              .where((m) => m.malId != null && m.type == 'ANIME')
                              .map((m) => m.malId!)
                              .toList(),
                          otherMedia: staff.mediaWorks
                              .where((m) => m.malId == null || m.type != 'ANIME')
                              .toList(),
                        ),
                        const SizedBox(height: 12),
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

class _WorksList extends ConsumerWidget {
  const _WorksList({required this.malIds, required this.otherMedia});

  final List<int> malIds;
  final List<AniListMediaAppearance> otherMedia;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAnime = malIds.isNotEmpty
        ? ref.watch(animeListProvider(malIds.join(',')))
        : null;

    return Column(
      children: [
        if (asyncAnime != null)
          asyncAnime.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (animeList) => Column(
              children: animeList
                  .map((anime) => AnimeCard(anime: anime))
                  .toList(),
            ),
          ),
        for (final media in otherMedia)
          AnimeCard(
            anime: Anime(
              id: media.malId ?? media.anilistId,
              title: media.titleEnglish ?? media.title,
              mainPicture: media.imageUrl != null
                  ? MainPicture(medium: media.imageUrl)
                  : null,
              mediaType: media.type?.toLowerCase(),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This app does not support this media type'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
      ],
    );
  }
}
