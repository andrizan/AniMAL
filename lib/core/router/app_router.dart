import 'package:animal/core/router/route_guards.dart';
import 'package:animal/features/detail/presentation/screens/anime_detail_page.dart';
import 'package:animal/features/detail/presentation/screens/character_staff_pages.dart';
import 'package:animal/features/detail/presentation/screens/studio_page.dart';
import 'package:animal/features/search/presentation/screens/anime_search_page.dart';
import 'package:animal/features/home/presentation/screens/home_page.dart';
import 'package:animal/features/auth/presentation/auth_controller.dart';
import 'package:animal/features/auth/presentation/login_page.dart';
import 'package:animal/features/auth/presentation/oauth_callback_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String home = '/';
  static const String search = '/search';
  static const String animeDetail = '/anime/:id';
  static const String characterProfile = '/character/:id';
  static const String staffProfile = '/staff/:id';
  static const String studioProfile = '/studio/:id';
  static const String oauthCallback = '/oauth/callback';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authStatus = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: AuthRefreshListenable(ref),
    redirect: (context, state) => authGuard(state, authStatus),
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        builder: (context, state) => const AnimeSearchPage(),
      ),
      GoRoute(
        path: AppRoutes.animeDetail,
        name: 'animeDetail',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const HomePage();
          return AnimeDetailPage(animeId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.characterProfile,
        name: 'characterProfile',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const HomePage();
          return CharacterProfilePage(characterId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.staffProfile,
        name: 'staffProfile',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const HomePage();
          return StaffProfilePage(staffId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.studioProfile,
        name: 'studioProfile',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const HomePage();
          return StudioProfilePage(studioId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.oauthCallback,
        name: 'oauthCallback',
        builder: (context, state) {
          final code = state.uri.queryParameters['code'];
          return OAuthCallbackPage(code: code);
        },
      ),
    ],
  );
});
