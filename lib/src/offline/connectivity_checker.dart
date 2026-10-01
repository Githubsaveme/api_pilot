import 'dart:io';

/// Utility for checking device network connectivity before making API calls.
class ConnectivityChecker {
  /// Evaluates whether internet connection is active.
  static Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('dns.google').timeout(
        const Duration(seconds: 3),
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
