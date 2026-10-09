import 'package:animal/core/providers.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/broadcast.dart';
import 'package:animal/data/models/season.dart';
import 'package:animal/features/seasonal/providers/seasonal_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

Anime _anime(int id, {String? day, String? time}) => Anime(
  id: id,
  title: 'Anime $id',
  broadcast: day == null && time == null
      ? null
      : Broadcast(dayOfWeek: day, startTime: time),
);

Season _previous(Season s) => switch (s) {
  Season.winter => Season.fall,
  Season.spring => Season.winter,
  Season.summer => Season.spring,
  Season.fall => Season.summer,
};

void main() {
  Future<GroupedSeasonalAnime> grouped(
    ScheduleParams params,
    List<Override> overrides,
  ) async {
    final container = ProviderContainer(
      overrides: overrides,
      retry: noProviderRetry,
    );
    addTearDown(container.dispose);
    return container.read(groupedSeasonalAnimeProvider(params).future);
  }

  const past = (year: 2020, season: Season.spring);

  group('grouping', () {
    test('has every weekday even when nothing airs', () async {
      final result = await grouped(past, [
        animeScheduleProvider(past).overrideWith((ref) async => <Anime>[]),
      ]);

      expect(result.grouped.keys, [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ]);
      expect(result.grouped.values.every((l) => l.isEmpty), isTrue);
      expect(result.noBroadcast, isEmpty);
    });

    test('puts each anime on its broadcast day, earliest first', () async {
      final result = await grouped(past, [
        animeScheduleProvider(past).overrideWith(
          (ref) async => [
            _anime(1, day: 'monday', time: '23:30'),
            _anime(2, day: 'monday', time: '01:00'),
            _anime(3, day: 'friday', time: '18:00'),
          ],
        ),
      ]);

      expect(result.grouped['monday']!.map((a) => a.id), [2, 1]);
      expect(result.grouped['friday']!.map((a) => a.id), [3]);
      expect(result.grouped['tuesday'], isEmpty);
    });

    test(
      'anime without a usable broadcast day go to the bottom list',
      () async {
        final result = await grouped(past, [
          animeScheduleProvider(past).overrideWith(
            (ref) async => [
              _anime(1),
              _anime(2, time: '10:00'),
              _anime(3, day: 'someday', time: '10:00'),
              _anime(4, day: 'sunday', time: '10:00'),
            ],
          ),
        ]);

        expect(result.noBroadcast.map((a) => a.id), [1, 2, 3]);
        expect(result.grouped['sunday']!.map((a) => a.id), [4]);
      },
    );
  });

  group('empty current season fallback', () {
    final now = DateTime.now();
    final season = Season.fromDate(now);
    final current = (year: now.year, season: season);
    final prevYear = season == Season.winter ? now.year - 1 : now.year;
    final previous = (year: prevYear, season: _previous(season));

    test('shows the previous season until the new one is published', () async {
      final result = await grouped(current, [
        animeScheduleProvider(current).overrideWith((ref) async => <Anime>[]),
        animeScheduleProvider(previous).overrideWith(
          (ref) async => [_anime(9, day: 'monday', time: '20:00')],
        ),
      ]);

      expect(result.grouped['monday']!.map((a) => a.id), [9]);
    });

    test('prefers the current season once it has anime', () async {
      final result = await grouped(current, [
        animeScheduleProvider(current).overrideWith(
          (ref) async => [_anime(1, day: 'tuesday', time: '20:00')],
        ),
        animeScheduleProvider(previous).overrideWith(
          (ref) async => [_anime(9, day: 'monday', time: '20:00')],
        ),
      ]);

      expect(result.grouped['tuesday']!.map((a) => a.id), [1]);
      expect(result.grouped['monday'], isEmpty);
    });

    test('stays empty when the previous season fails to load', () async {
      final result = await grouped(current, [
        animeScheduleProvider(current).overrideWith((ref) async => <Anime>[]),
        animeScheduleProvider(previous)
            .overrideWith((ref) async => throw Exception('offline')),
      ]);

      expect(result.grouped.values.every((l) => l.isEmpty), isTrue);
    });

    test('does not borrow from another season for a different year', () async {
      final other = (year: now.year - 3, season: season);

      final result = await grouped(other, [
        animeScheduleProvider(other).overrideWith((ref) async => <Anime>[]),
      ]);

      expect(result.grouped.values.every((l) => l.isEmpty), isTrue);
    });
  });
}
