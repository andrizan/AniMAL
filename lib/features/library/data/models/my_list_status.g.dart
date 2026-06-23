// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_list_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MyListStatus _$MyListStatusFromJson(Map<String, dynamic> json) =>
    _MyListStatus(
      status: $enumDecode(_$WatchStatusEnumMap, json['status']),
      numEpisodesWatched: (json['num_episodes_watched'] as num?)?.toInt(),
      score: (json['score'] as num?)?.toInt(),
      isRewatching: json['is_rewatching'] as bool?,
      updatedAt: json['updated_at'] as String?,
      numTimesRewatched: (json['num_times_rewatched'] as num?)?.toInt(),
      priority: (json['priority'] as num?)?.toInt(),
      rewatchValue: (json['rewatch_value'] as num?)?.toInt(),
      comments: json['comments'] as String?,
    );

Map<String, dynamic> _$MyListStatusToJson(_MyListStatus instance) =>
    <String, dynamic>{
      'status': _$WatchStatusEnumMap[instance.status]!,
      'num_episodes_watched': instance.numEpisodesWatched,
      'score': instance.score,
      'is_rewatching': instance.isRewatching,
      'updated_at': instance.updatedAt,
      'num_times_rewatched': instance.numTimesRewatched,
      'priority': instance.priority,
      'rewatch_value': instance.rewatchValue,
      'comments': instance.comments,
    };

const _$WatchStatusEnumMap = {
  WatchStatus.watching: 'watching',
  WatchStatus.completed: 'completed',
  WatchStatus.onHold: 'on_hold',
  WatchStatus.dropped: 'dropped',
  WatchStatus.planToWatch: 'plan_to_watch',
};
