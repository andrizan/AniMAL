import 'dart:async';

import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Timer? _debounceTimer;

/// Debounced FutureProvider family for anime search.
// ignore: specify_nonobvious_property_types
final animeSearchProvider = FutureProvider.family<List<Anime>, String>((
  ref,
  query,
) async {
  _debounceTimer?.cancel();
  if (query.trim().isEmpty) return [];

  final completer = Completer<List<Anime>>();
  _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
    if (completer.isCompleted) return;
    try {
      final repo = ref.read(animeRepositoryProvider);
      final result = await repo.searchAnime(query);
      if (!completer.isCompleted) completer.complete(result);
    } catch (e) {
      if (!completer.isCompleted) completer.completeError(e);
    }
  });
  return completer.future;
});

/// FutureProvider for anime ranking.
final animeRankingProvider = FutureProvider<List<Anime>>((ref) async {
  final repo = ref.watch(animeRepositoryProvider);
  return repo.getAnimeRanking();
});

/// FutureProvider family for anime detail by ID.
/// Returns `null` if the anime doesn't exist on MAL (404).
/// Auto-disposes when no widgets are watching.
// ignore: specify_nonobvious_property_types
final animeDetailProvider = FutureProvider.autoDispose
    .family<AnimeDetail?, int>((ref, animeId) async {
      final repo = ref.watch(animeRepositoryProvider);
      return repo.getAnimeDetail(animeId);
    });
