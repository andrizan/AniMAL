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
}
