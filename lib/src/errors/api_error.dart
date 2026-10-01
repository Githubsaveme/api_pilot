import 'package:flutter/foundation.dart';
import '../enums/error_type.dart';

/// Base exception class for all errors generated or handled by EasyApiKit.
abstract class ApiError implements Exception {
  /// User-friendly message explaining what went wrong.
  final String message;

  /// Specific error type classification.
  final ApiErrorType type;

  /// HTTP response status code if available (e.g. 404, 500).
  final int? statusCode;

  /// Raw response body or error payload returned by server.
  final dynamic rawData;

  /// Requested endpoint path or full URL.
  final String? endpoint;

  /// HTTP method used (GET, POST, etc.).
  final String? method;

  /// Map of validation errors returned by backend (e.g., `{"email": ["Invalid email address"]}`).
  final Map<String, List<String>> validationErrors;

  /// Underlying cause or original exception (e.g., SocketException).
  final Object? cause;

  /// Stack trace associated with the original error.
  final StackTrace? stackTrace;

  const ApiError({
    required this.message,
    required this.type,
    this.statusCode,
    this.rawData,
    this.endpoint,
    this.method,
    this.validationErrors = const {},
    this.cause,
    this.stackTrace,
  });

  /// Detailed human-readable explanation of why this error likely occurred.
  String get explanation;

  /// List of potential developer troubleshooting steps to resolve the error.
  List<String> get solutionSteps;

  /// Renders a terminal-friendly string representation of the error.
  String toFormattedString() {
    final buffer = StringBuffer();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('EASY API KIT - ERROR [${type.name.toUpperCase()}]');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    if (method != null || endpoint != null) {
      buffer.writeln('Endpoint : ${method ?? ''} ${endpoint ?? ''}'.trim());
    }
    if (statusCode != null) {
      buffer.writeln('Status   : $statusCode');
    }
    buffer.writeln('Message  : $message');
    buffer.writeln('');
    buffer.writeln('EXPLANATION:');
    buffer.writeln(explanation);
    buffer.writeln('');
    if (validationErrors.isNotEmpty) {
      buffer.writeln('VALIDATION ERRORS:');
      validationErrors.forEach((key, messages) {
        buffer.writeln('  • $key: ${messages.join(", ")}');
      });
      buffer.writeln('');
    }
    final steps = solutionSteps;
    if (steps.isNotEmpty) {
      buffer.writeln('POSSIBLE SOLUTIONS:');
      for (var i = 0; i < steps.length; i++) {
        buffer.writeln('${i + 1}. ${steps[i]}');
      }
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return buffer.toString();
  }

  @override
  String toString() => '$runtimeType: $message (Status: $statusCode)';
}

/// Occurs when the device cannot establish a network connection to the server.
class NetworkError extends ApiError {
  const NetworkError({
    super.message = 'Failed to connect to the server.',
    super.statusCode,
    super.rawData,
    super.endpoint,
    super.method,
    super.cause,
    super.stackTrace,
  }) : super(type: ApiErrorType.network);

  @override
  String get explanation =>
      'The device could not establish a network connection to the requested host. '
      'This could be caused by lack of internet, incorrect domain URL, or server being unreachable.';

  @override
  List<String> get solutionSteps => [
        'Check device internet/Wi-Fi connection.',
        'Verify the base URL and domain name spelling.',
        'Ensure the backend server is running and accessible.',
        'Check firewall, VPN, or network security settings.',
      ];
}

/// Occurs when a request exceeds the configured connect, receive, or send timeout.
class TimeoutError extends ApiError {
  final Duration timeoutDuration;

  const TimeoutError({
    required this.timeoutDuration,
    super.message = 'The server did not respond within the configured timeout period.',
    super.statusCode,
    super.rawData,
    super.endpoint,
    super.method,
    super.cause,
    super.stackTrace,
  }) : super(type: ApiErrorType.timeout);

  @override
  String get explanation =>
      'The server took longer than ${timeoutDuration.inSeconds} seconds to complete the request.';

  @override
  List<String> get solutionSteps => [
        'Check server processing performance and database query speed.',
        'Increase timeout duration in EasyApi.configure().',
        'Verify network connection quality.',
      ];
}

/// Occurs when the server returns 401 Unauthorized.
class UnauthorizedError extends ApiError {
  const UnauthorizedError({
    super.message = 'Unauthorized access. Authentication token missing or expired.',
    super.rawData,
    super.endpoint,
    super.method,
    super.cause,
    super.stackTrace,
  }) : super(
          type: ApiErrorType.unauthorized,
          statusCode: 401,
        );

  @override
  String get explanation =>
      'The backend rejected the request because valid authentication credentials were not provided or expired.';

  @override
  List<String> get solutionSteps => [
        'Provide a valid authentication token via EasyApi.setToken().',
        'Configure automatic token refresh handler in EasyApi.configure().',
        'Verify backend Authorization header format (e.g. Bearer <token>).',
      ];
}

/// Occurs when the server returns 403 Forbidden.
class ForbiddenError extends ApiError {
  const ForbiddenError({
    super.message = 'Forbidden. You do not have permission to access this resource.',
    super.rawData,
    super.endpoint,
    super.method,
    super.cause,
    super.stackTrace,
  }) : super(
          type: ApiErrorType.forbidden,
          statusCode: 403,
        );

  @override
  String get explanation =>
      'The client is authenticated, but lacks sufficient authorization roles/permissions for this resource.';

  @override
  List<String> get solutionSteps => [
        'Check user permissions and roles on the backend.',
        'Verify the endpoint route permission requirements.',
      ];
}

/// Occurs when the server returns 404 Not Found.
class NotFoundError extends ApiError {
  const NotFoundError({
    super.message = 'Resource not found.',
    super.rawData,
    super.endpoint,
    super.method,
    super.cause,
    super.stackTrace,
  }) : super(
          type: ApiErrorType.notFound,
          statusCode: 404,
        );

  @override
  String get explanation =>
      'The server was reached successfully, but the requested endpoint or resource ID does not exist.';

  @override
  List<String> get solutionSteps => [
        'Check the endpoint URL path.',
        'Verify path parameter IDs.',
        'Verify backend API routing definitions.',
      ];
}

/// Occurs when the server returns 422 Unprocessable Entity or 400 Bad Request validation failure.
class ValidationError extends ApiError {
  const ValidationError({
    super.message = 'Request validation failed.',
    super.statusCode = 422,
    super.rawData,
    super.endpoint,
    super.method,
    super.validationErrors = const {},
    super.cause,
    super.stackTrace,
  }) : super(type: ApiErrorType.validation);

  @override
  String get explanation =>
      'The server received the request payload but rejected it due to field validation errors.';

  @override
  List<String> get solutionSteps => [
        'Check error.validationErrors for specific invalid field names.',
        'Verify field requirements and data types against the API specification.',
      ];
}

/// Occurs when the server returns a 5xx HTTP status code.
class ServerError extends ApiError {
  const ServerError({
    required super.statusCode,
    super.message = 'Internal server error occurred.',
    super.rawData,
    super.endpoint,
    super.method,
    super.cause,
    super.stackTrace,
  }) : super(type: ApiErrorType.server);

  @override
  String get explanation =>
      'The server encountered an error while processing the request (HTTP $statusCode).';

  @override
  List<String> get solutionSteps => [
        'Check backend application logs.',
        'Verify database connectivity on the server.',
        'Retry the request if it is an intermittent 502/503/504 gateway issue.',
      ];
}

/// Occurs when JSON parsing fails while converting HTTP response into a strongly typed Dart model.
class ParsingError extends ApiError {
  final String? parserName;
  final String? fieldName;
  final String? expectedType;
  final String? receivedType;

  const ParsingError({
    required super.message,
    this.parserName,
    this.fieldName,
    this.expectedType,
    this.receivedType,
    super.statusCode = 200,
    super.rawData,
    super.endpoint,
    super.method,
    super.cause,
    super.stackTrace,
  }) : super(type: ApiErrorType.parsing);

  @override
  String get explanation =>
      'The API request succeeded with HTTP status $statusCode, but the response JSON '
      'could not be parsed into model object using $parserName.\n'
      '${fieldName != null ? "Field: $fieldName\n" : ""}'
      '${expectedType != null ? "Expected type: $expectedType\n" : ""}'
      '${receivedType != null ? "Received type: $receivedType" : ""}';

  @override
  List<String> get solutionSteps => [
        'Check the raw backend JSON response structure.',
        'Verify model `fromJson` constructor mappings.',
        'Handle nullable fields properly (e.g. `json["key"] as String?`).',
        'Safely convert dynamic types (e.g. `(json["id"] as num?)?.toInt()`).',
      ];

  @override
  String toFormattedString() {
    final buffer = StringBuffer();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('EASY API KIT - MODEL PARSE ERROR');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Endpoint:');
    buffer.writeln('${method ?? ''} ${endpoint ?? ''}'.trim());
    buffer.writeln('');
    buffer.writeln('Status:');
    buffer.writeln('$statusCode OK');
    buffer.writeln('');
    buffer.writeln('Problem:');
    buffer.writeln(
        'The API request succeeded, but the response could not be converted.');
    buffer.writeln('');
    if (parserName != null) {
      buffer.writeln('Parser:');
      buffer.writeln(parserName);
      buffer.writeln('');
    }
    if (fieldName != null) {
      buffer.writeln('Field:');
      buffer.writeln(fieldName);
      buffer.writeln('');
    }
    if (expectedType != null) {
      buffer.writeln('Expected:');
      buffer.writeln(expectedType);
      buffer.writeln('');
    }
    if (receivedType != null) {
      buffer.writeln('Received:');
      buffer.writeln(receivedType);
      buffer.writeln('');
    }
    if (rawData != null) {
      buffer.writeln('Raw Response:');
      if (kReleaseMode) {
        buffer.writeln('*** REDACTED IN PRODUCTION ***');
      } else {
        buffer.writeln('$rawData');
      }
      buffer.writeln('');
    }
    buffer.writeln('Possible solutions:');
    for (var i = 0; i < solutionSteps.length; i++) {
      buffer.writeln('${i + 1}. ${solutionSteps[i]}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return buffer.toString();
  }
}

/// Occurs when uploading multipart files fails.
class UploadError extends ApiError {
  const UploadError({
    super.message = 'Multipart upload failed.',
    super.statusCode,
    super.rawData,
    super.endpoint,
    super.method,
    super.cause,
    super.stackTrace,
  }) : super(type: ApiErrorType.upload);

  @override
  String get explanation =>
      'Failed while preparing or transmitting multipart upload files.';

  @override
  List<String> get solutionSteps => [
        'Check if upload files exist on disk and are readable.',
        'Verify field names match what the backend expects.',
        'Check file size limits set by backend server.',
      ];
}

/// Occurs when a request is explicitly cancelled using a [CancellationToken].
class CancelledError extends ApiError {
  const CancelledError({
    super.message = 'Request was cancelled by CancellationToken.',
    super.endpoint,
    super.method,
  }) : super(type: ApiErrorType.cancelled);

  @override
  String get explanation =>
      'The API call was actively cancelled before completion.';

  @override
  List<String> get solutionSteps => [
        'Ignore this error if cancellation was initiated by user navigation or search typing.',
      ];
}

/// Occurs when device has no active network connectivity.
class OfflineError extends ApiError {
  const OfflineError({
    super.message = 'No internet connection is currently available.',
    super.endpoint,
    super.method,
  }) : super(type: ApiErrorType.offline);

  @override
  String get explanation =>
      'The device is offline or has no active internet connection.';

  @override
  List<String> get solutionSteps => [
        'Check Wi-Fi or mobile data connection.',
        'Ensure Airplane mode is disabled.',
        'Retry when connectivity is restored.',
      ];
}

/// Catch-all ApiError for unclassified exceptions.
class UnknownApiError extends ApiError {
  const UnknownApiError({
    required super.message,
    super.statusCode,
    super.rawData,
    super.endpoint,
    super.method,
    super.cause,
    super.stackTrace,
  }) : super(type: ApiErrorType.unknown);

  @override
  String get explanation =>
      'An unexpected exception occurred during request execution.';

  @override
  List<String> get solutionSteps => [
        'Inspect error.cause and error.stackTrace for lower level details.',
      ];
}
