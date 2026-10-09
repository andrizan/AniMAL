import 'package:animal/core/constants/mal_endpoints.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/mal_user.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/season.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:dio/dio.dart';

class MalApiClient {
  const MalApiClient(this._dio);

  final Dio _dio;

  static const _listFields =
      'id,title,main_picture,mean,rank,popularity,num_episodes,status,'
      'rating,media_type,alternative_titles,genres,my_list_status';

  static const _detailFields =
      '$_listFields,synopsis,start_date,end_date,media_type,source,'
      'num_scoring_users,genres,broadcast,related_anime,my_list_status,'
      'start_season,average_episode_duration';

  static const _userListFields = '$_listFields,broadcast,my_list_status';

  static const _scheduleFields = '$_listFields,broadcast,start_season';

  Future<List<Anime>> searchAnime(String query, {int limit = 20}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      MalEndpoints.search(),
      queryParameters: {
        'q': query,
        'limit': limit,
        'fields': _listFields,
        'nsfw': true,
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
        'nsfw': true,
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
      queryParameters: {'fields': _detailFields, 'nsfw': true},
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
        'nsfw': true,
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

  Future<List<Anime>> getUndatedUpcomingAnime() async {
    final undated = <Anime>[];
    for (var page = 0; page < ApiConstants.malUpcomingMaxPages; page++) {
      final response = await _dio.get<Map<String, dynamic>>(
        MalEndpoints.ranking(),
        queryParameters: {
          'ranking_type': 'upcoming',
          'limit': ApiConstants.malRankingPageSize,
          'offset': page * ApiConstants.malRankingPageSize,
          'fields': '$_listFields,start_date',
          'nsfw': true,
        },
      );
      final data = _extractList(response.data, 'data') ?? [];
      for (final e in data) {
        final node =
            (e as Map<String, dynamic>)['node'] as Map<String, dynamic>;
        if (node['start_date'] == null) {
          undated.add(Anime.fromJson(node));
        }
      }
      final paging = response.data?['paging'];
      final hasNext =
          data.isNotEmpty &&
          paging is Map<String, dynamic> &&
          paging['next'] != null;
      if (!hasNext) {
        break;
      }
    }
    return undated;
  }

  Future<List<Anime>> getUserAnimeList({
    WatchStatus status = WatchStatus.watching,
  }) async {
    final byId = <int, Anime>{};
    var offset = 0;
    bool hasNext;
    do {
      final response = await _dio.get<Map<String, dynamic>>(
        MalEndpoints.animeList,
        queryParameters: {
          'status': status.value,
          'limit': ApiConstants.malUserListPageSize,
          'offset': offset,
          'fields': _userListFields,
          'nsfw': true,
        },
      );
      final data = _extractList(response.data, 'data') ?? [];
      for (final e in data) {
        final anime = Anime.fromJson(
          (e as Map<String, dynamic>)['node'] as Map<String, dynamic>,
        );
        byId[anime.id] = anime;
      }
      offset += data.length;
      final paging = response.data?['paging'];
      hasNext =
          data.isNotEmpty &&
          paging is Map<String, dynamic> &&
          paging['next'] != null;
    } while (hasNext);
    return byId.values.toList();
  }

  Future<void> deleteAnimeFromList(int animeId) async {
    await _dio.delete<void>(MalEndpoints.myListStatus(animeId));
  }

  Future<MyListStatus> updateAnimeListStatus(
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
    final response = await _dio.put<Map<String, dynamic>>(
      MalEndpoints.myListStatus(animeId),
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final body = response.data;
    if (body == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Empty response body',
      );
    }
    return MyListStatus.fromJson(body);
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
