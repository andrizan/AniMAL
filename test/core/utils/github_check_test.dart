import 'package:animal/core/config/env.dart';
import 'package:animal/core/utils/github_check.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_adapter.dart';

void main() {
  test('returns the latest release json', () async {
    final adapter = FakeAdapter(
      (_) => const FakeResponse.json({
        'tag_name': 'v2.9.0',
        'html_url': 'https://github.com/andrizan/AniMAL/releases/tag/v2.9.0',
        'body': 'notes',
      }),
    );

    final release = await fetchLatestRelease(dio: fakeDio(adapter));

    expect(release!['tag_name'], 'v2.9.0');
    expect(
      adapter.requests.single.uri.toString(),
      Env.githubReleasesUrl(Env.githubRepo),
    );
  });

  test('is null when GitHub is unreachable or rate limited', () async {
    for (final status in [403, 404, 500]) {
      final adapter = FakeAdapter((_) => FakeResponse.json({}, status: status));

      expect(
        await fetchLatestRelease(dio: fakeDio(adapter)),
        isNull,
        reason: '$status',
      );
    }
  });

  test('is null on a connection error', () async {
    final dio = Dio()..httpClientAdapter = _Offline();

    expect(await fetchLatestRelease(dio: dio), isNull);
  });
}

class _Offline implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => throw DioException(
    requestOptions: options,
    type: DioExceptionType.connectionError,
  );

  @override
  void close({bool force = false}) {}
}
