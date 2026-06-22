import 'package:animal/features/anime/domain/anime.dart';

/// Merged anime data combining MAL anime info + AniList airing schedule.
///
/// MAL is the primary source. AniList supplements:
/// - [airingAt] exact airing timestamp
/// - [nextEpisode] next episode number
/// - [timeUntilAiring] seconds until next episode
class AnimeWithSchedule {
  const AnimeWithSchedule({
    required this.anime,
    this.airingAt,
    this.nextEpisode,
    this.timeUntilAiring,
  });

  /// MAL anime data (primary).
  final Anime anime;

  /// When the next episode airs (from AniList).
  final DateTime? airingAt;

  /// Next episode number (from AniList).
  final int? nextEpisode;

  /// Seconds until next episode airs (from AniList).
  /// Null if unknown or already aired.
  final int? timeUntilAiring;

  /// Formatted countdown string (e.g. "2d 5h", "3h 20m", "45m").
  String? get countdown {
    if (timeUntilAiring == null || timeUntilAiring! <= 0) return null;
    final days = timeUntilAiring! ~/ 86400;
    final hours = (timeUntilAiring! % 86400) ~/ 3600;
    final minutes = (timeUntilAiring! % 3600) ~/ 60;

    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  /// Whether the countdown is urgent (< 6 hours).
  bool get isUrgent =>
      timeUntilAiring != null &&
      timeUntilAiring! > 0 &&
      timeUntilAiring! < 21600;

  /// Broadcast day from MAL.
  String? get dayOfWeek => anime.broadcast?.dayOfWeek;

  /// Broadcast time from MAL (JST).
  String? get broadcastTime => anime.broadcast?.startTime;

  /// Anime title from MAL.
  String get title => anime.title;

  /// Japanese title.
  String? get titleNative => anime.alternativeTitles?.ja;

  /// Cover image URL.
  String? get imageUrl => anime.mainPicture?.medium;

  /// Number of episodes from MAL.
  int? get numEpisodes => anime.numEpisodes;

  /// Mean score from MAL.
  double? get meanScore => anime.mean;

  /// Genres from MAL.
  List<dynamic> get genres => anime.genres;

  /// Age rating from MAL.
  String? get rating => anime.rating;

  /// Media type from MAL.
  String? get mediaType => anime.mediaType;

  /// Airing status from MAL.
  String? get status => anime.status;
}
