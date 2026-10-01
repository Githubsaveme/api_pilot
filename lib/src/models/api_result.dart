import '../errors/api_error.dart';

/// Functional result type representing either a success value [T] or an [ApiError].
abstract class ApiResult<T> {
  const ApiResult();

  /// `true` if the request succeeded.
  bool get isSuccess => this is ApiSuccess<T>;

  /// `true` if the request failed.
  bool get isFailure => this is ApiFailure<T>;

  /// Data payload if successful, `null` otherwise.
  T? get data => isSuccess ? (this as ApiSuccess<T>).value : null;

  /// Error details if failed, `null` otherwise.
  ApiError? get error => isFailure ? (this as ApiFailure<T>).err : null;

  /// Pattern match handler for success and failure outcomes.
  R when<R>({
    required R Function(T data) success,
    required R Function(ApiError error) failure,
  }) {
    if (this is ApiSuccess<T>) {
      return success((this as ApiSuccess<T>).value);
    } else {
      return failure((this as ApiFailure<T>).err);
    }
  }

  /// Maps successful result data into type [R].
  ApiResult<R> map<R>(R Function(T data) mapper) {
    if (this is ApiSuccess<T>) {
      return ApiResult.success(mapper((this as ApiSuccess<T>).value));
    } else {
      return ApiResult.failure((this as ApiFailure<T>).err);
    }
  }

  /// Creates a successful [ApiResult].
  factory ApiResult.success(T value) = ApiSuccess<T>;

  /// Creates a failed [ApiResult].
  factory ApiResult.failure(ApiError error) = ApiFailure<T>;
}

/// Successful outcome wrapper.
class ApiSuccess<T> extends ApiResult<T> {
  final T value;
  const ApiSuccess(this.value);

  @override
  String toString() => 'ApiSuccess($value)';
}

/// Failed outcome wrapper.
class ApiFailure<T> extends ApiResult<T> {
  final ApiError err;
  const ApiFailure(this.err);

  @override
  String toString() => 'ApiFailure($err)';
}
