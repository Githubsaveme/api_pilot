import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../enums/http_method.dart';
import '../errors/api_error.dart';

/// Parses raw HTTP responses and exceptions into structured [ApiError] instances.
class ErrorParser {
  /// Converts an HTTP status code and response payload into an appropriate [ApiError].
  static ApiError parseResponse({
    required http.Response response,
    required String url,
    required HttpMethod method,
  }) {
    final status = response.statusCode;
    final rawBody = response.body;
    dynamic decodedBody;

    try {
      if (rawBody.isNotEmpty) {
        decodedBody = jsonDecode(rawBody);
      }
    } catch (_) {
      decodedBody = rawBody;
    }

    final errorMessage = _extractErrorMessage(decodedBody) ??
        'HTTP $status ${response.reasonPhrase ?? ""}';

    final validationMap = _extractValidationErrors(decodedBody);

    switch (status) {
      case 401:
        return UnauthorizedError(
          message: errorMessage,
          rawData: decodedBody,
          endpoint: url,
          method: method.name,
        );
      case 403:
        return ForbiddenError(
          message: errorMessage,
          rawData: decodedBody,
          endpoint: url,
          method: method.name,
        );
      case 404:
        return NotFoundError(
          message: errorMessage,
          rawData: decodedBody,
          endpoint: url,
          method: method.name,
        );
      case 400:
      case 422:
        return ValidationError(
          message: errorMessage,
          statusCode: status,
          rawData: decodedBody,
          endpoint: url,
          method: method.name,
          validationErrors: validationMap,
        );
      default:
        if (status >= 500) {
          return ServerError(
            statusCode: status,
            message: errorMessage,
            rawData: decodedBody,
            endpoint: url,
            method: method.name,
          );
        }
        return UnknownApiError(
          message: errorMessage,
          statusCode: status,
          rawData: decodedBody,
          endpoint: url,
          method: method.name,
        );
    }
  }

  /// Converts lower-level Dart exceptions into [ApiError] instances.
  static ApiError parseException({
    required Object error,
    required String url,
    required HttpMethod method,
    StackTrace? stackTrace,
  }) {
    if (error is ApiError) {
      return error;
    }

    if (error is TimeoutException) {
      return TimeoutError(
        timeoutDuration: const Duration(seconds: 30),
        message: 'Network request timed out.',
        endpoint: url,
        method: method.name,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is SocketException || error is http.ClientException) {
      return NetworkError(
        message: 'Network error: Unable to connect to host (${error.toString()}).',
        endpoint: url,
        method: method.name,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is HttpException) {
      return NetworkError(
        message: 'HTTP protocol exception: ${error.message}',
        endpoint: url,
        method: method.name,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return UnknownApiError(
      message: 'Unexpected error: $error',
      endpoint: url,
      method: method.name,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  static String? _extractErrorMessage(dynamic decoded) {
    if (decoded is Map) {
      if (decoded.containsKey('message') && decoded['message'] != null) {
        return decoded['message'].toString();
      }
      if (decoded.containsKey('error') && decoded['error'] != null) {
        final err = decoded['error'];
        if (err is String) return err;
        if (err is Map && err.containsKey('message')) {
          return err['message'].toString();
        }
      }
      if (decoded.containsKey('msg') && decoded['msg'] != null) {
        return decoded['msg'].toString();
      }
      if (decoded.containsKey('detail') && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    }
    return null;
  }

  static Map<String, List<String>> _extractValidationErrors(dynamic decoded) {
    final result = <String, List<String>>{};
    if (decoded is Map) {
      dynamic errorsObj = decoded['errors'] ?? decoded['validation_errors'] ?? decoded['details'];
      if (errorsObj is Map) {
        errorsObj.forEach((key, val) {
          final fieldKey = '$key';
          if (val is List) {
            result[fieldKey] = val.map((e) => '$e').toList();
          } else if (val != null) {
            result[fieldKey] = ['$val'];
          }
        });
      }
    }
    return result;
  }
}
