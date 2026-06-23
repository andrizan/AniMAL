import 'package:animal/features/library/data/models/watch_status.dart';
import 'package:animal/features/home/presentation/widgets/anime_list_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sort options for the anime list.
enum ListSort {
  name('Name'),
  score('Score'),
  episodes('Episodes'),
  airing('Airing');

  const ListSort(this.label);
  final String label;
}

/// Airing status filter.
enum AiringFilter {
  all('All'),
  airing('Airing'),
  finished('Finished'),
  upcoming('Upcoming');

  const AiringFilter(this.label);
  final String label;
}

/// Home tab with tabbed anime lists and filter bar.
class AnimeHomeTab extends ConsumerStatefulWidget {
  const AnimeHomeTab({super.key});

  @override
  ConsumerState<AnimeHomeTab> createState() => _AnimeHomeTabState();
}

class _AnimeHomeTabState extends ConsumerState<AnimeHomeTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  ListSort _sortBy = ListSort.name;
  bool _ascending = true;
  AiringFilter _airingFilter = AiringFilter.all;
  bool _loaded = false;
  SharedPreferences? _prefs;

  static const _tabs = [
    Tab(text: 'Watching'),
    Tab(text: 'Plan to Watch'),
    Tab(text: 'On Hold'),
    Tab(text: 'Completed'),
    Tab(text: 'Dropped'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final sortIndex = (prefs.getInt('list_sort') ?? 0)
        .clamp(0, ListSort.values.length - 1);
    final ascending = prefs.getBool('list_ascending') ?? true;
    final filterIndex = (prefs.getInt('airing_filter') ?? 0)
        .clamp(0, AiringFilter.values.length - 1);
    setState(() {
      _sortBy = ListSort.values[sortIndex];
      _ascending = ascending;
      _airingFilter = AiringFilter.values[filterIndex];
      _loaded = true;
    });
  }

  Future<void> _saveSort(ListSort sort) async {
    setState(() => _sortBy = sort);
    await _prefs?.setInt('list_sort', sort.index);
  }

  Future<void> _saveAscending(bool ascending) async {
    setState(() => _ascending = ascending);
    await _prefs?.setBool('list_ascending', ascending);
  }

  Future<void> _saveAiringFilter(AiringFilter filter) async {
    setState(() => _airingFilter = filter);
    await _prefs?.setInt('airing_filter', filter.index);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Tab bar
        TabBar(
          controller: _tabController,
          tabs: _tabs,
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
        ),

        // Filter bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              // Sort dropdown
              DropdownButton<ListSort>(
                value: _sortBy,
                underline: const SizedBox.shrink(),
                style: theme.textTheme.bodySmall,
                items: ListSort.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.label),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) _saveSort(value);
                },
              ),
              const SizedBox(width: 4),
              // ASC/DESC toggle
              IconButton(
                iconSize: 20,
                icon: Icon(
                  _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                tooltip: _ascending ? 'Ascending' : 'Descending',
                onPressed: () => _saveAscending(!_ascending),
              ),
              const Spacer(),
              // Airing status filter
              DropdownButton<AiringFilter>(
                value: _airingFilter,
                underline: const SizedBox.shrink(),
                style: theme.textTheme.bodySmall,
                items: AiringFilter.values
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.label),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) _saveAiringFilter(value);
                },
              ),
            ],
          ),
        ),

        // Tab content
        if (_loaded)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                AnimeListTab(status: WatchStatus.watching, sortBy: _sortBy, ascending: _ascending, airingFilter: _airingFilter),
                AnimeListTab(status: WatchStatus.planToWatch, sortBy: _sortBy, ascending: _ascending, airingFilter: _airingFilter),
                AnimeListTab(status: WatchStatus.onHold, sortBy: _sortBy, ascending: _ascending, airingFilter: _airingFilter),
                AnimeListTab(status: WatchStatus.completed, sortBy: _sortBy, ascending: _ascending, airingFilter: _airingFilter),
                AnimeListTab(status: WatchStatus.dropped, sortBy: _sortBy, ascending: _ascending, airingFilter: _airingFilter),
              ],
            ),
          )
        else
          const Expanded(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }
}
