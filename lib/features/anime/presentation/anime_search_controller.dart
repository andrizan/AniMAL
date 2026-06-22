import 'package:animal/features/anime/domain/anime.dart';
import 'package:animal/features/anime/domain/anime_detail.dart';
import 'package:animal/features/anime/presentation/anime_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FutureProvider family for anime search.
// ignore: specify_nonobvious_property_types
final animeSearchProvider =
    FutureProvider.family<List<Anime>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(animeRepositoryProvider);
  return repo.searchAnime(query);
});

/// FutureProvider for anime ranking.
final animeRankingProvider =
    FutureProvider<List<Anime>>((ref) async {
  final repo = ref.watch(animeRepositoryProvider);
  return repo.getAnimeRanking();
});

/// FutureProvider family for anime detail by ID.
/// Returns `null` if the anime doesn't exist on MAL (404).
/// Auto-disposes when no widgets are watching.
// ignore: specify_nonobvious_property_types
final animeDetailProvider =
    FutureProvider.autoDispose.family<AnimeDetail?, int>((ref, animeId) async {
  final repo = ref.watch(animeRepositoryProvider);
  return repo.getAnimeDetail(animeId);
});
