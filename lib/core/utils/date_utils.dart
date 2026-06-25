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
    final localDate = DateTime(
      localDateTime.year,
      localDateTime.month,
      localDateTime.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final dayDiff = localDate.difference(today).inDays;
    final prefix = dayDiff > 0 ? 'Tomorrow ' : '';
    return '$prefix${localDateTime.hour.toString().padLeft(2, '0')}:'
        '${localDateTime.minute.toString().padLeft(2, '0')}';
  } on Exception {
    return jstTime;
  }
}
