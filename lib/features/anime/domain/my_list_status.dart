import 'package:animal/features/anime/domain/anime.dart' show Anime;
import 'package:animal/features/anime/domain/watch_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_list_status.freezed.dart';
part 'my_list_status.g.dart';

/// The user's list status for a single anime.
///
/// Returned inside the `my_list_status` field of an [Anime] when
/// requesting the user's anime list or anime details.
@freezed
sealed class MyListStatus with _$MyListStatus {
  const factory MyListStatus({
    required WatchStatus status,

    /// Number of episodes the user has watched.
    @JsonKey(name: 'num_episodes_watched') int? numEpisodesWatched,

    /// User's score (0–10), 0 means no score.
    int? score,

    /// Whether the user is currently rewatching.
    @JsonKey(name: 'is_rewatching') bool? isRewatching,

    /// ISO-8601 timestamp of the last update.
    @JsonKey(name: 'updated_at') String? updatedAt,

    /// How many times the user has rewatched the anime.
    @JsonKey(name: 'num_times_rewatched') int? numTimesRewatched,

    /// Priority (0–2).
    int? priority,

    /// Rewatch value (0–5).
    @JsonKey(name: 'rewatch_value') int? rewatchValue,

    /// Free-text notes the user attached to the entry.
    String? comments,
  }) = _MyListStatus;

  factory MyListStatus.fromJson(Map<String, dynamic> json) =>
      _$MyListStatusFromJson(json);
}
