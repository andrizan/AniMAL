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
            AppSpacing.page,
            0,
          ),
          child: PillTabBar(controller: _tabController, labels: _tabLabels),
        ),

        // Filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              _SortPill(
                sortBy: _sortBy,
                ascending: _ascending,
                onSort: _saveSort,
                onDirection: _saveAscending,
              ),
              const SizedBox(width: AppSpacing.sm),
              _MenuPill<AiringFilter>(
                tooltip: 'Filter by airing status',
                value: _airingFilter,
                values: AiringFilter.values,
                labelOf: (f) => f.label,
                onSelected: _saveAiringFilter,
              ),
              const Spacer(),
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

/// The pill body shared by the sort and filter menus.
class _PillBody extends StatelessWidget {
  const _PillBody({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      height: 40,
      padding: const EdgeInsets.fromLTRB(14, 0, 10, 0),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
          const SizedBox(width: AppSpacing.xs),
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// "Title ↑": the sort field with its direction. The menu lists the fields
/// and, below a divider, the two directions.
class _SortPill extends StatelessWidget {
  const _SortPill({
    required this.sortBy,
    required this.ascending,
    required this.onSort,
    required this.onDirection,
  });

  final ListSort sortBy;
  final bool ascending;
  final ValueChanged<ListSort> onSort;
  final ValueChanged<bool> onDirection;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<Object>(
      tooltip: 'Sort by',
      onSelected: (value) {
        if (value is ListSort) onSort(value);
        if (value is bool) onDirection(value);
      },
      itemBuilder: (context) => [
        for (final s in ListSort.values)
          PopupMenuItem<Object>(
            value: s,
            child: Row(
              children: [
                Expanded(child: Text(s.label)),
                if (s == sortBy)
                  Icon(Icons.check_rounded, size: 18, color: scheme.primary),
              ],
            ),
          ),
        const PopupMenuDivider(),
        for (final (direction, label, icon) in const [
          (true, 'Ascending', Icons.arrow_upward),
          (false, 'Descending', Icons.arrow_downward),
        ])
          PopupMenuItem<Object>(
            value: direction,
            child: Row(
              children: [
                Icon(icon, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(label)),
                if (direction == ascending)
                  Icon(Icons.check_rounded, size: 18, color: scheme.primary),
              ],
            ),
          ),
      ],
      child: _PillBody(
        label: sortBy.label,
        icon: ascending ? Icons.arrow_upward : Icons.arrow_downward,
      ),
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
    return PopupMenuButton<T>(
      tooltip: tooltip,
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final v in values)
          PopupMenuItem(value: v, child: Text(labelOf(v))),
      ],
      child: _PillBody(label: labelOf(value), icon: Icons.expand_more_rounded),
    );
  }
}
