import 'package:animal/data/models/anime.dart' as model;

final class AnimeEntity {
  const AnimeEntity({
    required this.id,
    required this.title,
    this.japaneseTitle,
    this.imageUrl,
    this.largeImageUrl,
    this.meanScore,
    this.rank,
    this.popularity,
    this.numEpisodes,
    this.status,
    this.rating,
    this.mediaType,
    this.broadcastDay,
    this.broadcastTime,
    this.genres = const [],
    this.personalScore,
    this.watchedEpisodes,
    this.listStatus,
  });

  final int id;
  final String title;
  final String? japaneseTitle;
  final String? imageUrl;
  final String? largeImageUrl;
  final double? meanScore;
  final int? rank;
  final int? popularity;
  final int? numEpisodes;
  final String? status;
  final String? rating;
  final String? mediaType;
  final String? broadcastDay;
  final String? broadcastTime;
  final List<String> genres;
  final int? personalScore;
  final int? watchedEpisodes;
  final String? listStatus;

  factory AnimeEntity.fromModel(model.Anime anime) {
    return AnimeEntity(
      id: anime.id,
      title: anime.title,
      japaneseTitle: anime.alternativeTitles?.ja,
      imageUrl: anime.mainPicture?.medium,
      largeImageUrl: anime.mainPicture?.large,
      meanScore: anime.mean,
      rank: anime.rank,
      popularity: anime.popularity,
      numEpisodes: anime.numEpisodes,
      status: anime.status,
      rating: anime.rating,
      mediaType: anime.mediaType,
      broadcastDay: anime.broadcast?.dayOfWeek,
      broadcastTime: anime.broadcast?.startTime,
      genres: anime.genres.map((g) => g.name).toList(),
      personalScore: anime.myListStatus?.score,
      watchedEpisodes: anime.myListStatus?.numEpisodesWatched,
      listStatus: anime.myListStatus?.status.value,
    );
  }
}
