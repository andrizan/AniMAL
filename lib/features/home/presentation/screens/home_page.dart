import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/shared/providers/airing_refresh_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Shell that hosts the bottom navigation bar with tab state preservation.
///
/// Uses [StatefulShellRoute.indexedStack] to keep all tabs alive. The header
/// carries the page title, the search button and, on the Airing tab, the
/// schedule refresh button.
class HomePage extends ConsumerWidget {
  const HomePage({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _airingIndex = 1;

  static const _titles = ['Library', 'Airing', 'Calendar', 'Profile'];

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.tv_outlined),
      selectedIcon: Icon(Icons.tv),
      label: 'Airing',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      label: 'Calendar',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  Future<void> _refreshAiring(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(airingRefreshProvider.notifier).refresh();
    final message = airingRefreshMessage(result);
    if (message == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final index = navigationShell.currentIndex;
    final refreshing = ref.watch(airingRefreshProvider);
    const topRadius = BorderRadius.vertical(
      top: Radius.circular(AppRadius.hero),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[index]),
        titleTextStyle: theme.textTheme.headlineMedium,
        actions: [
          if (index == _airingIndex)
            IconButton(
              tooltip: 'Refresh',
              iconSize: 22,
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              icon: refreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: refreshing ? null : () => _refreshAiring(context, ref),
            ),
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              right: AppSpacing.md,
            ),
            child: IconButton.filledTonal(
              tooltip: 'Search',
              iconSize: 22,
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              icon: const Icon(Icons.search),
              onPressed: () => context.pushNamed('search'),
            ),
          ),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: topRadius,
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.10),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: topRadius,
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: navigationShell.goBranch,
            destinations: _destinations,
          ),
        ),
      ),
    );
  }
}
