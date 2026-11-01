import 'package:animal/core/router/deep_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? map(String url) => oauthCallbackLocation(Uri.parse(url));

  group('the MAL redirect', () {
    test('maps to the in-app callback route with code and state', () {
      expect(
        map('animal://oauth/callback?code=abc123&state=xyz'),
        '/oauth/callback?code=abc123&state=xyz',
      );
    });

    test('works without a state', () {
      expect(
        map('animal://oauth/callback?code=abc123'),
        '/oauth/callback?code=abc123',
      );
    });

    test('keeps special characters intact instead of corrupting the url', () {
      final uri = Uri(
        scheme: 'animal',
        host: 'oauth',
        path: '/callback',
        queryParameters: {'code': 'a+b&c=d%20/e', 'state': 'x y&z'},
      );

      final location = oauthCallbackLocation(uri)!;
      final params = Uri.parse(location).queryParameters;

      expect(Uri.parse(location).path, '/oauth/callback');
      expect(params['code'], 'a+b&c=d%20/e');
      expect(params['state'], 'x y&z');
    });

    test('still opens the callback page when the user denied access', () {
      expect(
        map('animal://oauth/callback?error=access_denied&state=xyz'),
        '/oauth/callback?state=xyz',
      );
      expect(map('animal://oauth/callback'), '/oauth/callback');
    });
  });

  group('anything else is ignored', () {
    test('another scheme', () {
      expect(map('https://oauth/callback?code=abc'), isNull);
    });

    test('another host', () {
      expect(map('animal://anime/callback?code=abc'), isNull);
    });

    test('another path', () {
      expect(map('animal://oauth/other?code=abc'), isNull);
      expect(map('animal://oauth/callback/extra?code=abc'), isNull);
    });
  });

  group('a MyAnimeList anime page', () {
    int? id(String url) => malAnimeId(Uri.parse(url));

    test('gives the anime id', () {
      expect(id('https://myanimelist.net/anime/5114'), 5114);
      expect(id('https://myanimelist.net/anime/5114/'), 5114);
    });

    test('ignores the title slug and any sub page', () {
      expect(
        id(
          'https://myanimelist.net/anime/5114/Fullmetal_Alchemist__Brotherhood',
        ),
        5114,
      );
      expect(id('https://myanimelist.net/anime/5114/x/reviews?p=2'), 5114);
      expect(id('https://myanimelist.net/anime/5114?q=1#top'), 5114);
    });

    test('works on the www host and over http', () {
      expect(id('https://www.myanimelist.net/anime/1'), 1);
      expect(id('http://myanimelist.net/anime/1'), 1);
    });

    test('is not an anime page without a numeric id', () {
      expect(id('https://myanimelist.net/anime/season/2026/fall'), isNull);
      expect(id('https://myanimelist.net/anime/genre/1/Action'), isNull);
      expect(id('https://myanimelist.net/anime'), isNull);
      expect(id('https://myanimelist.net/anime/0'), isNull);
      expect(id('https://myanimelist.net/anime/-3'), isNull);
    });

    test('is not another MyAnimeList page', () {
      expect(id('https://myanimelist.net/manga/5114'), isNull);
      expect(id('https://myanimelist.net/profile/someone'), isNull);
      expect(
        id('https://myanimelist.net/v1/oauth2/authorize?client_id=1'),
        isNull,
      );
    });

    test('is not another site or scheme', () {
      expect(id('https://example.com/anime/5114'), isNull);
      expect(id('https://notmyanimelist.net/anime/5114'), isNull);
      expect(id('https://myanimelist.net.evil.test/anime/5114'), isNull);
      expect(id('animal://myanimelist.net/anime/5114'), isNull);
    });
  });
}
