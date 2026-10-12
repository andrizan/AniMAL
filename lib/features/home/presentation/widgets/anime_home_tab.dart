import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/features/home/presentation/widgets/anime_list_tab.dart';
import 'package:animal/shared/providers/anime_list_providers.dart'
    show AiringFilter, ListSort, refreshUserAnimeListProvider;
import 'package:animal/shared/widgets/pill_tab_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const _tabLabels = [
    'Watching',
    'Plan to Watch',
    'On Hold',
    'Completed',
    'Dropped',
  ];

  static const List<WatchStatus> _statuses = [
    WatchStatus.watching,
    WatchStatus.planToWatch,
    WatchStatus.onHold,
    WatchStatus.completed,
    WatchStatus.dropped,
  ];

  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final sortIndex = (prefs.getInt('list_sort') ?? 0).clamp(
      0,
      ListSort.values.length - 1,
    );
    final ascending = prefs.getBool('list_ascending') ?? true;
    final filterIndex = (prefs.getInt('airing_filter') ?? 0).clamp(
      0,
      AiringFilter.values.length - 1,
    );
    if (!mounted) return;
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

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await ref.read(refreshUserAnimeListProvider)(
        _statuses[_tabController.index],
      );
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xs,
            AppSpacing.sm,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: PillTabBar(
                  controller: _tabController,
                  labels: _tabLabels,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
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
        ),

        // Filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              _MenuPill<ListSort>(
                tooltip: 'Sort by',
                value: _sortBy,
                values: ListSort.values,
                labelOf: (s) => s.label,
                onSelected: _saveSort,
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                iconSize: 20,
                icon: Icon(
                  _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                tooltip: _ascending ? 'Ascending' : 'Descending',
                onPressed: () => _saveAscending(!_ascending),
              ),
              const Spacer(),
              _MenuPill<AiringFilter>(
                tooltip: 'Filter by airing status',
                value: _airingFilter,
                values: AiringFilter.values,
                labelOf: (f) => f.label,
                onSelected: _saveAiringFilter,
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
                for (final status in _statuses)
                  AnimeListTab(
                    status: status,
                    sortBy: _sortBy,
                    ascending: _ascending,
                    airingFilter: _airingFilter,
                  ),
              ],
            ),
          )
        else
          const Expanded(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }
}

/// A tonal pill that opens a menu of [values].
class _MenuPill<T> extends StatelessWidget {
  const _MenuPill({
    required this.tooltip,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onSelected,
  });

  final String tooltip;
  final T value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PopupMenuButton<T>(
      tooltip: tooltip,
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final v in values)
          PopupMenuItem(value: v, child: Text(labelOf(v))),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.fromLTRB(14, 0, 10, 0),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(labelOf(value), style: theme.textTheme.labelLarge),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
