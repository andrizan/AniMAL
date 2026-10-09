class CountEntry {
  const CountEntry(this.label, this.count);

  final String label;
  final int count;
}

class MonthActivity {
  const MonthActivity({required this.month, required this.count});

  final DateTime month;
  final int count;
}

class ProfileInsights {
  const ProfileInsights({
    required this.totalCount,
    required this.scoreCounts,
    required this.genres,
    required this.formats,
    required this.activity,
  });

  final int totalCount;

  /// Number of titles per score, index 0 is a score of 1.
  final List<int> scoreCounts;

  /// Genres by number of titles, most common first.
  final List<CountEntry> genres;

  /// Media types by number of titles, most common first.
  final List<CountEntry> formats;

  /// Titles by the month of their last list update, oldest month first.
  final List<MonthActivity> activity;

  int get ratedCount => scoreCounts.fold(0, (sum, count) => sum + count);

  int? get mostGivenScore {
    var best = -1;
    for (var i = 0; i < scoreCounts.length; i++) {
      if (scoreCounts[i] > 0 &&
          (best < 0 || scoreCounts[i] > scoreCounts[best])) {
        best = i;
      }
    }
    return best < 0 ? null : best + 1;
  }

  int get activityTotal => activity.fold(0, (sum, m) => sum + m.count);
}
