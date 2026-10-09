import 'dart:convert';
import 'dart:typed_data';

import 'package:animal/data/mal/mal_api_client.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _PagedAdapter implements HttpClientAdapter {
  _PagedAdapter(int total, {this.maxLimit = 1000, this.failAtOffset})
    : ids = [for (var i = 1; i <= total; i++) i];

  final List<int> ids;
  final int maxLimit;
  final int? failAtOffset;
  final offsets = <int>[];
  bool insertAfterFirstRequest = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final offset = options.queryParameters['offset'] as int;
    final limit = (options.queryParameters['limit'] as int).clamp(0, maxLimit);
    offsets.add(offset);
    if (offset == failAtOffset) return ResponseBody.fromString('{}', 500);

    final end = (offset + limit).clamp(0, ids.length);
    final page = [
      for (var i = offset; i < end; i++)
        {
          'node': {'id': ids[i], 'title': 'T${ids[i]}'},
        },
    ];
    final body = {
      'data': page,
      'paging': {if (end < ids.length) 'next': 'https://example.test/next'},
    };
    if (insertAfterFirstRequest && offsets.length == 1) ids.insert(0, 99999);
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

MalApiClient _client(_PagedAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..httpClientAdapter = adapter;
  return MalApiClient(dio);
}

void main() {
  group('MalApiClient.getUserAnimeList', () {
    test('empty list needs a single request', () async {
      final adapter = _PagedAdapter(0);

      final out = await _client(adapter).getUserAnimeList();

      expect(out, isEmpty);
      expect(adapter.offsets, [0]);
    });

    test('list within one page needs a single request', () async {
      final adapter = _PagedAdapter(120);

      final out = await _client(adapter)
          .getUserAnimeList(status: WatchStatus.completed);

      expect(out, hasLength(120));
      expect(adapter.offsets, [0]);
    });

    test('follows paging until every entry is fetched', () async {
      final adapter = _PagedAdapter(1200);

      final out = await _client(adapter).getUserAnimeList();

      expect(out.map((a) => a.id).toList(), [
        for (var i = 1; i <= 1200; i++) i,
      ]);
      expect(adapter.offsets, [0, 500, 1000]);
    });

    test('advances by rows received when the server clamps limit', () async {
      final adapter = _PagedAdapter(1200, maxLimit: 300);

      final out = await _client(adapter).getUserAnimeList();

      expect(out, hasLength(1200));
      expect(adapter.offsets, [0, 300, 600, 900]);
    });

    test('drops duplicates when the list shifts between pages', () async {
      final adapter = _PagedAdapter(1200)..insertAfterFirstRequest = true;

      final out = await _client(adapter).getUserAnimeList();

      final ids = out.map((a) => a.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(
        ids.toSet().containsAll([for (var i = 1; i <= 1200; i++) i]),
        isTrue,
      );
    });

    test('a failing page fails the whole fetch', () async {
      final adapter = _PagedAdapter(1200, failAtOffset: 500);

      expect(_client(adapter).getUserAnimeList(), throwsA(isA<DioException>()));
    });
  });
}
