import 'package:animal/core/utils/date_utils.dart';
import 'package:animal/data/models/broadcast.dart';
import 'package:animal/features/detail/presentation/widgets/detail_sections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('broadcastLabel', () {
    test('words the MAL slot in the device zone', () {
      const broadcast = Broadcast(dayOfWeek: 'friday', startTime: '23:00');
      final local = convertJstBroadcastToLocal('friday', '23:00')!;

      expect(
        broadcastLabel(broadcast),
        '${local.day[0].toUpperCase()}${local.day.substring(1)}s, '
        '${local.time} your time',
      );
    });

    test('shows only the weekday when MAL has no time', () {
      expect(broadcastLabel(const Broadcast(dayOfWeek: 'friday')), 'Fridays');
    });

    test('falls back to the JST text for a time it cannot read', () {
      expect(
        broadcastLabel(const Broadcast(dayOfWeek: 'friday', startTime: '??')),
        'Fridays, ?? JST',
      );
    });

    test('is empty when there is nothing to say', () {
      expect(broadcastLabel(null), '');
      expect(broadcastLabel(const Broadcast()), '');
      expect(broadcastLabel(const Broadcast(startTime: '23:00')), '');
    });

    test('prefers the AniList airing over a MAL slot that disagrees', () {
      // 14:00 UTC is 23:00 JST; MAL claims 23:30 on another weekday.
      final airingAt = DateTime.utc(2026, 10, 16, 14);
      const broadcast = Broadcast(dayOfWeek: 'sunday', startTime: '23:30');

      final label = broadcastLabel(broadcast, nextAiringAt: airingAt);

      expect(
        label,
        weeklyAirSlotLabel(resolveAirSlot(nextAiringAt: airingAt)!),
      );
      expect(label, isNot(contains('Sundays')));
    });

    test('works from the AniList airing alone', () {
      final airingAt = DateTime.utc(2026, 10, 16, 14);

      expect(
        broadcastLabel(null, nextAiringAt: airingAt),
        weeklyAirSlotLabel(resolveAirSlot(nextAiringAt: airingAt)!),
      );
    });

    test('and its next-episode wording share the same day and time', () {
      final airingAt = DateTime.utc(2026, 10, 16, 14, 26);
      final slot = resolveAirSlot(nextAiringAt: airingAt)!;

      final weekly = broadcastLabel(null, nextAiringAt: airingAt);
      final next = nextAirSlotLabel(slot);

      // "Fridays, 21:26 your time" and "Friday, 21:26 your time".
      expect(weekly.replaceFirst('s,', ','), next);
    });
  });
}
