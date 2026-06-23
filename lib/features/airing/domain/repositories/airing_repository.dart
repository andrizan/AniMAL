import 'package:animal/features/airing/domain/entities/airing_entry.dart';

abstract interface class AiringRepository {
  Future<Map<String, List<AiringEntry>>> getWeeklySchedule();
  void invalidateCache();
}
