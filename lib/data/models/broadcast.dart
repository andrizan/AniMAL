import 'package:freezed_annotation/freezed_annotation.dart';

part 'broadcast.freezed.dart';
part 'broadcast.g.dart';

@freezed
sealed class Broadcast with _$Broadcast {
  const factory Broadcast({
    @JsonKey(name: 'day_of_week') String? dayOfWeek,
    @JsonKey(name: 'start_time') String? startTime,
  }) = _Broadcast;

  factory Broadcast.fromJson(Map<String, dynamic> json) =>
      _$BroadcastFromJson(json);
}
