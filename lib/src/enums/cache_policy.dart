/// Specifies the caching strategy for HTTP GET requests.
enum CachePolicy {
  /// Always bypass cache and fetch directly from network (Default).
  networkOnly,

  /// Always serve from cache. Fails with [NotFoundError] if not cached.
  cacheOnly,

  /// Return cached response if available and valid; fallback to network if missing or expired.
  cacheFirst,

  /// Attempt network request first; fallback to cached response if network fails.
  networkFirst,

  /// Immediately return cached response if present, then execute network request in background to update cache.
  staleWhileRevalidate,
}
