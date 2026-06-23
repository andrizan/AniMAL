import 'package:freezed_annotation/freezed_annotation.dart';

part 'mal_user.freezed.dart';
part 'mal_user.g.dart';

@freezed
sealed class MalUser with _$MalUser {
  const factory MalUser({
    required int id,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'picture') String? picture,
    @JsonKey(name: 'gender') String? gender,
    @JsonKey(name: 'birthday') String? birthday,
    @JsonKey(name: 'location') String? location,
    @JsonKey(name: 'joined_at') String? joinedAt,
    @JsonKey(name: 'anime_statistics') AnimeStatistics? animeStatistics,
  }) = _MalUser;

  factory MalUser.fromJson(Map<String, dynamic> json) =>
      _$MalUserFromJson(json);
}

@freezed
sealed class AnimeStatistics with _$AnimeStatistics {
  const factory AnimeStatistics({
    @JsonKey(name: 'num_items_watching') int? numItemsWatching,
    @JsonKey(name: 'num_items_completed') int? numItemsCompleted,
    @JsonKey(name: 'num_items_on_hold') int? numItemsOnHold,
    @JsonKey(name: 'num_items_dropped') int? numItemsDropped,
    @JsonKey(name: 'num_items_plan_to_watch') int? numItemsPlanToWatch,
    @JsonKey(name: 'num_items') int? numItems,
    @JsonKey(name: 'num_days_watched') double? numDaysWatched,
    @JsonKey(name: 'num_days_watching') double? numDaysWatching,
    @JsonKey(name: 'num_days_completed') double? numDaysCompleted,
    @JsonKey(name: 'num_days_on_hold') double? numDaysOnHold,
    @JsonKey(name: 'num_days_dropped') double? numDaysDropped,
    @JsonKey(name: 'num_days') double? numDays,
    @JsonKey(name: 'mean_score') double? meanScore,
    @JsonKey(name: 'num_episodes') int? numEpisodes,
  }) = _AnimeStatistics;

  factory AnimeStatistics.fromJson(Map<String, dynamic> json) =>
      _$AnimeStatisticsFromJson(json);
}
