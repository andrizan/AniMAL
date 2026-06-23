// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mal_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MalUser _$MalUserFromJson(Map<String, dynamic> json) => _MalUser(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  picture: json['picture'] as String?,
  gender: json['gender'] as String?,
  birthday: json['birthday'] as String?,
  location: json['location'] as String?,
  joinedAt: json['joined_at'] as String?,
  animeStatistics: json['anime_statistics'] == null
      ? null
      : AnimeStatistics.fromJson(
          json['anime_statistics'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$MalUserToJson(_MalUser instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'picture': instance.picture,
  'gender': instance.gender,
  'birthday': instance.birthday,
  'location': instance.location,
  'joined_at': instance.joinedAt,
  'anime_statistics': instance.animeStatistics,
};

_AnimeStatistics _$AnimeStatisticsFromJson(Map<String, dynamic> json) =>
    _AnimeStatistics(
      numItemsWatching: (json['num_items_watching'] as num?)?.toInt(),
      numItemsCompleted: (json['num_items_completed'] as num?)?.toInt(),
      numItemsOnHold: (json['num_items_on_hold'] as num?)?.toInt(),
      numItemsDropped: (json['num_items_dropped'] as num?)?.toInt(),
      numItemsPlanToWatch: (json['num_items_plan_to_watch'] as num?)?.toInt(),
      numItems: (json['num_items'] as num?)?.toInt(),
      numDaysWatched: (json['num_days_watched'] as num?)?.toDouble(),
      numDaysWatching: (json['num_days_watching'] as num?)?.toDouble(),
      numDaysCompleted: (json['num_days_completed'] as num?)?.toDouble(),
      numDaysOnHold: (json['num_days_on_hold'] as num?)?.toDouble(),
      numDaysDropped: (json['num_days_dropped'] as num?)?.toDouble(),
      numDays: (json['num_days'] as num?)?.toDouble(),
      meanScore: (json['mean_score'] as num?)?.toDouble(),
      numEpisodes: (json['num_episodes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AnimeStatisticsToJson(_AnimeStatistics instance) =>
    <String, dynamic>{
      'num_items_watching': instance.numItemsWatching,
      'num_items_completed': instance.numItemsCompleted,
      'num_items_on_hold': instance.numItemsOnHold,
      'num_items_dropped': instance.numItemsDropped,
      'num_items_plan_to_watch': instance.numItemsPlanToWatch,
      'num_items': instance.numItems,
      'num_days_watched': instance.numDaysWatched,
      'num_days_watching': instance.numDaysWatching,
      'num_days_completed': instance.numDaysCompleted,
      'num_days_on_hold': instance.numDaysOnHold,
      'num_days_dropped': instance.numDaysDropped,
      'num_days': instance.numDays,
      'mean_score': instance.meanScore,
      'num_episodes': instance.numEpisodes,
    };
