import '../models/api_request.dart';
import 'api_interceptor.dart';

/// Interceptor that automatically injects Authorization headers into requests.
class AuthInterceptor extends ApiInterceptor {
  String? _explicitToken;
  final Future<String?> Function()? tokenProvider;
  final String headerKey;
  final String headerPrefix;

  AuthInterceptor({
    String? initialToken,
    this.tokenProvider,
    this.headerKey = 'Authorization',
    this.headerPrefix = 'Bearer ',
  }) : _explicitToken = initialToken;

  /// Sets an explicit authentication token.
  void setToken(String token) {
    _explicitToken = token;
  }

  /// Clears the stored explicit token.
  void clearToken() {
    _explicitToken = null;
  }

  /// Retrieves the active token from explicit storage or dynamic provider.
  Future<String?> getToken() async {
    if (_explicitToken != null && _explicitToken!.isNotEmpty) {
      return _explicitToken;
    }
    if (tokenProvider != null) {
      return await tokenProvider!();
    }
    return null;
  }

  @override
  Future<ApiRequest> onRequest(ApiRequest request) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return request;
    }

    final currentHeaders = Map<String, String>.from(request.headers ?? {});
    // Do not overwrite if explicit Authorization header is already passed for this specific request
    if (!currentHeaders.containsKey(headerKey) && !currentHeaders.containsKey(headerKey.toLowerCase())) {
      final headerValue = headerPrefix.isEmpty ? token : '$headerPrefix$token';
      currentHeaders[headerKey] = headerValue;
    }

    return request.copyWith(headers: currentHeaders);
  }
}
