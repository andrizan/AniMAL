import 'package:animal/core/providers.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/local/anilist_cache.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Cache extends Fake implements AniListCache {}

class _Client extends Fake implements AniListClient {
  final asked = <String>[];
  Object? failure;

  Future<T> _answer<T>(String what, T value) async {
    asked.add(what);
    if (failure != null) throw failure!;
    return value;
  }

  @override
  Future<AniListCharacterDetail> getCharacterDetail(int id) =>
      _answer('character $id', AniListCharacterDetail(id: id, name: 'C$id'));

  @override
  Future<AniListStaffDetail> getStaffDetail(int id) =>
      _answer('staff $id', AniListStaffDetail(id: id, name: 'S$id'));

  @override
  Future<AniListStudioDetail> getStudioDetail(int id) =>
      _answer('studio $id', AniListStudioDetail(id: id, name: 'Z$id'));

  @override
  Future<AniListAnimeExtra> getAnimeExtraInfo(int malId) =>
      _answer('extra $malId', const AniListAnimeExtra());
}

void main() {
  late _Client client;
  late ProviderContainer container;

  setUp(() {
    client = _Client();
    container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [anilistApiProvider.overrideWithValue(client)],
    );
    addTearDown(container.dispose);
  });

  group('anilistApiProvider', () {
    test('builds one client on the AniList cache', () {
      final real = ProviderContainer(
        overrides: [anilistCacheProvider.overrideWithValue(_Cache())],
      );
      addTearDown(real.dispose);

      final api = real.read(anilistApiProvider);

      expect(api, isA<AniListClient>());
      expect(real.read(anilistApiProvider), same(api));
    });
  });

  group('detail providers', () {
    test('a character is looked up by its own id', () async {
      final detail = await container.read(
        anilistCharacterDetailProvider(7).future,
      );

      expect(detail.id, 7);
      expect(client.asked, ['character 7']);
    });

    test('a staff member is looked up by its own id', () async {
      final detail = await container.read(anilistStaffDetailProvider(8).future);

      expect(detail.name, 'S8');
      expect(client.asked, ['staff 8']);
    });

    test('a studio is looked up by its own id', () async {
      final detail = await container.read(
        anilistStudioDetailProvider(9).future,
      );

      expect(detail.name, 'Z9');
      expect(client.asked, ['studio 9']);
    });

    test('the extra info is looked up by the MAL id', () async {
      await container.read(anilistAnimeExtraProvider(5114).future);

      expect(client.asked, ['extra 5114']);
    });

    test('each id is its own request', () async {
      await container.read(anilistStaffDetailProvider(1).future);
      await container.read(anilistStaffDetailProvider(2).future);

      expect(client.asked, ['staff 1', 'staff 2']);
    });

    test('a failure surfaces as the provider error', () async {
      client.failure = Exception('offline');
      final sub = container.listen(
        anilistStudioDetailProvider(9),
        (_, _) {},
        onError: (_, _) {},
      );
      addTearDown(sub.close);

      await expectLater(
        container.read(anilistStudioDetailProvider(9).future),
        throwsA(isA<Exception>()),
      );
    });

    test('a provider that nobody watches is dropped and asks again', () async {
      final first = container.listen(
        anilistCharacterDetailProvider(3),
        (_, _) {},
      );
      await container.read(anilistCharacterDetailProvider(3).future);
      first.close();
      await Future<void>.delayed(Duration.zero);

      await container.read(anilistCharacterDetailProvider(3).future);

      expect(client.asked, ['character 3', 'character 3']);
    });
  });
}
