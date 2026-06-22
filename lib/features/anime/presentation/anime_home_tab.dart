import 'package:animal/features/anime/domain/watch_status.dart';
import 'package:animal/features/anime/presentation/anime_list_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sort options for the anime list.
enum ListSort {
  name('Name'),
  score('Score'),
  episodes('Episodes');

  const ListSort(this.label);
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
                  if (value != null) setState(() => _sortBy = value);
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
                onPressed: () =>
                    setState(() => _ascending = !_ascending),
              ),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              AnimeListTab(status: WatchStatus.watching, sortBy: _sortBy, ascending: _ascending),
              AnimeListTab(status: WatchStatus.planToWatch, sortBy: _sortBy, ascending: _ascending),
              AnimeListTab(status: WatchStatus.onHold, sortBy: _sortBy, ascending: _ascending),
              AnimeListTab(status: WatchStatus.completed, sortBy: _sortBy, ascending: _ascending),
              AnimeListTab(status: WatchStatus.dropped, sortBy: _sortBy, ascending: _ascending),
            ],
          ),
        ),
      ],
    );
  }
}
