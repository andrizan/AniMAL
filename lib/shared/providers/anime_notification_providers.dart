import 'package:animal/core/constants/mal_endpoints.dart';
import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:animal/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationPermissionProvider =
    NotifierProvider<NotificationPermissionNotifier, bool>(
      NotificationPermissionNotifier.new,
    );

class NotificationPermissionNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(notificationServiceProvider).permissionGranted;
  }

  Future<bool> request() async {
    final service = ref.read(notificationServiceProvider);
    state = await service.requestPermission();
    return state;
  }
}

enum NotificationToggleResult {
  enabled,
  disabled,
  permissionDenied,
  tooLate,
  failed;

  bool get changedState => this == enabled || this == disabled;

  String message(int episode) => switch (this) {
    enabled => 'Notification enabled for Episode $episode',
    disabled => 'Notification disabled',
    permissionDenied => 'Notification permission denied',
    tooLate =>
      'Too late to schedule: Episode $episode airs in under '
          '${ApiConstants.notificationLeadMinutes} minutes or has aired',
    failed => 'Could not schedule the notification',
  };
}

final animeNotificationProvider =
    NotifierProvider<AnimeNotificationNotifier, Set<int>>(
      AnimeNotificationNotifier.new,
    );

class AnimeNotificationNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    return Set.unmodifiable(
      ref.read(notificationServiceProvider).notificationIds,
    );
  }

  void _refresh() {
    state = Set.unmodifiable(
      ref.read(notificationServiceProvider).notificationIds,
    );
  }

  bool isEnabled(int animeId) => state.contains(animeId);

  Future<void> removeAnime(int animeId) async {
    if (!state.contains(animeId)) return;
    await ref.read(notificationServiceProvider).cancelNotification(animeId);
    _refresh();
  }

  Future<NotificationToggleResult> toggle({
    required int animeId,
    required String title,
    required int episode,
    required DateTime airingAt,
  }) async {
    final service = ref.read(notificationServiceProvider);

    if (state.contains(animeId)) {
      final stillScheduled = await service.isNotificationScheduled(animeId);
      await service.cancelNotification(animeId);
      if (stillScheduled) {
        _refresh();
        return NotificationToggleResult.disabled;
      }
    }

    if (!service.permissionGranted) {
      final granted = await ref
          .read(notificationPermissionProvider.notifier)
          .request();
      if (!granted) {
        _refresh();
        return NotificationToggleResult.permissionDenied;
      }
    }

    final result = await service.scheduleAnimeNotification(
      animeId: animeId,
      title: title,
      episode: episode,
      airingAt: airingAt,
    );
    _refresh();
    return switch (result) {
      ScheduleResult.scheduled => NotificationToggleResult.enabled,
      ScheduleResult.permissionDenied =>
        NotificationToggleResult.permissionDenied,
      ScheduleResult.tooLate => NotificationToggleResult.tooLate,
      ScheduleResult.failed => NotificationToggleResult.failed,
    };
  }
}
