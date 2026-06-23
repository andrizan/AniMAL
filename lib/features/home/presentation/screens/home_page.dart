import 'package:animal/features/airing/presentation/screens/anime_airing_page.dart';
import 'package:animal/features/home/presentation/widgets/anime_home_tab.dart';
import 'package:animal/features/profile/presentation/screens/anime_profile_page.dart';
import 'package:animal/features/seasonal/presentation/screens/anime_schedule_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Main home page with bottom navigation bar.
///
/// Four tabs: Home, Calendar, Airing, Profile.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;

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

  static const _tabs = <Widget>[
    AnimeHomeTab(),
    AnimeAiringPage(),
    AnimeSchedulePage(),
    AnimeProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AniMAL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.pushNamed('search'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: _destinations,
      ),
    );
  }
}
