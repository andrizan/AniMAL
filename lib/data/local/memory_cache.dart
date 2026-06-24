class MemoryCache {
  MemoryCache();

  final _store = <String, _CacheEntry>{};
  int _putCount = 0;

  static const _cleanupInterval = 50;

  T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (_isExpired(entry)) {
      _store.remove(key);
      return null;
    }
    if (entry.value is! T) {
      _store.remove(key);
      return null;
    }
    return entry.value as T;
  }

  List<({String key, T value})> getWhere<T>(
    bool Function(String key) predicate,
  ) {
    final results = <({String key, T value})>[];
    _store.removeWhere((key, entry) {
      if (_isExpired(entry)) return true;
      return false;
    });
    for (final entry in _store.entries) {
      if (predicate(entry.key) && entry.value.value is T) {
        results.add((key: entry.key, value: entry.value.value as T));
      }
    }
    return results;
  }

  void put<T>(
    String key,
    T value, {
    Duration ttl = const Duration(minutes: 15),
  }) {
    _store[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl),
    );
    _putCount++;
    if (_putCount % _cleanupInterval == 0) {
      _evictExpired();
    }
  }

  void remove(String key) => _store.remove(key);

  void removeWhere(bool Function(String key) predicate) {
    _store.removeWhere((key, _) => predicate(key));
  }

  void clear() => _store.clear();

  void _evictExpired() {
    final now = DateTime.now();
    _store.removeWhere((_, entry) => now.isAfter(entry.expiresAt));
  }

  bool _isExpired(_CacheEntry entry) => DateTime.now().isAfter(entry.expiresAt);
}

class _CacheEntry {
  _CacheEntry({required this.value, required this.expiresAt});
  final dynamic value;
  final DateTime expiresAt;
}
