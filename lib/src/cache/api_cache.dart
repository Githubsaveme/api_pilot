import 'memory_cache.dart';

/// Core caching manager for EasyApiKit.
class ApiCache {
  final MemoryCache _memoryCache = MemoryCache();

  /// Accesses underlying memory cache.
  MemoryCache get store => _memoryCache;

  /// Generates a cache key for request.
  String generateKey(String method, String url, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) {
      return '$method:$url';
    }
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return '$method:$url:${sortedParams.toString()}';
  }

  /// Clears all cached entries.
  void clear() {
    _memoryCache.clear();
  }
}
