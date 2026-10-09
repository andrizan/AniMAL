const _monthNames = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String shortMonthName(int month) => _monthNames[(month - 1) % 12];

String formatCount(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String? formatMonthYear(String? isoDate) {
  final date = DateTime.tryParse(isoDate ?? '')?.toLocal();
  if (date == null) return null;
  return '${shortMonthName(date.month)} ${date.year}';
}
