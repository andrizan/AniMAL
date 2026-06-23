import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum WatchStatus {
  watching('watching'),
  completed('completed'),
  onHold('on_hold'),
  dropped('dropped'),
  planToWatch('plan_to_watch');

  const WatchStatus(this.value);

  final String value;

  String get label => switch (this) {
        WatchStatus.watching => 'Watching',
        WatchStatus.completed => 'Completed',
        WatchStatus.onHold => 'On Hold',
        WatchStatus.dropped => 'Dropped',
        WatchStatus.planToWatch => 'Plan to Watch',
      };
}
