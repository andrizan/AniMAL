import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/core/utils/anilist_mappings.dart';
import 'package:animal/core/utils/date_utils.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/features/airing/providers/airing_providers.dart';
import 'package:animal/shared/providers/airing_refresh_providers.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:animal/shared/widgets/countdown_badge.dart';
import 'package:animal/shared/widgets/empty_view.dart';
import 'package:animal/shared/widgets/error_view.dart';
import 'package:animal/shared/widgets/pill_tab_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Airing page showing weekly anime schedule.
///
/// Data: AniList schedule (airingAt, episode, countdown)
///       + MAL score (mean).
///
/// The explicit refresh button lives in the home shell's header; it and the
/// pull-to-refresh here share [airingRefreshProvider].
class AnimeAiringPage extends ConsumerStatefulWidget {
  const AnimeAiringPage({super.key});

  @override
  ConsumerState<AnimeAiringPage> createState() => _AnimeAiringPageState();
}

class _AnimeAiringPageState extends ConsumerState<AnimeAiringPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().toUtc().weekday - 1;
    _tabController = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: today,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final result = await ref.read(airingRefreshProvider.notifier).refresh();
    final message = airingRefreshMessage(result);
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _retry() => ref.read(airingRefreshProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final asyncSchedule = ref.watch(weeklyAiringProvider);

    return asyncSchedule.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          ErrorView(message: 'Failed to load airing schedule', onRetry: _retry),
      data: (grouped) {
        final isWeekEmpty = grouped.values.every((l) => l.isEmpty);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.xs,
                AppSpacing.page,
                AppSpacing.xs,
              ),
              child: PillTabBar(controller: _tabController, labels: _dayLabels),
            ),
            if (isWeekEmpty)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.6,
                      child: EmptyView(
                        icon: Icons.tv_off,
                        message: 'No airing schedule yet',
                        onRetry: _retry,
                      ),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _days.map((day) {
                    // Whole-week rule: show every entry of the day,
                    // including already-aired ones (badge shows "Aired").
                    final animeForDay = grouped[day] ?? [];

                    if (animeForDay.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _refresh,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.5,
                            child: EmptyView(
                              icon: Icons.tv_off,
                              message:
                                  'No anime on ${_dayLabels[_days.indexOf(day)]}',
                            ),
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        itemCount: animeForDay.length,
                        itemBuilder: (context, index) {
                          final entry = animeForDay[index];
                          return _AiringCard(
                            key: ValueKey(
                              '${entry.anilistId}_${entry.episode}',
                            ),
                            entry: entry,
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Airing card: airing time and episode above the title, countdown below.
class _AiringCard extends StatefulWidget {
  const _AiringCard({required this.entry, super.key});

  final AiringEntry entry;

  @override
  State<_AiringCard> createState() => _AiringCardState();
}

class _AiringCardState extends State<_AiringCard> {
  late Anime _anime;
  late final VoidCallback? _onTap;

  Anime _buildAnime(AiringEntry entry) {
    final malId = entry.malId;
    return Anime(
      id: malId ?? entry.anilistId,
      title: entry.title,
      mainPicture: entry.imageUrl != null
          ? MainPicture(medium: entry.imageUrl, large: entry.imageUrl)
          : null,
      mean: entry.malScore,
      numEpisodes: entry.episodes,
      status: malStatusOf(entry.status),
      genres: entry.genres.map((g) => Genre(id: 0, name: g)).toList(),
      alternativeTitles: AlternativeTitles(
        en: entry.titleEnglish,
        ja: entry.titleNative,
      ),
      myListStatus: entry.myListStatus,
    );
  }

  @override
  void initState() {
    super.initState();
    _anime = _buildAnime(widget.entry);
    _onTap = widget.entry.malId != null
        ? null
        : () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Details only available through MyAnimeList'),
                duration: Duration(seconds: 2),
              ),
            );
          };
  }

  @override
  void didUpdateWidget(_AiringCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry) {
      _anime = _buildAnime(widget.entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return AnimeCard(
      anime: _anime,
      header: _AiringHeader(airingAt: entry.airingAt, episode: entry.episode),
      trailing: CountdownBadge(
        airingAt: entry.airingAt,
        episode: entry.episode,
        showEpisode: false,
      ),
      note: entry.malId == null ? 'Not on MyAnimeList yet' : null,
      onTap: _onTap,
    );
  }
}

class _AiringHeader extends StatelessWidget {
  const _AiringHeader({required this.airingAt, required this.episode});

  final DateTime airingAt;
  final int episode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final time = resolveAirSlot(nextAiringAt: airingAt)!.time;

    return Row(
      children: [
        Icon(Icons.schedule_rounded, size: 14, color: scheme.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          time,
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            'Episode $episode',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
