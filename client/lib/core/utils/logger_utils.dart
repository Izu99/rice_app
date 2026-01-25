import 'package:flutter/foundation.dart';

/// Centralized logging utility for the Rice App
/// Uses emojis and colors for better visibility in the terminal
class Log {
  static const String _tag = '[RiceMill]';

  /// Log an info message (General)
  static void i(String message, {String? tag}) {
    _print('ℹ️  ${tag ?? 'INFO'}: $message');
  }

  /// Log a success message (Successfully completed actions)
  static void s(String message, {String? tag}) {
    _print('✅  ${tag ?? 'SUCCESS'}: $message');
  }

  /// Log a warning message
  static void w(String message, {String? tag}) {
    _print('⚠️  ${tag ?? 'WARNING'}: $message');
  }

  /// Log an error message
  static void e(String message, {String? tag, dynamic error}) {
    _print('❌  ${tag ?? 'ERROR'}: $message');
    if (error != null) {
      _print('    Error context: $error');
    }
  }

  /// Log authentication events
  static void auth(String message) {
    _print('🔐  AUTH: $message');
  }

  /// Log company management events
  static void company(String message) {
    _print('🏢  COMPANY: $message');
  }

  /// Log customer management events
  static void customer(String message) {
    _print('🤝  CUSTOMER: $message');
  }

  /// Log logout events
  static void logout(String message) {
    _print('🚪  LOGOUT: $message');
  }

  /// Log API requests
  static void api(String method, String path, {dynamic data}) {
    _print('🌐  API $method: $path');
    if (data != null && kDebugMode) {
      _print('    Data: $data');
    }
  }

  static void _print(String message) {
    if (kDebugMode) {
      // Use debugPrint for better handling of long strings
      debugPrint('$_tag $message');
    }
  }
}

