import 'package:animal/features/anime/domain/anime.dart';
import 'package:animal/features/anime/domain/anime_detail.dart';
import 'package:animal/features/anime/presentation/anime_providers.dart';
import 'package:riverpod/src/providers/future_provider.dart';

/// FutureProvider family for anime search.
final FutureProviderFamily<List<Anime>, String> animeSearchProvider =
    FutureProvider.family<List<Anime>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(animeRepositoryProvider);
  return repo.searchAnime(query);
});

/// FutureProvider for anime ranking.
final FutureProvider<List<Anime>> animeRankingProvider =
    FutureProvider<List<Anime>>((ref) async {
  final repo = ref.watch(animeRepositoryProvider);
  return repo.getAnimeRanking();
});

/// FutureProvider family for anime detail by ID.
final FutureProviderFamily<AnimeDetail, int> animeDetailProvider =
    FutureProvider.family<AnimeDetail, int>((ref, animeId) async {
  final repo = ref.watch(animeRepositoryProvider);
  return repo.getAnimeDetail(animeId);
});
