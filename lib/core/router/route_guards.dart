import 'package:animal/core/router/app_router.dart';
import 'package:animal/features/auth/presentation/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

String? authGuard(GoRouterState state, AuthStatus authStatus) {
  final isLoggedIn = authStatus == AuthStatus.authenticated;
  final isLoggingIn = state.matchedLocation == AppRoutes.login;
  final isCallback = state.matchedLocation == AppRoutes.oauthCallback;

  if (!isLoggedIn && !isLoggingIn && !isCallback) {
    return AppRoutes.login;
  }

  if (isLoggedIn && isLoggingIn) {
    return AppRoutes.home;
  }

  return null;
}

class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}
