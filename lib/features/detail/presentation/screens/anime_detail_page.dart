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
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/app_cached_image.dart';
import 'package:animal/shared/widgets/empty_view.dart';
import 'package:animal/shared/widgets/error_view.dart';
import 'package:animal/shared/widgets/full_screen_image.dart';
import 'package:animal/shared/widgets/scrim_icon_button.dart';
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
      if (nextAiring != null)
        NextEpisodeCard(
          next: nextAiring,
          animeId: animeId,
          title: detail.title,
        ),
      if (AboutCard.hasContent(detail)) AboutCard(detail: detail),
      if (InfoCard.hasContent(
        detail,
        studios,
        nextAiringAt: nextAiring?.airingAt,
      ))
        InfoCard(
          detail: detail,
          studios: studios,
          nextAiringAt: nextAiring?.airingAt,
        ),
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
              expandedHeight: 320,
              pinned: true,
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              backgroundColor: theme.colorScheme.surface,
              leading: ScrimIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                ScrimIconButton(
                  icon: Icons.share_rounded,
                  tooltip: 'Share',
                  onPressed: () => _shareAnime(detail),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 64,
                  end: AppSpacing.lg,
                  bottom: 18,
                ),
                title: _CollapsedTitle(detail.title),
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
                            stops: const [0.0, 0.5, 0.82, 1.0],
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

/// The app bar title: hidden while the cover is expanded, fading in as the
/// bar collapses so the heading under the cover is not shown twice.
class _CollapsedTitle extends StatelessWidget {
  const _CollapsedTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final settings = context
        .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    var opacity = 1.0;
    if (settings != null) {
      final range = settings.maxExtent - settings.minExtent;
      final expanded = range > 0
          ? ((settings.currentExtent - settings.minExtent) / range).clamp(
              0.0,
              1.0,
            )
          : 0.0;
      opacity = (1 - expanded * 4).clamp(0.0, 1.0);
    }
    return Opacity(
      opacity: opacity,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
