import 'package:animal/data/models/watch_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_list_status.freezed.dart';
part 'my_list_status.g.dart';

@freezed
sealed class MyListStatus with _$MyListStatus {
  const factory MyListStatus({
    required WatchStatus status,
    @JsonKey(name: 'num_episodes_watched') int? numEpisodesWatched,
    int? score,
    @JsonKey(name: 'is_rewatching') bool? isRewatching,
    @JsonKey(name: 'updated_at') String? updatedAt,
    @JsonKey(name: 'num_times_rewatched') int? numTimesRewatched,
    int? priority,
    @JsonKey(name: 'rewatch_value') int? rewatchValue,
    String? comments,
  }) = _MyListStatus;

  factory MyListStatus.fromJson(Map<String, dynamic> json) =>
      _$MyListStatusFromJson(json);
}
