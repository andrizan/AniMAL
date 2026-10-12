import 'package:animal/data/models/broadcast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Broadcast', () {
    test('reads MAL snake case keys', () {
      final b = Broadcast.fromJson({
        'day_of_week': 'friday',
        'start_time': '23:00',
      });

      expect(b.dayOfWeek, 'friday');
      expect(b.startTime, '23:00');
    });

    test('tolerates a broadcast with only a day', () {
      final b = Broadcast.fromJson({'day_of_week': 'friday'});

      expect(b.dayOfWeek, 'friday');
      expect(b.startTime, isNull);
    });

    test('tolerates an empty broadcast', () {
      final b = Broadcast.fromJson({});

      expect(b.dayOfWeek, isNull);
      expect(b.startTime, isNull);
    });

    test('writes the same keys back', () {
      const b = Broadcast(dayOfWeek: 'monday', startTime: '04:13');

      expect(b.toJson(), {'day_of_week': 'monday', 'start_time': '04:13'});
      expect(Broadcast.fromJson(b.toJson()), b);
    });

    test('equal values are equal', () {
      const a = Broadcast(dayOfWeek: 'monday', startTime: '04:13');
      const b = Broadcast(dayOfWeek: 'monday', startTime: '04:13');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(const Broadcast(dayOfWeek: 'monday', startTime: '04:14')),
      );
    });

    test('copyWith changes only what it is given', () {
      const a = Broadcast(dayOfWeek: 'monday', startTime: '04:13');

      final b = a.copyWith(startTime: '05:00');

      expect(b.dayOfWeek, 'monday');
      expect(b.startTime, '05:00');
    });
  });
}
