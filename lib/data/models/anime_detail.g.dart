// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AnimeDetail _$AnimeDetailFromJson(Map<String, dynamic> json) => _AnimeDetail(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  mainPicture: json['main_picture'] == null
      ? null
      : MainPicture.fromJson(json['main_picture'] as Map<String, dynamic>),
  mean: (json['mean'] as num?)?.toDouble(),
  rank: (json['rank'] as num?)?.toInt(),
  popularity: (json['popularity'] as num?)?.toInt(),
  numEpisodes: (json['num_episodes'] as num?)?.toInt(),
  status: json['status'] as String?,
  rating: json['rating'] as String?,
  source: json['source'] as String?,
  synopsis: json['synopsis'] as String?,
  startDate: json['start_date'] as String?,
  endDate: json['end_date'] as String?,
  mediaType: json['media_type'] as String?,
  numScoringUsers: (json['num_scoring_users'] as num?)?.toInt(),
  genres:
      (json['genres'] as List<dynamic>?)
          ?.map((e) => Genre.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  broadcast: json['broadcast'] == null
      ? null
      : Broadcast.fromJson(json['broadcast'] as Map<String, dynamic>),
  alternativeTitles: json['alternative_titles'] == null
      ? null
      : AlternativeTitles.fromJson(
          json['alternative_titles'] as Map<String, dynamic>,
        ),
  relatedAnime:
      (json['related_anime'] as List<dynamic>?)
          ?.map((e) => RelatedAnime.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  myListStatus: json['my_list_status'] == null
      ? null
      : MyListStatus.fromJson(json['my_list_status'] as Map<String, dynamic>),
  startSeason: json['start_season'] == null
      ? null
      : StartSeason.fromJson(json['start_season'] as Map<String, dynamic>),
  averageEpisodeDuration: (json['average_episode_duration'] as num?)?.toInt(),
);

Map<String, dynamic> _$AnimeDetailToJson(_AnimeDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'main_picture': instance.mainPicture,
      'mean': instance.mean,
      'rank': instance.rank,
      'popularity': instance.popularity,
      'num_episodes': instance.numEpisodes,
      'status': instance.status,
      'rating': instance.rating,
      'source': instance.source,
      'synopsis': instance.synopsis,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'media_type': instance.mediaType,
      'num_scoring_users': instance.numScoringUsers,
      'genres': instance.genres,
      'broadcast': instance.broadcast,
      'alternative_titles': instance.alternativeTitles,
      'related_anime': instance.relatedAnime,
      'my_list_status': instance.myListStatus,
      'start_season': instance.startSeason,
      'average_episode_duration': instance.averageEpisodeDuration,
    };

_Genre _$GenreFromJson(Map<String, dynamic> json) =>
    _Genre(id: (json['id'] as num).toInt(), name: json['name'] as String);

Map<String, dynamic> _$GenreToJson(_Genre instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};

_RelatedAnime _$RelatedAnimeFromJson(Map<String, dynamic> json) =>
    _RelatedAnime(
      node: AnimeNode.fromJson(json['node'] as Map<String, dynamic>),
      relationType: json['relation_type'] as String?,
      relationTypeFormatted: json['relation_type_formatted'] as String?,
    );

Map<String, dynamic> _$RelatedAnimeToJson(_RelatedAnime instance) =>
    <String, dynamic>{
      'node': instance.node,
      'relation_type': instance.relationType,
      'relation_type_formatted': instance.relationTypeFormatted,
    };

_AnimeNode _$AnimeNodeFromJson(Map<String, dynamic> json) => _AnimeNode(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  mainPicture: json['main_picture'] == null
      ? null
      : MainPicture.fromJson(json['main_picture'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AnimeNodeToJson(_AnimeNode instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'main_picture': instance.mainPicture,
    };

_StartSeason _$StartSeasonFromJson(Map<String, dynamic> json) => _StartSeason(
  year: (json['year'] as num).toInt(),
  season: json['season'] as String,
);

Map<String, dynamic> _$StartSeasonToJson(_StartSeason instance) =>
    <String, dynamic>{'year': instance.year, 'season': instance.season};
