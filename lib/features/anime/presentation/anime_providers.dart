import 'package:animal/core/providers.dart';
import 'package:animal/features/anime/data/anime_repository.dart';
import 'package:animal/features/anime/data/mal_anime_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for [MalAnimeApi].
final malAnimeApiProvider = Provider<MalAnimeApi>((ref) {
  return MalAnimeApi(ref.watch(dioProvider));
});

/// Provider for [AnimeRepository].
final animeRepositoryProvider = Provider<AnimeRepository>((ref) {
  return AnimeRepository(
    ref.watch(malAnimeApiProvider),
    ref.watch(loggerProvider),
  );
});
