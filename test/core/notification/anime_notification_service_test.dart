import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const _channel = MethodChannel('dexterous.com/flutter/local_notifications');
const _prefsKey = 'anime_notification_ids';

class _Native {
  bool permissionGranted = true;
  bool notificationsEnabled = true;
  bool failSchedule = false;
  bool failPending = false;
  bool failCancel = false;
  Map<String, Object?>? launchDetails;
  List<int> pending = [];
  final calls = <MethodCall>[];

  Iterable<MethodCall> of(String method) =>
      calls.where((c) => c.method == method);

  Future<Object?> handle(MethodCall call) async {
    calls.add(call);
    switch (call.method) {
      case 'initialize':
        return true;
      case 'getNotificationAppLaunchDetails':
        return launchDetails;
      case 'requestNotificationsPermission':
        return permissionGranted;
      case 'areNotificationsEnabled':
        return notificationsEnabled;
      case 'zonedSchedule':
        if (failSchedule)
          throw PlatformException(code: 'exact_alarms_not_permitted');
        return null;
      case 'cancel':
        if (failCancel) throw PlatformException(code: 'cancel_failed');
        return null;
      case 'pendingNotificationRequests':
        if (failPending) throw PlatformException(code: 'pending_failed');
        return [
          for (final id in pending)
            {'id': id, 'title': 't', 'body': 'b', 'payload': null},
        ];
      default:
        return null;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Native native;
  late AnimeNotificationService service;

  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    AndroidFlutterLocalNotificationsPlugin.registerWith();
  });

  setUp(() {
    native = _Native();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, native.handle);
    service = AnimeNotificationService(logger: Logger(level: Level.off));
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  Future<ScheduleResult> schedule({
    int animeId = 5,
    Duration airsIn = const Duration(hours: 2),
  }) => service.scheduleAnimeNotification(
    animeId: animeId,
    title: 'Frieren',
    episode: 3,
    airingAt: DateTime.now().add(airsIn),
  );

  Future<List<String>?> storedIds() async =>
      (await SharedPreferences.getInstance()).getStringList(_prefsKey);

  group('scheduleAnimeNotification', () {
    test('schedules a reminder and remembers the anime', () async {
      expect(await schedule(), ScheduleResult.scheduled);

      final call = native.of('zonedSchedule').single;
      final args = call.arguments as Map<Object?, Object?>;
      expect(args['id'], 5);
      expect(args['title'], 'Episode 3 Airing Soon');
      expect(args['body'], contains('Frieren'));
      expect(service.notificationIds, {5});
      expect(await storedIds(), ['5']);
    });

    test('reminds fifteen minutes before airing, in the device zone', () async {
      final airingAt = DateTime.utc(2035, 1, 1, 12);

      final result = await service.scheduleAnimeNotification(
        animeId: 5,
        title: 'Frieren',
        episode: 3,
        airingAt: airingAt,
      );

      expect(result, ScheduleResult.scheduled);
      final args = native.of('zonedSchedule').single.arguments as Map;
      expect(args['scheduledDateTime'], '2035-01-01T18:45:00');
      expect(args['timeZoneName'], 'Asia/Jakarta');
    });

    test('is too late when the reminder time has already passed', () async {
      expect(
        await schedule(airsIn: const Duration(minutes: 10)),
        ScheduleResult.tooLate,
      );
      expect(
        await schedule(airsIn: const Duration(hours: -1)),
        ScheduleResult.tooLate,
      );

      expect(native.of('zonedSchedule'), isEmpty);
      expect(service.notificationIds, isEmpty);
    });

    test('the lead time is exactly fifteen minutes', () async {
      expect(
        await schedule(airsIn: const Duration(minutes: 16)),
        ScheduleResult.scheduled,
      );
      expect(
        await schedule(airsIn: const Duration(minutes: 14), animeId: 6),
        ScheduleResult.tooLate,
      );
    });

    test('asks for permission once and reports a refusal', () async {
      native.permissionGranted = false;

      expect(await schedule(), ScheduleResult.permissionDenied);

      expect(native.of('requestNotificationsPermission'), hasLength(1));
      expect(native.of('zonedSchedule'), isEmpty);
      expect(service.permissionGranted, isFalse);
    });

    test('does not ask again once permission is granted', () async {
      await schedule();
      await schedule(animeId: 6);

      expect(native.of('requestNotificationsPermission'), hasLength(1));
      expect(service.permissionGranted, isTrue);
    });

    test('reports a platform failure without remembering the anime', () async {
      native.failSchedule = true;

      expect(await schedule(), ScheduleResult.failed);

      expect(service.notificationIds, isEmpty);
      expect(await storedIds(), isNull);
    });
  });

  group('cancelNotification', () {
    test('cancels natively and forgets the anime', () async {
      await schedule();

      await service.cancelNotification(5);

      expect((native.of('cancel').single.arguments as Map)['id'], 5);
      expect(service.notificationIds, isEmpty);
      expect(await storedIds(), isEmpty);
    });

    test('forgets the anime even if the native cancel fails', () async {
      await schedule();
      native.failCancel = true;

      await service.cancelNotification(5);

      expect(service.notificationIds, isEmpty);
    });

    test('cancelAll clears everything', () async {
      await schedule();
      await schedule(animeId: 6);

      await service.cancelAllNotifications();

      expect(native.of('cancelAll'), hasLength(1));
      expect(service.notificationIds, isEmpty);
      expect(await storedIds(), isEmpty);
    });
  });

  group('isNotificationScheduled', () {
    test('reflects what the system still has pending', () async {
      native.pending = [5];

      expect(await service.isNotificationScheduled(5), isTrue);
      expect(await service.isNotificationScheduled(6), isFalse);
    });

    test(
      'falls back to the remembered ids when the system cannot be asked',
      () async {
        await schedule();
        native.failPending = true;

        expect(await service.isNotificationScheduled(5), isTrue);
        expect(await service.isNotificationScheduled(6), isFalse);
      },
    );
  });

  group('cleanupStaleNotifications', () {
    test('drops ids whose notification already fired', () async {
      await schedule();
      await schedule(animeId: 6);
      await schedule(animeId: 7);
      native.pending = [6];

      await service.cleanupStaleNotifications();

      expect(service.notificationIds, {6});
      expect(await storedIds(), ['6']);
    });

    test('keeps the ids when pending notifications cannot be read', () async {
      await schedule();
      native.failPending = true;

      await service.cleanupStaleNotifications();

      expect(service.notificationIds, {5});
    });
  });

  group('initialize', () {
    test('restores remembered ids that are still pending', () async {
      SharedPreferences.setMockInitialValues({
        _prefsKey: ['5', '6'],
      });
      native.pending = [6];

      await service.initialize();

      expect(service.notificationIds, {6});
    });

    test('ignores corrupted stored ids', () async {
      SharedPreferences.setMockInitialValues({
        _prefsKey: ['5', 'abc'],
      });

      await service.initialize();

      expect(service.notificationIds, isEmpty);
    });

    test('reads the notification permission from the system', () async {
      native.notificationsEnabled = false;

      await service.initialize();

      expect(service.permissionGranted, isFalse);
    });

    test('remembers which anime launched the app, once', () async {
      native.launchDetails = {
        'notificationLaunchedApp': true,
        'notificationResponse': {
          'notificationId': 42,
          'actionId': null,
          'input': null,
          'payload': null,
          'notificationResponseType': 0,
        },
      };

      await service.initialize();

      expect(service.consumeLaunchAnimeId(), 42);
      expect(service.consumeLaunchAnimeId(), isNull);
    });

    test('has no launch anime on a normal start', () async {
      await service.initialize();

      expect(service.consumeLaunchAnimeId(), isNull);
    });
  });

  test('checkPermission follows the system setting', () async {
    native.notificationsEnabled = false;
    expect(await service.checkPermission(), isFalse);

    native.notificationsEnabled = true;
    expect(await service.checkPermission(), isTrue);
  });
}
