import 'package:animal/features/detail/presentation/screens/anime_detail_page.dart';
import 'package:animal/features/detail/presentation/screens/character_staff_pages.dart';
import 'package:animal/features/search/presentation/screens/anime_search_page.dart';
import 'package:animal/features/home/presentation/screens/home_page.dart';
import 'package:animal/features/auth/presentation/auth_controller.dart';
import 'package:animal/features/auth/presentation/login_page.dart';
import 'package:animal/features/auth/presentation/oauth_callback_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Application route paths.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String home = '/';
  static const String search = '/search';
  static const String animeDetail = '/anime/:id';
  static const String characterProfile = '/character/:id';
  static const String staffProfile = '/staff/:id';
  static const String oauthCallback = '/oauth/callback';
}

/// GoRouter provider with auth guard.
final routerProvider = Provider<GoRouter>((ref) {
  final authStatus = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      final isLoggedIn = authStatus == AuthStatus.authenticated;
      final isLoggingIn = state.matchedLocation == AppRoutes.login;
      final isCallback =
          state.matchedLocation == AppRoutes.oauthCallback;

      // Allow login page and OAuth callback without auth
      if (!isLoggedIn && !isLoggingIn && !isCallback) {
        return AppRoutes.login;
      }

      // Redirect to home if already logged in and on login page
      if (isLoggedIn && isLoggingIn) {
        return AppRoutes.home;
      }

      return null;
    },
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

/// Listenable that triggers GoRouter refresh when auth state changes.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    ref.listen(authControllerProvider, (_, _) {
      notifyListeners();
    });
  }
}
