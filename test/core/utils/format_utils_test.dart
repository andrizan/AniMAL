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

  group('formatDate', () {
    test('formats a full date', () {
      expect(formatDate('2023-09-29'), 'Sep 29, 2023');
      expect(formatDate('2024-03-02'), 'Mar 2, 2024');
    });

    test('returns partial or unreadable dates as they are', () {
      expect(formatDate('2023'), '2023');
      expect(formatDate('2023-09'), '2023-09');
      expect(formatDate('2023-13-01'), '2023-13-01');
      expect(formatDate('2023-xx-01'), '2023-xx-01');
    });
  });
}
