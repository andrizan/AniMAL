import 'package:animal/core/providers.dart';
import 'package:animal/data/mal/mal_api_client.dart';
import 'package:animal/features/profile/data/profile_repository_impl.dart';
import 'package:animal/features/profile/domain/entities/user_profile_entity.dart';
import 'package:animal/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    malApi: MalApiClient(ref.watch(dioProvider)),
    logger: ref.watch(loggerProvider),
  );
});

final userProfileProvider =
    FutureProvider<UserProfileEntity?>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getUserProfile();
});
