import 'package:freezed_annotation/freezed_annotation.dart';

part 'broadcast.freezed.dart';
part 'broadcast.g.dart';

/// Broadcast schedule info for an anime.
///
/// Used to build the "jadwal anime" (anime schedule) view by
/// grouping anime by their broadcast day & time.
@freezed
sealed class Broadcast with _$Broadcast {
  const factory Broadcast({
    /// Day of the week, e.g. `monday`, `tuesday`, … `sunday`.
    @JsonKey(name: 'day_of_week') String? dayOfWeek,

    /// Start time in `HH:MM` (24h, JST) format, e.g. `01:35`.
    @JsonKey(name: 'start_time') String? startTime,
  }) = _Broadcast;

  factory Broadcast.fromJson(Map<String, dynamic> json) =>
      _$BroadcastFromJson(json);
}
