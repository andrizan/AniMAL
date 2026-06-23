import 'dart:async';

import 'package:animal/core/logger/app_logger.dart';
import 'package:animal/core/network/dio_client.dart';
import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:animal/core/storage/secure_token_storage.dart';
import 'package:animal/features/auth/data/repositories/mal_auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// Global logger instance.
final loggerProvider = Provider<Logger>((ref) => appLogger);

/// Secure token storage.
final tokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return const SecureTokenStorage();
});

/// Configured Dio client.
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    logger: ref.watch(loggerProvider),
  );
});

/// Raw Dio instance (convenience shortcut).
final dioProvider = Provider<Dio>((ref) {
  return ref.watch(dioClientProvider).dio;
});

/// Notification service — initialized once in main.dart.
final notificationServiceProvider = Provider<AnimeNotificationService>(
  (ref) => throw UnimplementedError(
    'Override this provider in main.dart with the initialized instance',
  ),
);

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
