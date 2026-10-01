import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../cache/api_cache.dart';
import '../enums/body_type.dart';
import '../enums/cache_policy.dart';
import '../enums/http_method.dart';
import '../errors/api_error.dart';
import '../interceptors/api_interceptor.dart';
import '../interceptors/auth_interceptor.dart';
import '../logging/api_logger.dart';
import '../models/api_request.dart';
import '../models/api_response.dart';
import '../multipart/multipart_builder.dart';
import '../offline/connectivity_checker.dart';
import '../retry/retry_policy.dart';
import '../utils/error_parser.dart';
import '../utils/response_parser.dart';
import 'api_config.dart';
import 'cancellation_token.dart';

/// Low-level HTTP engine managing connection lifecycles, interceptors, retries, and logging.
class ApiClient {
  ApiConfig config;
  final http.Client _httpClient;
  final AuthInterceptor authInterceptor;
  final List<ApiInterceptor> _interceptors = [];
  final ApiCache cache = ApiCache();
  late ApiLogger logger;
  late RetryPolicy retryPolicy;

  int _requestCounter = 0;
  bool _isRefreshingToken = false;

  ApiClient({
    ApiConfig? config,
    http.Client? httpClient,
  })  : config = config ?? ApiConfig(),
        _httpClient = httpClient ?? http.Client(),
        authInterceptor = AuthInterceptor(
          tokenProvider: config?.tokenProvider,
          headerKey: config?.authHeaderKey ?? 'Authorization',
          headerPrefix: config?.authHeaderPrefix ?? 'Bearer ',
        ) {
    _initLoggerAndRetry();
  }

  void _initLoggerAndRetry() {
    logger = ApiLogger(
      enabled: config.enableLogging,
      logLevel: config.logLevel,
      sensitiveHeaders: config.sensitiveHeaders,
      sensitiveBodyKeys: config.sensitiveBodyKeys,
    );
    retryPolicy = RetryPolicy(
      retryCount: config.retryCount,
      retryDelay: config.retryDelay,
      retryOnMethods: config.retryOnMethods,
    );
  }

  /// Registers an interceptor into the execution pipeline.
  void addInterceptor(ApiInterceptor interceptor) {
    _interceptors.add(interceptor);
  }

  /// Removes a registered interceptor.
  void removeInterceptor(ApiInterceptor interceptor) {
    _interceptors.remove(interceptor);
  }

  /// Clears all non-system interceptors.
  void clearInterceptors() {
    _interceptors.clear();
  }

  /// Updates client configuration.
  void updateConfig(ApiConfig newConfig) {
    config = newConfig;
    _initLoggerAndRetry();
  }

  /// Primary execution pipeline for all HTTP requests.
  Future<ApiResponse<T>> execute<T>(
    ApiRequest request, {
    dynamic Function(dynamic json)? parser,
    bool isList = false,
    void Function(bool isLoading)? onLoading,
  }) async {
    final startTime = DateTime.now();
    final requestId = request.id.isEmpty ? _generateRequestId() : request.id;

    if (onLoading != null) onLoading(true);

    try {
      request.cancellationToken?.throwIfCancelled();

      // Check Offline Connectivity
      if (config.checkOfflineFirst) {
        final online = await ConnectivityChecker.isConnected();
        if (!online) {
          throw const OfflineError();
        }
      }

      // Step 1: Prepare headers & apply Interceptors
      var currentRequest = request.copyWith(
        id: requestId,
        baseUrl: request.baseUrl ?? config.baseUrl,
      );

      // Apply Default Config Headers
      final mergedHeaders = Map<String, String>.from(config.defaultHeaders);
      if (currentRequest.headers != null) {
        mergedHeaders.addAll(currentRequest.headers!);
      }
      currentRequest = currentRequest.copyWith(headers: mergedHeaders);

      // Run Auth Interceptor & Custom Interceptors
      currentRequest = await authInterceptor.onRequest(currentRequest);
      for (final interceptor in _interceptors) {
        currentRequest = await interceptor.onRequest(currentRequest);
      }

      currentRequest.cancellationToken?.throwIfCancelled();

      // Check Cache for GET Requests
      final policy = currentRequest.cachePolicy ?? CachePolicy.networkOnly;
      if (currentRequest.method == HttpMethod.get && (policy != CachePolicy.networkOnly || config.enableCache)) {
        final cacheKey = cache.generateKey(currentRequest.method.name, currentRequest.fullUrl, currentRequest.queryParameters);
        final cached = cache.store.get(cacheKey);

        if (policy == CachePolicy.cacheOnly) {
          if (cached != null) {
            return _processCachedResponse<T>(cached, currentRequest, parser, isList, startTime);
          } else {
            throw NotFoundError(
              message: 'No cached response found for key: $cacheKey',
              endpoint: currentRequest.fullUrl,
              method: currentRequest.method.name,
            );
          }
        }

        if ((policy == CachePolicy.cacheFirst || config.enableCache) && cached != null) {
          return _processCachedResponse<T>(cached, currentRequest, parser, isList, startTime);
        }
      }

      // Log Request
      logger.logRequest(currentRequest);

      // Step 2: Perform Request with Retry Policy
      final response = await _executeWithRetry<T>(
        currentRequest: currentRequest,
        parser: parser,
        isList: isList,
        startTime: startTime,
        attemptNumber: 0,
      );
      return response;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      final apiError = ErrorParser.parseException(
        error: e,
        url: request.fullUrl,
        method: request.method,
        stackTrace: stackTrace,
      );

      logger.logError(apiError);

      return ApiResponse<T>.failure(
        error: apiError,
        requestId: requestId,
        duration: duration,
        request: request,
      );
    } finally {
      if (onLoading != null) onLoading(false);
    }
  }

  Future<ApiResponse<T>> _executeWithRetry<T>({
    required ApiRequest currentRequest,
    required dynamic Function(dynamic json)? parser,
    required bool isList,
    required DateTime startTime,
    required int attemptNumber,
  }) async {
    try {
      final response = await _sendNetworkRequest(currentRequest);
      final duration = DateTime.now().difference(startTime);

      // Log raw response
      var apiResponse = ApiResponse<T>(
        data: null,
        rawData: response.body,
        statusCode: response.statusCode,
        statusMessage: response.reasonPhrase,
        headers: response.headers,
        requestId: currentRequest.id,
        duration: duration,
        request: currentRequest,
      );

      // Run Response Interceptors
      for (final interceptor in _interceptors) {
        apiResponse = (await interceptor.onResponse(apiResponse)) as ApiResponse<T>;
      }

      logger.logResponse(apiResponse);

      // Handle 401 Token Refresh Logic
      if (response.statusCode == 401 && config.refreshTokenHandler != null && !_isRefreshingToken) {
        _isRefreshingToken = true;
        try {
          final refreshed = await config.refreshTokenHandler!();
          if (refreshed) {
            _isRefreshingToken = false;
            // Retry original request once with fresh token
            final retriedRequest = await authInterceptor.onRequest(currentRequest);
            final newResp = await _sendNetworkRequest(retriedRequest);
            final refreshedResult = _processRawResponse<T>(
              response: newResp,
              request: retriedRequest,
              parser: parser,
              isList: isList,
              duration: DateTime.now().difference(startTime),
            );
            return refreshedResult;
          }
        } finally {
          _isRefreshingToken = false;
        }
      }

      // Check success range (200-299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final successRes = _processRawResponse<T>(
          response: response,
          request: currentRequest,
          parser: parser,
          isList: isList,
          duration: duration,
        );
        return successRes;
      } else {
        final error = ErrorParser.parseResponse(
          response: response,
          url: currentRequest.fullUrl,
          method: currentRequest.method,
        );

        // Check if retry is appropriate
        if (retryPolicy.shouldRetry(
          error: error,
          attemptNumber: attemptNumber,
          method: currentRequest.method,
        )) {
          await Future.delayed(retryPolicy.getDelay(attemptNumber + 1));
          final retryRes = await _executeWithRetry<T>(
            currentRequest: currentRequest,
            parser: parser,
            isList: isList,
            startTime: startTime,
            attemptNumber: attemptNumber + 1,
          );
          return retryRes;
        }

        // Run Error Interceptors
        var finalError = error;
        for (final interceptor in _interceptors) {
          final modified = await interceptor.onError(finalError);
          if (modified != null) finalError = modified;
        }

        logger.logError(finalError);

        return ApiResponse<T>.failure(
          error: finalError,
          rawData: response.body,
          statusCode: response.statusCode,
          statusMessage: response.reasonPhrase,
          headers: response.headers,
          requestId: currentRequest.id,
          duration: duration,
          request: currentRequest,
        );
      }
    } catch (e, stackTrace) {
      final error = ErrorParser.parseException(
        error: e,
        url: currentRequest.fullUrl,
        method: currentRequest.method,
        stackTrace: stackTrace,
      );

      if (retryPolicy.shouldRetry(
        error: error,
        attemptNumber: attemptNumber,
        method: currentRequest.method,
      )) {
        await Future.delayed(retryPolicy.getDelay(attemptNumber + 1));
        return await _executeWithRetry<T>(
          currentRequest: currentRequest,
          parser: parser,
          isList: isList,
          startTime: startTime,
          attemptNumber: attemptNumber + 1,
        );
      }

      logger.logError(error);

      return ApiResponse<T>.failure(
        error: error,
        requestId: currentRequest.id,
        duration: DateTime.now().difference(startTime),
        request: currentRequest,
      );
    }
  }

  Future<http.Response> _sendNetworkRequest(ApiRequest request) async {
    final timeout = request.receiveTimeout ?? config.receiveTimeout;

    // Check if multipart request
    if ((request.files != null && request.files!.isNotEmpty) ||
        request.bodyType == BodyType.formData) {
      return await _sendMultipartRequest(request).timeout(timeout);
    }

    final uri = Uri.parse(request.fullUrl).replace(
      queryParameters: _prepareQueryParameters(request.queryParameters),
    );

    final method = request.method.name;
    final headers = request.headers ?? {};
    final body = _prepareRequestBody(request.data, request.bodyType);

    final httpRequest = http.Request(method, uri);
    httpRequest.headers.addAll(headers);

    if (body != null) {
      if (body is String) {
        httpRequest.body = body;
      } else if (body is List<int>) {
        httpRequest.bodyBytes = body;
      } else if (body is Map<String, String>) {
        httpRequest.bodyFields = body;
      }
    }

    // Cancellation check
    request.cancellationToken?.throwIfCancelled();

    final streamedResponse = await _httpClient.send(httpRequest).timeout(timeout);

    // Download progress tracking
    if (request.onReceiveProgress != null) {
      return await _readStreamWithProgress(streamedResponse, request.onReceiveProgress!);
    } else {
      return await http.Response.fromStream(streamedResponse);
    }
  }

  Future<http.Response> _sendMultipartRequest(ApiRequest request) async {
    final multipartReq = await MultipartBuilder.buildRequest(request);

    if (request.onSendProgress != null) {
      final streamedProgressReq = MultipartBuilder.createProgressRequest(
        multipartReq,
        request.onSendProgress!,
      );
      final streamedResponse = await _httpClient.send(streamedProgressReq);
      return await http.Response.fromStream(streamedResponse);
    } else {
      final streamedResponse = await _httpClient.send(multipartReq);
      return await http.Response.fromStream(streamedResponse);
    }
  }

  Future<http.Response> _readStreamWithProgress(
    http.StreamedResponse streamedResponse,
    ProgressCallback onReceiveProgress,
  ) async {
    final contentLength = streamedResponse.contentLength ?? 0;
    var bytesReceived = 0;
    final chunks = <List<int>>[];

    await for (final chunk in streamedResponse.stream) {
      bytesReceived += chunk.length;
      chunks.add(chunk);
      if (contentLength > 0) {
        onReceiveProgress(bytesReceived, contentLength);
      }
    }

    final bytes = Uint8List.fromList(chunks.expand((x) => x).toList());
    return http.Response.bytes(
      bytes,
      streamedResponse.statusCode,
      headers: streamedResponse.headers,
      isRedirect: streamedResponse.isRedirect,
      persistentConnection: streamedResponse.persistentConnection,
      reasonPhrase: streamedResponse.reasonPhrase,
    );
  }

  /// Downloads a file from [url] and streams directly to disk at [savePath].
  Future<ApiResponse<File>> download(
    String url, {
    required String savePath,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    ProgressCallback? onReceiveProgress,
    CancellationToken? cancellationToken,
    void Function(bool isLoading)? onLoading,
  }) async {
    final startTime = DateTime.now();
    final requestId = _generateRequestId();

    if (onLoading != null) onLoading(true);

    try {
      cancellationToken?.throwIfCancelled();

      final fullUrl = url.startsWith('http') ? url : '${config.baseUrl}$url';
      final uri = Uri.parse(fullUrl).replace(
        queryParameters: _prepareQueryParameters(queryParameters),
      );

      final httpRequest = http.Request('GET', uri);
      if (headers != null) httpRequest.headers.addAll(headers);

      final streamedResponse = await _httpClient.send(httpRequest);

      final file = File(savePath);
      final sink = file.openWrite();

      final totalBytes = streamedResponse.contentLength ?? 0;
      var bytesReceived = 0;

      await for (final chunk in streamedResponse.stream) {
        cancellationToken?.throwIfCancelled();
        bytesReceived += chunk.length;
        sink.add(chunk);
        if (onReceiveProgress != null && totalBytes > 0) {
          onReceiveProgress(bytesReceived, totalBytes);
        }
      }

      await sink.flush();
      await sink.close();

      final duration = DateTime.now().difference(startTime);

      final req = ApiRequest(
        id: requestId,
        method: HttpMethod.get,
        url: url,
        queryParameters: queryParameters,
        headers: headers,
      );

      return ApiResponse<File>.success(
        data: file,
        rawData: savePath,
        statusCode: streamedResponse.statusCode,
        statusMessage: streamedResponse.reasonPhrase,
        headers: streamedResponse.headers,
        requestId: requestId,
        duration: duration,
        request: req,
      );
    } catch (e, stackTrace) {
      final error = ErrorParser.parseException(
        error: e,
        url: url,
        method: HttpMethod.get,
        stackTrace: stackTrace,
      );
      return ApiResponse<File>.failure(
        error: error,
        requestId: requestId,
        duration: DateTime.now().difference(startTime),
        request: ApiRequest(id: requestId, method: HttpMethod.get, url: url),
      );
    } finally {
      if (onLoading != null) onLoading(false);
    }
  }

  ApiResponse<T> _processCachedResponse<T>(
    dynamic cached,
    ApiRequest request,
    dynamic Function(dynamic json)? parser,
    bool isList,
    DateTime startTime,
  ) {
    final duration = DateTime.now().difference(startTime);
    final raw = cached.rawData;
    T? parsedData;

    if (parser != null && raw != null) {
      parsedData = ResponseParser.parse<T>(
        rawBody: raw,
        parser: parser,
        isList: isList,
        endpoint: request.fullUrl,
        method: request.method,
        statusCode: cached.statusCode,
      );
    } else {
      parsedData = cached.data as T?;
    }

    return ApiResponse<T>.success(
      data: parsedData,
      rawData: raw,
      statusCode: cached.statusCode,
      statusMessage: 'OK (Cached)',
      headers: Map<String, String>.from(cached.headers),
      requestId: request.id,
      duration: duration,
      request: request,
    );
  }

  ApiResponse<T> _processRawResponse<T>({
    required http.Response response,
    required ApiRequest request,
    required dynamic Function(dynamic json)? parser,
    required bool isList,
    required Duration duration,
  }) {
    dynamic decodedBody = response.body;
    try {
      if (response.body.isNotEmpty) {
        decodedBody = jsonDecode(response.body);
      }
    } catch (_) {
      decodedBody = response.body;
    }

    // Save to Cache if GET and cache active
    if (request.method == HttpMethod.get &&
        (request.cachePolicy != null || config.enableCache)) {
      final cacheKey = cache.generateKey(
        request.method.name,
        request.fullUrl,
        request.queryParameters,
      );
      cache.store.set(
        key: cacheKey,
        data: decodedBody,
        rawData: decodedBody,
        statusCode: response.statusCode,
        headers: response.headers,
        duration: request.cacheDuration ?? config.defaultCacheDuration,
      );
    }

    if (parser == null) {
      return ApiResponse<T>.success(
        data: decodedBody as T?,
        rawData: decodedBody,
        statusCode: response.statusCode,
        statusMessage: response.reasonPhrase,
        headers: response.headers,
        requestId: request.id,
        duration: duration,
        request: request,
      );
    }

    try {
      final parsedData = ResponseParser.parse<T>(
        rawBody: decodedBody,
        parser: parser,
        isList: isList,
        endpoint: request.fullUrl,
        method: request.method,
        statusCode: response.statusCode,
      );

      return ApiResponse<T>.success(
        data: parsedData,
        rawData: decodedBody,
        statusCode: response.statusCode,
        statusMessage: response.reasonPhrase,
        headers: response.headers,
        requestId: request.id,
        duration: duration,
        request: request,
      );
    } on ParsingError catch (parseError) {
      logger.logError(parseError);
      return ApiResponse<T>.failure(
        error: parseError,
        rawData: decodedBody,
        statusCode: response.statusCode,
        statusMessage: response.reasonPhrase,
        headers: response.headers,
        requestId: request.id,
        duration: duration,
        request: request,
      );
    }
  }

  Map<String, String>? _prepareQueryParameters(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return null;
    final map = <String, String>{};
    params.forEach((key, value) {
      if (value != null) {
        map[key] = '$value';
      }
    });
    return map;
  }

  dynamic _prepareRequestBody(dynamic data, BodyType? bodyType) {
    if (data == null) return null;

    if (bodyType == BodyType.urlEncoded && data is Map) {
      final map = <String, String>{};
      data.forEach((k, v) => map['$k'] = '$v');
      return map;
    }

    if (data is String || data is List<int> || data is Uint8List) {
      return data;
    }

    if (data is Map || data is List) {
      return jsonEncode(data);
    }

    return data.toString();
  }

  String _generateRequestId() {
    _requestCounter++;
    return 'req_${DateTime.now().millisecondsSinceEpoch}_$_requestCounter';
  }

  /// Closes underlying HTTP client.
  void dispose() {
    _httpClient.close();
  }
}
