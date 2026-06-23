import 'package:animal/data/mal/mal_api_client.dart';
import 'package:animal/features/calendar/domain/entities/schedule_params.dart';
import 'package:animal/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:animal/features/home/domain/entities/anime_entity.dart';
import 'package:logger/logger.dart';

final class CalendarRepositoryImpl implements CalendarRepository {
  CalendarRepositoryImpl({
    required MalApiClient malApi,
    Logger? logger,
  })  : _malApi = malApi,
        _logger = logger ?? Logger();

  final MalApiClient _malApi;
  final Logger _logger;

  @override
  Future<List<AnimeEntity>> getSchedule(ScheduleParams params) async {
    try {
      final result = await _malApi.getSeasonalAnime(
        year: params.year,
        season: params.season,
      );
      return result.map(AnimeEntity.fromModel).toList();
    } on Exception catch (e) {
      _logger.e('getSchedule failed', error: e);
      return [];
    }
  }
}
