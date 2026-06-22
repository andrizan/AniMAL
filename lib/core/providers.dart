import 'package:animal/core/network/dio_client.dart';
import 'package:animal/core/storage/secure_token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// Global logger instance.
final loggerProvider = Provider<Logger>((ref) => Logger());

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
