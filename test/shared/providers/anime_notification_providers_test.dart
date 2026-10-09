import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/shared/providers/anime_notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNotificationService extends Fake implements AnimeNotificationService {
  FakeNotificationService({
    this.granted = true,
    this.result = ScheduleResult.scheduled,
  });

  bool granted;
  ScheduleResult result;
  final ids = <int>{};
  final pending = <int>{};

  @override
  bool get permissionGranted => granted;

  @override
  Set<int> get notificationIds => Set.unmodifiable(ids);

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<ScheduleResult> scheduleAnimeNotification({
    required int animeId,
    required String title,
    required int episode,
    required DateTime airingAt,
  }) async {
    if (result == ScheduleResult.scheduled) {
      ids.add(animeId);
      pending.add(animeId);
    }
    return result;
  }

  @override
  Future<void> cancelNotification(int animeId) async {
    await Future<void>.delayed(Duration.zero);
    ids.remove(animeId);
    pending.remove(animeId);
  }

  @override
  Future<bool> isNotificationScheduled(int animeId) async =>
      pending.contains(animeId);
}

void main() {
  late FakeNotificationService service;
  late ProviderContainer container;

  AnimeNotificationNotifier notifier() =>
      container.read(animeNotificationProvider.notifier);

  bool enabled(int id) =>
      container.read(animeNotificationProvider).contains(id);

  Future<NotificationToggleResult> toggle(int id) => notifier().toggle(
    animeId: id,
    title: 'Anime $id',
    episode: 5,
    airingAt: DateTime.now().add(const Duration(hours: 2)),
  );

  void start(FakeNotificationService fake) {
    service = fake;
    container = ProviderContainer(
      overrides: [notificationServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
  }

  group('toggle', () {
    test('schedules and reports enabled', () async {
      start(FakeNotificationService());

      expect(await toggle(1), NotificationToggleResult.enabled);
      expect(enabled(1), isTrue);
    });

    test('an active notification is disabled on the next toggle', () async {
      start(FakeNotificationService());
      await toggle(1);

      expect(await toggle(1), NotificationToggleResult.disabled);
      expect(enabled(1), isFalse);
    });

    test('a too-late schedule is reported, never as disabled', () async {
      start(FakeNotificationService(result: ScheduleResult.tooLate));

      expect(await toggle(1), NotificationToggleResult.tooLate);
      expect(enabled(1), isFalse);
    });

    test('a failed schedule is reported as failed', () async {
      start(FakeNotificationService(result: ScheduleResult.failed));

      expect(await toggle(1), NotificationToggleResult.failed);
      expect(enabled(1), isFalse);
    });

    test('a denied permission is reported as denied', () async {
      start(FakeNotificationService(granted: false));

      expect(await toggle(1), NotificationToggleResult.permissionDenied);
      expect(enabled(1), isFalse);
    });

    test('an id whose notification already fired is rescheduled', () async {
      final fake = FakeNotificationService()..ids.add(1);
      start(fake);
      expect(enabled(1), isTrue);

      expect(await toggle(1), NotificationToggleResult.enabled);
      expect(enabled(1), isTrue);
      expect(fake.pending, contains(1));
    });

    test('a stale id is dropped when rescheduling is too late', () async {
      final fake = FakeNotificationService(result: ScheduleResult.tooLate)
        ..ids.add(1);
      start(fake);

      expect(await toggle(1), NotificationToggleResult.tooLate);
      expect(enabled(1), isFalse);
    });
  });

  test('removeAnime refreshes the state after the cancel completes', () async {
    final fake = FakeNotificationService()
      ..ids.add(1)
      ..pending.add(1);
    start(fake);
    expect(enabled(1), isTrue);

    await notifier().removeAnime(1);

    expect(enabled(1), isFalse);
  });

  test('messages never call a failed schedule "disabled"', () {
    expect(
      NotificationToggleResult.disabled.message(5),
      'Notification disabled',
    );
    expect(
      NotificationToggleResult.tooLate.message(5),
      allOf(contains('Episode 5'), contains('15 minutes')),
    );
    expect(NotificationToggleResult.tooLate.changedState, isFalse);
    expect(NotificationToggleResult.enabled.changedState, isTrue);
  });
}
