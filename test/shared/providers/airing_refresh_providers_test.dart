import 'dart:async';

import 'package:animal/shared/providers/airing_entry.dart';
import 'package:animal/shared/providers/airing_refresh_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Airing extends Fake implements AiringRepository {
  int refreshes = 0;
  Object? failure;
  Map<String, List<AiringEntry>> result = {};
  Completer<void>? gate;

  @override
  Future<Map<String, List<AiringEntry>>> refreshWeeklySchedule() async {
    refreshes++;
    await gate?.future;
    final error = failure;
    if (error != null) throw error;
    return result;
  }
}

AiringEntry _entry() => AiringEntry(
  anilistId: 1,
  title: 'Show',
  airingAt: DateTime.utc(2026, 10, 14, 15),
  episode: 3,
  timeUntilAiring: 3600,
);

void main() {
  late _Airing airing;
  late ProviderContainer container;
  late int scheduleBuilds;

  setUp(() {
    airing = _Airing();
    scheduleBuilds = 0;
    container = ProviderContainer(
      overrides: [
        airingRepositoryProvider.overrideWithValue(airing),
        weeklyAiringProvider.overrideWith((ref) async {
          scheduleBuilds++;
          return <String, List<AiringEntry>>{};
        }),
      ],
    );
    addTearDown(container.dispose);
    // Keep the schedule alive so an invalidation shows up as a rebuild.
    container.listen(weeklyAiringProvider, (_, _) {});
  });

  AiringRefreshNotifier notifier() =>
      container.read(airingRefreshProvider.notifier);

  group('airingRefreshMessage', () {
    test('words the two outcomes that need a snackbar', () {
      expect(
        airingRefreshMessage(AiringRefreshResult.empty),
        'Airing schedule is empty, try again later',
      );
      expect(
        airingRefreshMessage(AiringRefreshResult.failed),
        'Refresh failed, showing cached schedule',
      );
    });

    test('stays silent for a good refresh and for a duplicate tap', () {
      expect(airingRefreshMessage(AiringRefreshResult.refreshed), isNull);
      expect(airingRefreshMessage(AiringRefreshResult.busy), isNull);
    });
  });

  group('refresh', () {
    test('is idle until asked', () {
      expect(container.read(airingRefreshProvider), isFalse);
      expect(airing.refreshes, 0);
    });

    test('reports a schedule that has entries', () async {
      airing.result = {
        'monday': [_entry()],
      };

      expect(await notifier().refresh(), AiringRefreshResult.refreshed);
      expect(airing.refreshes, 1);
    });

    test('reports a week with no entries at all as empty', () async {
      airing.result = {'monday': [], 'tuesday': []};

      expect(await notifier().refresh(), AiringRefreshResult.empty);
    });

    test('reports a completely empty map as empty too', () async {
      expect(await notifier().refresh(), AiringRefreshResult.empty);
    });

    test('turns any thrown error into a failed result', () async {
      airing.failure = Exception('offline');

      expect(await notifier().refresh(), AiringRefreshResult.failed);
    });

    test('also catches non-Exception throwables', () async {
      airing.failure = StateError('broken');

      expect(await notifier().refresh(), AiringRefreshResult.failed);
    });

    test('is busy while the request runs and idle again afterwards', () async {
      airing.gate = Completer<void>();
      final states = <bool>[];
      container.listen(airingRefreshProvider, (_, next) => states.add(next));

      final pending = notifier().refresh();
      expect(container.read(airingRefreshProvider), isTrue);

      airing.gate!.complete();
      await pending;

      expect(container.read(airingRefreshProvider), isFalse);
      expect(states, [true, false]);
    });

    test('is idle again after a failure so the user can retry', () async {
      airing.failure = Exception('offline');
      await notifier().refresh();

      expect(container.read(airingRefreshProvider), isFalse);

      airing.failure = null;
      airing.result = {
        'monday': [_entry()],
      };
      expect(await notifier().refresh(), AiringRefreshResult.refreshed);
    });

    test('ignores a second tap while one is running', () async {
      airing.gate = Completer<void>();

      final first = notifier().refresh();
      final second = await notifier().refresh();

      expect(second, AiringRefreshResult.busy);
      expect(airing.refreshes, 1);

      airing.gate!.complete();
      await first;
      expect(airing.refreshes, 1);
    });

    test('reloads the schedule once, even when the refresh failed', () async {
      await container.read(weeklyAiringProvider.future);
      expect(scheduleBuilds, 1);

      airing.failure = Exception('offline');
      await notifier().refresh();
      await container.read(weeklyAiringProvider.future);
      expect(scheduleBuilds, 2);

      airing.failure = null;
      await notifier().refresh();
      await container.read(weeklyAiringProvider.future);
      expect(scheduleBuilds, 3);
    });
  });
}
