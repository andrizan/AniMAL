import 'package:animal/features/anime/domain/mal_user.dart';
import 'package:animal/features/anime/presentation/anime_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches the current user's MAL profile info.
final userInfoProvider = FutureProvider<MalUser>((ref) async {
  final repo = ref.watch(animeRepositoryProvider);
  return repo.getUserInfo();
});
