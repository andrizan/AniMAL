import 'package:animal/core/providers.dart';
import 'package:animal/data/mal/mal_api_client.dart';
import 'package:animal/data/models/season.dart';
import 'package:animal/features/calendar/data/calendar_repository_impl.dart';
import 'package:animal/features/calendar/domain/entities/schedule_params.dart';
import 'package:animal/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:animal/features/home/domain/entities/anime_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepositoryImpl(
    malApi: MalApiClient(ref.watch(dioProvider)),
    logger: ref.watch(loggerProvider),
  );
});

final calendarScheduleProvider =
    FutureProvider.family<List<AnimeEntity>, ScheduleParams>(
  (ref, params) async {
    final repo = ref.watch(calendarRepositoryProvider);
    return repo.getSchedule(params);
  },
);

final availableSeasonsProvider = Provider<List<Season>>((ref) {
  return Season.values;
});

final currentYearProvider = Provider<int>((ref) {
  return DateTime.now().year;
});
