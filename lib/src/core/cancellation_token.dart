import '../errors/api_error.dart';

/// A token that can be passed to API requests to cancel them in-flight.
class CancellationToken {
  bool _isCancelled = false;
  String? _cancelReason;
  final List<void Function(String? reason)> _listeners = [];

  /// Returns `true` if the token has been cancelled.
  bool get isCancelled => _isCancelled;

  /// Returns the reason for cancellation if provided.
  String? get cancelReason => _cancelReason;

  /// Cancels the associated request.
  ///
  /// Optionally supply a [reason] explaining why it was cancelled.
  void cancel([String? reason]) {
    if (_isCancelled) return;
    _isCancelled = true;
    _cancelReason = reason ?? 'Request was cancelled by user';
    for (final listener in List.from(_listeners)) {
      listener(_cancelReason);
    }
    _listeners.clear();
  }

  /// Adds a listener callback invoked when cancellation occurs.
  void addListener(void Function(String? reason) listener) {
    if (_isCancelled) {
      listener(_cancelReason);
      return;
    }
    _listeners.add(listener);
  }

  /// Removes a previously added listener.
  void removeListener(void Function(String? reason) listener) {
    _listeners.remove(listener);
  }

  /// Throws a [CancelledError] if this token is cancelled.
  void throwIfCancelled() {
    if (_isCancelled) {
      throw CancelledError(
        message: _cancelReason ?? 'Request was cancelled',
      );
    }
  }
}
