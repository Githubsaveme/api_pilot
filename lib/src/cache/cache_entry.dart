/// Wraps a cached HTTP response payload with expiration metadata.
class CacheEntry<T> {
  final T data;
  final dynamic rawData;
  final int statusCode;
  final Map<String, String> headers;
  final DateTime timestamp;
  final Duration duration;

  CacheEntry({
    required this.data,
    required this.rawData,
    required this.statusCode,
    required this.headers,
    required this.timestamp,
    required this.duration,
  });

  /// `true` if the cache entry has exceeded its configured duration.
  bool get isExpired => DateTime.now().isAfter(timestamp.add(duration));
}
