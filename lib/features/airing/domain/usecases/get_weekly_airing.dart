import 'package:animal/features/airing/domain/entities/airing_entry.dart';
import 'package:animal/features/airing/domain/repositories/airing_repository.dart';

final class GetWeeklyAiring {
  const GetWeeklyAiring(this._repository);

  final AiringRepository _repository;

  Future<Map<String, List<AiringEntry>>> call() {
    return _repository.getWeeklySchedule();
  }
}
