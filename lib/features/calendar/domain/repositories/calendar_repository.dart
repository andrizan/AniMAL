import 'package:animal/features/calendar/domain/entities/schedule_params.dart';
import 'package:animal/features/home/domain/entities/anime_entity.dart';

abstract interface class CalendarRepository {
  Future<List<AnimeEntity>> getSchedule(ScheduleParams params);
}
