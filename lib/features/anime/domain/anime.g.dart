// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Anime _$AnimeFromJson(Map<String, dynamic> json) => _Anime(
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
  mediaType: json['media_type'] as String?,
  broadcast: json['broadcast'] == null
      ? null
      : Broadcast.fromJson(json['broadcast'] as Map<String, dynamic>),
  alternativeTitles: json['alternative_titles'] == null
      ? null
      : AlternativeTitles.fromJson(
          json['alternative_titles'] as Map<String, dynamic>,
        ),
  genres:
      (json['genres'] as List<dynamic>?)
          ?.map((e) => Genre.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  myListStatus: json['my_list_status'] == null
      ? null
      : MyListStatus.fromJson(json['my_list_status'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AnimeToJson(_Anime instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'main_picture': instance.mainPicture,
  'mean': instance.mean,
  'rank': instance.rank,
  'popularity': instance.popularity,
  'num_episodes': instance.numEpisodes,
  'status': instance.status,
  'rating': instance.rating,
  'media_type': instance.mediaType,
  'broadcast': instance.broadcast,
  'alternative_titles': instance.alternativeTitles,
  'genres': instance.genres,
  'my_list_status': instance.myListStatus,
};

_MainPicture _$MainPictureFromJson(Map<String, dynamic> json) => _MainPicture(
  medium: json['medium'] as String?,
  large: json['large'] as String?,
);

Map<String, dynamic> _$MainPictureToJson(_MainPicture instance) =>
    <String, dynamic>{'medium': instance.medium, 'large': instance.large};

_AlternativeTitles _$AlternativeTitlesFromJson(Map<String, dynamic> json) =>
    _AlternativeTitles(
      en: json['en'] as String?,
      ja: json['ja'] as String?,
      synonyms:
          (json['synonyms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$AlternativeTitlesToJson(_AlternativeTitles instance) =>
    <String, dynamic>{
      'en': instance.en,
      'ja': instance.ja,
      'synonyms': instance.synonyms,
    };
