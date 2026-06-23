import 'package:json_annotation/json_annotation.dart';

/// Status of an anime in the user's MyAnimeList list.
///
/// The [value] field holds the raw string used by the MAL API
/// (e.g. `on_hold`), and is also the value used during JSON
/// serialization thanks to [JsonEnum].
@JsonEnum(valueField: 'value')
enum WatchStatus {
  watching('watching'),
  completed('completed'),
  onHold('on_hold'),
  dropped('dropped'),
  planToWatch('plan_to_watch');

  const WatchStatus(this.value);

  /// Raw string sent to / received from the MAL API.
  final String value;

  /// Human-readable label for display in the UI.
  String get label => switch (this) {
        WatchStatus.watching => 'Watching',
        WatchStatus.completed => 'Completed',
        WatchStatus.onHold => 'On Hold',
        WatchStatus.dropped => 'Dropped',
        WatchStatus.planToWatch => 'Plan to Watch',
      };
}
