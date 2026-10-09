import 'package:animal/data/models/mal_user.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/features/profile/domain/entities/profile_insights.dart';
import 'package:animal/features/profile/domain/usecases/get_profile_insights.dart';
import 'package:animal/shared/providers/anime_list_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches the current user's MAL profile info.
final userInfoProvider = FutureProvider<MalUser?>((ref) async {
  final repo = ref.watch(animeRepositoryProvider);
  return repo.getUserInfo();
});

/// Aggregates the whole personal list into the numbers behind the charts.
final profileInsightsProvider = FutureProvider<ProfileInsights>((ref) async {
  final lists = await Future.wait([
    for (final status in WatchStatus.values)
      ref.watch(userAnimeListProvider(status).future),
  ]);
  return const GetProfileInsights()(lists.expand((list) => list));
});
