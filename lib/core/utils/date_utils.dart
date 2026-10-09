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
