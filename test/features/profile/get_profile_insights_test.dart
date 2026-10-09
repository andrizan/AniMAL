import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/features/profile/domain/entities/profile_insights.dart';
import 'package:animal/features/profile/domain/usecases/get_profile_insights.dart';
import 'package:flutter_test/flutter_test.dart';

Anime _anime(
  int id, {
  int? score,
  List<String> genres = const [],
  String? type,
  String? updatedAt,
  bool withStatus = true,
}) => Anime(
  id: id,
  title: 'Anime $id',
  mediaType: type,
  genres: [
    for (var i = 0; i < genres.length; i++) Genre(id: i, name: genres[i]),
  ],
  myListStatus: withStatus
      ? MyListStatus(
          status: WatchStatus.completed,
          score: score,
          updatedAt: updatedAt,
        )
      : null,
);

void main() {
  const useCase = GetProfileInsights();
  final now = DateTime(2026, 10, 10, 12);

  ProfileInsights run(List<Anime> list) => useCase(list, now: now);

  test('an empty list gives empty insights', () {
    final insights = run(const []);

    expect(insights.totalCount, 0);
    expect(insights.ratedCount, 0);
    expect(insights.mostGivenScore, isNull);
    expect(insights.genres, isEmpty);
    expect(insights.formats, isEmpty);
    expect(insights.scoreCounts, List.filled(10, 0));
    expect(insights.activity, hasLength(12));
    expect(insights.activityTotal, 0);
  });

  group('scores', () {
    test('count titles per score', () {
      final insights = run([
        _anime(1, score: 8),
        _anime(2, score: 8),
        _anime(3, score: 10),
        _anime(4, score: 1),
      ]);

      expect(insights.scoreCounts, [1, 0, 0, 0, 0, 0, 0, 2, 0, 1]);
      expect(insights.ratedCount, 4);
      expect(insights.mostGivenScore, 8);
    });

    test('unrated, out of range and status-less titles are not counted', () {
      final insights = run([
        _anime(1, score: 0),
        _anime(2),
        _anime(3, score: 11),
        _anime(4, score: -1),
        _anime(5, withStatus: false),
        _anime(6, score: 5),
      ]);

      expect(insights.ratedCount, 1);
      expect(insights.mostGivenScore, 5);
      expect(insights.totalCount, 6);
    });

    test('a tie goes to the lower score', () {
      final insights = run([_anime(1, score: 9), _anime(2, score: 4)]);

      expect(insights.mostGivenScore, 4);
    });
  });

  group('genres and formats', () {
    test('are ranked by count, then by name', () {
      final insights = run([
        _anime(1, genres: ['Drama', 'Action'], type: 'tv'),
        _anime(2, genres: ['Action'], type: 'tv'),
        _anime(3, genres: ['Comedy'], type: 'movie'),
        _anime(4, genres: ['Comedy', 'Action'], type: 'ova'),
      ]);

      expect(insights.genres.map((g) => (g.label, g.count)), [
        ('Action', 3),
        ('Comedy', 2),
        ('Drama', 1),
      ]);
      expect(insights.formats.map((f) => (f.label, f.count)), [
        ('TV', 2),
        ('Movie', 1),
        ('OVA', 1),
      ]);
    });

    test('formats use readable labels and skip missing types', () {
      final insights = run([
        _anime(1, type: 'tv_special'),
        _anime(2),
        _anime(3, type: ''),
      ]);

      expect(insights.formats.map((f) => f.label), ['TV Special']);
    });
  });

  test('a title that appears twice is counted once', () {
    final insights = run([
      _anime(1, score: 7, genres: ['Action']),
      _anime(1, score: 7, genres: ['Action']),
    ]);

    expect(insights.totalCount, 1);
    expect(insights.ratedCount, 1);
    expect(insights.genres.single.count, 1);
  });

  group('activity', () {
    test('covers twelve months ending with the current one', () {
      final months = run(const []).activity.map((m) => m.month).toList();

      expect(months.first, DateTime(2025, 11));
      expect(months.last, DateTime(2026, 10));
      expect(months, hasLength(12));
    });

    test('buckets titles by the month of their last update', () {
      final insights = run([
        _anime(1, updatedAt: DateTime(2026, 10, 3, 12).toIso8601String()),
        _anime(2, updatedAt: DateTime(2026, 10, 9, 12).toIso8601String()),
        _anime(3, updatedAt: DateTime(2026, 1, 15, 12).toIso8601String()),
        _anime(4, updatedAt: DateTime(2025, 11, 15, 12).toIso8601String()),
      ]);

      final counts = insights.activity.map((m) => m.count).toList();
      expect(counts.first, 1);
      expect(counts.last, 2);
      expect(counts[2], 1);
      expect(insights.activityTotal, 4);
    });

    test('ignores updates outside the window and unreadable dates', () {
      final insights = run([
        _anime(1, updatedAt: DateTime(2025, 10, 15, 12).toIso8601String()),
        _anime(2, updatedAt: DateTime(2026, 11, 15, 12).toIso8601String()),
        _anime(3, updatedAt: 'garbage'),
        _anime(4),
      ]);

      expect(insights.activityTotal, 0);
    });

    test('works across a year boundary', () {
      final january = GetProfileInsights()([
        _anime(1, updatedAt: DateTime(2025, 12, 5, 12).toIso8601String()),
      ], now: DateTime(2026, 1, 20));

      expect(january.activity.first.month, DateTime(2025, 2));
      expect(january.activity.last.month, DateTime(2026, 1));
      expect(january.activity[10].count, 1);
    });
  });
}
