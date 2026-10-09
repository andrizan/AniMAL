import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class FakeResponse {
  const FakeResponse.json(
    Object? body, {
    this.status = 200,
    this.headers = const {},
  }) : raw = null,
       _json = body;

  const FakeResponse.raw(
    String body, {
    this.status = 200,
    this.headers = const {},
  }) : raw = body,
       _json = null;

  final int status;
  final Map<String, List<String>> headers;
  final String? raw;
  final Object? _json;

  String get body => raw ?? jsonEncode(_json);
}

typedef FakeHandler = FutureOr<FakeResponse> Function(RequestOptions options);

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final FakeHandler handler;
  final List<RequestOptions> requests = [];

  int count(bool Function(RequestOptions o) where) =>
      requests.where(where).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final r = await handler(options);
    return ResponseBody.fromString(
      r.body,
      r.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...r.headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio fakeDio(FakeAdapter adapter, {String baseUrl = 'https://api.test/v2'}) =>
    Dio(BaseOptions(baseUrl: baseUrl))..httpClientAdapter = adapter;
