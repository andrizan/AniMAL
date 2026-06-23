import 'package:animal/features/library/data/models/anime.dart';
import 'package:animal/features/library/data/models/watch_status.dart';
import 'package:animal/features/library/presentation/providers/anime_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches the current user's anime list filtered by [WatchStatus].
// ignore: specify_nonobvious_property_types
final userAnimeListProvider =
    FutureProvider.family<List<Anime>, WatchStatus>((ref, status) async {
  final repo = ref.watch(animeRepositoryProvider);
  return repo.getUserAnimeList(status: status);
});
