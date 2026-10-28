import 'dart:async';

import 'package:animal/core/constants/mal_endpoints.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for [AniListClient].
final anilistApiProvider = Provider<AniListClient>((ref) {
  return AniListClient(
    cache: ref.watch(anilistCacheProvider),
    ref: ref,
    logger: ref.watch(loggerProvider),
  );
});

final anilistCharacterDetailProvider = FutureProvider.autoDispose
    .family<AniListCharacterDetail, int>((ref, characterId) async {
      final api = ref.watch(anilistApiProvider);
      return api.getCharacterDetail(characterId);
    });

final anilistStaffDetailProvider = FutureProvider.autoDispose
    .family<AniListStaffDetail, int>((ref, staffId) async {
      final api = ref.watch(anilistApiProvider);
      return api.getStaffDetail(staffId);
    });

final anilistAnimeExtraProvider = FutureProvider.autoDispose
    .family<AniListAnimeExtra, int>((ref, malId) async {
      final api = ref.watch(anilistApiProvider);
      final extra = await api.getAnimeExtraInfo(malId);
      final now = DateTime.now().toUtc();
      if (extra.nextAiring?.airingAt.toUtc() case final at?
          when at.isAfter(now)) {
        final timer = Timer(
          at.difference(now) + ApiConstants.airedRefreshDelay,
          ref.invalidateSelf,
        );
        ref.onDispose(timer.cancel);
      }
      return extra;
    });

final anilistStudioDetailProvider = FutureProvider.autoDispose
    .family<AniListStudioDetail, int>((ref, studioId) async {
      final api = ref.watch(anilistApiProvider);
      return api.getStudioDetail(studioId);
    });
