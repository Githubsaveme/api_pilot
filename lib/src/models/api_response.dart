import '../errors/api_error.dart';
import 'api_request.dart';

/// Standard wrapper returned by all EasyApi Kit requests.
class ApiResponse<T> {
  /// Parsed response object or list of type [T]. `null` if parsing failed or error occurred.
  final T? data;

  /// Original raw decoded payload (Map, List, String, or Uint8List).
  final dynamic rawData;

  /// HTTP status code (e.g. 200, 201, 400, 404, 500).
  final int? statusCode;

  /// HTTP status message or reason phrase.
  final String? statusMessage;

  /// Normalized response headers map.
  final Map<String, String> headers;

  /// Unique request tracking ID.
  final String requestId;

  /// Total duration taken by the network roundtrip and parsing.
  final Duration duration;

  /// Original request configuration.
  final ApiRequest request;

  /// Strongly typed error if the request failed or parsing failed.
  final ApiError? error;

  const ApiResponse({
    this.data,
    this.rawData,
    this.statusCode,
    this.statusMessage,
    this.headers = const {},
    required this.requestId,
    required this.duration,
    required this.request,
    this.error,
  });

  /// `true` if HTTP status code is in 2xx range (200-299) AND no parsing error occurred.
  bool get isSuccess =>
      statusCode != null &&
      statusCode! >= 200 &&
      statusCode! < 300 &&
      error == null;

  /// `true` if HTTP request failed or parsing error occurred.
  bool get isError => !isSuccess;

  /// Convenient getter for message from error or status text.
  String get message =>
      error?.message ?? statusMessage ?? 'HTTP $statusCode';

  /// Creates a success response wrapper.
  factory ApiResponse.success({
    T? data,
    dynamic rawData,
    int? statusCode,
    String? statusMessage,
    Map<String, String> headers = const {},
    required String requestId,
    required Duration duration,
    required ApiRequest request,
  }) {
    return ApiResponse<T>(
      data: data,
      rawData: rawData,
      statusCode: statusCode ?? 200,
      statusMessage: statusMessage ?? 'OK',
      headers: headers,
      requestId: requestId,
      duration: duration,
      request: request,
    );
  }

  /// Creates an error response wrapper.
  factory ApiResponse.failure({
    required ApiError error,
    dynamic rawData,
    int? statusCode,
    String? statusMessage,
    Map<String, String> headers = const {},
    required String requestId,
    required Duration duration,
    required ApiRequest request,
  }) {
    return ApiResponse<T>(
      data: null,
      rawData: rawData,
      statusCode: statusCode ?? error.statusCode,
      statusMessage: statusMessage,
      headers: headers,
      requestId: requestId,
      duration: duration,
      request: request,
      error: error,
    );
  }

  /// Map response data into another type.
  ApiResponse<R> map<R>(R Function(T? data) mapper) {
    return ApiResponse<R>(
      data: mapper(data),
      rawData: rawData,
      statusCode: statusCode,
      statusMessage: statusMessage,
      headers: headers,
      requestId: requestId,
      duration: duration,
      request: request,
      error: error,
    );
  }

  @override
  String toString() =>
      'ApiResponse<$T>(status: $statusCode, isSuccess: $isSuccess, data: $data, error: $error)';
}
