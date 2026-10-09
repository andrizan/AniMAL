String? convertJstToLocal(
  String? jstTime, {
  DateTime? now,
  Duration? localOffset,
}) {
  if (jstTime == null || jstTime.isEmpty) return null;
  final parts = jstTime.split(':');
  if (parts.length < 2) return jstTime;
  try {
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final reference = now ?? DateTime.now();
    final offset = localOffset ?? reference.timeZoneOffset;
    final jstInstant = DateTime.utc(
      reference.year,
      reference.month,
      reference.day,
      hour,
      minute,
    ).subtract(const Duration(hours: 9));
    final local = jstInstant.add(offset);
    final dayDiff = DateTime.utc(local.year, local.month, local.day)
        .difference(
          DateTime.utc(reference.year, reference.month, reference.day),
        )
        .inDays;
    final prefix = dayDiff > 0 ? 'Tomorrow ' : '';
    return '$prefix${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  } on FormatException {
    return jstTime;
  }
}

const _weekDays = <String>[
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

({String day, String time})? convertJstBroadcastToLocal(
  String? jstDay,
  String? jstTime, {
  Duration? localOffset,
}) {
  if (jstDay == null || jstTime == null) return null;
  final dayIndex = _weekDays.indexOf(jstDay.toLowerCase());
  final parts = jstTime.split(':');
  final hour = parts.length < 2 ? null : int.tryParse(parts[0]);
  final minute = parts.length < 2 ? null : int.tryParse(parts[1]);
  if (dayIndex < 0 || hour == null || minute == null) return null;

  final offset = localOffset ?? DateTime.now().timeZoneOffset;
  final total = hour * 60 + minute - 9 * 60 + offset.inMinutes;
  final dayShift = (total / Duration.minutesPerDay).floor();
  final minuteOfDay = total - dayShift * Duration.minutesPerDay;
  return (
    day: _weekDays[(dayIndex + dayShift) % 7],
    time:
        '${(minuteOfDay ~/ 60).toString().padLeft(2, '0')}:'
        '${(minuteOfDay % 60).toString().padLeft(2, '0')}',
  );
}
