import 'dart:async';

import 'package:animal/core/constants/mal_endpoints.dart';
import 'package:animal/core/logger/app_logger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class AnimeNotificationService {
  AnimeNotificationService({Logger? logger}) : _logger = logger ?? appLogger;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final Logger _logger;

  bool _permissionGranted = false;
  bool get permissionGranted => _permissionGranted;

  final _notificationIds = <int>{};
  Set<int> get notificationIds => Set.unmodifiable(_notificationIds);

  final _notificationTapController = StreamController<int>.broadcast();
  Stream<int> get onNotificationTapped => _notificationTapController.stream;

  static const _prefsKey = 'anime_notification_ids';

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: darwinSettings, macOS: darwinSettings);
    await _plugin.initialize(settings: initSettings, onDidReceiveNotificationResponse: (details) {
      final animeId = details.id;
      if (animeId != null && animeId > 0) _notificationTapController.add(animeId);
    });
    await Future.wait([_initPermission(), _loadIds()]);
  }

  Future<void> _initPermission() async {
    _permissionGranted = await checkPermission();
  }

  Future<void> _loadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_prefsKey) ?? [];
      _notificationIds.addAll(ids.map(int.parse));
    } on FormatException {
      _notificationIds.clear();
    }
  }

  Future<void> _saveIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _notificationIds.map((id) => id.toString()).toList());
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return _permissionGranted = granted ?? true;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(alert: true, badge: true, sound: true);
      return _permissionGranted = granted ?? false;
    }
    final macos = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    if (macos != null) {
      final granted = await macos.requestPermissions(alert: true, badge: true, sound: true);
      return _permissionGranted = granted ?? false;
    }
    _logger.w('Notification: unknown platform, assuming permission granted');
    return _permissionGranted = true;
  }

  Future<bool> checkPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return _permissionGranted = (await android.areNotificationsEnabled()) ?? false;
    return _permissionGranted;
  }

  Future<bool> scheduleAnimeNotification({required int animeId, required String title, required int episode, required DateTime airingAt}) async {
    if (!_permissionGranted) { final g = await requestPermission(); if (!g) return false; }
    final scheduledDate = tz.TZDateTime.from(
      airingAt.subtract(Duration(minutes: ApiConstants.notificationLeadMinutes)),
      tz.local,
    );
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return false;
    try {
      await _plugin.zonedSchedule(
        id: animeId, title: 'Episode $episode Airing Soon', body: '$title - Episode $episode starts in 15 minutes!',
        scheduledDate: scheduledDate,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails('anime_airing', 'Anime Airing', channelDescription: 'Notifications for upcoming anime episodes', importance: Importance.high, priority: Priority.high),
          iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
          macOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      _notificationIds.add(animeId);
      await _saveIds();
      return true;
    } on Exception catch (e) {
      _logger.e('Failed to schedule notification: $e');
      return false;
    }
  }

  Future<void> cancelNotification(int animeId) async {
    try { await _plugin.cancel(id: animeId); } on Exception catch (e) { _logger.e('Failed to cancel: $animeId: $e'); }
    _notificationIds.remove(animeId);
    await _saveIds();
  }

  Future<void> cancelAllNotifications() async { await _plugin.cancelAll(); _notificationIds.clear(); await _saveIds(); }

  Future<void> cleanupStaleNotifications() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      final pendingIds = pending.map((n) => n.id).toSet();
      _notificationIds.removeWhere((id) => !pendingIds.contains(id));
      await _saveIds();
    } on Exception catch (e) { _logger.w('Stale cleanup: $e'); }
  }

  Future<bool> isNotificationScheduled(int animeId) async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.any((n) => n.id == animeId);
  }

  void dispose() { _notificationTapController.close(); }
}
