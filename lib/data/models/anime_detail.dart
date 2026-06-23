import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/broadcast.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'anime_detail.freezed.dart';
part 'anime_detail.g.dart';

@freezed
sealed class AnimeDetail with _$AnimeDetail {
  const factory AnimeDetail({
    required int id,
    required String title,
    @JsonKey(name: 'main_picture') MainPicture? mainPicture,
    double? mean,
    int? rank,
    int? popularity,
    @JsonKey(name: 'num_episodes') int? numEpisodes,
    String? status,
    String? rating,
    String? source,
    String? synopsis,
    @JsonKey(name: 'start_date') String? startDate,
    @JsonKey(name: 'end_date') String? endDate,
    @JsonKey(name: 'media_type') String? mediaType,
    @JsonKey(name: 'num_scoring_users') int? numScoringUsers,
    @Default([]) List<Genre> genres,
    Broadcast? broadcast,
    @JsonKey(name: 'alternative_titles')
    AlternativeTitles? alternativeTitles,
    @JsonKey(name: 'related_anime') @Default([]) List<RelatedAnime> relatedAnime,
    @JsonKey(name: 'my_list_status') MyListStatus? myListStatus,
  }) = _AnimeDetail;

  factory AnimeDetail.fromJson(Map<String, dynamic> json) =>
      _$AnimeDetailFromJson(json);
}

@freezed
sealed class Genre with _$Genre {
  const factory Genre({
    required int id,
    required String name,
  }) = _Genre;

  factory Genre.fromJson(Map<String, dynamic> json) => _$GenreFromJson(json);
}

@freezed
sealed class RelatedAnime with _$RelatedAnime {
  const factory RelatedAnime({
    @JsonKey(name: 'node') required AnimeNode node,
    @JsonKey(name: 'relation_type') String? relationType,
    @JsonKey(name: 'relation_type_formatted') String? relationTypeFormatted,
  }) = _RelatedAnime;

  factory RelatedAnime.fromJson(Map<String, dynamic> json) =>
      _$RelatedAnimeFromJson(json);
}

@freezed
sealed class AnimeNode with _$AnimeNode {
  const factory AnimeNode({
    required int id,
    required String title,
    @JsonKey(name: 'main_picture') MainPicture? mainPicture,
  }) = _AnimeNode;

  factory AnimeNode.fromJson(Map<String, dynamic> json) =>
      _$AnimeNodeFromJson(json);
}
