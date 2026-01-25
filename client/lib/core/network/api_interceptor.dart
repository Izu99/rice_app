import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import 'api_service.dart';

// ==================== AUTH INTERCEPTOR ====================

/// Interceptor for handling authentication
class AuthInterceptor extends Interceptor {
  final SharedPreferences _prefs;
  final void Function()? onTokenExpired;
  final ApiService? _apiService; // Add ApiService instance

  AuthInterceptor(
    this._prefs, {
    this.onTokenExpired,
    ApiService? apiService, // Make it optional for now, will be passed
  }) : _apiService = apiService;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for certain endpoints
    if (_isPublicEndpoint(options.path)) {
      return handler.next(options);
    }

    // Add auth token if available
    try {
      final token = _prefs.getString(AppConstants.tokenKey);

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        debugPrint('AuthInterceptor: Sending token for ${options.path}');
      } else {
        debugPrint('AuthInterceptor: No token found for ${options.path}');
      }
    } catch (e) {
      debugPrint('Error reading auth token: $e');
    }

    // Add common headers
    options.headers.addAll({
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    });

    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    // Check for token in response and update if present
    _updateTokenFromResponse(response);
    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized
    if (err.response?.statusCode == 401) {
      if (_apiService != null) {
        _apiService!.clearCache(); // Clear cache on 401 to prevent stale data
        debugPrint('AuthInterceptor: Cleared API cache due to 401 error.');
      }
      await _handleUnauthorized();
    }

    handler.next(err);
  }

  /// Check if endpoint is public (doesn't require auth)
  bool _isPublicEndpoint(String path) {
    const publicEndpoints = [
      '/auth/login',
      '/auth/register',
      '/auth/forgot-password',
      '/auth/reset-password',
      '/health',
      '/ping',
    ];

    return publicEndpoints.any((endpoint) => path.contains(endpoint));
  }

  /// Update token from response if present
  void _updateTokenFromResponse(Response response) async {
    try {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final newToken = data['access_token'] ??
            data['token'] ??
            (data['data'] is Map
                ? data['data']['access_token'] ?? data['data']['token']
                : null);

        if (newToken != null && newToken is String) {
          await _prefs.setString(
            AppConstants.tokenKey,
            newToken,
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating token: $e');
    }
  }

  /// Handle unauthorized response
  Future<void> _handleUnauthorized() async {
    try {
      // Clear stored token
      await _prefs.remove(AppConstants.tokenKey);
      await _prefs.remove(AppConstants.userKey);

      // Notify app about token expiry
      onTokenExpired?.call();
    } catch (e) {
      debugPrint('Error handling unauthorized: $e');
    }
  }
}

// ==================== LOGGING INTERCEPTOR ====================

/// Interceptor for logging requests and responses
class LoggingInterceptor extends Interceptor {
  final Logger _logger;
  final bool logRequestBody;
  final bool logResponseBody;
  final bool logHeaders;

  LoggingInterceptor({
    Logger? logger,
    this.logRequestBody = true,
    this.logResponseBody = true,
    this.logHeaders = false,
  }) : _logger = logger ??
      Logger(
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 50,
          colors: true,
          printEmojis: true,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
      );

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final buffer = StringBuffer();

    buffer.writeln(
        '┌────────────────────────────────────────────────────────────');
    buffer.writeln('│ 🚀 REQUEST');
    buffer.writeln('│ ${options.method} ${options.uri}');

    if (logHeaders && options.headers.isNotEmpty) {
      buffer.writeln('│ Headers:');
      options.headers.forEach((key, value) {
        // Hide sensitive headers
        if (key.toLowerCase() == 'authorization') {
          buffer.writeln('│   $key: Bearer ***');
        } else {
          buffer.writeln('│   $key: $value');
        }
      });
    }

    if (options.queryParameters.isNotEmpty) {
      buffer.writeln('│ Query: ${options.queryParameters}');
    }

    if (logRequestBody && options.data != null) {
      buffer.writeln('│ Body: ${_formatData(options.data)}');
    }

    buffer.writeln(
        '└────────────────────────────────────────────────────────────');

    _logger.i(buffer.toString());
    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    final buffer = StringBuffer();
    final statusEmoji = _getStatusEmoji(response.statusCode ?? 0);

    buffer.writeln(
        '┌────────────────────────────────────────────────────────────');
    buffer.writeln('│ $statusEmoji RESPONSE [${response.statusCode}]');
    buffer.writeln(
        '│ ${response.requestOptions.method} ${response.requestOptions.uri}');
    buffer.writeln(
        '│ Time: ${response.requestOptions.extra['startTime'] != null ? '${DateTime.now().difference(response.requestOptions.extra['startTime'] as DateTime).inMilliseconds}ms' : 'N/A'}');

    if (logResponseBody && response.data != null) {
      buffer.writeln('│ Data: ${_formatData(response.data)}');
    }

    buffer.writeln(
        '└────────────────────────────────────────────────────────────');

    _logger.i(buffer.toString());
    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    final buffer = StringBuffer();

    buffer.writeln(
        '┌────────────────────────────────────────────────────────────');
    buffer.writeln('│ ❌ ERROR [${err.response?.statusCode ?? 'N/A'}]');
    buffer.writeln('│ ${err.requestOptions.method} ${err.requestOptions.uri}');
    buffer.writeln('│ Type: ${err.type}');
    buffer.writeln('│ Message: ${err.message}');

    if (err.response?.data != null) {
      buffer.writeln('│ Response: ${_formatData(err.response?.data)}');
    }

    buffer.writeln(
        '└────────────────────────────────────────────────────────────');

    _logger.e(buffer.toString());
    handler.next(err);
  }

  /// Format data for logging
  String _formatData(dynamic data) {
    try {
      if (data is Map || data is List) {
        final jsonString = const JsonEncoder.withIndent('  ').convert(data);
        // Truncate if too long
        if (jsonString.length > 1000) {
          return '${jsonString.substring(0, 1000)}... [truncated]';
        }
        return jsonString;
      }
      return data.toString();
    } catch (e) {
      return data.toString();
    }
  }

  /// Get emoji based on status code
  String _getStatusEmoji(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return '✅';
    if (statusCode >= 300 && statusCode < 400) return '↪️';
    if (statusCode >= 400 && statusCode < 500) return '⚠️';
    if (statusCode >= 500) return '💥';
    return '❓';
  }
}

// ==================== RETRY INTERCEPTOR ====================

/// Interceptor for retrying failed requests
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;
  final List<int> retryStatusCodes;
  final List<DioExceptionType> retryExceptionTypes;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.retryStatusCodes = const [408, 429, 500, 502, 503, 504],
    this.retryExceptionTypes = const [
      DioExceptionType.connectionError,
    ],
  });

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final retryCount = options.extra['retryCount'] ?? 0;

    // Check if should retry
    if (_shouldRetry(err) && retryCount < maxRetries) {
      options.extra['retryCount'] = retryCount + 1;

      // Calculate delay with exponential backoff
      final delay = retryDelay * (retryCount + 1);

      debugPrint(
        '🔄 Retrying request (${retryCount + 1}/$maxRetries) '
        'after ${delay.inMilliseconds}ms: ${options.path}',
      );

      await Future.delayed(delay);

      try {
        final response = await dio.fetch(options);
        return handler.resolve(response);
      } catch (e) {
        // Let it fall through to next retry or final error
        if (e is DioException) {
          return handler.next(e);
        }
        return handler.next(
          DioException(
            requestOptions: options,
            error: e,
            type: DioExceptionType.unknown,
          ),
        );
      }
    }

    handler.next(err);
  }

  /// Check if request should be retried
  bool _shouldRetry(DioException err) {
    // Don't retry if it's a cancel
    if (err.type == DioExceptionType.cancel) {
      return false;
    }

    // Don't retry POST/PUT/PATCH by default (not idempotent)
    // Unless specifically marked as retryable
    final method = err.requestOptions.method.toUpperCase();
    final isRetryable = err.requestOptions.extra['retryable'] ?? false;

    if (['POST', 'PUT', 'PATCH'].contains(method) && !isRetryable) {
      return false;
    }

    // Check exception type
    if (retryExceptionTypes.contains(err.type)) {
      return true;
    }

    // Check status code
    final statusCode = err.response?.statusCode;
    if (statusCode != null && retryStatusCodes.contains(statusCode)) {
      return true;
    }

    return false;
  }
}

// ==================== CACHE INTERCEPTOR ====================

/// Simple in-memory cache interceptor
class CacheInterceptor extends Interceptor {
  final Map<String, CacheEntry> _cache = {};
  final Duration defaultTtl;
  final int maxCacheSize;

  CacheInterceptor({
    this.defaultTtl = const Duration(minutes: 5),
    this.maxCacheSize = 100,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // Only cache GET requests
    if (options.method.toUpperCase() != 'GET') {
      return handler.next(options);
    }

    // Check if caching is disabled for this request
    if (options.extra['noCache'] == true) {
      return handler.next(options);
    }

    final cacheKey = _generateCacheKey(options);
    final cachedEntry = _cache[cacheKey];

    if (cachedEntry != null && !cachedEntry.isExpired) {
      debugPrint('📦 Cache hit: ${options.path}');
      return handler.resolve(
        Response(
          requestOptions: options,
          data: cachedEntry.data,
          statusCode: 200,
          headers: Headers.fromMap({
            'x-cache': ['HIT']
          }),
        ),
      );
    }

    // Store start time for cache
    options.extra['cacheKey'] = cacheKey;
    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    // Only cache successful GET responses
    if (response.requestOptions.method.toUpperCase() == 'GET' &&
        response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      final cacheKey = response.requestOptions.extra['cacheKey'] as String?;
      if (cacheKey != null) {
        _addToCache(cacheKey, response.data);
      }
    }

    handler.next(response);
  }

  /// Generate cache key from request options
  String _generateCacheKey(RequestOptions options) {
    final buffer = StringBuffer();
    buffer.write(options.path);

    if (options.queryParameters.isNotEmpty) {
      final sortedParams = Map.fromEntries(
        options.queryParameters.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
      );
      buffer.write('?${Uri(queryParameters: sortedParams.map(
        (key, value) => MapEntry(key, value.toString()),
      )).query}');
    }

    return buffer.toString();
  }

  /// Add entry to cache
  void _addToCache(String key, dynamic data) {
    // Remove oldest entries if cache is full
    if (_cache.length >= maxCacheSize) {
      final oldestKey = _cache.entries
          .reduce(
              (a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b)
          .key;
      _cache.remove(oldestKey);
    }

    _cache[key] = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      ttl: defaultTtl,
    );
  }

  /// Clear all cache
  void clearCache() {
    _cache.clear();
  }

  /// Clear cache for specific path
  void clearCacheForPath(String path) {
    _cache.removeWhere((key, _) => key.startsWith(path));
  }

  /// Get cache stats
  Map<String, dynamic> get cacheStats => {
        'size': _cache.length,
        'maxSize': maxCacheSize,
        'keys': _cache.keys.toList(),
      };
}

/// Cache entry model
class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().isAfter(timestamp.add(ttl));
}

// ==================== ERROR TRANSFORMATION INTERCEPTOR ====================

/// Interceptor for transforming errors to app exceptions
class ErrorTransformInterceptor extends Interceptor {
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    // Transform DioException to AppException for easier handling
    AppException appException;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        appException = NetworkException.timeout();
        break;

      case DioExceptionType.connectionError:
        appException = NetworkException.noInternet();
        break;

      case DioExceptionType.badResponse:
        appException = _transformBadResponse(err.response);
        break;

      case DioExceptionType.cancel:
        appException = ServerException(message: 'Request cancelled');
        break;

      default:
        appException = ServerException(
          message: err.message ?? 'Unknown error occurred',
          originalError: err,
        );
    }

    // Store transformed exception in error
    err.requestOptions.extra['appException'] = appException;
    handler.next(err);
  }

  /// Transform bad response to appropriate exception
  AppException _transformBadResponse(Response? response) {
    if (response == null) {
      return ServerException(message: 'No response from server');
    }

    final statusCode = response.statusCode ?? 500;
    final data = response.data;

    String message = 'Server error occurred';
    Map<String, List<String>>? validationErrors;

    if (data is Map<String, dynamic>) {
      message = data['message'] as String? ?? message;

      if (data['errors'] != null) {
        final errors = data['errors'];
        if (errors is Map<String, dynamic>) {
          validationErrors = errors.map((key, value) {
            if (value is List) {
              return MapEntry(key, value.map((e) => e.toString()).toList());
            }
            return MapEntry(key, [value.toString()]);
          });
        }
      }
    }

    switch (statusCode) {
      case 400:
        return validationErrors != null
            ? ValidationException.fields(validationErrors)
            : ValidationException(message: message);

      case 401:
        return AuthException(message: message, statusCode: 401);

      case 403:
        return AuthException.forbidden();

      case 404:
        return ServerException(message: message, statusCode: 404);

      case 422:
        return validationErrors != null
            ? ValidationException.fields(validationErrors)
            : ValidationException(message: message);

      default:
        return ServerException(message: message, statusCode: statusCode);
    }
  }
}

// ==================== TIMING INTERCEPTOR ====================

/// Interceptor for tracking request timing
class TimingInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.extra['startTime'] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    _logTiming(response.requestOptions);
    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    _logTiming(err.requestOptions);
    handler.next(err);
  }

  void _logTiming(RequestOptions options) {
    final startTime = options.extra['startTime'] as DateTime?;
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      debugPrint(
          '⏱️ ${options.method} ${options.path}: ${duration.inMilliseconds}ms');
    }
  }
}

