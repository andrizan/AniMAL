import 'package:animal/core/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 10, 12);

  String? convert(String? jst, int offsetHours) => convertJstToLocal(
    jst,
    now: now,
    localOffset: Duration(hours: offsetHours),
  );

  group('convertJstToLocal', () {
    test('returns null for a missing or empty time', () {
      expect(convertJstToLocal(null), isNull);
      expect(convertJstToLocal(''), isNull);
    });

    test('keeps the time when the device is on JST', () {
      expect(convert('23:00', 9), '23:00');
      expect(convert('00:00', 9), '00:00');
    });

    test('converts to the device zone, not to UTC', () {
      expect(convert('23:00', 7), '21:00');
      expect(convert('02:30', 7), '00:30');
      expect(convert('23:00', 0), '14:00');
      expect(convert('23:00', 8), '22:00');
    });

    test('marks a broadcast that lands on the next local day', () {
      expect(convert('23:00', 13), 'Tomorrow 03:00');
      expect(convert('22:00', 12), 'Tomorrow 01:00');
      expect(convert('20:00', 12), '23:00');
    });

    test('does not add a prefix when the local time is earlier in the day', () {
      expect(convert('02:30', -5), '12:30');
      expect(convert('09:00', 0), '00:00');
    });

    test('pads hours and minutes', () {
      expect(convert('09:05', 9), '09:05');
      expect(convert('18:07', 7), '16:07');
    });

    test('returns malformed input untouched instead of throwing', () {
      expect(convert('abc', 7), 'abc');
      expect(convert('10', 7), '10');
      expect(convert('10:xx', 7), '10:xx');
    });
  });
}
