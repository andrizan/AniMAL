import 'package:animal/features/anime/data/anilist_api.dart';
import 'package:animal/features/anime/presentation/anilist_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Airing page showing weekly anime schedule from AniList.
///
/// Displays anime grouped by day of week (Monday-Sunday),
/// sorted by airing time.
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
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
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
    final asyncSchedule = ref.watch(anilistAiringScheduleProvider);
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
                onPressed: () =>
                    ref.invalidate(anilistAiringScheduleProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (schedule) {
        // Group by day of week
        final grouped = <String, List<AniListScheduleEntry>>{};
        for (final day in _days) {
          grouped[day] = [];
        }

        for (final entry in schedule) {
          if (grouped.containsKey(entry.dayOfWeek)) {
            grouped[entry.dayOfWeek]!.add(entry);
          }
        }

        // Sort by airing time within each day
        for (final entry in grouped.entries) {
          entry.value.sort((a, b) => a.airingAt.compareTo(b.airingAt));
        }

        return Column(
          children: [
            // Refresh bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${schedule.length} airing this week',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    iconSize: 20,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: () =>
                        ref.invalidate(anilistAiringScheduleProvider),
                  ),
                ],
              ),
            ),

            // Day tabs
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
                  final animeForDay = grouped[day]!;

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
                        ref.invalidate(anilistAiringScheduleProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: animeForDay.length,
                      itemBuilder: (context, index) {
                        return _ScheduleCard(entry: animeForDay[index]);
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

/// Card for a scheduled anime airing.
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.entry});

  final AniListScheduleEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr =
        '${entry.airingAt.hour.toString().padLeft(2, '0')}:'
        '${entry.airingAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
      child: SizedBox(
        height: 125,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover image
            SizedBox(
              width: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (entry.imageUrl != null) CachedNetworkImage(
                          imageUrl: entry.imageUrl!,
                          fit: BoxFit.cover,
                        ) else ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.movie,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                  // Episode badge
                  if (entry.episode != null)
                    Positioned(
                      top: 2,
                      left: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'Ep ${entry.episode}',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      entry.titleEnglish ?? entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // Japanese title
                    if (entry.titleNative != null &&
                        entry.titleNative!.isNotEmpty)
                      Text(
                        entry.titleNative!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),

                    // Genres
                    if (entry.genres.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: entry.genres.take(3).map((g) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                g,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: theme
                                      .colorScheme.onSecondaryContainer,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    const Spacer(),

                    // Bottom: airing time + score + episodes
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '$timeStr JST',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (entry.meanScore != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.star_rounded,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            '${entry.meanScore}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (entry.episodes != null)
                          Text(
                            '${entry.episodes} eps',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
