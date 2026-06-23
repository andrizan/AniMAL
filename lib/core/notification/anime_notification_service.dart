import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class AnimeNotificationService {
  AnimeNotificationService();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _permissionGranted = false;
  bool get permissionGranted => _permissionGranted;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _plugin.initialize(settings: initSettings);
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      _permissionGranted = granted ?? false;
      return _permissionGranted;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      _permissionGranted = granted ?? false;
      return _permissionGranted;
    }

    final macos = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();

    if (macos != null) {
      final granted = await macos.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      _permissionGranted = granted ?? false;
      return _permissionGranted;
    }

    _permissionGranted = true;
    return true;
  }

  Future<bool> checkPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final enabled = await android.areNotificationsEnabled();
      _permissionGranted = enabled ?? false;
      return _permissionGranted;
    }

    return _permissionGranted;
  }

  Future<void> scheduleAnimeNotification({
    required int animeId,
    required String title,
    required int episode,
    required DateTime airingAt,
  }) async {
    if (!_permissionGranted) {
      final granted = await requestPermission();
      if (!granted) return;
    }

    final scheduledDate = tz.TZDateTime.from(
      airingAt.subtract(const Duration(minutes: 15)),
      tz.local,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    try {
      await _plugin.zonedSchedule(
        id: animeId,
        title: 'Episode $episode Airing Soon',
        body: '$title - Episode $episode starts in 15 minutes!',
        scheduledDate: scheduledDate,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'anime_airing',
            'Anime Airing',
            channelDescription: 'Notifications for upcoming anime episodes',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          macOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } on Exception catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  Future<void> cancelNotification(int animeId) async {
    await _plugin.cancel(id: animeId);
  }

  Future<bool> isNotificationScheduled(int animeId) async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.any((n) => n.id == animeId);
  }
}
