import 'dart:convert';
import 'dart:typed_data';

import 'package:animal/core/network/dio_client.dart';
import 'package:animal/core/storage/secure_token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

class _FakeTokenStorage implements SecureTokenStorage {
  @override
  Future<String?> getAccessToken() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _OkAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'data': [
          for (var i = 0; i < 100; i++) {'id': i},
        ],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _CaptureFilter extends LogFilter {
  final messages = <Object?>[];

  @override
  bool shouldLog(LogEvent event) {
    messages.add(event.message);
    return false;
  }
}

void main() {
  test('request and response bodies are logged lazily', () async {
    final filter = _CaptureFilter();
    final client = DioClient(
      tokenStorage: _FakeTokenStorage(),
      logger: Logger(filter: filter),
    );
    client.dio.httpClientAdapter = _OkAdapter();

    await client.dio.get<dynamic>('/anime');

    final lazy = filter.messages.whereType<Function>();
    final eager = filter.messages.whereType<String>();
    expect(lazy, hasLength(3));
    expect(
      eager.where((m) => m.contains('body:') || m.contains('headers:')),
      isEmpty,
    );
  });
}
