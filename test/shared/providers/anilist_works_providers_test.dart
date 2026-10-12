import 'dart:async';

import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:animal/shared/providers/anilist_works_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AniListMediaAppearance _work(int id) => AniListMediaAppearance(
  anilistId: id,
  malId: id + 1000,
  title: 'Work $id',
  type: 'ANIME',
);

List<AniListMediaAppearance> _works(int from, int count) => [
  for (var i = from; i < from + count; i++) _work(i),
];

class _Api extends Fake implements AniListClient {
  final requests = <(AniListWorksSource, int, int)>[];
  final pages = <int, AniListWorksPage>{};
  final failures = <int>{};
  Completer<void>? gate;

  @override
  Future<AniListWorksPage> getWorksPage(
    AniListWorksSource source,
    int id,
    int page,
  ) async {
    requests.add((source, id, page));
    await gate?.future;
    if (failures.contains(page)) throw Exception('offline');
    return pages[page] ?? const AniListWorksPage(items: [], hasNextPage: false);
  }
}

void main() {
  const staffKey = (source: AniListWorksSource.staff, id: 8);
  late _Api api;
  late ProviderContainer container;

  ProviderContainer build({
    List<AniListMediaAppearance>? first,
    AniListWorksCursor cursor = const AniListWorksCursor(hasMore: true),
  }) {
    final works = first ?? _works(0, 10);
    final c = ProviderContainer(
      overrides: [
        anilistApiProvider.overrideWithValue(api),
        anilistStaffDetailProvider(8).overrideWith(
          (ref) async => AniListStaffDetail(
            id: 8,
            name: 'S',
            mediaWorks: works,
            worksCursor: cursor,
          ),
        ),
        anilistStudioDetailProvider(7).overrideWith(
          (ref) async => AniListStudioDetail(
            id: 7,
            name: 'Bones',
            mediaWorks: _works(100, 10),
            worksCursor: const AniListWorksCursor(hasMore: true),
          ),
        ),
        anilistCharacterDetailProvider(3).overrideWith(
          (ref) async => AniListCharacterDetail(
            id: 3,
            name: 'Roy',
            mediaAppearances: _works(200, 10),
            worksCursor: const AniListWorksCursor(hasMore: true),
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> ready(WorksKey key) async {
    // Keep the autoDispose pager alive and let its detail resolve.
    container.listen(worksPagerProvider(key), (_, _) {});
    switch (key.source) {
      case AniListWorksSource.staff:
        await container.read(anilistStaffDetailProvider(key.id).future);
      case AniListWorksSource.studio:
        await container.read(anilistStudioDetailProvider(key.id).future);
      case AniListWorksSource.character:
        await container.read(anilistCharacterDetailProvider(key.id).future);
    }
    await Future<void>.delayed(Duration.zero);
  }

  WorksPagerState state([WorksKey key = staffKey]) =>
      container.read(worksPagerProvider(key));

  Future<void> loadMore([WorksKey key = staffKey]) =>
      container.read(worksPagerProvider(key).notifier).loadMore();

  setUp(() {
    api = _Api();
    container = build();
  });

  group('first page', () {
    test('is the works of the detail, with nothing fetched yet', () async {
      await ready(staffKey);

      expect(state().items.map((m) => m.anilistId), [
        for (var i = 0; i < 10; i++) i,
      ]);
      expect(state().hasMore, isTrue);
      expect(state().nextPage, 2);
      expect(state().loadingMore, isFalse);
      expect(state().error, isNull);
      expect(api.requests, isEmpty);
    });

    test('a list the cursor calls finished has nothing more to load', () async {
      container = build(
        first: _works(0, 4),
        cursor: const AniListWorksCursor(),
      );
      await ready(staffKey);

      expect(state().items, hasLength(4));
      expect(state().hasMore, isFalse);

      await loadMore();
      expect(api.requests, isEmpty);
    });

    test('a full list is not extended once the cursor says it ended', () async {
      container = build(
        first: _works(0, AniListClient.worksPageSize),
        cursor: const AniListWorksCursor(nextPage: 3),
      );
      await ready(staffKey);

      expect(state().items, hasLength(AniListClient.worksPageSize));
      expect(state().hasMore, isFalse);
      await loadMore();
      expect(api.requests, isEmpty);
    });

    test('the cursor, not the length, says more follow', () async {
      container = build(first: _works(0, 3));
      await ready(staffKey);

      expect(state().hasMore, isTrue);
    });

    test('continues where the stored pages stop', () async {
      container = build(
        first: _works(0, 30),
        cursor: const AniListWorksCursor(nextPage: 4, hasMore: true),
      );
      await ready(staffKey);
      api.pages[4] = AniListWorksPage(items: _works(30, 5), hasNextPage: false);

      expect(state().items, hasLength(30));
      expect(state().nextPage, 4);

      await loadMore();

      expect(api.requests, [(AniListWorksSource.staff, 8, 4)]);
      expect(state().items, hasLength(35));
      expect(state().nextPage, 5);
      expect(state().hasMore, isFalse);
    });

    test('an empty detail has no works and no more pages', () async {
      container = build(first: const [], cursor: const AniListWorksCursor());
      await ready(staffKey);

      expect(state().items, isEmpty);
      expect(state().hasMore, isFalse);
    });

    test('shows nothing until the detail has loaded, then fills in', () async {
      container.listen(worksPagerProvider(staffKey), (_, _) {});
      expect(state().items, isEmpty);
      expect(state().hasMore, isFalse);

      await container.read(anilistStaffDetailProvider(8).future);
      await Future<void>.delayed(Duration.zero);

      expect(state().items, hasLength(10));
      expect(state().hasMore, isTrue);
    });

    test('each source reads its own detail', () async {
      const studio = (source: AniListWorksSource.studio, id: 7);
      const character = (source: AniListWorksSource.character, id: 3);
      await ready(studio);
      await ready(character);

      expect(state(studio).items.first.anilistId, 100);
      expect(state(character).items.first.anilistId, 200);
    });
  });

  group('loadMore', () {
    test('appends the next page in order and moves on', () async {
      await ready(staffKey);
      api.pages[2] = AniListWorksPage(items: _works(10, 10), hasNextPage: true);
      api.pages[3] = AniListWorksPage(items: _works(20, 3), hasNextPage: false);

      await loadMore();
      expect(state().items.map((m) => m.anilistId), [
        for (var i = 0; i < 20; i++) i,
      ]);
      expect(state().hasMore, isTrue);
      expect(state().nextPage, 3);

      await loadMore();
      expect(state().items, hasLength(23));
      expect(state().items.last.anilistId, 22);
      expect(state().hasMore, isFalse);
      expect(api.requests, [
        (AniListWorksSource.staff, 8, 2),
        (AniListWorksSource.staff, 8, 3),
      ]);
    });

    test('does nothing once the last page was reached', () async {
      await ready(staffKey);
      api.pages[2] = AniListWorksPage(items: _works(10, 2), hasNextPage: false);
      await loadMore();

      await loadMore();
      await loadMore();

      expect(api.requests, hasLength(1));
    });

    test('ignores a call while a page is already on its way', () async {
      await ready(staffKey);
      api.gate = Completer<void>();
      api.pages[2] = AniListWorksPage(items: _works(10, 10), hasNextPage: true);

      final first = loadMore();
      expect(state().loadingMore, isTrue);
      await loadMore();
      await loadMore();
      api.gate!.complete();
      await first;

      expect(api.requests, hasLength(1));
      expect(state().items, hasLength(20));
      expect(state().loadingMore, isFalse);
    });

    test('never lists the same work twice', () async {
      await ready(staffKey);
      api.pages[2] = AniListWorksPage(
        items: [..._works(8, 4)],
        hasNextPage: false,
      );

      await loadMore();

      final ids = state().items.map((m) => m.anilistId).toList();
      expect(ids, hasLength(12));
      expect(ids.toSet(), hasLength(12));
    });

    test(
      'an empty page ends the list even if AniList says more follow',
      () async {
        await ready(staffKey);
        api.pages[2] = const AniListWorksPage(items: [], hasNextPage: true);

        await loadMore();

        expect(state().hasMore, isFalse);
        await loadMore();
        expect(api.requests, hasLength(1));
      },
    );

    test('a page of only repeats still moves on to the next page', () async {
      await ready(staffKey);
      api.pages[2] = AniListWorksPage(items: _works(0, 3), hasNextPage: true);
      api.pages[3] = AniListWorksPage(items: _works(10, 3), hasNextPage: false);

      await loadMore();
      expect(state().items, hasLength(10));
      expect(state().hasMore, isTrue);

      await loadMore();
      expect(state().items, hasLength(13));
    });
  });

  group('failures', () {
    test('keep the works shown and offer a retry', () async {
      await ready(staffKey);
      api.failures.add(2);

      await loadMore();

      expect(state().items, hasLength(10));
      expect(state().error, isNotNull);
      expect(state().loadingMore, isFalse);
      expect(state().hasMore, isTrue);
      expect(state().nextPage, 2);
    });

    test('stop scrolling from retrying on its own', () async {
      await ready(staffKey);
      api.failures.add(2);
      expect(state().canAutoLoad, isTrue);

      await loadMore();

      expect(state().canAutoLoad, isFalse);
    });

    test('a retry asks for the same page again and clears the error', () async {
      await ready(staffKey);
      api.failures.add(2);
      await loadMore();
      api.failures.clear();
      api.pages[2] = AniListWorksPage(items: _works(10, 5), hasNextPage: false);

      await loadMore();

      expect(api.requests.map((r) => r.$3), [2, 2]);
      expect(state().error, isNull);
      expect(state().items, hasLength(15));
      expect(state().hasMore, isFalse);
    });

    test('are shown as loading again while the retry runs', () async {
      await ready(staffKey);
      api.failures.add(2);
      await loadMore();
      api.failures.clear();
      api.gate = Completer<void>();

      final retry = loadMore();

      expect(state().loadingMore, isTrue);
      expect(state().error, isNull);
      api.gate!.complete();
      await retry;
    });
  });

  group('lifecycle', () {
    test('a page that arrives after the list closed changes nothing', () async {
      await ready(staffKey);
      api.gate = Completer<void>();
      api.pages[2] = AniListWorksPage(items: _works(10, 10), hasNextPage: true);

      final pending = loadMore();
      container.invalidate(worksPagerProvider(staffKey));
      api.gate!.complete();

      await expectLater(pending, completes);
    });

    test('a failure that arrives after the list closed is ignored', () async {
      await ready(staffKey);
      api.gate = Completer<void>();
      api.failures.add(2);

      final pending = loadMore();
      container.invalidate(worksPagerProvider(staffKey));
      api.gate!.complete();

      await expectLater(pending, completes);
    });
  });

  group('WorksPagerState', () {
    test('canAutoLoad needs more pages, no request and no error', () {
      const base = WorksPagerState(items: [], hasMore: true);

      expect(base.canAutoLoad, isTrue);
      expect(base.copyWith(hasMore: false).canAutoLoad, isFalse);
      expect(base.copyWith(loadingMore: true).canAutoLoad, isFalse);
      expect(base.copyWith(error: 'x').canAutoLoad, isFalse);
    });

    test('copyWith keeps what it is not given and can clear the error', () {
      final state = WorksPagerState(
        items: _works(0, 2),
        hasMore: true,
        nextPage: 4,
        error: 'x',
      );

      final copy = state.copyWith(loadingMore: true);
      expect(copy.items, state.items);
      expect(copy.nextPage, 4);
      expect(copy.error, 'x');
      expect(state.copyWith(clearError: true).error, isNull);
    });
  });
}
