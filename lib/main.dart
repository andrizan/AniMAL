import 'package:animal/app.dart';
import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  final notificationService = AnimeNotificationService();
  await notificationService.initialize();
  await notificationService.requestPermission();

  runApp(const ProviderScope(child: App()));
}
