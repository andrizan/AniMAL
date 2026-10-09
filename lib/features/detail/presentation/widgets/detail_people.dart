import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/data/models/anilist/anilist_models.dart';
import 'package:animal/shared/widgets/app_cached_image.dart';
import 'package:animal/shared/widgets/section_card.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const _defaultLimit = 4;

class CharactersCard extends StatefulWidget {
  const CharactersCard({required this.characters, super.key});

  final List<AniListCharacter> characters;

  @override
  State<CharactersCard> createState() => _CharactersCardState();
}

class _CharactersCardState extends State<CharactersCard> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final characters = widget.characters;
    final shown = _showAll ? characters : characters.take(_defaultLimit);

    return _PeopleCard(
      title: 'Characters & Voice Actors',
      total: characters.length,
      showAll: _showAll,
      onToggle: () => setState(() => _showAll = !_showAll),
      rows: [for (final c in shown) _CharacterRow(character: c)],
    );
  }
}

class StaffCard extends StatefulWidget {
  const StaffCard({required this.staff, super.key});

  final List<AniListStaff> staff;

  @override
  State<StaffCard> createState() => _StaffCardState();
}

class _StaffCardState extends State<StaffCard> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final staff = widget.staff;
    final shown = _showAll ? staff : staff.take(_defaultLimit);

    return _PeopleCard(
      title: 'Staff',
      total: staff.length,
      showAll: _showAll,
      onToggle: () => setState(() => _showAll = !_showAll),
      rows: [for (final s in shown) _StaffRow(staff: s)],
    );
  }
}

class _PeopleCard extends StatelessWidget {
  const _PeopleCard({
    required this.title,
    required this.total,
    required this.showAll,
    required this.onToggle,
    required this.rows,
  });

  final String title;
  final int total;
  final bool showAll;
  final VoidCallback onToggle;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      trailing: '$total',
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Column(
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const Divider(height: 1),
            row,
          ],
          if (total > _defaultLimit)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onToggle,
                child: Text(showAll ? 'Show Less' : 'See All ($total)'),
              ),
            )
          else
            const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

String _roleLabel(String role) =>
    role.isEmpty ? role : role[0] + role.substring(1).toLowerCase();

class _CharacterRow extends StatelessWidget {
  const _CharacterRow({required this.character});

  final AniListCharacter character;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final va = character.voiceActors.isNotEmpty
        ? character.voiceActors.first
        : null;

    return InkWell(
      onTap: () => context.pushNamed(
        'characterProfile',
        pathParameters: {'id': '${character.id}'},
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            _Avatar(imageUrl: character.imageUrl, fallbackIcon: Icons.person),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  if (character.role != null)
                    Text(
                      _roleLabel(character.role!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                ],
              ),
            ),
            if (va != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.pushNamed(
                    'staffProfile',
                    pathParameters: {'id': '${va.id}'},
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              va.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall,
                            ),
                            if (va.language != null)
                              Text(
                                va.language!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _Avatar(
                        imageUrl: va.imageUrl,
                        fallbackIcon: Icons.mic,
                        size: 36,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({required this.staff});

  final AniListStaff staff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.pushNamed(
        'staffProfile',
        pathParameters: {'id': '${staff.id}'},
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            _Avatar(imageUrl: staff.imageUrl, fallbackIcon: Icons.work_outline),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  if (staff.role != null)
                    Text(
                      staff.role!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.imageUrl,
    required this.fallbackIcon,
    this.size = 44,
  });

  final String? imageUrl;
  final IconData fallbackIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: AppCachedImage(
        imageUrl: imageUrl ?? '',
        width: size,
        height: size,
        borderRadius: BorderRadius.circular(size / 2),
        fallbackIcon: fallbackIcon,
        fallbackSize: size * 0.45,
      ),
    );
  }
}
