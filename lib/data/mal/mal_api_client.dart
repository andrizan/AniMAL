import 'package:animal/core/constants/mal_endpoints.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/mal_user.dart';
import 'package:animal/data/models/season.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:dio/dio.dart';

class MalApiClient {
  const MalApiClient(this._dio);

  final Dio _dio;

  static const _listFields =
      'id,title,main_picture,mean,rank,popularity,num_episodes,status,'
      'rating,media_type,alternative_titles,genres';

  static const _detailFields =
      '$_listFields,synopsis,start_date,end_date,media_type,source,'
      'num_scoring_users,genres,broadcast,related_anime,my_list_status,'
      'start_season,studios,average_episode_duration';

  static const _userListFields = '$_listFields,broadcast,my_list_status';

  static const _scheduleFields = '$_listFields,broadcast,start_season';

  Future<List<Anime>> searchAnime(String query, {int limit = 20}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      MalEndpoints.search(),
      queryParameters: {'q': query, 'limit': limit, 'fields': _listFields},
    );
    final data = _extractList(response.data, 'data') ?? [];
    return data
        .map(
          (e) => Anime.fromJson(
            (e as Map<String, dynamic>)['node'] as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<List<Anime>> getSeasonalAnime({
    required int year,
    required Season season,
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      MalEndpoints.seasonal(year, season.value),
      queryParameters: {
        'limit': limit,
        'offset': offset,
        'fields': _scheduleFields,
      },
    );
    final data = _extractList(response.data, 'data') ?? [];
    return data
        .map(
          (e) => Anime.fromJson(
            (e as Map<String, dynamic>)['node'] as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<AnimeDetail?> getAnimeDetail(int animeId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      MalEndpoints.animeDetail(animeId),
      queryParameters: {'fields': _detailFields},
    );
    final map = _extractMap(response.data);
    if (map == null) return null;
    return AnimeDetail.fromJson(map);
  }

  Future<List<Anime>> getAnimeRanking({
    String rankingType = 'all',
    int limit = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      MalEndpoints.ranking(),
      queryParameters: {
        'ranking_type': rankingType,
        'limit': limit,
        'fields': _listFields,
      },
    );
    final data = _extractList(response.data, 'data') ?? [];
    return data
        .map(
          (e) => Anime.fromJson(
            (e as Map<String, dynamic>)['node'] as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<List<Anime>> getUserAnimeList({
    WatchStatus status = WatchStatus.watching,
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      MalEndpoints.animeList,
      queryParameters: {
        'status': status.value,
        'limit': limit,
        'offset': offset,
        'fields': _userListFields,
      },
    );
    final data = _extractList(response.data, 'data') ?? [];
    return data
        .map(
          (e) => Anime.fromJson(
            (e as Map<String, dynamic>)['node'] as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> deleteAnimeFromList(int animeId) async {
    await _dio.delete<void>(MalEndpoints.myListStatus(animeId));
  }

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
    if (numWatchedEpisodes != null)
      data['num_watched_episodes'] = numWatchedEpisodes;
    if (score != null) data['score'] = score;
    if (isRewatching != null) data['is_rewatching'] = isRewatching;
    if (priority != null) data['priority'] = priority;
    if (rewatchValue != null) data['rewatch_value'] = rewatchValue;
    if (comments != null) data['comments'] = comments;
    await _dio.put<void>(
      MalEndpoints.myListStatus(animeId),
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  Future<MalUser?> getUserInfo() async {
    final response = await _dio.get<Map<String, dynamic>>(
      MalEndpoints.userInfo,
      queryParameters: {'fields': 'anime_statistics'},
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
