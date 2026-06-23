import 'package:animal/data/mal/mal_api_client.dart';
import 'package:animal/features/profile/domain/entities/user_profile_entity.dart';
import 'package:animal/features/profile/domain/repositories/profile_repository.dart';
import 'package:animal/core/logger/app_logger.dart';
import 'package:logger/logger.dart';

final class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required MalApiClient malApi,
    Logger? logger,
  })  : _malApi = malApi,
        _logger = logger ?? appLogger;

  final MalApiClient _malApi;
  final Logger _logger;

  @override
  Future<UserProfileEntity?> getUserProfile() async {
    try {
      final user = await _malApi.getUserInfo();
      if (user == null) return null;

      final stats = user.animeStatistics;
      return UserProfileEntity(
        id: user.id,
        name: user.name,
        picture: user.picture,
        joinedAt: user.joinedAt,
        numItems: stats?.numItems,
        numEpisodes: stats?.numEpisodes,
        daysWatched: stats?.numDays,
        meanScore: stats?.meanScore,
        watching: stats?.numItemsWatching,
        completed: stats?.numItemsCompleted,
        onHold: stats?.numItemsOnHold,
        dropped: stats?.numItemsDropped,
        planToWatch: stats?.numItemsPlanToWatch,
      );
    } on Exception catch (e) {
      _logger.e('getUserProfile failed', error: e);
      return null;
    }
  }
}
