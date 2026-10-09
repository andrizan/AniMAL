import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/utils/anime_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('statusLabel', () {
    test('maps known statuses in both modes', () {
      expect(AnimeLabels.statusLabel('currently_airing'), 'Airing');
      expect(
        AnimeLabels.statusLabel('currently_airing', compact: true),
        'AIRING',
      );
      expect(AnimeLabels.statusLabel('finished_airing'), 'Finished');
      expect(
        AnimeLabels.statusLabel('finished_airing', compact: true),
        'FINISHED',
      );
      expect(AnimeLabels.statusLabel('not_yet_aired'), 'Upcoming');
      expect(
        AnimeLabels.statusLabel('not_yet_aired', compact: true),
        'UPCOMING',
      );
    });

    test('falls back to the raw value, or empty for null', () {
      expect(AnimeLabels.statusLabel('weird'), 'weird');
      expect(AnimeLabels.statusLabel(null), '');
    });
  });

  test('statusColor uses the shared palette', () {
    expect(AnimeLabels.statusColor('currently_airing'), AppColors.statusAiring);
    expect(
      AnimeLabels.statusColor('finished_airing'),
      AppColors.statusFinished,
    );
    expect(AnimeLabels.statusColor('not_yet_aired'), AppColors.statusUpcoming);
    expect(AnimeLabels.statusColor(null), AppColors.statusDefault);
    expect(AnimeLabels.statusColor('other'), AppColors.statusDefault);
  });

  group('ratingLabel', () {
    test('maps every MAL rating', () {
      expect(AnimeLabels.ratingLabel('g'), 'G - All Ages');
      expect(AnimeLabels.ratingLabel('g', compact: true), 'G');
      expect(AnimeLabels.ratingLabel('pg'), 'PG - Children');
      expect(AnimeLabels.ratingLabel('pg_13'), 'PG-13');
      expect(AnimeLabels.ratingLabel('pg_13', compact: true), 'PG-13');
      expect(AnimeLabels.ratingLabel('r'), 'R - 17+');
      expect(AnimeLabels.ratingLabel('r+'), 'R+ - Profanity');
      expect(AnimeLabels.ratingLabel('rx'), 'Rx - Hentai');
      expect(AnimeLabels.ratingLabel('rx', compact: true), 'Rx');
    });

    test('falls back safely', () {
      expect(AnimeLabels.ratingLabel('xyz'), 'xyz');
      expect(AnimeLabels.ratingLabel(null), '');
    });
  });

  group('mediaTypeLabel', () {
    test('maps every media type', () {
      expect(AnimeLabels.mediaTypeLabel('tv'), 'TV');
      expect(AnimeLabels.mediaTypeLabel('movie'), 'Movie');
      expect(AnimeLabels.mediaTypeLabel('movie', compact: true), 'MOVIE');
      expect(AnimeLabels.mediaTypeLabel('ova'), 'OVA');
      expect(AnimeLabels.mediaTypeLabel('ona'), 'ONA');
      expect(AnimeLabels.mediaTypeLabel('special'), 'Special');
      expect(AnimeLabels.mediaTypeLabel('special', compact: true), 'SP');
      expect(AnimeLabels.mediaTypeLabel('music'), 'Music');
      expect(AnimeLabels.mediaTypeLabel('music', compact: true), 'MV');
      expect(AnimeLabels.mediaTypeLabel('tv_special'), 'TV Special');
      expect(AnimeLabels.mediaTypeLabel('tv_special', compact: true), 'TV SP');
      expect(AnimeLabels.mediaTypeLabel('cm'), 'CM');
      expect(AnimeLabels.mediaTypeLabel('pv'), 'PV');
    });

    test('falls back safely', () {
      expect(AnimeLabels.mediaTypeLabel('weird'), 'weird');
      expect(AnimeLabels.mediaTypeLabel(null), '');
    });
  });

  test('sourceLabel maps every source and falls back', () {
    const expected = {
      'original': 'Original',
      'manga': 'Manga',
      'light_novel': 'Light Novel',
      'visual_novel': 'Visual Novel',
      'video_game': 'Video Game',
      'other': 'Other',
      'novel': 'Novel',
      'doujinshi': 'Doujinshi',
      'anime': 'Anime',
      'web_manga': 'Web Manga',
      'web_novel': 'Web Novel',
      'game': 'Game',
      'comic': 'Comic',
      'multimedia_project': 'Multimedia Project',
      'picture_book': 'Picture Book',
    };
    expected.forEach((raw, label) {
      expect(AnimeLabels.sourceLabel(raw), label, reason: raw);
    });
    expect(AnimeLabels.sourceLabel('unknown_source'), 'unknown_source');
    expect(AnimeLabels.sourceLabel(null), '');
  });

  test('seasonLabel maps seasons and falls back', () {
    expect(AnimeLabels.seasonLabel('winter'), 'Winter');
    expect(AnimeLabels.seasonLabel('spring'), 'Spring');
    expect(AnimeLabels.seasonLabel('summer'), 'Summer');
    expect(AnimeLabels.seasonLabel('fall'), 'Fall');
    expect(AnimeLabels.seasonLabel('monsoon'), 'monsoon');
    expect(AnimeLabels.seasonLabel(null), '');
  });

  group('durationLabel', () {
    test('is empty for missing or non-positive durations', () {
      expect(AnimeLabels.durationLabel(null), '');
      expect(AnimeLabels.durationLabel(0), '');
      expect(AnimeLabels.durationLabel(-60), '');
    });

    test('formats minutes, whole hours, and hours with minutes', () {
      expect(AnimeLabels.durationLabel(1440), '24m');
      expect(AnimeLabels.durationLabel(59 * 60), '59m');
      expect(AnimeLabels.durationLabel(3600), '1h');
      expect(AnimeLabels.durationLabel(7200), '2h');
      expect(AnimeLabels.durationLabel(5400), '1h 30m');
      expect(AnimeLabels.durationLabel(7 * 3600 + 20 * 60), '7h 20m');
    });
  });

  group('cleanAniListDescription', () {
    test('strips bbcode-like tags', () {
      expect(cleanAniListDescription('a [b]bold[/b] [i]it[/i]'), 'a bold it');
    });

    test('replaces spoilers, even several on one line', () {
      expect(
        cleanAniListDescription('x ~!secret!~ y ~!more!~'),
        'x [Spoiler] y [Spoiler]',
      );
    });

    test('decodes entities and line breaks', () {
      expect(
        cleanAniListDescription(
          'Tom &amp; Jerry&#039;s &quot;show&quot;<br>next<br/>line',
        ),
        'Tom & Jerry\'s "show"\nnext\nline',
      );
    });

    test('leaves plain text alone', () {
      expect(cleanAniListDescription('Just text.'), 'Just text.');
    });
  });
}
