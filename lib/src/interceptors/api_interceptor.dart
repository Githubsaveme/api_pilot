import '../errors/api_error.dart';
import '../models/api_request.dart';
import '../models/api_response.dart';

/// Abstract interceptor class for modifying requests, responses, or errors in flight.
abstract class ApiInterceptor {
  const ApiInterceptor();

  /// Called before the request is sent over the network.
  ///
  /// Can modify headers, parameters, or body of the outgoing [request].
  Future<ApiRequest> onRequest(ApiRequest request) async => request;

  /// Called when a response is received from the server.
  ///
  /// Can transform or inspect the incoming [response].
  Future<ApiResponse> onResponse(ApiResponse response) async => response;

  /// Called when an HTTP or network error occurs.
  ///
  /// Return an [ApiError] to pass it down the chain, or return `null` if resolved.
  Future<ApiError?> onError(ApiError error) async => error;
}

/// A functional implementation of [ApiInterceptor] allowing quick inline callbacks.
class SimpleInterceptor extends ApiInterceptor {
  final Future<ApiRequest> Function(ApiRequest request)? onRequestCallback;
  final Future<ApiResponse> Function(ApiResponse response)? onResponseCallback;
  final Future<ApiError?> Function(ApiError error)? onErrorCallback;

  const SimpleInterceptor({
    this.onRequestCallback,
    this.onResponseCallback,
    this.onErrorCallback,
  });

  @override
  Future<ApiRequest> onRequest(ApiRequest request) async {
    if (onRequestCallback != null) {
      return await onRequestCallback!(request);
    }
    return request;
  }

  @override
  Future<ApiResponse> onResponse(ApiResponse response) async {
    if (onResponseCallback != null) {
      return await onResponseCallback!(response);
    }
    return response;
  }

  @override
  Future<ApiError?> onError(ApiError error) async {
    if (onErrorCallback != null) {
      return await onErrorCallback!(error);
    }
    return error;
  }
}
