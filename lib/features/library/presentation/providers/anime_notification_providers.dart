import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final animeNotificationServiceProvider = Provider<AnimeNotificationService>(
  (ref) => AnimeNotificationService(),
);

final notificationPermissionProvider =
    NotifierProvider<NotificationPermissionNotifier, bool>(
  NotificationPermissionNotifier.new,
);

class NotificationPermissionNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(animeNotificationServiceProvider).permissionGranted;
  }

  Future<bool> request() async {
    final service = ref.read(animeNotificationServiceProvider);
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
      ref.read(animeNotificationServiceProvider).notificationIds,
    );
  }

  void _refreshFromService() {
    state = Set.unmodifiable(
      ref.read(animeNotificationServiceProvider).notificationIds,
    );
  }

  bool isEnabled(int animeId) => state.contains(animeId);

  Future<bool> toggle({
    required int animeId,
    required String title,
    required int episode,
    required DateTime airingAt,
  }) async {
    final service = ref.read(animeNotificationServiceProvider);

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
    _refreshFromService();
    return true;
  }
}
