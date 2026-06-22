import 'package:animal/features/anime/domain/anime.dart';
import 'package:animal/features/anime/domain/watch_status.dart';
import 'package:animal/features/anime/presentation/anime_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches the current user's anime list filtered by [WatchStatus].
// ignore: specify_nonobvious_property_types
final userAnimeListProvider =
    FutureProvider.family<List<Anime>, WatchStatus>((ref, status) async {
  final repo = ref.watch(animeRepositoryProvider);
  return repo.getUserAnimeList(status: status);
});
