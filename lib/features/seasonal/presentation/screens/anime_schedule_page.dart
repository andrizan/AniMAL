import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/season.dart';
import 'package:animal/features/seasonal/providers/seasonal_providers.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Calendar page showing 4 seasons + "Later" tab for a selected year.
///
/// Default year is the current year. Max year is current year + 1.
class AnimeSchedulePage extends ConsumerStatefulWidget {
  const AnimeSchedulePage({super.key});

  @override
  ConsumerState<AnimeSchedulePage> createState() => _AnimeSchedulePageState();
}

class _AnimeSchedulePageState extends ConsumerState<AnimeSchedulePage>
    with SingleTickerProviderStateMixin {
  late int _selectedYear;
  late final TabController _seasonTabController;

  static final int _currentYear = DateTime.now().year;
  static const List<Season> _seasons = [
    Season.winter,
    Season.spring,
    Season.summer,
    Season.fall,
  ];

  static const _seasonLabels = [
    'Winter',
    'Spring',
    'Summer',
    'Fall',
    'Later',
  ];

  static const List<IconData> _seasonIcons = [
    Icons.ac_unit,
    Icons.local_florist,
    Icons.wb_sunny,
    Icons.park,
    Icons.schedule,
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = _currentYear;
    _seasonTabController = TabController(
      length: _seasonLabels.length,
      vsync: this,
      initialIndex: _currentSeasonIndex,
    );
  }

  int get _currentSeasonIndex {
    final now = DateTime.now();
    return _seasons.indexOf(Season.fromDate(now));
  }

  @override
  void dispose() {
    _seasonTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Year selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.colorScheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _selectedYear > _currentYear - 50
                    ? () => setState(() => _selectedYear--)
                    : null,
              ),
              GestureDetector(
                onTap: () => _showYearPicker(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_selectedYear',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: theme.colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _selectedYear < _currentYear + 1
                    ? () => setState(() => _selectedYear++)
                    : null,
              ),
            ],
          ),
        ),

        // Season + Later tabs
        TabBar(
          controller: _seasonTabController,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13,
          ),
          tabs: List.generate(_seasonLabels.length, (i) {
            return Tab(
              key: ValueKey('${_seasonLabels[i]}_$_selectedYear'),
              icon: Icon(_seasonIcons[i], size: 22),
              text: _seasonLabels[i],
            );
          }),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _seasonTabController,
            children: [
              ..._seasons.map((season) {
                return _SeasonAnimeList(
                  year: _selectedYear,
                  season: season,
                );
              }),
              _LaterAnimeList(year: _selectedYear),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showYearPicker(BuildContext context) async {
    const totalYears = 51; // 50 years back + current + next
    final selectedIndex = _selectedYear - (_currentYear - 50);

    final scrollController = ScrollController(
      initialScrollOffset: (selectedIndex * 48.0) - 150,
    );

    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Year'),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          content: SizedBox(
            width: double.minPositive,
            height: 300,
            child: ListView.builder(
              controller: scrollController,
              itemCount: totalYears,
              itemBuilder: (context, i) {
                final year = _currentYear - 50 + i;
                final isSelected = year == _selectedYear;
                return ListTile(
                  dense: true,
                  title: Text(
                    '$year',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: isSelected ? 18 : 15,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  selected: isSelected,
                  onTap: () => Navigator.pop(ctx, year),
                );
              },
            ),
          ),
        );
      },
    );

    scrollController.dispose();

    if (picked != null) {
      setState(() => _selectedYear = picked);
    }
  }
}

({Map<String, List<Anime>> grouped, List<Anime> noBroadcast})
_groupAnimeByDay(List<Anime> animeList) {
  const days = <String>[
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  final grouped = <String, List<Anime>>{};
  for (final day in days) {
    grouped[day] = [];
  }
  final noBroadcast = <Anime>[];

  for (final anime in animeList) {
    final day = anime.broadcast?.dayOfWeek;
    if (day != null && grouped.containsKey(day)) {
      grouped[day]!.add(anime);
    } else {
      noBroadcast.add(anime);
    }
  }

  for (final entry in grouped.entries) {
    entry.value.sort((a, b) {
      final at = a.broadcast?.startTime ?? '';
      final bt = b.broadcast?.startTime ?? '';
      return at.compareTo(bt);
    });
  }

  return (grouped: grouped, noBroadcast: noBroadcast);
}

/// Displays anime for a specific year/season grouped by broadcast day.
class _SeasonAnimeList extends ConsumerWidget {
  const _SeasonAnimeList({
    required this.year,
    required this.season,
  });

  final int year;
  final Season season;

  static const _days = <String>[
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const _dayLabels = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (year: year, season: season);
    final asyncAnime = ref.watch(animeScheduleProvider(params));
    final theme = Theme.of(context);

    return asyncAnime.when(
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
              Text(
                'Failed to load ${season.label} $year',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(animeScheduleProvider(params)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (animeList) {
        if (animeList.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No anime for ${season.label} $year',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        // Group by broadcast day
        final (:grouped, :noBroadcast) = _groupAnimeByDay(animeList);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(animeScheduleProvider(params)),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Anime grouped by day
              for (int i = 0; i < _days.length; i++) ...[
                if (grouped[_days[i]]!.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _DayHeader(day: _dayLabels[i]),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final anime = grouped[_days[i]]![index];
                        return AnimeCard(anime: anime);
                      },
                      childCount: grouped[_days[i]]!.length,
                    ),
                  ),
                ],
              ],

              // Anime without broadcast info
              if (noBroadcast.isNotEmpty) ...[
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return AnimeCard(anime: noBroadcast[index]);
                    },
                    childCount: noBroadcast.length,
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        );
      },
    );
  }
}

/// "Later" tab — anime that have no broadcast year/date.
class _LaterAnimeList extends ConsumerWidget {
  const _LaterAnimeList({this.year});

  final int? year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final params = (
      year: year ?? now.year + 1,
      season: Season.winter,
    );
    final asyncAnime = ref.watch(animeScheduleProvider(params));
    final theme = Theme.of(context);

    return asyncAnime.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            const Text('Failed to load upcoming anime'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.invalidate(animeScheduleProvider(params)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (animeList) {
        if (animeList.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No upcoming anime found',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(animeScheduleProvider(params)),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: animeList.length,
            itemBuilder: (context, index) {
              return AnimeCard(anime: animeList[index]);
            },
          ),
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final String day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        day,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
