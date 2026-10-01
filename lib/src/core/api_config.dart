import 'package:flutter/foundation.dart';
import '../enums/http_method.dart';
import '../enums/log_level.dart';
import '../enums/multipart_strategy.dart';

/// Configuration options for EasyApiKit client instances.
class ApiConfig {
  /// Base URL prepended to all relative request endpoints (e.g., "https://api.example.com").
  final String baseUrl;

  /// Network connection timeout.
  final Duration connectTimeout;

  /// Response data reception timeout.
  final Duration receiveTimeout;

  /// Request payload transmission timeout.
  final Duration sendTimeout;

  /// Default headers sent with every request.
  final Map<String, String> defaultHeaders;

  /// Async provider callback to dynamically retrieve the authorization token.
  final Future<String?> Function()? tokenProvider;

  /// Async callback executed on 401 Unauthorized to refresh authentication token.
  /// Should return `true` if token was refreshed successfully, `false` otherwise.
  final Future<bool> Function()? refreshTokenHandler;

  /// Header field name used for authentication (default: "Authorization").
  final String authHeaderKey;

  /// Prefix prepended to authorization token (default: "Bearer ").
  final String authHeaderPrefix;

  /// Maximum number of automated retries for transient failures (default: 0).
  final int retryCount;

  /// Delay between retry attempts.
  final Duration retryDelay;

  /// List of HTTP methods eligible for automated retry.
  final List<HttpMethod> retryOnMethods;

  /// Whether terminal logging is enabled. Defaults to `true` in debug mode.
  final bool enableLogging;

  /// Verbosity level for terminal logs.
  final ApiLogLevel logLevel;

  /// Header names masked in terminal logs for privacy/security.
  final List<String> sensitiveHeaders;

  /// JSON body keys masked in terminal logs for privacy/security.
  final List<String> sensitiveBodyKeys;

  /// Default multi-file naming strategy for multipart requests.
  final MultipartFileStrategy multipartStrategy;

  /// Whether HTTP client automatically follows 3xx redirects.
  final bool followRedirects;

  /// Maximum redirect hops allowed.
  final int maxRedirects;

  /// Whether in-memory caching is enabled for GET requests.
  final bool enableCache;

  /// Default TTL duration for cached responses (default: 5 minutes).
  final Duration defaultCacheDuration;

  /// Whether client verifies active network connection before making API calls.
  final bool checkOfflineFirst;

  ApiConfig({
    this.baseUrl = '',
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    this.tokenProvider,
    this.refreshTokenHandler,
    this.authHeaderKey = 'Authorization',
    this.authHeaderPrefix = 'Bearer ',
    this.retryCount = 0,
    this.retryDelay = const Duration(seconds: 1),
    this.retryOnMethods = const [
      HttpMethod.get,
      HttpMethod.head,
      HttpMethod.options,
    ],
    bool? enableLogging,
    this.logLevel = ApiLogLevel.full,
    this.sensitiveHeaders = const [
      'authorization',
      'cookie',
      'set-cookie',
      'x-api-key',
      'api-key',
      'secret',
    ],
    this.sensitiveBodyKeys = const [
      'password',
      'pass',
      'token',
      'access_token',
      'refresh_token',
      'secret',
      'credit_card',
      'card_number',
    ],
    this.multipartStrategy = MultipartFileStrategy.arraySuffix,
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.enableCache = false,
    this.defaultCacheDuration = const Duration(minutes: 5),
    this.checkOfflineFirst = false,
  }) : enableLogging = enableLogging ?? kDebugMode;

  /// Creates a modified copy of [ApiConfig].
  ApiConfig copyWith({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Map<String, String>? defaultHeaders,
    Future<String?> Function()? tokenProvider,
    Future<bool> Function()? refreshTokenHandler,
    String? authHeaderKey,
    String? authHeaderPrefix,
    int? retryCount,
    Duration? retryDelay,
    List<HttpMethod>? retryOnMethods,
    bool? enableLogging,
    ApiLogLevel? logLevel,
    List<String>? sensitiveHeaders,
    List<String>? sensitiveBodyKeys,
    MultipartFileStrategy? multipartStrategy,
    bool? followRedirects,
    int? maxRedirects,
  }) {
    return ApiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      tokenProvider: tokenProvider ?? this.tokenProvider,
      refreshTokenHandler: refreshTokenHandler ?? this.refreshTokenHandler,
      authHeaderKey: authHeaderKey ?? this.authHeaderKey,
      authHeaderPrefix: authHeaderPrefix ?? this.authHeaderPrefix,
      retryCount: retryCount ?? this.retryCount,
      retryDelay: retryDelay ?? this.retryDelay,
      retryOnMethods: retryOnMethods ?? this.retryOnMethods,
      enableLogging: enableLogging ?? this.enableLogging,
      logLevel: logLevel ?? this.logLevel,
      sensitiveHeaders: sensitiveHeaders ?? this.sensitiveHeaders,
      sensitiveBodyKeys: sensitiveBodyKeys ?? this.sensitiveBodyKeys,
      multipartStrategy: multipartStrategy ?? this.multipartStrategy,
      followRedirects: followRedirects ?? this.followRedirects,
      maxRedirects: maxRedirects ?? this.maxRedirects,
    );
  }
}
