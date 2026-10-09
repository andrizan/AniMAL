import 'package:animal/core/providers.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:animal/shared/providers/anime_list_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

AiringEntry _entry(
  int anilistId,
  int? malId,
  Duration fromNow, {
  int episode = 1,
}) => AiringEntry(
  anilistId: anilistId,
  malId: malId,
  title: 'T$anilistId',
  airingAt: DateTime.now().toUtc().add(fromNow),
  episode: episode,
  timeUntilAiring: fromNow.inSeconds,
);

void main() {
  Future<Map<int, AiringEntry>> byMalId(
    Map<String, List<AiringEntry>> week,
  ) async {
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [weeklyAiringProvider.overrideWith((ref) async => week)],
    );
    addTearDown(container.dispose);
    return container.read(airingByMalIdProvider.future);
  }

  group('airingByMalIdProvider', () {
    test('keeps the soonest upcoming episode of each anime', () async {
      final map = await byMalId({
        'monday': [_entry(1, 10, const Duration(days: 3), episode: 6)],
        'tuesday': [_entry(1, 10, const Duration(hours: 5), episode: 5)],
      });

      expect(map.keys, [10]);
      expect(map[10]!.episode, 5);
    });

    test('ignores episodes that already aired', () async {
      final map = await byMalId({
        'monday': [_entry(1, 10, const Duration(hours: -2))],
      });

      expect(map, isEmpty);
    });

    test('ignores entries that have no MAL id', () async {
      final map = await byMalId({
        'monday': [_entry(1, null, const Duration(hours: 2))],
      });

      expect(map, isEmpty);
    });

    test('maps different anime independently', () async {
      final map = await byMalId({
        'monday': [
          _entry(1, 10, const Duration(hours: 2)),
          _entry(2, 20, const Duration(hours: 9)),
        ],
      });

      expect(map.keys.toSet(), {10, 20});
    });

    test('is empty for an empty week', () async {
      expect(await byMalId({}), isEmpty);
    });
  });

  group('when the schedule cannot be loaded', () {
    List<Override> failingSchedule() => [
      weeklyAiringProvider.overrideWith(
        (ref) async => throw Exception('anilist down'),
      ),
      userAnimeListProvider(
        WatchStatus.watching,
      ).overrideWith((ref) async => [const Anime(id: 1, title: 'Still here')]),
    ];

    test('the map is simply empty', () async {
      final container = ProviderContainer(
        retry: noProviderRetry,
        overrides: failingSchedule(),
      );
      addTearDown(container.dispose);

      expect(await container.read(airingByMalIdProvider.future), isEmpty);
    });

    test('the MAL list still loads instead of failing with it', () async {
      final container = ProviderContainer(
        retry: noProviderRetry,
        overrides: failingSchedule(),
      );
      addTearDown(container.dispose);

      final result = await container.read(
        sortedUserAnimeListProvider((
          status: WatchStatus.watching,
          sortBy: ListSort.name,
          ascending: true,
          airingFilter: AiringFilter.all,
        )).future,
      );

      expect(result.anime.map((a) => a.title), ['Still here']);
      expect(result.airingMap, isEmpty);
    });
  });
}
