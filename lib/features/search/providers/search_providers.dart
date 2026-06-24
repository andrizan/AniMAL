import 'dart:async';

import 'package:animal/data/models/anime.dart';
import 'package:animal/shared/providers/anime_providers.dart'
    show animeListVersionProvider, animeRepositoryProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Debounced FutureProvider family for anime search.
// ignore: specify_nonobvious_property_types
final animeSearchProvider = FutureProvider.family<List<Anime>, String>(
  (
    ref,
    query,
  ) async {
    ref.watch(animeListVersionProvider);
    if (query.trim().isEmpty) return [];

    final completer = Completer<List<Anime>>();
    final timer = Timer(const Duration(milliseconds: 300), () async {
      if (completer.isCompleted) return;
      try {
        final repo = ref.read(animeRepositoryProvider);
        final result = await repo.searchAnime(query);
        if (!completer.isCompleted) completer.complete(result);
      } catch (e, st) {
        if (!completer.isCompleted) completer.completeError(e, st);
      }
    });
    ref.onDispose(timer.cancel);
    return completer.future;
  },
);

/// FutureProvider for anime ranking.
final animeRankingProvider = FutureProvider<List<Anime>>((ref) async {
  final repo = ref.watch(animeRepositoryProvider);
  return repo.getAnimeRanking();
});
