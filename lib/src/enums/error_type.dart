/// Categorizes API errors into specific actionable types.
enum ApiErrorType {
  /// Unable to reach the server due to no connection, DNS issues, or socket errors.
  network,

  /// Request, connect, send, or receive timeout exceeded.
  timeout,

  /// 401 Unauthorized - Authentication required or token expired.
  unauthorized,

  /// 403 Forbidden - Authenticated but lacks permissions.
  forbidden,

  /// 404 Not Found - Resource does not exist.
  notFound,

  /// 422 Unprocessable Entity or 400 Bad Request with validation errors.
  validation,

  /// 5xx Server Error (500, 502, 503, 504).
  server,

  /// API call succeeded, but model JSON parsing failed.
  parsing,

  /// Failed during multipart file upload.
  upload,

  /// Request was cancelled manually by CancellationToken.
  cancelled,

  /// Device has no internet connectivity.
  offline,

  /// Unknown or unhandled error.
  unknown,
}
