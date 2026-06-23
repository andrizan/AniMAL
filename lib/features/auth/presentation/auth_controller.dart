import 'dart:async';

import 'package:animal/core/providers.dart';
import 'package:animal/features/auth/data/repositories/mal_auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Auth state – keeps track of whether the user is logged in.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Provider for [MalAuthRepository].
final malAuthRepositoryProvider = Provider<MalAuthRepository>((ref) {
  return MalAuthRepository(
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

/// Notifier that manages authentication state.
class AuthController extends Notifier<AuthStatus> {
  late final MalAuthRepository _repo;

  @override
  AuthStatus build() {
    _repo = ref.watch(malAuthRepositoryProvider);
    unawaited(_checkAuthStatus());
    return AuthStatus.unknown;
  }

  Future<void> _checkAuthStatus() async {
    final authed = await _repo.isAuthenticated;
    state = authed ? AuthStatus.authenticated : AuthStatus.unauthenticated;
  }

  /// Build the authorization URL.
  ///
  /// The code verifier is persisted to storage so it survives
  /// the app backgrounding during OAuth flow.
  Future<Uri> getAuthorizationUrl() => _repo.buildAuthorizationUrl();

  /// Exchange the code for tokens.
  Future<void> exchangeCode(String code) async {
    await _repo.exchangeCode(code);
    state = AuthStatus.authenticated;
  }

  /// Refresh the access token.
  Future<bool> refreshToken() async {
    final token = await _repo.refreshToken();
    return token != null;
  }

  /// Log the user out.
  Future<void> logout() async {
    await _repo.logout();
    state = AuthStatus.unauthenticated;
  }
}

/// Provider for [AuthController].
final authControllerProvider = NotifierProvider<AuthController, AuthStatus>(
  AuthController.new,
);
