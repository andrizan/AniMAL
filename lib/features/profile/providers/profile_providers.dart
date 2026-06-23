import 'package:animal/data/models/mal_user.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches the current user's MAL profile info.
final userInfoProvider = FutureProvider<MalUser?>((ref) async {
  final repo = ref.watch(animeRepositoryProvider);
  return repo.getUserInfo();
});
