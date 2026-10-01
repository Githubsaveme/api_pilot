import 'dart:convert';
import '../enums/http_method.dart';
import '../errors/api_error.dart';

/// Utility for safely parsing raw JSON or dynamic HTTP payloads into strongly typed Dart objects.
class ResponseParser {
  /// Parses decoded or raw string JSON into model [T].
  ///
  /// Supports single object parsing or list mapping via [isList].
  static T parse<T>({
    required dynamic rawBody,
    required dynamic Function(dynamic json)? parser,
    bool isList = false,
    required String endpoint,
    required HttpMethod method,
    required int statusCode,
  }) {
    if (parser == null) {
      return rawBody as T;
    }

    dynamic jsonObject = rawBody;
    if (rawBody is String && rawBody.isNotEmpty) {
      try {
        jsonObject = jsonDecode(rawBody);
      } catch (e) {
        throw ParsingError(
          message: 'Failed to decode JSON string payload: $e',
          parserName: parser.toString(),
          statusCode: statusCode,
          rawData: rawBody,
          endpoint: endpoint,
          method: method.name,
          cause: e,
        );
      }
    }

    try {
      if (isList) {
        if (jsonObject is! List) {
          throw ParsingError(
            message: 'Expected a List response body, but received ${jsonObject.runtimeType}',
            parserName: parser.toString(),
            expectedType: 'List<dynamic>',
            receivedType: jsonObject.runtimeType.toString(),
            statusCode: statusCode,
            rawData: jsonObject,
            endpoint: endpoint,
            method: method.name,
          );
        }

        // Attempt direct parser execution if parser handles List directly
        try {
          final directResult = parser(jsonObject);
          if (directResult is T) return directResult;
        } catch (_) {}

        final dynamic parsedList = jsonObject.map((item) => parser(item)).toList();
        return parsedList;
      } else {
        return parser(jsonObject) as T;
      }
    } catch (e, stackTrace) {
      if (e is ApiError) rethrow;

      final typeErrorDetails = _analyzeTypeError(e, jsonObject);

      throw ParsingError(
        message: 'Model conversion failed: $e',
        parserName: _getParserName(parser),
        fieldName: typeErrorDetails.fieldName,
        expectedType: typeErrorDetails.expectedType,
        receivedType: typeErrorDetails.receivedType,
        statusCode: statusCode,
        rawData: jsonObject,
        endpoint: endpoint,
        method: method.name,
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  static String _getParserName(Function parser) {
    final str = parser.toString();
    if (str.contains('from') || str.contains('fromJson')) {
      return str;
    }
    return 'User-provided json parser ($str)';
  }

  static _TypeErrorAnalysis _analyzeTypeError(Object error, dynamic json) {
    final errStr = error.toString();
    String? fieldName;
    String? expectedType;
    String? receivedType;

    final subtypeMatch = RegExp(r"type '([^']+)' is not a subtype of type '([^']+)'").firstMatch(errStr);
    if (subtypeMatch != null) {
      receivedType = subtypeMatch.group(1);
      expectedType = subtypeMatch.group(2);
    }

    if (json is Map) {
      for (final entry in json.entries) {
        if (receivedType != null && entry.value != null) {
          if (entry.value.runtimeType.toString() == receivedType) {
            fieldName = '${entry.key}';
            break;
          }
        }
      }
    }

    return _TypeErrorAnalysis(
      fieldName: fieldName,
      expectedType: expectedType,
      receivedType: receivedType,
    );
  }
}

class _TypeErrorAnalysis {
  final String? fieldName;
  final String? expectedType;
  final String? receivedType;

  _TypeErrorAnalysis({
    this.fieldName,
    this.expectedType,
    this.receivedType,
  });
}
