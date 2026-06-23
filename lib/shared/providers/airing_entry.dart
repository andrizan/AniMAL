import 'package:animal/data/models/my_list_status.dart';

/// Merged entry combining AniList schedule + MAL anime data.
class AiringEntry {
  const AiringEntry({
    required this.anilistId,
    required this.title,
    required this.airingAt,
    required this.episode,
    required this.timeUntilAiring,
    this.malId,
    this.titleEnglish,
    this.titleNative,
    this.imageUrl,
    this.malScore,
    this.genres = const [],
    this.episodes,
    this.format,
    this.status,
    this.myListStatus,
  });

  final int anilistId;
  final int? malId;
  final String title;
  final String? titleEnglish;
  final String? titleNative;
  final String? imageUrl;
  final DateTime airingAt;
  final int episode;
  final int timeUntilAiring;
  final double? malScore; // Score from MAL
  final List<String> genres;
  final int? episodes;
  final String? format;
  final String? status;
  final MyListStatus? myListStatus;

  String? get countdown {
    if (timeUntilAiring <= 0) return null;
    final days = timeUntilAiring ~/ 86400;
    final hours = (timeUntilAiring % 86400) ~/ 3600;
    final minutes = (timeUntilAiring % 3600) ~/ 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  bool get isUrgent => timeUntilAiring > 0 && timeUntilAiring < 21600;
}
