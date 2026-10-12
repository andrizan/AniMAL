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

  group('resolveAirSlot', () {
    // Friday 2026-10-16 14:00 UTC is Friday 23:00 in JST.
    final fridayJstEvening = DateTime.utc(2026, 10, 16, 14);

    AirSlot? resolve({
      DateTime? airingAt,
      String? day,
      String? time,
      int offsetHours = 7,
    }) => resolveAirSlot(
      nextAiringAt: airingAt,
      jstDay: day,
      jstTime: time,
      localOffset: Duration(hours: offsetHours),
    );

    test('turns the AniList instant into the device zone', () {
      expect(resolve(airingAt: fridayJstEvening), (
        day: 'friday',
        time: '21:00',
      ));
      expect(resolve(airingAt: fridayJstEvening, offsetHours: 9), (
        day: 'friday',
        time: '23:00',
      ));
    });

    test('rolls the weekday over midnight in either direction', () {
      expect(resolve(airingAt: DateTime.utc(2026, 10, 16, 20)), (
        day: 'saturday',
        time: '03:00',
      ));
      expect(resolve(airingAt: DateTime.utc(2026, 10, 18, 20)), (
        day: 'monday',
        time: '03:00',
      ));
      expect(
        resolve(airingAt: DateTime.utc(2026, 10, 16, 3), offsetHours: -5),
        (day: 'thursday', time: '22:00'),
      );
    });

    test('AniList wins over a MAL slot that disagrees with it', () {
      final slot = resolve(
        airingAt: fridayJstEvening,
        day: 'friday',
        time: '23:30',
      );

      expect(slot, (day: 'friday', time: '21:00'));
    });

    test('AniList wins even when MAL names another weekday', () {
      final slot = resolve(
        airingAt: fridayJstEvening,
        day: 'sunday',
        time: '01:00',
      );

      expect(slot?.day, 'friday');
    });

    test('falls back to the converted MAL slot without an AniList time', () {
      expect(resolve(day: 'friday', time: '23:00'), (
        day: 'friday',
        time: '21:00',
      ));
      expect(
        resolve(day: 'friday', time: '23:00'),
        convertJstBroadcastToLocal(
          'friday',
          '23:00',
          localOffset: const Duration(hours: 7),
        ),
      );
    });

    test('is null when neither source is usable', () {
      expect(resolve(), isNull);
      expect(resolve(day: 'friday'), isNull);
      expect(resolve(time: '23:00'), isNull);
      expect(resolve(day: 'friday', time: 'late'), isNull);
    });

    test('treats a local DateTime and the same UTC instant alike', () {
      final utc = DateTime.utc(2026, 10, 16, 14, 30);

      expect(resolve(airingAt: utc.toLocal()), resolve(airingAt: utc));
    });

    test('uses the device zone by default', () {
      final instant = DateTime.utc(2026, 10, 16, 14, 45);
      final local = instant.toLocal();

      final slot = resolveAirSlot(nextAiringAt: instant)!;

      expect(
        slot.time,
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}',
      );
      expect(
        slot.day,
        const [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
        ][local.weekday - 1],
      );
    });

    test('keeps minutes, so a 23:26 broadcast is not rounded to 23:30', () {
      expect(
        resolve(airingAt: DateTime.utc(2026, 10, 16, 14, 26), offsetHours: 9),
        (day: 'friday', time: '23:26'),
      );
    });
  });

  group('air slot labels', () {
    const names = {
      'monday': ('Mon', 'Mondays', 'Monday'),
      'tuesday': ('Tue', 'Tuesdays', 'Tuesday'),
      'wednesday': ('Wed', 'Wednesdays', 'Wednesday'),
      'thursday': ('Thu', 'Thursdays', 'Thursday'),
      'friday': ('Fri', 'Fridays', 'Friday'),
      'saturday': ('Sat', 'Saturdays', 'Saturday'),
      'sunday': ('Sun', 'Sundays', 'Sunday'),
    };

    test('format every weekday on cards, weekly slots and next episodes', () {
      names.forEach((day, forms) {
        final slot = (day: day, time: '23:30');

        expect(shortAirSlotLabel(slot), '${forms.$1} 23:30', reason: day);
        expect(
          weeklyAirSlotLabel(slot),
          '${forms.$2}, 23:30 your time',
          reason: day,
        );
        expect(
          nextAirSlotLabel(slot),
          '${forms.$3}, 23:30 your time',
          reason: day,
        );
      });
    });

    test('a card and its detail page agree on the day and the time', () {
      final slot = resolveAirSlot(
        nextAiringAt: DateTime.utc(2026, 10, 16, 14, 30),
        localOffset: const Duration(hours: 7),
      )!;

      expect(shortAirSlotLabel(slot), 'Fri 21:30');
      expect(weeklyAirSlotLabel(slot), 'Fridays, 21:30 your time');
      expect(nextAirSlotLabel(slot), 'Friday, 21:30 your time');
    });
  });
}
