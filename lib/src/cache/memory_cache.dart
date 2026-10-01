import 'cache_entry.dart';

/// In-memory cache store for HTTP response payloads.
class MemoryCache {
  final Map<String, CacheEntry<dynamic>> _store = {};

  /// Stores a value in memory cache with specified duration TTL.
  void set<T>({
    required String key,
    required T data,
    required dynamic rawData,
    required int statusCode,
    required Map<String, String> headers,
    required Duration duration,
  }) {
    _store[key] = CacheEntry<T>(
      data: data,
      rawData: rawData,
      statusCode: statusCode,
      headers: headers,
      timestamp: DateTime.now(),
      duration: duration,
    );
  }

  /// Retrieves a valid non-expired cache entry for [key].
  CacheEntry<dynamic>? get(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _store.remove(key);
      return null;
    }
    return entry;
  }

  /// Removes a key from cache.
  void remove(String key) {
    _store.remove(key);
  }

  /// Clears all entries from cache.
  void clear() {
    _store.clear();
  }
}
