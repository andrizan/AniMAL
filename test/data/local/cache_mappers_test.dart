import 'dart:convert';

import 'package:animal/data/local/cache_mappers.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/broadcast.dart';
import 'package:animal/data/models/mal_user.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mappers = CacheMappers();

  group('anime rows', () {
    test('round-trips a fully populated anime', () {
      const anime = Anime(
        id: 5114,
        title: 'Fullmetal Alchemist: Brotherhood',
        mainPicture: MainPicture(medium: 'm.jpg', large: 'l.jpg'),
        mean: 9.1,
        rank: 1,
        popularity: 3,
        numEpisodes: 64,
        status: 'finished_airing',
        rating: 'r',
        mediaType: 'tv',
        broadcast: Broadcast(dayOfWeek: 'sunday', startTime: '17:00'),
        alternativeTitles: AlternativeTitles(
          en: 'FMA: Brotherhood',
          ja: '鋼の錬金術師',
          synonyms: ['Hagaren', 'FMAB'],
        ),
        myListStatus: MyListStatus(
          status: WatchStatus.completed,
          numEpisodesWatched: 64,
          score: 10,
          isRewatching: false,
          updatedAt: '2026-01-01T00:00:00+00:00',
          numTimesRewatched: 1,
          priority: 2,
          rewatchValue: 3,
          comments: 'classic',
        ),
      );
      const genres = [
        Genre(id: 1, name: 'Action'),
        Genre(id: 2, name: 'Drama'),
      ];

      final restored = mappers.animeFromRow(
        mappers.animeToRow(anime),
        genres: genres,
      );

      expect(restored, anime.copyWith(genres: genres));
    });

    test('keeps an anime with only the required fields', () {
      const anime = Anime(id: 1, title: 'Bare');

      final row = mappers.animeToRow(anime);
      final restored = mappers.animeFromRow(row);

      expect(row['mal_id'], 1);
      expect(row['title'], 'Bare');
      expect(restored.id, 1);
      expect(restored.title, 'Bare');
      expect(restored.mean, isNull);
      expect(restored.broadcast, isNull);
      expect(restored.alternativeTitles, isNull);
      expect(restored.myListStatus, isNull);
      expect(restored.genres, isEmpty);
    });

    test(
      'stores the list status twice: as json and as a filterable column',
      () {
        const anime = Anime(
          id: 1,
          title: 'T',
          myListStatus: MyListStatus(status: WatchStatus.onHold, score: 7),
        );

        final row = mappers.animeToRow(anime);

        expect(row['my_list_status_user'], 'on_hold');
        expect(
          jsonDecode(row['my_list_status_json']! as String),
          containsPair('status', 'on_hold'),
        );
      },
    );

    test('restores a broadcast that has only a day or only a time', () {
      expect(
        mappers
            .animeFromRow(
              mappers.animeToRow(
                const Anime(
                  id: 1,
                  title: 'T',
                  broadcast: Broadcast(dayOfWeek: 'monday'),
                ),
              ),
            )
            .broadcast,
        const Broadcast(dayOfWeek: 'monday'),
      );
      expect(
        mappers
            .animeFromRow(
              mappers.animeToRow(
                const Anime(
                  id: 1,
                  title: 'T',
                  broadcast: Broadcast(startTime: '09:30'),
                ),
              ),
            )
            .broadcast,
        const Broadcast(startTime: '09:30'),
      );
    });

    test('restores alternative titles with only some parts', () {
      final restored = mappers.animeFromRow(
        mappers.animeToRow(
          const Anime(
            id: 1,
            title: 'T',
            alternativeTitles: AlternativeTitles(en: 'English'),
          ),
        ),
      );

      expect(restored.alternativeTitles!.en, 'English');
      expect(restored.alternativeTitles!.ja, isNull);
      expect(restored.alternativeTitles!.synonyms, isEmpty);
    });

    test('reads a numeric mean stored as an integer', () {
      final row = mappers.animeToRow(const Anime(id: 1, title: 'T'))
        ..['mean'] = 8;

      expect(mappers.animeFromRow(row).mean, 8.0);
    });
  });

  group('list status json', () {
    test('round-trips every field', () {
      const status = MyListStatus(
        status: WatchStatus.planToWatch,
        numEpisodesWatched: 0,
        score: 0,
        isRewatching: true,
        updatedAt: 'x',
        numTimesRewatched: 2,
        priority: 1,
        rewatchValue: 4,
        comments: 'later',
      );

      final json = jsonDecode(
        mappers.encodeMyListStatus(status),
      ) as Map<String, dynamic>;

      expect(mappers.myListStatusFromJson(json), status);
    });

    test('falls back to watching for an unknown status value', () {
      expect(
        mappers.myListStatusFromJson({'status': 'abandoned'}).status,
        WatchStatus.watching,
      );
    });

    test('tolerates a minimal payload', () {
      final status = mappers.myListStatusFromJson({'status': 'dropped'});

      expect(status.status, WatchStatus.dropped);
      expect(status.score, isNull);
      expect(status.comments, isNull);
    });
  });

  group('genres', () {
    const genres = [Genre(id: 1, name: 'Action'), Genre(id: 2, name: 'Drama')];

    test('exposes ids and rows for storage', () {
      expect(mappers.extractGenreIds(genres), [1, 2]);
      expect(mappers.genreRows(genres), [
        {'id': 1, 'name': 'Action'},
        {'id': 2, 'name': 'Drama'},
      ]);
    });

    test('resolves ids back to genres and skips unknown ones', () {
      final byId = {for (final g in genres) g.id: g};

      expect(mappers.genresFromIds([2, 99, 1], byId), [genres[1], genres[0]]);
    });
  });

  group('anime detail rows', () {
    const detail = AnimeDetail(
      id: 7,
      title: 'Detail',
      mainPicture: MainPicture(medium: 'm', large: 'l'),
      mean: 8.2,
      rank: 10,
      popularity: 20,
      numEpisodes: 12,
      status: 'finished_airing',
      rating: 'pg_13',
      mediaType: 'tv',
      source: 'manga',
      synopsis: 'Story',
      startDate: '2020-01-01',
      endDate: '2020-03-20',
      numScoringUsers: 5000,
      averageEpisodeDuration: 1440,
      startSeason: StartSeason(year: 2020, season: 'winter'),
      relatedAnime: [
        RelatedAnime(
          node: AnimeNode(
            id: 8,
            title: 'Sequel',
            mainPicture: MainPicture(medium: 'sm', large: 'sl'),
          ),
          relationType: 'sequel',
          relationTypeFormatted: 'Sequel',
        ),
        RelatedAnime(node: AnimeNode(id: 9, title: 'No Picture')),
      ],
    );

    test('round-trips the detail-only fields', () {
      final row = {
        ...mappers.animeToRow(
          Anime(id: detail.id, title: detail.title, mean: detail.mean),
        ),
        ...mappers.animeDetailToExtraRow(detail),
      };

      final restored = mappers.animeDetailFromRow(row);

      expect(restored.source, 'manga');
      expect(restored.synopsis, 'Story');
      expect(restored.startDate, '2020-01-01');
      expect(restored.endDate, '2020-03-20');
      expect(restored.numScoringUsers, 5000);
      expect(restored.averageEpisodeDuration, 1440);
      expect(
        restored.startSeason,
        const StartSeason(year: 2020, season: 'winter'),
      );
      expect(restored.relatedAnime, hasLength(2));
      expect(restored.relatedAnime.first.node.title, 'Sequel');
      expect(restored.relatedAnime.first.node.mainPicture!.large, 'sl');
      expect(restored.relatedAnime.first.relationTypeFormatted, 'Sequel');
      expect(restored.relatedAnime.last.node.mainPicture!.medium, isNull);
    });

    test('has no related anime or season when none were stored', () {
      final row = {
        ...mappers.animeToRow(const Anime(id: 1, title: 'T')),
        ...mappers.animeDetailToExtraRow(const AnimeDetail(id: 1, title: 'T')),
      };

      final restored = mappers.animeDetailFromRow(row);

      expect(row['related_anime_json'], isNull);
      expect(restored.relatedAnime, isEmpty);
      expect(restored.startSeason, isNull);
    });

    test('ignores a half-stored start season', () {
      final row = {
        ...mappers.animeToRow(const Anime(id: 1, title: 'T')),
        ...mappers.animeDetailToExtraRow(const AnimeDetail(id: 1, title: 'T')),
        'start_season_year': 2024,
        'start_season_season': null,
      };

      expect(mappers.animeDetailFromRow(row).startSeason, isNull);
    });

    test('carries the list status and genres into the detail', () {
      final row = {
        ...mappers.animeToRow(
          const Anime(
            id: 1,
            title: 'T',
            myListStatus: MyListStatus(
              status: WatchStatus.watching,
              numEpisodesWatched: 4,
            ),
          ),
        ),
        ...mappers.animeDetailToExtraRow(const AnimeDetail(id: 1, title: 'T')),
      };

      final restored = mappers.animeDetailFromRow(
        row,
        genres: const [Genre(id: 3, name: 'Comedy')],
      );

      expect(restored.myListStatus!.numEpisodesWatched, 4);
      expect(restored.genres.single.name, 'Comedy');
    });
  });

  group('user rows', () {
    test(
      'round-trips a user with statistics, coercing whole numbers to doubles',
      () {
        const user = MalUser(
          id: 1,
          name: 'andrizan',
          picture: 'p.jpg',
          gender: 'male',
          birthday: '1999-01-01',
          location: 'ID',
          joinedAt: '2020-01-01',
          animeStatistics: AnimeStatistics(
            numItemsWatching: 3,
            numItemsCompleted: 120,
            numItemsOnHold: 1,
            numItemsDropped: 2,
            numItemsPlanToWatch: 40,
            numItems: 166,
            numDaysWatched: 30,
            numDaysWatching: 2.5,
            numDaysCompleted: 27,
            numDaysOnHold: 0.5,
            numDaysDropped: 0.25,
            numDays: 30.75,
            meanScore: 7.9,
            numEpisodes: 2500,
          ),
        );

        final row = mappers.malUserToRow(user);
        final restored = mappers.malUserFromRow(row);

        expect(row['cache_key'], 'userInfo');
        expect(restored, user);
      },
    );

    test('accepts statistics that were stored as integers', () {
      final row = mappers.malUserToRow(const MalUser(id: 1, name: 'u'))
        ..['stats_json'] = jsonEncode({'mean_score': 8, 'num_days': 12});

      final stats = mappers.malUserFromRow(row).animeStatistics!;

      expect(stats.meanScore, 8.0);
      expect(stats.numDays, 12.0);
    });

    test('has no statistics when none were stored', () {
      final restored = mappers.malUserFromRow(
        mappers.malUserToRow(const MalUser(id: 2, name: 'bare')),
      );

      expect(restored.animeStatistics, isNull);
      expect(restored.picture, isNull);
    });
  });
}
