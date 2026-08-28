import 'dart:convert';

import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/broadcast.dart';
import 'package:animal/data/models/mal_user.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/watch_status.dart';

/// Pure mappers between model objects and SQLite row maps.
///
/// All methods return or accept plain `Map<String, Object?>` so the mappers
/// stay decoupled from the sqflite cursor layer.
class CacheMappers {
  const CacheMappers();

  // ---------- Anime ----------

  Map<String, Object?> animeToRow(Anime a) {
    return <String, Object?>{
      'mal_id': a.id,
      'title': a.title,
      'picture_medium': a.mainPicture?.medium,
      'picture_large': a.mainPicture?.large,
      'alt_title_en': a.alternativeTitles?.en,
      'alt_title_ja': a.alternativeTitles?.ja,
      'alt_title_synonyms_json': a.alternativeTitles?.synonyms == null
          ? null
          : jsonEncode(a.alternativeTitles!.synonyms),
      'mean': a.mean,
      'rank': a.rank,
      'popularity': a.popularity,
      'num_episodes': a.numEpisodes,
      'status': a.status,
      'rating': a.rating,
      'media_type': a.mediaType,
      'broadcast_day_of_week': a.broadcast?.dayOfWeek,
      'broadcast_start_time': a.broadcast?.startTime,
      'my_list_status_json': a.myListStatus == null
          ? null
          : jsonEncode(_myListStatusToJson(a.myListStatus!)),
      'my_list_status_user': a.myListStatus?.status.value,
    };
  }

  Anime animeFromRow(
    Map<String, Object?> row, {
    List<Genre> genres = const [],
  }) {
    return Anime(
      id: row['mal_id']! as int,
      title: row['title']! as String,
      mainPicture: MainPicture(
        medium: row['picture_medium'] as String?,
        large: row['picture_large'] as String?,
      ),
      mean: (row['mean'] as num?)?.toDouble(),
      rank: row['rank'] as int?,
      popularity: row['popularity'] as int?,
      numEpisodes: row['num_episodes'] as int?,
      status: row['status'] as String?,
      rating: row['rating'] as String?,
      mediaType: row['media_type'] as String?,
      broadcast:
          row['broadcast_day_of_week'] == null &&
              row['broadcast_start_time'] == null
          ? null
          : Broadcast(
              dayOfWeek: row['broadcast_day_of_week'] as String?,
              startTime: row['broadcast_start_time'] as String?,
            ),
      alternativeTitles: _altTitlesFromRow(row),
      genres: genres,
      myListStatus: _myListStatusFromJsonString(
        row['my_list_status_json'] as String?,
      ),
    );
  }

  AlternativeTitles? _altTitlesFromRow(Map<String, Object?> row) {
    final en = row['alt_title_en'] as String?;
    final ja = row['alt_title_ja'] as String?;
    final synJson = row['alt_title_synonyms_json'] as String?;
    if (en == null && ja == null && synJson == null) return null;
    return AlternativeTitles(
      en: en,
      ja: ja,
      synonyms: synJson == null
          ? const <String>[]
          : List<String>.from(jsonDecode(synJson) as List<dynamic>),
    );
  }

  // ---------- Genres ----------

  /// Returns a list of `(mal_id, genre_id)` rows for `anime_genre`, and a list
  /// of unique `(id, name)` rows for `genre` (caller upserts).
  List<int> extractGenreIds(List<Genre> genres) =>
      genres.map((g) => g.id).toList(growable: false);

  List<Map<String, Object?>> genreRows(List<Genre> genres) {
    return genres
        .map((g) => <String, Object?>{'id': g.id, 'name': g.name})
        .toList(growable: false);
  }

  List<Genre> genresFromIds(
    List<int> ids,
    Map<int, Genre> idToGenre,
  ) {
    return ids
        .map((id) => idToGenre[id])
        .whereType<Genre>()
        .toList(growable: false);
  }

  // ---------- MyListStatus ----------

  Map<String, dynamic> _myListStatusToJson(MyListStatus s) {
    return <String, dynamic>{
      'status': s.status.value,
      'num_episodes_watched': s.numEpisodesWatched,
      'score': s.score,
      'is_rewatching': s.isRewatching,
      'updated_at': s.updatedAt,
      'num_times_rewatched': s.numTimesRewatched,
      'priority': s.priority,
      'rewatch_value': s.rewatchValue,
      'comments': s.comments,
    };
  }

  /// Encodes [status] to a JSON string for storage in `my_list_status_json`.
  String encodeMyListStatus(MyListStatus status) =>
      jsonEncode(_myListStatusToJson(status));

  MyListStatus? _myListStatusFromJsonString(String? raw) {
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return myListStatusFromJson(map);
  }

  MyListStatus myListStatusFromJson(Map<String, dynamic> json) {
    return MyListStatus(
      status: WatchStatus.values.firstWhere(
        (w) => w.value == (json['status'] as String),
        orElse: () => WatchStatus.watching,
      ),
      numEpisodesWatched: json['num_episodes_watched'] as int?,
      score: json['score'] as int?,
      isRewatching: json['is_rewatching'] as bool?,
      updatedAt: json['updated_at'] as String?,
      numTimesRewatched: json['num_times_rewatched'] as int?,
      priority: json['priority'] as int?,
      rewatchValue: json['rewatch_value'] as int?,
      comments: json['comments'] as String?,
    );
  }

  // ---------- AnimeDetail ----------

  Map<String, Object?> animeDetailToExtraRow(AnimeDetail d) {
    return <String, Object?>{
      'mal_id': d.id,
      'synopsis': d.synopsis,
      'source': d.source,
      'start_date': d.startDate,
      'end_date': d.endDate,
      'num_scoring_users': d.numScoringUsers,
      'average_episode_duration': d.averageEpisodeDuration,
      'start_season_year': d.startSeason?.year,
      'start_season_season': d.startSeason?.season,
      'related_anime_json': d.relatedAnime.isEmpty
          ? null
          : jsonEncode(
              d.relatedAnime.map(_relatedAnimeToJson).toList(growable: false),
            ),
    };
  }

  Map<String, dynamic> _relatedAnimeToJson(RelatedAnime r) {
    return <String, dynamic>{
      'node': <String, dynamic>{
        'id': r.node.id,
        'title': r.node.title,
        'main_picture': <String, dynamic>{
          'medium': r.node.mainPicture?.medium,
          'large': r.node.mainPicture?.large,
        },
      },
      'relation_type': r.relationType,
      'relation_type_formatted': r.relationTypeFormatted,
    };
  }

  AnimeDetail animeDetailFromRow(
    Map<String, Object?> row, {
    List<Genre> genres = const [],
  }) {
    final anime = animeFromRow(row, genres: genres);
    final relatedJson = row['related_anime_json'] as String?;
    final related = relatedJson == null
        ? const <RelatedAnime>[]
        : (jsonDecode(relatedJson) as List<dynamic>)
              .map((e) => _relatedAnimeFromJson(e as Map<String, dynamic>))
              .toList(growable: false);
    final seasonYear = row['start_season_year'] as int?;
    final seasonStr = row['start_season_season'] as String?;
    return AnimeDetail(
      id: anime.id,
      title: anime.title,
      mainPicture: anime.mainPicture,
      mean: anime.mean,
      rank: anime.rank,
      popularity: anime.popularity,
      numEpisodes: anime.numEpisodes,
      status: anime.status,
      rating: anime.rating,
      source: row['source'] as String?,
      synopsis: row['synopsis'] as String?,
      startDate: row['start_date'] as String?,
      endDate: row['end_date'] as String?,
      mediaType: anime.mediaType,
      numScoringUsers: row['num_scoring_users'] as int?,
      genres: genres,
      broadcast: anime.broadcast,
      alternativeTitles: anime.alternativeTitles,
      relatedAnime: related,
      myListStatus: anime.myListStatus,
      startSeason: (seasonYear == null || seasonStr == null)
          ? null
          : StartSeason(year: seasonYear, season: seasonStr),
      averageEpisodeDuration: row['average_episode_duration'] as int?,
    );
  }

  RelatedAnime _relatedAnimeFromJson(Map<String, dynamic> json) {
    final node = json['node'] as Map<String, dynamic>;
    final pic = node['main_picture'] as Map<String, dynamic>?;
    return RelatedAnime(
      node: AnimeNode(
        id: node['id'] as int,
        title: node['title'] as String,
        mainPicture: pic == null
            ? null
            : MainPicture(
                medium: pic['medium'] as String?,
                large: pic['large'] as String?,
              ),
      ),
      relationType: json['relation_type'] as String?,
      relationTypeFormatted: json['relation_type_formatted'] as String?,
    );
  }

  // ---------- MalUser ----------

  Map<String, Object?> malUserToRow(MalUser user) {
    return <String, Object?>{
      'cache_key': 'userInfo',
      'id': user.id,
      'name': user.name,
      'picture': user.picture,
      'gender': user.gender,
      'birthday': user.birthday,
      'location': user.location,
      'joined_at': user.joinedAt,
      'stats_json': user.animeStatistics == null
          ? null
          : jsonEncode(_animeStatsToJson(user.animeStatistics!)),
    };
  }

  Map<String, dynamic> _animeStatsToJson(AnimeStatistics s) {
    return <String, dynamic>{
      'num_items_watching': s.numItemsWatching,
      'num_items_completed': s.numItemsCompleted,
      'num_items_on_hold': s.numItemsOnHold,
      'num_items_dropped': s.numItemsDropped,
      'num_items_plan_to_watch': s.numItemsPlanToWatch,
      'num_items': s.numItems,
      'num_days_watched': s.numDaysWatched,
      'num_days_watching': s.numDaysWatching,
      'num_days_completed': s.numDaysCompleted,
      'num_days_on_hold': s.numDaysOnHold,
      'num_days_dropped': s.numDaysDropped,
      'num_days': s.numDays,
      'mean_score': s.meanScore,
      'num_episodes': s.numEpisodes,
    };
  }

  MalUser malUserFromRow(Map<String, Object?> row) {
    final statsJson = row['stats_json'] as String?;
    final statsMap = statsJson == null
        ? null
        : jsonDecode(statsJson) as Map<String, dynamic>;
    return MalUser(
      id: row['id']! as int,
      name: row['name']! as String,
      picture: row['picture'] as String?,
      gender: row['gender'] as String?,
      birthday: row['birthday'] as String?,
      location: row['location'] as String?,
      joinedAt: row['joined_at'] as String?,
      animeStatistics: statsMap == null ? null : _animeStatsFromJson(statsMap),
    );
  }

  AnimeStatistics _animeStatsFromJson(Map<String, dynamic> json) {
    return AnimeStatistics(
      numItemsWatching: json['num_items_watching'] as int?,
      numItemsCompleted: json['num_items_completed'] as int?,
      numItemsOnHold: json['num_items_on_hold'] as int?,
      numItemsDropped: json['num_items_dropped'] as int?,
      numItemsPlanToWatch: json['num_items_plan_to_watch'] as int?,
      numItems: json['num_items'] as int?,
      numDaysWatched: (json['num_days_watched'] as num?)?.toDouble(),
      numDaysWatching: (json['num_days_watching'] as num?)?.toDouble(),
      numDaysCompleted: (json['num_days_completed'] as num?)?.toDouble(),
      numDaysOnHold: (json['num_days_on_hold'] as num?)?.toDouble(),
      numDaysDropped: (json['num_days_dropped'] as num?)?.toDouble(),
      numDays: (json['num_days'] as num?)?.toDouble(),
      meanScore: (json['mean_score'] as num?)?.toDouble(),
      numEpisodes: json['num_episodes'] as int?,
    );
  }
}
