/// Specifies the verbosity of terminal logs.
enum ApiLogLevel {
  /// Disable all logs.
  none,

  /// Log request method, URL, and status code only.
  basic,

  /// Basic info plus request/response headers.
  headers,

  /// Basic info plus request/response body payload.
  body,

  /// Log everything: method, URL, status, headers, body, timing, and errors.
  full,
}
