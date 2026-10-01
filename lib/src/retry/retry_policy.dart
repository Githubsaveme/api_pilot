import '../enums/error_type.dart';
import '../enums/http_method.dart';
import '../errors/api_error.dart';

/// Evaluates and handles request retry logic for transient failures.
class RetryPolicy {
  final int retryCount;
  final Duration retryDelay;
  final List<HttpMethod> retryOnMethods;

  const RetryPolicy({
    this.retryCount = 0,
    this.retryDelay = const Duration(seconds: 1),
    this.retryOnMethods = const [
      HttpMethod.get,
      HttpMethod.head,
      HttpMethod.options,
    ],
  });

  /// Evaluates whether an error condition qualifies for retry.
  bool shouldRetry({
    required ApiError error,
    required int attemptNumber,
    required HttpMethod method,
  }) {
    if (attemptNumber >= retryCount) {
      return false;
    }

    if (!retryOnMethods.contains(method)) {
      return false;
    }

    // Always retry network timeouts and socket connectivity issues
    if (error.type == ApiErrorType.network || error.type == ApiErrorType.timeout) {
      return true;
    }

    // Retry transient 502 Bad Gateway, 503 Service Unavailable, 504 Gateway Timeout
    if (error.type == ApiErrorType.server) {
      final status = error.statusCode;
      if (status == 502 || status == 503 || status == 504) {
        return true;
      }
    }

    return false;
  }

  /// Calculates delay before next retry attempt (with linear or exponential delay).
  Duration getDelay(int attemptNumber) {
    return retryDelay * attemptNumber;
  }
}
