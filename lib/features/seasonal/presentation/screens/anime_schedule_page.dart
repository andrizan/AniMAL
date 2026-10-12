import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/data/models/season.dart';
import 'package:animal/features/seasonal/providers/seasonal_providers.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:animal/shared/widgets/empty_view.dart';
import 'package:animal/shared/widgets/error_view.dart';
import 'package:animal/shared/widgets/pill_tab_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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

  static const _seasonLabels = ['Winter', 'Spring', 'Summer', 'Fall', 'Later'];

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous year',
                onPressed: _selectedYear > _currentYear - 50
                    ? () => setState(() => _selectedYear--)
                    : null,
              ),
              FilledButton.tonal(
                onPressed: () => _showYearPicker(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 48),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    0,
                    AppSpacing.md,
                    0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_selectedYear',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.expand_more_rounded, size: 20),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next year',
                onPressed: _selectedYear < _currentYear + 1
                    ? () => setState(() => _selectedYear++)
                    : null,
              ),
            ],
          ),
        ),

        // Season + Later tabs
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.xs,
          ),
          child: PillTabBar(
            controller: _seasonTabController,
            scrollable: false,
            segmented: true,
            tabs: List.generate(_seasonLabels.length, (i) {
              return Tab(
                key: ValueKey('${_seasonLabels[i]}_$_selectedYear'),
                height: 60,
                iconMargin: const EdgeInsets.only(bottom: 2),
                icon: Icon(_seasonIcons[i], size: 20),
                text: _seasonLabels[i],
              );
            }),
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _seasonTabController,
            children: [
              ..._seasons.map((season) {
                return _SeasonAnimeList(year: _selectedYear, season: season);
              }),
              const _LaterAnimeList(),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showYearPicker(BuildContext context) async {
    const totalYears = 52; // 50 years back + current + next
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
            width: double.maxFinite,
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
                    style:
                        (isSelected
                                ? Theme.of(context).textTheme.titleMedium
                                : Theme.of(context).textTheme.bodyMedium)
                            ?.copyWith(
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

/// Displays anime for a specific year/season grouped by broadcast day.
class _SeasonAnimeList extends ConsumerWidget {
  const _SeasonAnimeList({required this.year, required this.season});

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
    final asyncAnime = ref.watch(groupedSeasonalAnimeProvider(params));

    return asyncAnime.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        message: 'Failed to load ${season.label} $year',
        onRetry: () => ref.invalidate(animeScheduleProvider(params)),
      ),
      data: (result) {
        final grouped = result.grouped;
        final noBroadcast = result.noBroadcast;
        final hasAny =
            grouped.values.any((l) => l.isNotEmpty) || noBroadcast.isNotEmpty;
        if (!hasAny) {
          return EmptyView(
            icon: Icons.calendar_month_outlined,
            message: 'No anime for ${season.label} $year',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(animeScheduleProvider(params)),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

              // Anime grouped by day
              for (int i = 0; i < _days.length; i++) ...[
                if (grouped[_days[i]]!.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _DayHeader(day: _dayLabels[i])),
                  SliverList.builder(
                    itemCount: grouped[_days[i]]!.length,
                    itemBuilder: (context, index) {
                      final anime = grouped[_days[i]]![index];
                      return AnimeCard(anime: anime);
                    },
                  ),
                ],
              ],

              // Anime without broadcast info
              if (noBroadcast.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.sm),
                ),
                SliverList.builder(
                  itemCount: noBroadcast.length,
                  itemBuilder: (context, index) {
                    return AnimeCard(anime: noBroadcast[index]);
                  },
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            ],
          ),
        );
      },
    );
  }
}

/// "Later" tab — upcoming anime that have no start date yet.
class _LaterAnimeList extends ConsumerWidget {
  const _LaterAnimeList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAnime = ref.watch(undatedAnimeProvider);

    return asyncAnime.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        message: 'Failed to load upcoming anime',
        onRetry: () => ref.invalidate(undatedAnimeProvider),
      ),
      data: (animeList) {
        if (animeList.isEmpty) {
          return const EmptyView(
            icon: Icons.schedule,
            message: 'No anime without a start date',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(undatedAnimeProvider),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page + AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.xs,
      ),
      child: Text(
        day,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
