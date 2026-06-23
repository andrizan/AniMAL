import 'package:flutter/material.dart';

String cleanAniListDescription(String desc) {
  return desc
      .replaceAll(RegExp(r'\[/?[a-zA-Z]+\]'), '')
      .replaceAll(RegExp('~!.*?!~'), '[Spoiler]')
      .replaceAll('&#039;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&amp;', '&')
      .replaceAll('<br>', '\n')
      .replaceAll('<br/>', '\n');
}

class AnimeLabels {
  const AnimeLabels._();

  static String statusLabel(String? status, {bool compact = false}) =>
      switch (status) {
        'currently_airing' => compact ? 'AIRING' : 'Airing',
        'finished_airing' => compact ? 'FINISHED' : 'Finished',
        'not_yet_aired' => compact ? 'UPCOMING' : 'Upcoming',
        _ => status ?? '',
      };

  static Color statusColor(String? status) => switch (status) {
        'currently_airing' => Colors.green,
        'finished_airing' => Colors.blue,
        'not_yet_aired' => Colors.orange,
        _ => Colors.grey,
      };

  static String ratingLabel(String? rating, {bool compact = false}) =>
      switch (rating) {
        'g' => compact ? 'G' : 'G - All Ages',
        'pg' => compact ? 'PG' : 'PG - Children',
        'pg_13' => 'PG-13',
        'r' => compact ? 'R' : 'R - 17+',
        'r+' => compact ? 'R+' : 'R+ - Profanity',
        'rx' => compact ? 'Rx' : 'Rx - Hentai',
        _ => rating ?? '',
      };

  static String mediaTypeLabel(String? type, {bool compact = false}) =>
      switch (type) {
        'tv' => 'TV',
        'movie' => compact ? 'MOVIE' : 'Movie',
        'ova' => 'OVA',
        'ona' => 'ONA',
        'special' => compact ? 'SP' : 'Special',
        'music' => compact ? 'MV' : 'Music',
        _ => type ?? '',
      };

  static String sourceLabel(String? source) => switch (source) {
        'original' => 'Original',
        'manga' => 'Manga',
        'light_novel' => 'Light Novel',
        'visual_novel' => 'Visual Novel',
        'video_game' => 'Video Game',
        'other' => 'Other',
        'novel' => 'Novel',
        'doujinshi' => 'Doujinshi',
        'anime' => 'Anime',
        'web_manga' => 'Web Manga',
        'web_novel' => 'Web Novel',
        'game' => 'Game',
        'comic' => 'Comic',
        'multimedia_project' => 'Multimedia Project',
        'picture_book' => 'Picture Book',
        _ => source ?? '',
      };
}
