import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../enums/log_level.dart';
import '../errors/api_error.dart';
import '../models/api_request.dart';
import '../models/api_response.dart';

/// Formatted logger for EasyApiKit operations with strict production security.
class ApiLogger {
  final bool enabled;
  final bool allowProductionLogging;
  final ApiLogLevel logLevel;
  final List<String> sensitiveHeaders;
  final List<String> sensitiveBodyKeys;

  ApiLogger({
    required this.enabled,
    this.allowProductionLogging = false,
    required this.logLevel,
    required this.sensitiveHeaders,
    required this.sensitiveBodyKeys,
  });

  /// `true` if logging is active and allowed under current environment mode.
  bool get isLoggingAllowed {
    if (!enabled || logLevel == ApiLogLevel.none) return false;
    // In production/release builds, block logs by default for security
    if (kReleaseMode && !allowProductionLogging) return false;
    return true;
  }

  /// Logs an outgoing HTTP request.
  void logRequest(ApiRequest request) {
    if (!isLoggingAllowed) return;

    final buffer = StringBuffer();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('EASY API KIT - REQUEST [${kDebugMode ? "DEBUG" : "PROD"}]');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('ID       : ${request.id}');
    buffer.writeln('METHOD   : ${request.method.name}');
    buffer.writeln('URL      : ${request.fullUrl}');
    buffer.writeln('TIME     : ${DateTime.now().toIso8601String().split('T').last}');

    if (logLevel == ApiLogLevel.headers || logLevel == ApiLogLevel.full) {
      if (request.headers != null && request.headers!.isNotEmpty) {
        final maskedHeaders = _maskHeaders(request.headers!);
        buffer.writeln('HEADERS  : ${_prettyPrintJson(maskedHeaders)}');
      }
    }

    if (logLevel == ApiLogLevel.body || logLevel == ApiLogLevel.full) {
      if (request.queryParameters != null && request.queryParameters!.isNotEmpty) {
        final maskedQueryParams = _maskBody(request.queryParameters);
        buffer.writeln('QUERY    : ${_prettyPrintJson(maskedQueryParams)}');
      }

      if (request.data != null) {
        final maskedData = _maskBody(request.data);
        buffer.writeln('BODY     : ${_prettyPrintJson(maskedData)}');
      }

      if (request.files != null && request.files!.isNotEmpty) {
        final fileSummary = request.files!
            .map((f) => '${f.field}: ${f.filename} (${f.contentType?.mimeType ?? "unknown"})')
            .join(', ');
        buffer.writeln('FILES    : [$fileSummary]');
      }
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _print(buffer.toString());
  }

  /// Logs an incoming HTTP response.
  void logResponse(ApiResponse response) {
    if (!isLoggingAllowed) return;

    final buffer = StringBuffer();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('EASY API KIT - RESPONSE [${kDebugMode ? "DEBUG" : "PROD"}]');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('ID       : ${response.requestId}');
    buffer.writeln('STATUS   : ${response.statusCode ?? "-"} ${response.statusMessage ?? ""}');
    buffer.writeln('METHOD   : ${response.request.method.name}');
    buffer.writeln('URL      : ${response.request.fullUrl}');
    buffer.writeln('DURATION : ${response.duration.inMilliseconds} ms');

    if (logLevel == ApiLogLevel.headers || logLevel == ApiLogLevel.full) {
      if (response.headers.isNotEmpty) {
        final maskedHeaders = _maskHeaders(response.headers);
        buffer.writeln('HEADERS  : ${_prettyPrintJson(maskedHeaders)}');
      }
    }

    if (logLevel == ApiLogLevel.body || logLevel == ApiLogLevel.full) {
      if (response.rawData != null) {
        if (kReleaseMode) {
          buffer.writeln('BODY     : *** MASKED IN PRODUCTION ***');
        } else {
          final maskedData = _maskBody(response.rawData);
          buffer.writeln('BODY     : ${_prettyPrintJson(maskedData)}');
        }
      }
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _print(buffer.toString());
  }

  /// Logs an API or network error.
  void logError(ApiError error) {
    if (!isLoggingAllowed) return;
    _print(error.toFormattedString());
  }

  Map<String, String> _maskHeaders(Map<String, String> headers) {
    final result = <String, String>{};
    final sensitiveLower = sensitiveHeaders.map((e) => e.toLowerCase()).toSet();

    headers.forEach((key, value) {
      final k = key.toLowerCase();
      if (sensitiveLower.contains(k) ||
          k.contains('token') ||
          k.contains('auth') ||
          k.contains('key') ||
          k.contains('secret') ||
          k.contains('cookie')) {
        result[key] = '*** MASKED ***';
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  dynamic _maskBody(dynamic body) {
    if (body == null) return null;
    final sensitiveLower = sensitiveBodyKeys.map((e) => e.toLowerCase()).toSet();

    if (body is Map) {
      final maskedMap = <String, dynamic>{};
      body.forEach((key, value) {
        final keyStr = '$key';
        final k = keyStr.toLowerCase();
        if (sensitiveLower.contains(k) ||
            k.contains('password') ||
            k.contains('token') ||
            k.contains('secret') ||
            k.contains('card') ||
            k.contains('key') ||
            k.contains('cvv') ||
            k.contains('auth')) {
          maskedMap[keyStr] = '*** MASKED ***';
        } else {
          maskedMap[keyStr] = _maskBody(value);
        }
      });
      return maskedMap;
    } else if (body is List) {
      return body.map((item) => _maskBody(item)).toList();
    }
    return body;
  }

  String _prettyPrintJson(dynamic jsonObject) {
    if (jsonObject == null) return 'null';
    try {
      if (jsonObject is Map || jsonObject is List) {
        return const JsonEncoder.withIndent('  ').convert(jsonObject);
      }
      return jsonObject.toString();
    } catch (_) {
      return jsonObject.toString();
    }
  }

  void _print(String text) {
    debugPrint(text);
  }
}
