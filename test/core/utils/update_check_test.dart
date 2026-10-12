import 'package:animal/core/config/env.dart';
import 'package:animal/core/utils/update_check.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _release(
  String tag, {
  String url = 'https://github.com/andrizan/AniMAL/releases/tag/x',
}) => {'tag_name': tag, 'html_url': url, 'body': 'notes'};

Future<AppUpdate?> _check(
  Map<String, dynamic>? release, {
  String installed = '2.10.0',
}) => findNewerRelease(
  fetchRelease: () async => release,
  currentVersion: () async => installed,
);

void main() {
  group('a newer release', () {
    test('is reported with its version and page', () async {
      final update = await _check(
        _release('v2.11.0', url: 'https://example.test/r'),
      );

      expect(update, (version: '2.11.0', url: 'https://example.test/r'));
    });

    test('is found across a major, minor and patch step', () async {
      for (final tag in ['v3.0.0', 'v2.11.0', 'v2.10.1', 'v2.10.0.1']) {
        expect((await _check(_release(tag)))?.version, tag.substring(1));
      }
    });

    test('is found when the tag has no v', () async {
      expect((await _check(_release('2.11.0')))?.version, '2.11.0');
    });

    test('is found when the tag has a capital V', () async {
      expect((await _check(_release('V2.11.0')))?.version, '2.11.0');
    });

    test('is compared as numbers, not text', () async {
      expect(
        (await _check(_release('v2.10.0'), installed: '2.9.0'))?.version,
        '2.10.0',
      );
    });

    test('ignores the build number of the installed app', () async {
      expect(await _check(_release('v2.10.0'), installed: '2.10.0+13'), isNull);
      expect(
        (await _check(_release('v2.10.1'), installed: '2.10.0+13'))?.version,
        '2.10.1',
      );
    });

    test('falls back to the releases page when the url is missing', () async {
      final update = await _check({'tag_name': 'v2.11.0'});

      expect(update?.url, '${Env.githubRepoUrl}/releases/latest');
    });

    test('falls back to the releases page when the url is empty', () async {
      final update = await _check(_release('v2.11.0', url: ''));

      expect(update?.url, '${Env.githubRepoUrl}/releases/latest');
    });
  });

  group('nothing to announce', () {
    test('when the installed version is the latest', () async {
      expect(await _check(_release('v2.10.0')), isNull);
    });

    test('when the installed version is ahead of the release', () async {
      expect(await _check(_release('v2.9.0')), isNull);
      expect(await _check(_release('v2.10.0'), installed: '2.10.1'), isNull);
    });

    test(
      'when the release is a pre-release of the installed version',
      () async {
        expect(await _check(_release('v2.10.0-beta')), isNull);
      },
    );

    test('when the lookup returned nothing', () async {
      expect(await _check(null), isNull);
    });

    test('when the release has no tag', () async {
      expect(await _check({'html_url': 'https://example.test'}), isNull);
      expect(await _check({'tag_name': ''}), isNull);
      expect(await _check({'tag_name': null}), isNull);
    });

    test('when the tag is not a version', () async {
      expect(await _check(_release('nightly')), isNull);
      expect(await _check(_release('latest')), isNull);
    });
  });

  group('failures never escape', () {
    test('a lookup that throws', () async {
      final update = await findNewerRelease(
        fetchRelease: () async => throw Exception('offline'),
        currentVersion: () async => '2.10.0',
      );

      expect(update, isNull);
    });

    test('an installed version that cannot be read', () async {
      final update = await findNewerRelease(
        fetchRelease: () async => _release('v2.11.0'),
        currentVersion: () async => throw StateError('no platform'),
      );

      expect(update, isNull);
    });

    test('a release with the wrong shape', () async {
      expect(await _check({'tag_name': 5}), isNull);
      expect(await _check({'tag_name': 'v2.11.0', 'html_url': 7}), isNull);
    });
  });

  test('the installed version is only read once a release exists', () async {
    var reads = 0;

    await findNewerRelease(
      fetchRelease: () async => null,
      currentVersion: () async {
        reads++;
        return '2.10.0';
      },
    );

    expect(reads, 0);
  });
}
