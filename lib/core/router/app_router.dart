import 'package:animal/core/router/route_guards.dart';
import 'package:animal/features/airing/presentation/screens/anime_airing_page.dart';
import 'package:animal/features/auth/presentation/login_page.dart';
import 'package:animal/features/auth/presentation/oauth_callback_page.dart';
import 'package:animal/features/auth/providers/auth_providers.dart';
import 'package:animal/features/detail/presentation/screens/anime_detail_page.dart';
import 'package:animal/features/detail/presentation/screens/character_staff_page.dart';
import 'package:animal/features/detail/presentation/screens/studio_page.dart';
import 'package:animal/features/home/presentation/screens/home_page.dart';
import 'package:animal/features/home/presentation/widgets/anime_home_tab.dart';
import 'package:animal/features/profile/presentation/screens/anime_profile_page.dart';
import 'package:animal/features/search/presentation/screens/anime_search_page.dart';
import 'package:animal/features/seasonal/presentation/screens/anime_schedule_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String search = '/search';
  static const String animeDetail = '/anime/:id';
  static const String characterProfile = '/character/:id';
  static const String staffProfile = '/staff/:id';
  static const String studioProfile = '/studio/:id';
  static const String oauthCallback = '/oauth/callback';
}

/// Every page change is a 200 ms fade, and no animation at all when the
/// device asks for reduced motion.
Page<void> fadePage(BuildContext context, GoRouterState state, Widget child) {
  final duration = MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 200);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

Widget _invalidId(String what) => Scaffold(
  appBar: AppBar(title: const Text('Invalid ID')),
  body: Center(child: Text('Invalid $what ID')),
);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = AuthRefreshListenable(ref);

  final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) =>
        authGuard(state, ref.read(authControllerProvider)),
    routes: [
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) => fadePage(
          context,
          state,
          HomePage(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const AnimeHomeTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/airing',
                name: 'airing',
                builder: (context, state) => const AnimeAiringPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                name: 'calendar',
                builder: (context, state) => const AnimeSchedulePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const AnimeProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        pageBuilder: (context, state) =>
            fadePage(context, state, const AnimeSearchPage()),
      ),
      GoRoute(
        path: AppRoutes.animeDetail,
        name: 'animeDetail',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return fadePage(
            context,
            state,
            id == null ? _invalidId('anime') : AnimeDetailPage(animeId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.characterProfile,
        name: 'characterProfile',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return fadePage(
            context,
            state,
            id == null
                ? _invalidId('character')
                : CharacterProfilePage(characterId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.staffProfile,
        name: 'staffProfile',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return fadePage(
            context,
            state,
            id == null ? _invalidId('staff') : StaffProfilePage(staffId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.studioProfile,
        name: 'studioProfile',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return fadePage(
            context,
            state,
            id == null ? _invalidId('studio') : StudioProfilePage(studioId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) =>
            fadePage(context, state, const LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.oauthCallback,
        name: 'oauthCallback',
        pageBuilder: (context, state) {
          final code = state.uri.queryParameters['code'];
          final oauthState = state.uri.queryParameters['state'];
          return fadePage(
            context,
            state,
            OAuthCallbackPage(code: code, state: oauthState),
          );
        },
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
