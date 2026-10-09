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

  group('convertJstBroadcastToLocal', () {
    ({String day, String time})? convertBroadcast(
      String? day,
      String? time,
      int offsetHours,
    ) => convertJstBroadcastToLocal(
      day,
      time,
      localOffset: Duration(hours: offsetHours),
    );

    test('keeps the day and time on JST', () {
      expect(convertBroadcast('friday', '23:00', 9), (
        day: 'friday',
        time: '23:00',
      ));
    });

    test('converts the time within the same day', () {
      expect(convertBroadcast('friday', '23:00', 7), (
        day: 'friday',
        time: '21:00',
      ));
    });

    test('moves to the next day ahead of JST, wrapping the week', () {
      expect(convertBroadcast('friday', '23:00', 13), (
        day: 'saturday',
        time: '03:00',
      ));
      expect(convertBroadcast('sunday', '23:00', 13), (
        day: 'monday',
        time: '03:00',
      ));
    });

    test('moves to the previous day behind JST, wrapping the week', () {
      expect(convertBroadcast('saturday', '01:00', 0), (
        day: 'friday',
        time: '16:00',
      ));
      expect(convertBroadcast('monday', '01:00', 0), (
        day: 'sunday',
        time: '16:00',
      ));
    });

    test('handles half hour offsets and midnight', () {
      expect(convertBroadcast('monday', '00:00', 9), (
        day: 'monday',
        time: '00:00',
      ));
      expect(
        convertJstBroadcastToLocal(
          'monday',
          '23:45',
          localOffset: const Duration(hours: 5, minutes: 30),
        ),
        (day: 'monday', time: '20:15'),
      );
    });

    test('accepts a capitalised day', () {
      expect(convertBroadcast('Friday', '23:00', 9)?.day, 'friday');
    });

    test('is null without a day or time, or for malformed input', () {
      expect(convertBroadcast(null, '23:00', 7), isNull);
      expect(convertBroadcast('friday', null, 7), isNull);
      expect(convertBroadcast('someday', '23:00', 7), isNull);
      expect(convertBroadcast('friday', 'abc', 7), isNull);
      expect(convertBroadcast('friday', '10', 7), isNull);
      expect(convertBroadcast('friday', '10:xx', 7), isNull);
    });
  });
}
