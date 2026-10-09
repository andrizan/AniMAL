import 'package:animal/core/config/env.dart';
import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/models/anilist/anilist_models.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/features/detail/presentation/widgets/detail_header.dart';
import 'package:animal/features/detail/presentation/widgets/detail_people.dart';
import 'package:animal/features/detail/presentation/widgets/detail_sections.dart';
import 'package:animal/features/detail/presentation/widgets/my_list_card.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:animal/shared/providers/anime_notification_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/app_cached_image.dart';
import 'package:animal/shared/widgets/empty_view.dart';
import 'package:animal/shared/widgets/error_view.dart';
import 'package:animal/shared/widgets/full_screen_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

/// Detail page for a single anime.
class AnimeDetailPage extends ConsumerStatefulWidget {
  const AnimeDetailPage({required this.animeId, super.key});

  final int animeId;

  @override
  ConsumerState<AnimeDetailPage> createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends ConsumerState<AnimeDetailPage> {
  AnimeDetail? _detail;

  int get animeId => widget.animeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  Future<void> _refresh() async {
    try {
      final repo = ref.read(animeRepositoryProvider);
      final detail = await repo.refreshAnimeDetail(animeId);
      if (!mounted) return;
      if (detail != null) {
        setState(() => _detail = detail);
      }
      ref.invalidate(anilistAnimeExtraProvider(animeId));
    } on Exception catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refresh failed, showing cached data'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetail = ref.watch(animeDetailProvider(animeId));
    final asyncExtra = ref.watch(anilistAnimeExtraProvider(animeId));
    final theme = Theme.of(context);

    if (_detail == null && asyncDetail.hasValue && asyncDetail.value != null) {
      _detail = asyncDetail.value;
    }

    final detail = _detail;

    if (detail == null) {
      return asyncDetail.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, _) => Scaffold(
          appBar: AppBar(),
          body: ErrorView(
            message: 'Failed to load anime detail',
            onRetry: () => ref.invalidate(animeDetailProvider(animeId)),
          ),
        ),
        data: (detail) {
          if (detail == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const EmptyView(
                icon: Icons.search_off,
                message: 'Anime not found',
                hint: 'This anime may not be available on MyAnimeList.',
              ),
            );
          }

          return _buildDetailContent(detail, asyncExtra, theme);
        },
      );
    }

    return _buildDetailContent(detail, asyncExtra, theme);
  }

  Widget _buildDetailContent(
    AnimeDetail detail,
    AsyncValue<AniListAnimeExtra> asyncExtra,
    ThemeData theme,
  ) {
    final inList = detail.myListStatus != null;
    final extra = asyncExtra.value;
    final nextAiring = extra?.nextAiring;
    final studios = extra?.studios ?? const <AniListStudio>[];
    final characters = extra?.people.characters ?? const <AniListCharacter>[];
    final staff = extra?.people.staff ?? const <AniListStaff>[];
    final links = extra?.externalLinks ?? const <AniListExternalLink>[];

    final sections = <Widget>[
      DetailHeader(detail: detail),
      if (inList)
        MyListCard(
          detail: detail,
          onUpdated: _onListStatusUpdated,
          onRemoved: _onAnimeRemoved,
        )
      else
        AddToListButton(animeId: animeId, onAdded: _onListStatusUpdated),
      if (nextAiring != null) NextEpisodeCard(next: nextAiring),
      if (AboutCard.hasContent(detail)) AboutCard(detail: detail),
      if (InfoCard.hasContent(detail, studios))
        InfoCard(detail: detail, studios: studios),
      if (characters.isNotEmpty) CharactersCard(characters: characters),
      if (staff.isNotEmpty) StaffCard(staff: staff),
      if (detail.relatedAnime.isNotEmpty)
        RelatedCard(related: detail.relatedAnime),
      if (AltTitlesCard.hasContent(detail.alternativeTitles))
        AltTitlesCard(titles: detail.alternativeTitles!),
      if (LinksCard.hasContent(links)) LinksCard(links: links),
    ];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              backgroundColor: theme.colorScheme.surface,
              leading: _OverlayButton(
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.iconLight,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              actions: [
                if (nextAiring != null)
                  _OverlayButton(
                    child: _NotificationBell(
                      animeId: animeId,
                      title: detail.title,
                      nextAiring: nextAiring,
                    ),
                  ),
                _OverlayButton(
                  child: IconButton(
                    icon: const Icon(Icons.share, color: AppColors.iconLight),
                    onPressed: () => _shareAnime(detail),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: SelectableText(
                  detail.title,
                  maxLines: 2,
                  style: theme.textTheme.titleMedium,
                ),
                titlePadding: const EdgeInsets.only(
                  left: AppSpacing.page,
                  bottom: AppSpacing.lg,
                ),
                background: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    if (detail.mainPicture?.large != null) {
                      FullScreenImageViewer.show(
                        context,
                        imageUrl: detail.mainPicture!.large!,
                        heroTag: 'anime_cover',
                      );
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppCachedImage(imageUrl: detail.mainPicture?.large ?? ''),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.transparent,
                              AppColors.transparent,
                              theme.colorScheme.surface.withValues(alpha: 0.6),
                              theme.colorScheme.surface,
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.xxl,
              ),
              sliver: SliverList.separated(
                itemCount: sections.length,
                itemBuilder: (context, index) => sections[index],
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.md),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onListStatusUpdated(MyListStatus updatedStatus) {
    setState(() {
      _detail = _detail?.copyWith(myListStatus: updatedStatus);
    });
  }

  void _onAnimeRemoved() {
    setState(() {
      _detail = _detail?.copyWith(myListStatus: null);
    });
  }

  Future<void> _shareAnime(AnimeDetail detail) async {
    final url = Env.malAnimeUrl(animeId);
    await SharePlus.instance.share(ShareParams(text: '${detail.title}\n$url'));
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.overlayDarker,
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Notification Bell for airing anime
// ═══════════════════════════════════════════════════════════════════

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell({
    required this.animeId,
    required this.title,
    required this.nextAiring,
  });

  final int animeId;
  final String title;
  final AniListNextAiring nextAiring;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      animeNotificationProvider.select((s) => s.contains(animeId)),
    );

    return IconButton(
      icon: Icon(
        enabled ? Icons.notifications_active : Icons.notifications_none,
        color: enabled ? AppColors.starColor : AppColors.iconLight,
      ),
      onPressed: () async {
        final result = await ref
            .read(animeNotificationProvider.notifier)
            .toggle(
              animeId: animeId,
              title: title,
              episode: nextAiring.episode,
              airingAt: nextAiring.airingAt,
            );

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message(nextAiring.episode)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}
