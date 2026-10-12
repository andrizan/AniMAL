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

/// A weekday and clock time in the device zone. [day] is a lower-case English
/// weekday name and [time] is `HH:mm`.
typedef AirSlot = ({String day, String time});

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

/// The one place that decides which air time the UI shows for an anime.
///
/// AniList's [nextAiringAt] wins when it is known: it is the instant the
/// countdown counts down to, so every label next to a countdown must agree
/// with it. Without it the MAL weekly slot ([jstDay] and [jstTime], in JST)
/// is converted to the device zone. Returns null when neither is usable.
///
/// [localOffset] overrides the device zone for tests.
AirSlot? resolveAirSlot({
  DateTime? nextAiringAt,
  String? jstDay,
  String? jstTime,
  Duration? localOffset,
}) {
  if (nextAiringAt != null) {
    final instant = nextAiringAt.toUtc();
    final local = instant.add(localOffset ?? instant.toLocal().timeZoneOffset);
    return (
      day: _weekDays[local.weekday - 1],
      time: '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}',
    );
  }
  return convertJstBroadcastToLocal(jstDay, jstTime, localOffset: localOffset);
}

/// `Fri 23:30`, the compact form used on cards.
String shortAirSlotLabel(AirSlot slot) =>
    '${_capitalize(slot.day).substring(0, 3)} ${slot.time}';

/// `Fridays, 23:30 your time`, the weekly form used for a broadcast slot.
String weeklyAirSlotLabel(AirSlot slot) =>
    '${_capitalize(slot.day)}s, ${slot.time} your time';

/// `Friday, 23:30 your time`, the form used for one upcoming episode.
String nextAirSlotLabel(AirSlot slot) =>
    '${_capitalize(slot.day)}, ${slot.time} your time';

AirSlot? convertJstBroadcastToLocal(
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
    time: '${_twoDigits(minuteOfDay ~/ 60)}:${_twoDigits(minuteOfDay % 60)}',
  );
}
