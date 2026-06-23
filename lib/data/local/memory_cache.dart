class MemoryCache {
  MemoryCache();

  final _store = <String, _CacheEntry>{};

  T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (_isExpired(entry)) {
      _store.remove(key);
      return null;
    }
    return entry.value as T;
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
  }

  void remove(String key) => _store.remove(key);

  void removeWhere(bool Function(String key) predicate) {
    _store.removeWhere((key, _) => predicate(key));
  }

  void clear() => _store.clear();

  bool _isExpired(_CacheEntry entry) => DateTime.now().isAfter(entry.expiresAt);
}

class _CacheEntry {
  _CacheEntry({required this.value, required this.expiresAt});
  final dynamic value;
  final DateTime expiresAt;
}
