import '../core/cancellation_token.dart';
import '../enums/body_type.dart';
import '../enums/cache_policy.dart';
import '../enums/http_method.dart';
import '../enums/multipart_strategy.dart';
import 'upload_file.dart';

/// Callback signature for monitoring upload or download progress.
typedef ProgressCallback = void Function(int count, int total);

/// Encapsulates all data and parameters for an outgoing API request.
class ApiRequest {
  /// Unique request identifier for tracking and logs.
  final String id;

  /// HTTP method (GET, POST, etc.).
  final HttpMethod method;

  /// Endpoint path (e.g. "/users") or complete URL ("https://api.com/users").
  final String url;

  /// Base URL configured for this request.
  final String? baseUrl;

  /// Query parameters map.
  final Map<String, dynamic>? queryParameters;

  /// Path parameters map (e.g. `{"id": 123}` for `/users/{id}`).
  final Map<String, dynamic>? pathParameters;

  /// Custom request headers.
  final Map<String, String>? headers;

  /// Request body payload (Map, List, String, or raw bytes).
  final dynamic data;

  /// Explicit body encoding type.
  final BodyType? bodyType;

  /// List of upload files for multipart requests.
  final List<UploadFile>? files;

  /// Timeout for establishing network connection.
  final Duration? connectTimeout;

  /// Timeout for receiving response data.
  final Duration? receiveTimeout;

  /// Timeout for sending request data.
  final Duration? sendTimeout;

  /// Token for cancelling request in flight.
  final CancellationToken? cancellationToken;

  /// Upload progress callback.
  final ProgressCallback? onSendProgress;

  /// Download progress callback.
  final ProgressCallback? onReceiveProgress;

  /// Multi-file field naming strategy for multipart requests.
  final MultipartFileStrategy? multipartStrategy;

  /// Caching strategy for GET requests.
  final CachePolicy? cachePolicy;

  /// TTL duration for caching responses.
  final Duration? cacheDuration;

  /// Custom user metadata attached to request.
  final Map<String, dynamic>? extra;

  ApiRequest({
    required this.id,
    required this.method,
    required this.url,
    this.baseUrl,
    this.queryParameters,
    this.pathParameters,
    this.headers,
    this.data,
    this.bodyType,
    this.files,
    this.connectTimeout,
    this.receiveTimeout,
    this.sendTimeout,
    this.cancellationToken,
    this.onSendProgress,
    this.onReceiveProgress,
    this.multipartStrategy,
    this.cachePolicy,
    this.cacheDuration,
    this.extra,
  });

  /// Resolves the full URL including path parameters replacement.
  String get fullUrl {
    var resolvedUrl = url;
    if (pathParameters != null && pathParameters!.isNotEmpty) {
      pathParameters!.forEach((key, value) {
        resolvedUrl = resolvedUrl.replaceAll('{$key}', '$value');
        resolvedUrl = resolvedUrl.replaceAll(':$key', '$value');
      });
    }

    if (resolvedUrl.startsWith('http://') || resolvedUrl.startsWith('https://')) {
      return resolvedUrl;
    }

    final base = baseUrl ?? '';
    if (base.isEmpty) return resolvedUrl;

    if (base.endsWith('/') && resolvedUrl.startsWith('/')) {
      return base + resolvedUrl.substring(1);
    } else if (!base.endsWith('/') && !resolvedUrl.startsWith('/')) {
      return '$base/$resolvedUrl';
    } else {
      return base + resolvedUrl;
    }
  }

  /// Creates a modified copy of this request.
  ApiRequest copyWith({
    String? id,
    HttpMethod? method,
    String? url,
    String? baseUrl,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    Map<String, String>? headers,
    dynamic data,
    BodyType? bodyType,
    List<UploadFile>? files,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    CancellationToken? cancellationToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    MultipartFileStrategy? multipartStrategy,
    CachePolicy? cachePolicy,
    Duration? cacheDuration,
    Map<String, dynamic>? extra,
  }) {
    return ApiRequest(
      id: id ?? this.id,
      method: method ?? this.method,
      url: url ?? this.url,
      baseUrl: baseUrl ?? this.baseUrl,
      queryParameters: queryParameters ?? this.queryParameters,
      pathParameters: pathParameters ?? this.pathParameters,
      headers: headers ?? this.headers,
      data: data ?? this.data,
      bodyType: bodyType ?? this.bodyType,
      files: files ?? this.files,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      cancellationToken: cancellationToken ?? this.cancellationToken,
      onSendProgress: onSendProgress ?? this.onSendProgress,
      onReceiveProgress: onReceiveProgress ?? this.onReceiveProgress,
      multipartStrategy: multipartStrategy ?? this.multipartStrategy,
      cachePolicy: cachePolicy ?? this.cachePolicy,
      cacheDuration: cacheDuration ?? this.cacheDuration,
      extra: extra ?? this.extra,
    );
  }
}
