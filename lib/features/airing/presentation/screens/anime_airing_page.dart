import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/broadcast.dart';
import 'package:animal/features/airing/providers/airing_providers.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:animal/shared/widgets/countdown_badge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Airing page showing weekly anime schedule.
///
/// Data: AniList schedule (airingAt, episode, countdown)
///       + MAL score (mean).
class AnimeAiringPage extends ConsumerStatefulWidget {
  const AnimeAiringPage({super.key});

  @override
  ConsumerState<AnimeAiringPage> createState() => _AnimeAiringPageState();
}

class _AnimeAiringPageState extends ConsumerState<AnimeAiringPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isRefreshing = false;

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

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final result = await ref
          .read(airingRepositoryProvider)
          .refreshWeeklySchedule();
      ref.invalidate(weeklyAiringProvider);
      if (mounted && result.values.every((l) => l.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Airing schedule is empty, try again later'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refresh failed, showing cached schedule'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _handleRetry() async {
    try {
      await ref.read(airingRepositoryProvider).refreshWeeklySchedule();
      // ignore: empty_catches
    } on Object {}
    ref.invalidate(weeklyAiringProvider);
  }

  @override
  Widget build(BuildContext context) {
    final asyncSchedule = ref.watch(weeklyAiringProvider);
    final theme = Theme.of(context);

    return asyncSchedule.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              const Text('Failed to load airing schedule'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _handleRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (grouped) {
        final isWeekEmpty = grouped.values.every((l) => l.isEmpty);
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                    ),
                    tabs: _dayLabels.map((d) => Tab(text: d)).toList(),
                  ),
                ),
                IconButton(
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: _isRefreshing ? null : _handleRefresh,
                ),
              ],
            ),
            if (isWeekEmpty)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.6,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tv_off,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No airing schedule yet',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _handleRetry,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
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
                    final allForDay = grouped[day] ?? [];
                    final now = DateTime.now().toUtc();
                    final animeForDay = allForDay
                        .where((e) => e.airingAt.toUtc().isAfter(now))
                        .toList();

                    if (animeForDay.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.5,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tv_off,
                                    size: 48,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No anime on ${_dayLabels[_days.indexOf(day)]}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _handleRefresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemExtent: 126,
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

/// Airing card with countdown trailing widget.
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
    final airingTime = _formatAiringTime(entry.airingAt);
    final malId = entry.malId;
    return Anime(
      id: malId ?? entry.anilistId,
      title: entry.title,
      mainPicture: entry.imageUrl != null
          ? MainPicture(medium: entry.imageUrl, large: entry.imageUrl)
          : null,
      mean: entry.malScore,
      numEpisodes: entry.episodes,
      status: _mapAniListStatus(entry.status),
      genres: entry.genres.map((g) => Genre(id: 0, name: g)).toList(),
      broadcast: airingTime != null ? Broadcast(startTime: airingTime) : null,
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
    return AnimeCard(
      anime: _anime,
      trailing: CountdownBadge(
        airingAt: widget.entry.airingAt,
        episode: widget.entry.episode,
      ),
      onTap: _onTap,
    );
  }

  String? _formatAiringTime(DateTime airingAt) {
    final local = airingAt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String? _mapAniListStatus(String? status) => switch (status) {
    'RELEASING' => 'currently_airing',
    'FINISHED' => 'finished_airing',
    'NOT_YET_RELEASED' => 'not_yet_aired',
    'CANCELLED' => 'finished_airing',
    _ => status,
  };
}
