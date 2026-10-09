import 'package:animal/core/utils/anime_labels.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/features/profile/domain/entities/profile_insights.dart';

class GetProfileInsights {
  const GetProfileInsights();

  static const activityMonths = 12;

  ProfileInsights call(Iterable<Anime> anime, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final firstMonth = DateTime(
      reference.year,
      reference.month - (activityMonths - 1),
    );
    final seen = <int>{};
    final scoreCounts = List<int>.filled(10, 0);
    final genres = <String, int>{};
    final formats = <String, int>{};
    final activity = List<int>.filled(activityMonths, 0);

    for (final item in anime) {
      if (!seen.add(item.id)) continue;
      final listStatus = item.myListStatus;

      final score = listStatus?.score ?? 0;
      if (score >= 1 && score <= 10) scoreCounts[score - 1]++;

      for (final genre in item.genres) {
        genres.update(genre.name, (count) => count + 1, ifAbsent: () => 1);
      }

      final type = item.mediaType;
      if (type != null && type.isNotEmpty) {
        formats.update(
          AnimeLabels.mediaTypeLabel(type),
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }

      final updated = DateTime.tryParse(listStatus?.updatedAt ?? '')?.toLocal();
      if (updated != null) {
        final index =
            (updated.year - firstMonth.year) * 12 +
            updated.month -
            firstMonth.month;
        if (index >= 0 && index < activityMonths) activity[index]++;
      }
    }

    return ProfileInsights(
      totalCount: seen.length,
      scoreCounts: scoreCounts,
      genres: _ranked(genres),
      formats: _ranked(formats),
      activity: [
        for (var i = 0; i < activityMonths; i++)
          MonthActivity(
            month: DateTime(firstMonth.year, firstMonth.month + i),
            count: activity[i],
          ),
      ],
    );
  }

  List<CountEntry> _ranked(Map<String, int> counts) {
    final entries = [for (final e in counts.entries) CountEntry(e.key, e.value)]
      ..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        return byCount != 0 ? byCount : a.label.compareTo(b.label);
      });
    return entries;
  }
}
