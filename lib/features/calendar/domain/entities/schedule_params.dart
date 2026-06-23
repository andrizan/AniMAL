import 'package:animal/data/models/season.dart';

final class ScheduleParams {
  const ScheduleParams({required this.year, required this.season});

  final int year;
  final Season season;

  @override
  bool operator ==(Object other) =>
      other is ScheduleParams && other.year == year && other.season == season;

  @override
  int get hashCode => Object.hash(year, season);
}
