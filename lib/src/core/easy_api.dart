import 'dart:io';
import 'dart:typed_data';
import '../enums/body_type.dart';
import '../enums/cache_policy.dart';
import '../enums/http_method.dart';
import '../enums/log_level.dart';
import '../enums/multipart_strategy.dart';
import '../interceptors/api_interceptor.dart';
import '../models/api_request.dart';
import '../models/api_response.dart';
import '../models/api_result.dart';
import '../models/upload_file.dart';
import '../pagination/pagination_controller.dart';
import '../pagination/pagination_result.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'cancellation_token.dart';

/// Primary public facade for EasyApiKit.
///
/// Provides static methods for simple, elegant API calling with advanced control available when needed.
class EasyApi {
  static final ApiClient _client = ApiClient();

  /// Returns the singleton [ApiClient] instance.
  static ApiClient get instance => _client;

  /// Global configuration for EasyApiKit.
  ///
  /// Call at app initialization (e.g. `main()`).
  static void configure({
    String baseUrl = '',
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 30),
    Duration sendTimeout = const Duration(seconds: 30),
    Map<String, String> defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    Future<String?> Function()? tokenProvider,
    Future<bool> Function()? refreshTokenHandler,
    String authHeaderKey = 'Authorization',
    String authHeaderPrefix = 'Bearer ',
    int retryCount = 0,
    Duration retryDelay = const Duration(seconds: 1),
    List<HttpMethod> retryOnMethods = const [
      HttpMethod.get,
      HttpMethod.head,
      HttpMethod.options,
    ],
    bool? enableLogging,
    ApiLogLevel logLevel = ApiLogLevel.full,
    List<String> sensitiveHeaders = const [
      'authorization',
      'cookie',
      'set-cookie',
      'x-api-key',
      'api-key',
      'secret',
    ],
    List<String> sensitiveBodyKeys = const [
      'password',
      'pass',
      'token',
      'access_token',
      'refresh_token',
      'secret',
    ],
    MultipartFileStrategy multipartStrategy = MultipartFileStrategy.arraySuffix,
    bool followRedirects = true,
    int maxRedirects = 5,
    bool enableCache = false,
    Duration defaultCacheDuration = const Duration(minutes: 5),
    bool checkOfflineFirst = false,
  }) {
    final config = ApiConfig(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      defaultHeaders: defaultHeaders,
      tokenProvider: tokenProvider,
      refreshTokenHandler: refreshTokenHandler,
      authHeaderKey: authHeaderKey,
      authHeaderPrefix: authHeaderPrefix,
      retryCount: retryCount,
      retryDelay: retryDelay,
      retryOnMethods: retryOnMethods,
      enableLogging: enableLogging,
      logLevel: logLevel,
      sensitiveHeaders: sensitiveHeaders,
      sensitiveBodyKeys: sensitiveBodyKeys,
      multipartStrategy: multipartStrategy,
      followRedirects: followRedirects,
      maxRedirects: maxRedirects,
      enableCache: enableCache,
      defaultCacheDuration: defaultCacheDuration,
      checkOfflineFirst: checkOfflineFirst,
    );
    _client.updateConfig(config);
  }

  /// Sets an explicit authorization token for all subsequent requests.
  static void setToken(String token) {
    _client.authInterceptor.setToken(token);
  }

  /// Clears the explicit authorization token.
  static void clearToken() {
    _client.authInterceptor.clearToken();
  }

  /// Registers a custom [ApiInterceptor] middleware.
  static void addInterceptor(ApiInterceptor interceptor) {
    _client.addInterceptor(interceptor);
  }

  /// Removes an interceptor.
  static void removeInterceptor(ApiInterceptor interceptor) {
    _client.removeInterceptor(interceptor);
  }

  /// Clears in-memory response cache.
  static void clearCache() {
    _client.cache.clear();
  }

  /// Downloads a file directly to [savePath] on disk with progress tracking.
  static Future<ApiResponse<File>> download(
    String url, {
    required String savePath,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    ProgressCallback? onReceiveProgress,
    CancellationToken? cancellationToken,
    void Function(bool isLoading)? onLoading,
  }) {
    return _client.download(
      url,
      savePath: savePath,
      queryParameters: queryParameters,
      headers: headers,
      onReceiveProgress: onReceiveProgress,
      cancellationToken: cancellationToken,
      onLoading: onLoading,
    );
  }

  /// Fetches paginated items and extracts [PaginationResult].
  static Future<ApiResponse<PaginationResult<T>>> paginate<T>(
    String url, {
    int page = 1,
    int limit = 20,
    required T Function(dynamic json) parser,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    void Function(bool isLoading)? onLoading,
  }) async {
    final params = Map<String, dynamic>.from(queryParameters ?? {});
    params['page'] = page;
    params['limit'] = limit;

    final response = await get<dynamic>(
      url,
      queryParameters: params,
      headers: headers,
      onLoading: onLoading,
    );

    if (response.isSuccess && response.rawData != null) {
      final paginated = PaginationParser.parse<T>(
        json: response.rawData,
        parser: parser,
        currentPage: page,
        limit: limit,
      );
      return ApiResponse<PaginationResult<T>>.success(
        data: paginated,
        rawData: response.rawData,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        headers: response.headers,
        requestId: response.requestId,
        duration: response.duration,
        request: response.request,
      );
    } else {
      return ApiResponse<PaginationResult<T>>.failure(
        error: response.error!,
        rawData: response.rawData,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        headers: response.headers,
        requestId: response.requestId,
        duration: response.duration,
        request: response.request,
      );
    }
  }

  /// Safe functional GET request returning [ApiResult<T>].
  static Future<ApiResult<T>> safeGet<T>(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    Map<String, String>? headers,
    dynamic Function(dynamic json)? parser,
    bool isList = false,
    CachePolicy? cachePolicy,
    Duration? cacheDuration,
    Duration? timeout,
    CancellationToken? cancellationToken,
  }) async {
    final response = await get<T>(
      url,
      queryParameters: queryParameters,
      pathParameters: pathParameters,
      headers: headers,
      parser: parser,
      isList: isList,
      cachePolicy: cachePolicy,
      cacheDuration: cacheDuration,
      timeout: timeout,
      cancellationToken: cancellationToken,
    );
    final resData = response.data;
    if (response.isSuccess && resData != null) {
      return ApiResult.success(resData);
    } else {
      return ApiResult.failure(response.error!);
    }
  }

  /// Safe functional POST request returning [ApiResult<T>].
  static Future<ApiResult<T>> safePost<T>(
    String url, {
    dynamic data,
    BodyType bodyType = BodyType.json,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    Map<String, String>? headers,
    dynamic Function(dynamic json)? parser,
    bool isList = false,
    Duration? timeout,
    CancellationToken? cancellationToken,
  }) async {
    final response = await post<T>(
      url,
      data: data,
      bodyType: bodyType,
      queryParameters: queryParameters,
      pathParameters: pathParameters,
      headers: headers,
      parser: parser,
      isList: isList,
      timeout: timeout,
      cancellationToken: cancellationToken,
    );
    final resData = response.data;
    if (response.isSuccess && resData != null) {
      return ApiResult.success(resData);
    } else {
      return ApiResult.failure(response.error!);
    }
  }

  /// Executes a GET request.
  static Future<ApiResponse<T>> get<T>(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    Map<String, String>? headers,
    dynamic Function(dynamic json)? parser,
    bool isList = false,
    CachePolicy? cachePolicy,
    Duration? cacheDuration,
    Duration? timeout,
    CancellationToken? cancellationToken,
    ProgressCallback? onReceiveProgress,
    void Function(bool isLoading)? onLoading,
  }) {
    final req = ApiRequest(
      id: '',
      method: HttpMethod.get,
      url: url,
      queryParameters: queryParameters,
      pathParameters: pathParameters,
      headers: headers,
      cachePolicy: cachePolicy,
      cacheDuration: cacheDuration,
      receiveTimeout: timeout,
      cancellationToken: cancellationToken,
      onReceiveProgress: onReceiveProgress,
    );
    return _client.execute<T>(
      req,
      parser: parser,
      isList: isList,
      onLoading: onLoading,
    );
  }

  /// Executes a POST request.
  static Future<ApiResponse<T>> post<T>(
    String url, {
    dynamic data,
    BodyType bodyType = BodyType.json,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    Map<String, String>? headers,
    dynamic Function(dynamic json)? parser,
    bool isList = false,
    Duration? timeout,
    CancellationToken? cancellationToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    void Function(bool isLoading)? onLoading,
  }) {
    final req = ApiRequest(
      id: '',
      method: HttpMethod.post,
      url: url,
      data: data,
      bodyType: bodyType,
      queryParameters: queryParameters,
      pathParameters: pathParameters,
      headers: headers,
      receiveTimeout: timeout,
      cancellationToken: cancellationToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return _client.execute<T>(
      req,
      parser: parser,
      isList: isList,
      onLoading: onLoading,
    );
  }

  /// Executes a PUT request.
  static Future<ApiResponse<T>> put<T>(
    String url, {
    dynamic data,
    BodyType bodyType = BodyType.json,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    Map<String, String>? headers,
    dynamic Function(dynamic json)? parser,
    bool isList = false,
    Duration? timeout,
    CancellationToken? cancellationToken,
    void Function(bool isLoading)? onLoading,
  }) {
    final req = ApiRequest(
      id: '',
      method: HttpMethod.put,
      url: url,
      data: data,
      bodyType: bodyType,
      queryParameters: queryParameters,
      pathParameters: pathParameters,
      headers: headers,
      receiveTimeout: timeout,
      cancellationToken: cancellationToken,
    );
    return _client.execute<T>(
      req,
      parser: parser,
      isList: isList,
      onLoading: onLoading,
    );
  }

  /// Executes a PATCH request.
  static Future<ApiResponse<T>> patch<T>(
    String url, {
    dynamic data,
    BodyType bodyType = BodyType.json,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    Map<String, String>? headers,
    dynamic Function(dynamic json)? parser,
    bool isList = false,
    Duration? timeout,
    CancellationToken? cancellationToken,
    void Function(bool isLoading)? onLoading,
  }) {
    final req = ApiRequest(
      id: '',
      method: HttpMethod.patch,
      url: url,
      data: data,
      bodyType: bodyType,
      queryParameters: queryParameters,
      pathParameters: pathParameters,
      headers: headers,
      receiveTimeout: timeout,
      cancellationToken: cancellationToken,
    );
    return _client.execute<T>(
      req,
      parser: parser,
      isList: isList,
      onLoading: onLoading,
    );
  }

  /// Executes a DELETE request.
  static Future<ApiResponse<T>> delete<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    Map<String, String>? headers,
    dynamic Function(dynamic json)? parser,
    bool isList = false,
    Duration? timeout,
    CancellationToken? cancellationToken,
    void Function(bool isLoading)? onLoading,
  }) {
    final req = ApiRequest(
      id: '',
      method: HttpMethod.delete,
      url: url,
      data: data,
      queryParameters: queryParameters,
      pathParameters: pathParameters,
      headers: headers,
      receiveTimeout: timeout,
      cancellationToken: cancellationToken,
    );
    return _client.execute<T>(
      req,
      parser: parser,
      isList: isList,
      onLoading: onLoading,
    );
  }

  /// Executes a HEAD request.
  static Future<ApiResponse<T>> head<T>(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    CancellationToken? cancellationToken,
  }) {
    final req = ApiRequest(
      id: '',
      method: HttpMethod.head,
      url: url,
      queryParameters: queryParameters,
      headers: headers,
      receiveTimeout: timeout,
      cancellationToken: cancellationToken,
    );
    return _client.execute<T>(req);
  }

  /// Executes an OPTIONS request.
  static Future<ApiResponse<T>> options<T>(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    CancellationToken? cancellationToken,
  }) {
    final req = ApiRequest(
      id: '',
      method: HttpMethod.options,
      url: url,
      queryParameters: queryParameters,
      headers: headers,
      receiveTimeout: timeout,
      cancellationToken: cancellationToken,
    );
    return _client.execute<T>(req);
  }

  /// Executes a Form URL Encoded POST/PUT request (`application/x-www-form-urlencoded`).
  static Future<ApiResponse<T>> form<T>(
    String url, {
    required Map<String, dynamic> data,
    HttpMethod method = HttpMethod.post,
    Map<String, String>? headers,
    dynamic Function(dynamic json)? parser,
    bool isList = false,
    void Function(bool isLoading)? onLoading,
  }) {
    final mergedHeaders = Map<String, String>.from(headers ?? {});
    mergedHeaders['Content-Type'] = 'application/x-www-form-urlencoded';

    final req = ApiRequest(
      id: '',
      method: method,
      url: url,
      data: data,
      bodyType: BodyType.urlEncoded,
      headers: mergedHeaders,
    );
    return _client.execute<T>(
      req,
      parser: parser,
      isList: isList,
      onLoading: onLoading,
    );
  }

  /// Executes a Multipart / Form-Data upload request with text fields and files.
  ///
  /// [files] accepts flexible file definitions:
  /// - `Map<String, dynamic>` e.g. `{"profile": File(...), "images": [File(...), File(...)]}`
  /// - `List<UploadFile>`
  /// - Single `UploadFile` or `File`.
  static Future<ApiResponse<T>> multipart<T>(
    String url, {
    Map<String, dynamic>? fields,
    dynamic files,
    HttpMethod method = HttpMethod.post,
    Map<String, String>? headers,
    MultipartFileStrategy? multipartStrategy,
    dynamic Function(dynamic json)? parser,
    bool isList = false,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    CancellationToken? cancellationToken,
    void Function(bool isLoading)? onLoading,
  }) {
    final normalizedFiles = _normalizeUploadFiles(files);

    final req = ApiRequest(
      id: '',
      method: method,
      url: url,
      data: fields,
      bodyType: BodyType.formData,
      files: normalizedFiles,
      headers: headers,
      multipartStrategy: multipartStrategy,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      cancellationToken: cancellationToken,
    );
    return _client.execute<T>(
      req,
      parser: parser,
      isList: isList,
      onLoading: onLoading,
    );
  }

  /// Alias for [multipart] upload method.
  static Future<ApiResponse<T>> upload<T>(
    String url, {
    Map<String, dynamic>? fields,
    dynamic files,
    HttpMethod method = HttpMethod.post,
    Map<String, String>? headers,
    MultipartFileStrategy? multipartStrategy,
    dynamic Function(dynamic json)? parser,
    bool isList = false,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    CancellationToken? cancellationToken,
    void Function(bool isLoading)? onLoading,
  }) {
    return multipart<T>(
      url,
      fields: fields,
      files: files,
      method: method,
      headers: headers,
      multipartStrategy: multipartStrategy,
      parser: parser,
      isList: isList,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      cancellationToken: cancellationToken,
      onLoading: onLoading,
    );
  }

  /// Advanced custom request method exposing all configurations.
  static Future<ApiResponse<T>> request<T>({
    required HttpMethod method,
    required String url,
    dynamic data,
    BodyType? bodyType,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? pathParameters,
    Map<String, String>? headers,
    List<UploadFile>? files,
    MultipartFileStrategy? multipartStrategy,
    dynamic Function(dynamic json)? parser,
    bool isList = false,
    Duration? timeout,
    CancellationToken? cancellationToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    void Function(bool isLoading)? onLoading,
  }) {
    final req = ApiRequest(
      id: '',
      method: method,
      url: url,
      data: data,
      bodyType: bodyType,
      queryParameters: queryParameters,
      pathParameters: pathParameters,
      headers: headers,
      files: files,
      multipartStrategy: multipartStrategy,
      receiveTimeout: timeout,
      cancellationToken: cancellationToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return _client.execute<T>(
      req,
      parser: parser,
      isList: isList,
      onLoading: onLoading,
    );
  }

  static List<UploadFile> _normalizeUploadFiles(dynamic input) {
    if (input == null) return [];
    if (input is List<UploadFile>) return input;

    final result = <UploadFile>[];

    if (input is UploadFile) {
      result.add(input);
    } else if (input is File) {
      result.add(UploadFile.fromFile(field: 'file', file: input));
    } else if (input is Map) {
      input.forEach((key, value) {
        final fieldKey = '$key';
        if (value is File) {
          result.add(UploadFile.fromFile(field: fieldKey, file: value));
        } else if (value is UploadFile) {
          result.add(value.copyWithField(fieldKey));
        } else if (value is Uint8List) {
          result.add(UploadFile.fromBytes(
            field: fieldKey,
            filename: '$fieldKey.bin',
            bytes: value,
          ));
        } else if (value is String) {
          result.add(UploadFile.fromPath(field: fieldKey, filePath: value));
        } else if (value is List) {
          for (var i = 0; i < value.length; i++) {
            final item = value[i];
            if (item is File) {
              result.add(UploadFile.fromFile(field: fieldKey, file: item));
            } else if (item is UploadFile) {
              result.add(item.copyWithField(fieldKey));
            } else if (item is Uint8List) {
              result.add(UploadFile.fromBytes(
                field: fieldKey,
                filename: '${fieldKey}_$i.bin',
                bytes: item,
              ));
            } else if (item is String) {
              result.add(UploadFile.fromPath(field: fieldKey, filePath: item));
            }
          }
        }
      });
    }

    return result;
  }
}
