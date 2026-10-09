import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/features/home/presentation/widgets/anime_list_tab.dart';
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _OfflineRepo extends Fake implements AnimeRepository {
  int calls = 0;

  @override
  Future<List<Anime>> getUserAnimeList({
    WatchStatus status = WatchStatus.watching,
  }) async {
    calls++;
    throw DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionError,
    );
  }
}

void main() {
  test('the policy never schedules a retry', () {
    for (var attempt = 0; attempt < 12; attempt++) {
      expect(noProviderRetry(attempt, Exception('offline')), isNull);
    }
  });

  group('a failing provider', () {
    late int calls;
    late FutureProvider<int> failing;

    setUp(() {
      calls = 0;
      failing = FutureProvider<int>((ref) async {
        calls++;
        throw DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
        );
      });
    });

    test('reports its error at once and is not re-run', () async {
      final container = ProviderContainer(retry: noProviderRetry);
      addTearDown(container.dispose);
      container.listen(failing, (_, __) {});

      await Future<void>.delayed(const Duration(milliseconds: 700));

      final state = container.read(failing);
      expect(state.hasError, isTrue);
      expect(state.isLoading, isFalse);
      expect(calls, 1);
    });

    test(
      'whereas the Riverpod default keeps it loading and re-runs it',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.listen(failing, (_, __) {});

        await Future<void>.delayed(const Duration(milliseconds: 700));

        expect(container.read(failing).isLoading, isTrue);
        expect(calls, greaterThan(1));
      },
    );
  });

  testWidgets('the home list shows its error right away when offline', (
    tester,
  ) async {
    final repo = _OfflineRepo();
    await tester.pumpWidget(
      ProviderScope(
        retry: noProviderRetry,
        overrides: [
          notificationServiceProvider.overrideWithValue(
            AnimeNotificationService(),
          ),
          airingByMalIdProvider.overrideWith((ref) async => {}),
          animeRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AnimeListTab(status: WatchStatus.watching)),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('Failed to load'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(repo.calls, 1);
  });
}
