import 'package:animal/core/providers.dart';
import 'package:animal/features/anime/data/anilist_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for [AniListApi].
final anilistApiProvider = Provider<AniListApi>((ref) {
  return AniListApi(logger: ref.watch(loggerProvider));
});

/// Fetches weekly airing schedule from AniList.
/// Returns map of day -> list of schedule entries.
final anilistWeeklyScheduleProvider =
    FutureProvider<Map<String, List<AniListScheduleEntry>>>((ref) async {
  final api = ref.watch(anilistApiProvider);
  return api.getWeeklyAiringSchedule();
});

/// Fetches characters + staff from AniList by MAL ID.
final anilistPeopleProvider =
    FutureProvider.family<AniListAnimePeople, int>((ref, malId) async {
  final api = ref.watch(anilistApiProvider);
  return api.getCharactersAndStaff(malId);
});

/// Fetches character detail from AniList by character ID.
final anilistCharacterDetailProvider =
    FutureProvider.family<AniListCharacterDetail, int>(
        (ref, characterId) async {
  final api = ref.watch(anilistApiProvider);
  return api.getCharacterDetail(characterId);
});

/// Fetches staff detail from AniList by staff ID.
final anilistStaffDetailProvider =
    FutureProvider.family<AniListStaffDetail, int>((ref, staffId) async {
  final api = ref.watch(anilistApiProvider);
  return api.getStaffDetail(staffId);
});

/// Fetches next airing schedule for an anime by MAL ID.
final anilistNextAiringProvider =
    FutureProvider.family<AniListNextAiring?, int>((ref, malId) async {
  final api = ref.watch(anilistApiProvider);
  return api.getNextAiringSchedule(malId);
});

/// Fetches external links for an anime by MAL ID.
final anilistExternalLinksProvider =
    FutureProvider.family<List<AniListExternalLink>, int>((ref, malId) async {
  final api = ref.watch(anilistApiProvider);
  return api.getExternalLinks(malId);
});
