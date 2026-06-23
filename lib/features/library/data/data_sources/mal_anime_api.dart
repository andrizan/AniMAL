import 'package:animal/features/library/data/models/anime.dart';
import 'package:animal/features/library/data/models/anime_detail.dart';
import 'package:animal/features/library/data/models/mal_user.dart';
import 'package:animal/features/library/data/models/season.dart';
import 'package:animal/features/library/data/models/watch_status.dart';
import 'package:dio/dio.dart';

/// Low-level API client for MyAnimeList anime endpoints.
class MalAnimeApi {
  const MalAnimeApi(this._dio);

  final Dio _dio;

  /// Default fields to request for list results.
  static const _listFields =
      'id,title,main_picture,mean,rank,popularity,num_episodes,status,'
      'rating,media_type,alternative_titles,genres';

  /// Extended fields for detail results.
  static const _detailFields =
      '$_listFields,synopsis,start_date,end_date,media_type,source,'
      'num_scoring_users,genres,broadcast,related_anime,my_list_status';

  /// Fields requested when fetching the user's anime list.
  static const _userListFields = '$_listFields,broadcast,my_list_status';

  /// Fields requested when building the seasonal schedule.
  static const _scheduleFields = '$_listFields,broadcast,start_season';

  /// Search anime by [query].
  Future<List<Anime>> searchAnime(String query, {int limit = 20}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/anime',
      queryParameters: {
        'q': query,
        'limit': limit,
        'fields': _listFields,
      },
    );

    final data = _extractList(response.data, 'data') ?? [];
    return data
        .map((e) => Anime.fromJson(
              (e as Map<String, dynamic>)['node'] as Map<String, dynamic>,
            ))
        .toList();
  }

  /// Fetch the seasonal anime ranking for [year] / [season].
  ///
  /// Includes broadcast info so the result can be used to build a
  /// weekly schedule ("jadwal anime").
  Future<List<Anime>> getSeasonalAnime({
    required int year,
    required Season season,
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/anime/season/$year/${season.value}',
      queryParameters: {
        'limit': limit,
        'offset': offset,
        'fields': _scheduleFields,
      },
    );

    final data = _extractList(response.data, 'data') ?? [];
    return data
        .map((e) => Anime.fromJson(
              (e as Map<String, dynamic>)['node'] as Map<String, dynamic>,
            ))
        .toList();
  }

  /// Fetch detailed info about a single anime.
  Future<AnimeDetail?> getAnimeDetail(int animeId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/anime/$animeId',
      queryParameters: {'fields': _detailFields},
    );

    final map = _extractMap(response.data);
    if (map == null) return null;
    return AnimeDetail.fromJson(map);
  }

  /// Get the top anime ranking.
  Future<List<Anime>> getAnimeRanking({
    String rankingType = 'all',
    int limit = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/anime/ranking',
      queryParameters: {
        'ranking_type': rankingType,
        'limit': limit,
        'fields': _listFields,
      },
    );

    final data = _extractList(response.data, 'data') ?? [];
    return data
        .map((e) => Anime.fromJson(
              (e as Map<String, dynamic>)['node'] as Map<String, dynamic>,
            ))
        .toList();
  }

  /// Fetch the current user's anime list filtered by [status].
  ///
  /// Endpoint: `GET /users/@me/animelist`
  Future<List<Anime>> getUserAnimeList({
    WatchStatus status = WatchStatus.watching,
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/users/@me/animelist',
      queryParameters: {
        'status': status.value,
        'limit': limit,
        'offset': offset,
        'fields': _userListFields,
      },
    );

    final data = _extractList(response.data, 'data') ?? [];
    return data
        .map((e) => Anime.fromJson(
              (e as Map<String, dynamic>)['node'] as Map<String, dynamic>,
            ))
        .toList();
  }

  /// Delete [animeId] from the current user's anime list.
  ///
  /// Endpoint: `DELETE /anime/{anime_id}/my_list_status`
  Future<void> deleteAnimeFromList(int animeId) async {
    await _dio.delete<void>(
      '/anime/$animeId/my_list_status',
    );
  }

  /// Update the current user's list status for [animeId].
  ///
  /// Only the provided parameters are sent; `null` values are
  /// omitted so the server leaves them untouched.
  ///
  /// Endpoint: `PUT /anime/{anime_id}/my_list_status`
  Future<void> updateAnimeListStatus(
    int animeId, {
    WatchStatus? status,
    int? numWatchedEpisodes,
    int? score,
    bool? isRewatching,
    int? priority,
    int? rewatchValue,
    String? comments,
  }) async {
    final data = <String, dynamic>{};
    if (status != null) data['status'] = status.value;
    if (numWatchedEpisodes != null) {
      data['num_watched_episodes'] = numWatchedEpisodes;
    }
    if (score != null) data['score'] = score;
    if (isRewatching != null) data['is_rewatching'] = isRewatching;
    if (priority != null) data['priority'] = priority;
    if (rewatchValue != null) data['rewatch_value'] = rewatchValue;
    if (comments != null) data['comments'] = comments;

    await _dio.put<void>(
      '/anime/$animeId/my_list_status',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  /// Fetch the current user's profile info.
  ///
  /// Endpoint: `GET /users/@me`
  Future<MalUser?> getUserInfo() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/users/@me',
      queryParameters: {
        'fields': 'anime_statistics',
      },
    );

    final map = _extractMap(response.data);
    if (map == null) return null;
    return MalUser.fromJson(map);
  }

  List<dynamic>? _extractList(dynamic data, String key) {
    if (data is! Map<String, dynamic>) return null;
    final list = data[key];
    if (list is! List<dynamic>) return null;
    return list;
  }

  Map<String, dynamic>? _extractMap(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    return data;
  }
}
