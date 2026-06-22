import 'package:animal/core/providers.dart';
import 'package:animal/features/anime/data/anilist_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/providers/future_provider.dart';

/// Provider for [AniListApi].
final anilistApiProvider = Provider<AniListApi>((ref) {
  return AniListApi(logger: ref.watch(loggerProvider));
});

/// Fetches characters + staff from AniList by MAL ID.
final FutureProviderFamily<AniListAnimePeople, int> anilistPeopleProvider =
    FutureProvider.family<AniListAnimePeople, int>((ref, malId) async {
  final api = ref.watch(anilistApiProvider);
  return api.getCharactersAndStaff(malId);
});

/// Fetches character detail from AniList by character ID.
final FutureProviderFamily<AniListCharacterDetail, int> anilistCharacterDetailProvider =
    FutureProvider.family<AniListCharacterDetail, int>(
        (ref, characterId) async {
  final api = ref.watch(anilistApiProvider);
  return api.getCharacterDetail(characterId);
});

/// Fetches staff detail from AniList by staff ID.
final FutureProviderFamily<AniListStaffDetail, int> anilistStaffDetailProvider =
    FutureProvider.family<AniListStaffDetail, int>((ref, staffId) async {
  final api = ref.watch(anilistApiProvider);
  return api.getStaffDetail(staffId);
});

/// Fetches weekly airing schedule from AniList.
final anilistAiringScheduleProvider =
    FutureProvider<List<AniListScheduleEntry>>((ref) async {
  final api = ref.watch(anilistApiProvider);
  return api.getWeeklyAiringSchedule();
});
