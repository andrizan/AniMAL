import 'package:animal/core/providers.dart';
import 'package:animal/features/anime/data/anilist_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for [AniListApi].
final anilistApiProvider = Provider<AniListApi>((ref) {
  return AniListApi(logger: ref.watch(loggerProvider));
});

/// Fetches character detail from AniList by character ID.
/// Auto-disposes when no widgets are watching.
// ignore: specify_nonobvious_property_types
final anilistCharacterDetailProvider =
    FutureProvider.autoDispose.family<AniListCharacterDetail, int>(
        (ref, characterId) async {
  final api = ref.watch(anilistApiProvider);
  return api.getCharacterDetail(characterId);
});

/// Fetches staff detail from AniList by staff ID.
/// Auto-disposes when no widgets are watching.
// ignore: specify_nonobvious_property_types
final anilistStaffDetailProvider =
    FutureProvider.autoDispose.family<AniListStaffDetail, int>(
        (ref, staffId) async {
  final api = ref.watch(anilistApiProvider);
  return api.getStaffDetail(staffId);
});

/// Fetches characters, staff, next airing, and external links in one call.
/// Auto-disposes when no widgets are watching.
// ignore: specify_nonobvious_property_types
final anilistAnimeExtraProvider =
    FutureProvider.autoDispose.family<AniListAnimeExtra, int>(
        (ref, malId) async {
  final api = ref.watch(anilistApiProvider);
  return api.getAnimeExtraInfo(malId);
});
