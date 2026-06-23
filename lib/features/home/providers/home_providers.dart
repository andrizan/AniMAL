import 'package:animal/core/providers.dart';
import 'package:animal/data/mal/mal_api_client.dart';
import 'package:animal/data/models/season.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/features/home/data/home_repository_impl.dart';
import 'package:animal/features/home/domain/entities/anime_entity.dart';
import 'package:animal/features/home/domain/repositories/home_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(
    malApi: MalApiClient(ref.watch(dioProvider)),
    logger: ref.watch(loggerProvider),
  );
});

final currentSeasonProvider = Provider<Season>((ref) {
  return Season.fromDate(DateTime.now());
});

final trendingAnimeProvider = FutureProvider<List<AnimeEntity>>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getAnimeRanking(limit: 20);
});

final seasonalAnimeProvider =
    FutureProvider.family<List<AnimeEntity>, ({int year, Season season})>(
      (ref, params) async {
        final repo = ref.watch(homeRepositoryProvider);
        return repo.getSeasonalAnime(year: params.year, season: params.season);
      },
    );

final userAnimeListProvider =
    FutureProvider.family<List<AnimeEntity>, WatchStatus>((ref, status) async {
      final repo = ref.watch(homeRepositoryProvider);
      return repo.getUserAnimeList(status: status.value);
    });
