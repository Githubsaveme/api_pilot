# CHANGELOG

## 1.0.1

* Security & Privacy Enhancements: Added production logging protection (`allowProductionLogging`) and expanded sensitive data masking in release mode.
* Improved type safety in `ResponseParser` and model parsing diagnostics.
* Performance optimizations for memory caching and direct-to-disk streaming downloads.

## 1.0.0

* Initial release of **EasyApiKit**.
* Clean 1-line HTTP methods: `get`, `post`, `put`, `patch`, `delete`, `head`, `options`, `form`, `multipart`, `upload`, `download`, `paginate`, and `safeGet`.
* Strongly typed model parsing (`User.fromJson`) for single models and lists.
* Detailed terminal model parse error diagnostics (`ParsingError`) with expected vs received field types.
* Multipart upload support for single/multiple files, bytes, disk paths, and field naming strategies (`arraySuffix`, `repeatKey`, `indexed`).
* In-memory response caching with `CachePolicy` (`cacheFirst`, `networkFirst`, `cacheOnly`, `staleWhileRevalidate`, `networkOnly`).
* Functional pattern-matched `ApiResult` type (`ApiSuccess` / `ApiFailure`) with `.when()`.
* Direct-to-disk file streaming downloads with real-time progress callbacks.
* Pagination helper (`PaginationResult` & `PaginationParser`).
* Built-in `AuthInterceptor` with automated 401 token refresh retries.
* Configurable retry policies with exponential backoff.
* In-flight request cancellation using `CancellationToken`.
* Flutter reactive state management helper `EasyApiController` / `ApiRequestController`.
* Terminal box logger with automatic sensitive data masking (`Authorization`, `password`, `tokens`).
