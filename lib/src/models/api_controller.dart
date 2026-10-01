import 'package:flutter/foundation.dart';
import '../errors/api_error.dart';
import 'api_response.dart';

/// Helper controller for managing API request lifecycle state in Flutter widgets.
///
/// Extends [ChangeNotifier] to seamlessly bind UI loading indicators, data, and error views.
class EasyApiController<T> extends ChangeNotifier {
  bool _isLoading = false;
  T? _data;
  ApiError? _error;
  ApiResponse<T>? _response;

  /// Whether an API request is currently executing.
  bool get isLoading => _isLoading;

  /// Parsed response data model when successful.
  T? get data => _data;

  /// Occurred API error if request failed.
  ApiError? get error => _error;

  /// Complete response object.
  ApiResponse<T>? get response => _response;

  /// Whether data is non-null and no error occurred.
  bool get hasData => _data != null && _error == null;

  /// Whether an error occurred.
  bool get hasError => _error != null;

  /// Executes an API request function while managing loading, data, and error state.
  Future<ApiResponse<T>> execute(
    Future<ApiResponse<T>> Function() requestFn, {
    void Function(bool isLoading)? onLoading,
  }) async {
    _setLoading(true, onLoading);
    _error = null;

    try {
      final res = await requestFn();
      _response = res;

      if (res.isSuccess) {
        _data = res.data;
        _error = null;
      } else {
        _error = res.error;
      }
      return res;
    } catch (e, stackTrace) {
      if (e is ApiError) {
        _error = e;
      } else {
        _error = UnknownApiError(
          message: e.toString(),
          cause: e,
          stackTrace: stackTrace,
        );
      }
      rethrow;
    } finally {
      _setLoading(false, onLoading);
    }
  }

  /// Resets controller state.
  void reset() {
    _isLoading = false;
    _data = null;
    _error = null;
    _response = null;
    notifyListeners();
  }

  void _setLoading(bool loading, void Function(bool)? onLoading) {
    _isLoading = loading;
    if (onLoading != null) {
      onLoading(loading);
    }
    notifyListeners();
  }
}

/// Alias for [EasyApiController] for alternative naming preference.
typedef ApiRequestController<T> = EasyApiController<T>;
