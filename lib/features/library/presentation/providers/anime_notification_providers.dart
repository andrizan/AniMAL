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

  void removeAnime(int animeId) {
    if (!state.contains(animeId)) return;
    ref.read(notificationServiceProvider).cancelNotification(animeId);
    _refresh();
  }

  Future<bool> toggle({
    required int animeId,
    required String title,
    required int episode,
    required DateTime airingAt,
  }) async {
    final service = ref.read(notificationServiceProvider);

    if (!service.permissionGranted) {
      final granted = await ref
          .read(notificationPermissionProvider.notifier)
          .request();
      if (!granted) return false;
    }

    if (state.contains(animeId)) {
      await service.cancelNotification(animeId);
    } else {
      await service.scheduleAnimeNotification(
        animeId: animeId,
        title: title,
        episode: episode,
        airingAt: airingAt,
      );
    }
    _refresh();
    return true;
  }
}
