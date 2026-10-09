import 'package:animal/data/models/anilist/anilist_models.dart';
import 'package:animal/data/models/season.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Season.fromDate', () {
    test('maps every month to the right season', () {
      const expected = {
        1: Season.winter,
        2: Season.winter,
        3: Season.winter,
        4: Season.spring,
        5: Season.spring,
        6: Season.spring,
        7: Season.summer,
        8: Season.summer,
        9: Season.summer,
        10: Season.fall,
        11: Season.fall,
        12: Season.fall,
      };
      expected.forEach((month, season) {
        expect(
          Season.fromDate(DateTime(2026, month, 15)),
          season,
          reason: 'month $month',
        );
      });
    });

    test('uses boundary days correctly', () {
      expect(Season.fromDate(DateTime(2026, 3, 31)), Season.winter);
      expect(Season.fromDate(DateTime(2026, 4)), Season.spring);
      expect(Season.fromDate(DateTime(2026, 12, 31)), Season.fall);
    });

    test('exposes api values, labels and year', () {
      expect(Season.values.map((s) => s.value), [
        'winter',
        'spring',
        'summer',
        'fall',
      ]);
      expect(Season.fall.label, 'Fall');
      expect(Season.yearFromDate(DateTime(2031, 6)), 2031);
    });
  });

  test('WatchStatus exposes api values and labels', () {
    expect(WatchStatus.onHold.value, 'on_hold');
    expect(WatchStatus.planToWatch.value, 'plan_to_watch');
    expect(WatchStatus.values.map((s) => s.label), [
      'Watching',
      'Completed',
      'On Hold',
      'Dropped',
      'Plan to Watch',
    ]);
  });

  group('AniListNextAiring', () {
    AniListNextAiring next(int seconds) => AniListNextAiring(
      airingAt: DateTime(2026),
      episode: 1,
      timeUntilAiring: seconds,
    );

    test('countdown formats days, hours and minutes', () {
      expect(next(2 * 86400 + 5 * 3600 + 59).countdown, '2d 5h');
      expect(next(86400).countdown, '1d 0h');
      expect(next(3 * 3600 + 20 * 60).countdown, '3h 20m');
      expect(next(45 * 60).countdown, '45m');
      expect(next(30).countdown, '0m');
    });

    test('countdown reports aired for zero or negative time', () {
      expect(next(0).countdown, 'Aired');
      expect(next(-120).countdown, 'Aired');
    });

    test('isUrgent is true only inside the last six hours', () {
      expect(next(0).isUrgent, isFalse);
      expect(next(-1).isUrgent, isFalse);
      expect(next(1).isUrgent, isTrue);
      expect(next(21599).isUrgent, isTrue);
      expect(next(21600).isUrgent, isFalse);
    });
  });

  group('AniListExternalLink.displaySite', () {
    test('prefers the declared site name', () {
      const link = AniListExternalLink(
        id: 1,
        url: 'https://x.test/a',
        site: 'Crunchyroll',
      );
      expect(link.displaySite, 'Crunchyroll');
    });

    test('falls back to the host when the site is missing or empty', () {
      expect(
        const AniListExternalLink(
          id: 1,
          url: 'https://www.netflix.com/title/1',
        ).displaySite,
        'www.netflix.com',
      );
      expect(
        const AniListExternalLink(
          id: 1,
          url: 'https://a.test/x',
          site: '',
        ).displaySite,
        'a.test',
      );
    });

    test('returns the raw url when it cannot be parsed', () {
      const link = AniListExternalLink(id: 1, url: 'http://[bad');
      expect(link.displaySite, 'http://[bad');
    });
  });
}
