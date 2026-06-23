import 'dart:convert';

import 'package:animal/core/storage/prefs_storage.dart';

class CacheService {
  CacheService(this._prefs);

  final PrefsStorage _prefs;

  static const _prefix = 'cache_';

  Future<void> put<T>(String key, T value, {Duration ttl = const Duration(minutes: 15)}) async {
    final entry = _CacheEntry(
      data: jsonEncode(value),
      expiresAt: DateTime.now().millisecondsSinceEpoch + ttl.inMilliseconds,
    );
    await _prefs.setString('$_prefix$key', jsonEncode(entry.toJson()));
  }

  T? get<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final entry = _CacheEntry.fromJson(map);
      if (entry.isExpired) {
        _prefs.remove('$_prefix$key');
        return null;
      }
      return fromJson(jsonDecode(entry.data) as Map<String, dynamic>);
    } on Exception {
      return null;
    }
  }

  List<T>? getList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final entry = _CacheEntry.fromJson(map);
      if (entry.isExpired) {
        _prefs.remove('$_prefix$key');
        return null;
      }
      final list = jsonDecode(entry.data) as List<dynamic>;
      return list
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    } on Exception {
      return null;
    }
  }

  Future<void> remove(String key) => _prefs.remove('$_prefix$key');

  Future<void> clearAll() async {
    // Not ideal but works for small caches; in production use a dedicated DB
  }
}

class _CacheEntry {
  _CacheEntry({required this.data, required this.expiresAt});

  final String data;
  final int expiresAt;

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;

  Map<String, dynamic> toJson() => {'data': data, 'expiresAt': expiresAt};

  factory _CacheEntry.fromJson(Map<String, dynamic> json) => _CacheEntry(
        data: json['data'] as String,
        expiresAt: json['expiresAt'] as int,
      );
}
