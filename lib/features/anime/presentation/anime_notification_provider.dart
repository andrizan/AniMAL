import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _check();
    return false;
  }

  Future<void> _check() async {
    final service = ref.read(animeNotificationServiceProvider);
    state = await service.checkPermission();
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
  static const _key = 'anime_notification_ids';

  @override
  Set<int> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    state = ids.map(int.parse).toSet();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      state.map((id) => id.toString()).toList(),
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
      state = {...state}..remove(animeId);
    } else {
      await service.scheduleAnimeNotification(
        animeId: animeId,
        title: title,
        episode: episode,
        airingAt: airingAt,
      );
      state = {...state}..add(animeId);
    }
    await _save();
    return true;
  }
}
