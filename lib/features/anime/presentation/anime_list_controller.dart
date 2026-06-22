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

/// Convenience provider for the "Watching" list.
final FutureProvider<List<Anime>> watchingListProvider =
    FutureProvider<List<Anime>>((ref) async {
  return ref.watch(userAnimeListProvider(WatchStatus.watching).future);
});

/// Convenience provider for the "Plan to Watch" list.
final FutureProvider<List<Anime>> planToWatchListProvider =
    FutureProvider<List<Anime>>((ref) async {
  return ref.watch(userAnimeListProvider(WatchStatus.planToWatch).future);
});

/// Convenience provider for the "On Hold" list.
final FutureProvider<List<Anime>> onHoldListProvider =
    FutureProvider<List<Anime>>((ref) async {
  return ref.watch(userAnimeListProvider(WatchStatus.onHold).future);
});

/// Encapsulates mutations (delete / update) on the user's anime list.
///
/// After each mutation the affected [userAnimeListProvider]s are
/// invalidated so the UI refreshes automatically.
class AnimeListActions {
  AnimeListActions(this._ref);

  final Ref _ref;

  /// Remove [animeId] from the user's list and refresh [status].
  Future<void> delete({
    required int animeId,
    required WatchStatus status,
  }) async {
    final repo = _ref.read(animeRepositoryProvider);
    await repo.deleteAnimeFromList(animeId);
    _ref.invalidate(userAnimeListProvider(status));
  }

  /// Update the user's list status for [animeId].
  Future<void> update(
    int animeId, {
    required WatchStatus currentStatus,
    WatchStatus? status,
    int? numWatchedEpisodes,
    int? score,
    bool? isRewatching,
  }) async {
    final repo = _ref.read(animeRepositoryProvider);
    await repo.updateAnimeListStatus(
      animeId,
      status: status,
      numWatchedEpisodes: numWatchedEpisodes,
      score: score,
      isRewatching: isRewatching,
    );
    _ref.invalidate(userAnimeListProvider(currentStatus));
    if (status != null && status != currentStatus) {
      _ref.invalidate(userAnimeListProvider(status));
    }
  }
}

/// Provider for [AnimeListActions].
final Provider<AnimeListActions> animeListActionsProvider =
    Provider<AnimeListActions>((ref) {
  return AnimeListActions(ref);
});
