import 'package:animal/core/providers.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for [AniListClient].
final anilistApiProvider = Provider<AniListClient>((ref) {
  return AniListClient(logger: ref.watch(loggerProvider));
});

final anilistCharacterDetailProvider =
    FutureProvider.autoDispose.family<AniListCharacterDetail, int>(
        (ref, characterId) async {
  final api = ref.watch(anilistApiProvider);
  return api.getCharacterDetail(characterId);
});

final anilistStaffDetailProvider =
    FutureProvider.autoDispose.family<AniListStaffDetail, int>(
        (ref, staffId) async {
  final api = ref.watch(anilistApiProvider);
  return api.getStaffDetail(staffId);
});

final anilistAnimeExtraProvider =
    FutureProvider.autoDispose.family<AniListAnimeExtra, int>(
        (ref, malId) async {
  final api = ref.watch(anilistApiProvider);
  return api.getAnimeExtraInfo(malId);
});
