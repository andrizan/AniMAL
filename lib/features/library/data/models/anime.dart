import 'package:animal/features/library/data/models/anime_detail.dart';
import 'package:animal/features/library/data/models/broadcast.dart';
import 'package:animal/features/library/data/models/my_list_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'anime.freezed.dart';
part 'anime.g.dart';

/// Represents a single anime entry from the MyAnimeList API.
@freezed
sealed class Anime with _$Anime {
  const factory Anime({
    required int id,
    required String title,
    @JsonKey(name: 'main_picture') MainPicture? mainPicture,
    double? mean,
    int? rank,
    int? popularity,
    @JsonKey(name: 'num_episodes') int? numEpisodes,
    String? status,
    String? rating,
    @JsonKey(name: 'media_type') String? mediaType,
    Broadcast? broadcast,
    @JsonKey(name: 'alternative_titles')
    AlternativeTitles? alternativeTitles,
    @Default([]) List<Genre> genres,

    /// Only populated when requesting the user's anime list or
    /// anime detail with the `my_list_status` field.
    @JsonKey(name: 'my_list_status') MyListStatus? myListStatus,
  }) = _Anime;

  factory Anime.fromJson(Map<String, dynamic> json) => _$AnimeFromJson(json);
}

/// Poster images for an anime.
@freezed
sealed class MainPicture with _$MainPicture {
  const factory MainPicture({
    String? medium,
    String? large,
  }) = _MainPicture;

  factory MainPicture.fromJson(Map<String, dynamic> json) =>
      _$MainPictureFromJson(json);
}

/// Alternative titles for an anime (Japanese, English, synonyms).
@freezed
sealed class AlternativeTitles with _$AlternativeTitles {
  const factory AlternativeTitles({
    String? en,
    String? ja,
    @Default([]) List<String> synonyms,
  }) = _AlternativeTitles;

  factory AlternativeTitles.fromJson(Map<String, dynamic> json) =>
      _$AlternativeTitlesFromJson(json);
}
