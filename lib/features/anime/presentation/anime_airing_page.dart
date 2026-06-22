import 'package:animal/features/anime/domain/anime.dart';
import 'package:animal/features/anime/domain/anime_detail.dart';
import 'package:animal/features/anime/domain/broadcast.dart';
import 'package:animal/features/anime/presentation/anime_airing_providers.dart';
import 'package:animal/features/anime/presentation/anime_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  static const _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const _dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().weekday - 1;
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
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              const Text('Failed to load airing schedule'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(weeklyAiringProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (grouped) {
        return Column(
          children: [
            // Scrollable day tabs
            TabBar(
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

            // Day content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _days.map((day) {
                  final animeForDay = grouped[day] ?? [];

                  if (animeForDay.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tv_off,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text(
                            'No anime on ${_dayLabels[_days.indexOf(day)]}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(weeklyAiringProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: animeForDay.length,
                      itemBuilder: (context, index) {
                        final entry = animeForDay[index];
                        return _AiringCard(entry: entry);
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
class _AiringCard extends StatelessWidget {
  const _AiringCard({required this.entry});

  final AiringEntry entry;

  @override
  Widget build(BuildContext context) {
    final countdown = entry.countdown;
    final isUrgent = entry.isUrgent;
    final airingTime = _formatAiringTime(entry.airingAt);

    // Build a minimal Anime for the unified card
    final anime = Anime(
      id: entry.malId ?? entry.anilistId,
      title: entry.title,
      mainPicture: entry.imageUrl != null
          ? MainPicture(medium: entry.imageUrl, large: entry.imageUrl)
          : null,
      mean: entry.malScore,
      numEpisodes: entry.episodes,
      genres: entry.genres.map((g) => Genre(id: 0, name: g)).toList(),
      broadcast: airingTime != null
          ? Broadcast(startTime: airingTime)
          : null,
      alternativeTitles: AlternativeTitles(
        en: entry.titleEnglish,
        ja: entry.titleNative,
      ),
    );

    return AnimeCard(
      anime: anime,
      trailing: countdown != null
          ? _CountdownChip(
              countdown: countdown,
              episode: entry.episode,
              isUrgent: isUrgent,
            )
          : null,
    );
  }

  String? _formatAiringTime(DateTime airingAt) {
    final local = airingAt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

/// Countdown chip shown on airing cards.
class _CountdownChip extends StatelessWidget {
  const _CountdownChip({
    required this.countdown,
    required this.episode,
    required this.isUrgent,
  });

  final String countdown;
  final int episode;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isUrgent
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 12,
            color: isUrgent
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            'Ep $episode · $countdown',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isUrgent
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
