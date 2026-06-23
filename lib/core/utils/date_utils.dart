import 'package:timezone/timezone.dart' as tz;

String? convertJstToLocal(String? jstTime) {
  if (jstTime == null || jstTime.isEmpty) return null;
  try {
    final parts = jstTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final now = DateTime.now();
    final jst = tz.getLocation('Asia/Tokyo');
    final jstDateTime = tz.TZDateTime(
      jst,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    final localDateTime = jstDateTime.toLocal();
    final prefix = localDateTime.day > now.day ? 'Tomorrow ' : '';
    return '$prefix${localDateTime.hour.toString().padLeft(2, '0')}:'
        '${localDateTime.minute.toString().padLeft(2, '0')}';
  } on Exception {
    return jstTime;
  }
}

String formatCountdown(int seconds) {
  if (seconds <= 0) return 'Aired';
  final days = seconds ~/ 86400;
  final hours = (seconds % 86400) ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (days > 0) return '${days}d ${hours}h';
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}

bool isUrgentCountdown(int seconds) => seconds > 0 && seconds < 21600;
