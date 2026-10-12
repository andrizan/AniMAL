import 'dart:convert';

import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// A detail response shaped like MyAnimeList's `GET /anime/{id}`.
Map<String, dynamic> _malDetail() => {
  'id': 52991,
  'title': 'Sousou no Frieren',
  'main_picture': {
    'medium': 'https://cdn.test/m.jpg',
    'large': 'https://cdn.test/l.jpg',
  },
  'alternative_titles': {
    'synonyms': ['Frieren'],
    'en': "Frieren: Beyond Journey's End",
    'ja': '葬送のフリーレン',
  },
  'start_date': '2023-09-29',
  'end_date': '2024-03-22',
  'synopsis': 'An elf outlives her party.',
  'mean': 9.31,
  'rank': 1,
  'popularity': 120,
  'num_scoring_users': 800000,
  'media_type': 'tv',
  'status': 'finished_airing',
  'genres': [
    {'id': 2, 'name': 'Adventure'},
    {'id': 10, 'name': 'Fantasy'},
  ],
  'num_episodes': 28,
  'start_season': {'year': 2023, 'season': 'fall'},
  'broadcast': {'day_of_week': 'friday', 'start_time': '23:00'},
  'source': 'manga',
  'average_episode_duration': 1560,
  'rating': 'pg_13',
  'my_list_status': {
    'status': 'watching',
    'score': 9,
    'num_episodes_watched': 12,
    'is_rewatching': false,
  },
  'related_anime': [
    {
      'node': {
        'id': 59978,
        'title': 'Frieren Season 2',
        'main_picture': {'medium': 'https://cdn.test/s2.jpg'},
      },
      'relation_type': 'sequel',
      'relation_type_formatted': 'Sequel',
    },
    {
      'node': {'id': 1, 'title': 'No picture'},
      'relation_type': 'side_story',
    },
  ],
};

void main() {
  group('AnimeDetail.fromJson', () {
    late AnimeDetail detail;

    setUp(() => detail = AnimeDetail.fromJson(_malDetail()));

    test('reads the headline fields', () {
      expect(detail.id, 52991);
      expect(detail.title, 'Sousou no Frieren');
      expect(detail.mean, 9.31);
      expect(detail.rank, 1);
      expect(detail.popularity, 120);
      expect(detail.numScoringUsers, 800000);
      expect(detail.numEpisodes, 28);
      expect(detail.mediaType, 'tv');
      expect(detail.status, 'finished_airing');
      expect(detail.rating, 'pg_13');
      expect(detail.source, 'manga');
      expect(detail.synopsis, 'An elf outlives her party.');
      expect(detail.startDate, '2023-09-29');
      expect(detail.endDate, '2024-03-22');
      expect(detail.averageEpisodeDuration, 1560);
    });

    test('reads both picture sizes', () {
      expect(detail.mainPicture?.medium, 'https://cdn.test/m.jpg');
      expect(detail.mainPicture?.large, 'https://cdn.test/l.jpg');
    });

    test('reads the season it started in', () {
      expect(detail.startSeason?.year, 2023);
      expect(detail.startSeason?.season, 'fall');
    });

    test('reads the broadcast slot', () {
      expect(detail.broadcast?.dayOfWeek, 'friday');
      expect(detail.broadcast?.startTime, '23:00');
    });

    test('reads the genres in order', () {
      expect(detail.genres.map((g) => g.name), ['Adventure', 'Fantasy']);
      expect(detail.genres.map((g) => g.id), [2, 10]);
    });

    test('reads every alternative title', () {
      expect(detail.alternativeTitles?.en, "Frieren: Beyond Journey's End");
      expect(detail.alternativeTitles?.ja, '葬送のフリーレン');
      expect(detail.alternativeTitles?.synonyms, ['Frieren']);
    });

    test('reads my list status', () {
      expect(detail.myListStatus?.status, WatchStatus.watching);
      expect(detail.myListStatus?.score, 9);
      expect(detail.myListStatus?.numEpisodesWatched, 12);
      expect(detail.myListStatus?.isRewatching, isFalse);
    });

    test('reads related anime with their relation and picture', () {
      final sequel = detail.relatedAnime.first;

      expect(detail.relatedAnime, hasLength(2));
      expect(sequel.node.id, 59978);
      expect(sequel.node.title, 'Frieren Season 2');
      expect(sequel.node.mainPicture?.medium, 'https://cdn.test/s2.jpg');
      expect(sequel.relationType, 'sequel');
      expect(sequel.relationTypeFormatted, 'Sequel');
    });

    test('a related anime may have no picture or formatted relation', () {
      final side = detail.relatedAnime.last;

      expect(side.node.mainPicture, isNull);
      expect(side.relationType, 'side_story');
      expect(side.relationTypeFormatted, isNull);
    });
  });

  group('AnimeDetail.fromJson with little data', () {
    test('needs only an id and a title', () {
      final detail = AnimeDetail.fromJson({'id': 1, 'title': 'Bare'});

      expect(detail.mainPicture, isNull);
      expect(detail.startSeason, isNull);
      expect(detail.broadcast, isNull);
      expect(detail.myListStatus, isNull);
      expect(detail.alternativeTitles, isNull);
      expect(detail.genres, isEmpty);
      expect(detail.relatedAnime, isEmpty);
    });

    test('a picture with only one size is accepted', () {
      final detail = AnimeDetail.fromJson({
        'id': 1,
        'title': 'Small',
        'main_picture': {'medium': 'https://cdn.test/m.jpg'},
      });

      expect(detail.mainPicture?.medium, 'https://cdn.test/m.jpg');
      expect(detail.mainPicture?.large, isNull);
    });

    test('alternative titles without synonyms read as an empty list', () {
      final detail = AnimeDetail.fromJson({
        'id': 1,
        'title': 'X',
        'alternative_titles': {'en': 'X'},
      });

      expect(detail.alternativeTitles?.synonyms, isEmpty);
    });
  });

  group('Anime.fromJson', () {
    test('reads a list entry the way MAL sends it', () {
      final anime = Anime.fromJson({
        'id': 5,
        'title': 'Entry',
        'main_picture': {
          'medium': 'https://cdn.test/m.jpg',
          'large': 'https://cdn.test/l.jpg',
        },
        'mean': 8.1,
        'num_episodes': 12,
        'media_type': 'movie',
        'alternative_titles': {'ja': 'エントリー', 'synonyms': <String>[]},
        'genres': [
          {'id': 1, 'name': 'Action'},
        ],
        'my_list_status': {'status': 'completed', 'score': 8},
      });

      expect(anime.mainPicture?.large, 'https://cdn.test/l.jpg');
      expect(anime.mean, 8.1);
      expect(anime.numEpisodes, 12);
      expect(anime.mediaType, 'movie');
      expect(anime.alternativeTitles?.ja, 'エントリー');
      expect(anime.genres.single.name, 'Action');
      expect(anime.myListStatus?.status, WatchStatus.completed);
      expect(anime.myListStatus?.score, 8);
    });
  });

  group('writing back', () {
    test('a detail survives a round trip through JSON', () {
      final detail = AnimeDetail.fromJson(_malDetail());

      final again = AnimeDetail.fromJson(_wire(detail));

      expect(again, detail);
    });

    test('keeps the MAL key names', () {
      final json = _wire(AnimeDetail.fromJson(_malDetail()));

      expect(
        json.keys,
        containsAll([
          'main_picture',
          'num_episodes',
          'start_date',
          'end_date',
          'media_type',
          'alternative_titles',
          'related_anime',
          'my_list_status',
          'start_season',
          'average_episode_duration',
        ]),
      );
    });
  });
}

/// What the model looks like once written out as JSON text and read back.
Map<String, dynamic> _wire(Object model) =>
    jsonDecode(jsonEncode(model)) as Map<String, dynamic>;
