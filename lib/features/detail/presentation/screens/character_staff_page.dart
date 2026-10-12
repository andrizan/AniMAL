import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/core/utils/anime_labels.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:animal/shared/widgets/app_cached_image.dart';
import 'package:animal/shared/widgets/error_view.dart';
import 'package:animal/shared/widgets/full_screen_image.dart';
import 'package:animal/shared/widgets/info_chip.dart';
import 'package:animal/shared/widgets/scrim_icon_button.dart';
import 'package:animal/shared/widgets/section_card.dart';
import 'package:animal/shared/widgets/works_sliver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Profile page for an AniList character.
class CharacterProfilePage extends ConsumerWidget {
  const CharacterProfilePage({required this.characterId, super.key});

  final int characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChar = ref.watch(anilistCharacterDetailProvider(characterId));

    return asyncChar.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: 'Failed to load character',
          onRetry: () =>
              ref.invalidate(anilistCharacterDetailProvider(characterId)),
        ),
      ),
      data: (character) => _PersonScaffold(
        name: character.name,
        nativeName: character.nativeName,
        imageUrl: character.imageUrl,
        heroTag: 'character',
        chips: [
          if (character.gender != null)
            InfoChip(icon: Icons.person_outline, label: character.gender!),
          if (character.age != null)
            InfoChip(icon: Icons.cake_outlined, label: 'Age: ${character.age}'),
          if (character.birthMonth != null)
            InfoChip(
              icon: Icons.calendar_today,
              label: _formatBirthday(character),
            ),
        ],
        description: character.description,
        worksTitle: 'Appears In',
        worksSource: AniListWorksSource.character,
        worksId: characterId,
      ),
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
    final scheme = Theme.of(context).colorScheme;

    return asyncStaff.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: 'Failed to load staff info',
          onRetry: () => ref.invalidate(anilistStaffDetailProvider(staffId)),
        ),
      ),
      data: (staff) => _PersonScaffold(
        name: staff.name,
        nativeName: staff.nativeName,
        imageUrl: staff.imageUrl,
        heroTag: 'staff',
        chips: [
          if (staff.occupations != null && staff.occupations!.isNotEmpty)
            for (final occ in staff.occupations!)
              InfoChip(
                icon: Icons.work_outline,
                label: occ,
                color: scheme.onPrimaryContainer,
                background: scheme.primaryContainer,
              ),
          if (staff.gender != null)
            InfoChip(icon: Icons.person_outline, label: staff.gender!),
          if (staff.age != null)
            InfoChip(icon: Icons.cake_outlined, label: 'Age: ${staff.age}'),
          if (staff.homeTown != null)
            InfoChip(icon: Icons.location_on_outlined, label: staff.homeTown!),
        ],
        description: staff.description,
        worksTitle: 'Works',
        worksSource: AniListWorksSource.staff,
        worksId: staffId,
      ),
    );
  }
}

/// Shared page for a character or staff member: portrait hero, names,
/// chips, description and the media they are part of.
class _PersonScaffold extends StatelessWidget {
  const _PersonScaffold({
    required this.name,
    required this.nativeName,
    required this.imageUrl,
    required this.heroTag,
    required this.chips,
    required this.description,
    required this.worksTitle,
    required this.worksSource,
    required this.worksId,
  });

  final String name;
  final String? nativeName;
  final String? imageUrl;
  final String heroTag;
  final List<Widget> chips;
  final String? description;
  final String worksTitle;
  final AniListWorksSource worksSource;
  final int worksId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasDescription = description != null && description!.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            foregroundColor: AppColors.iconLight,
            backgroundColor: scheme.surface,
            leading: ScrimIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: SelectableText(name, style: theme.textTheme.titleMedium),
              titlePadding: const EdgeInsets.only(
                left: AppSpacing.page,
                bottom: AppSpacing.lg,
              ),
              background: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (imageUrl != null) {
                    FullScreenImageViewer.show(
                      context,
                      imageUrl: imageUrl!,
                      heroTag: heroTag,
                    );
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppCachedImage(
                      imageUrl: imageUrl ?? '',
                      fallbackIcon: Icons.person,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.transparent,
                            AppColors.transparent,
                            scheme.surface.withValues(alpha: 0.7),
                            scheme.surface,
                          ],
                          stops: const [0.0, 0.45, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.xs,
                AppSpacing.page,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (nativeName != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.xs,
                        bottom: AppSpacing.md,
                      ),
                      child: SelectableText(
                        nativeName!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (chips.isNotEmpty)
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: chips,
                    ),
                  if (hasDescription) ...[
                    const SizedBox(height: AppSpacing.lg),
                    SectionCard(
                      title: 'About',
                      child: SelectableText(
                        cleanAniListDescription(description!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          WorksSliver(title: worksTitle, source: worksSource, id: worksId),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }
}
