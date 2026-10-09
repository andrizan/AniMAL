import 'package:animal/core/utils/format_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatCount', () {
    test('leaves small numbers alone', () {
      expect(formatCount(0), '0');
      expect(formatCount(7), '7');
      expect(formatCount(999), '999');
    });

    test('groups thousands', () {
      expect(formatCount(1000), '1,000');
      expect(formatCount(2500), '2,500');
      expect(formatCount(12345), '12,345');
      expect(formatCount(1234567), '1,234,567');
    });

    test('keeps the sign of negative numbers', () {
      expect(formatCount(-1500), '-1,500');
      expect(formatCount(-5), '-5');
    });
  });

  test('shortMonthName names every month', () {
    expect(
      [for (var m = 1; m <= 12; m++) shortMonthName(m)],
      [
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
      ],
    );
  });

  group('formatMonthYear', () {
    test('formats an ISO timestamp', () {
      expect(
        formatMonthYear('2019-03-12T09:41:05+00:00'),
        matches(r'^\w{3} 2019$'),
      );
    });

    test('is null when missing or unreadable', () {
      expect(formatMonthYear(null), isNull);
      expect(formatMonthYear(''), isNull);
      expect(formatMonthYear('not a date'), isNull);
    });
  });
}
