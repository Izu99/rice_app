import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../errors/failures.dart';
import 'api_interceptor.dart';
import 'api_response.dart';
import 'network_info.dart';

/// Main API Service class for handling HTTP requests
class ApiService {
  late final Dio _dio;
  final NetworkInfo _networkInfo;
  final SharedPreferences _prefs;

  // Interceptors
  late final AuthInterceptor _authInterceptor;
  late final RetryInterceptor _retryInterceptor;
  late final CacheInterceptor _cacheInterceptor;

  /// Token expired callback
  void Function()? onTokenExpired;

  ApiService({
    required NetworkInfo networkInfo,
    required SharedPreferences prefs,
    this.onTokenExpired,
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  })  : _networkInfo = networkInfo,
        _prefs = prefs {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiEndpoints.baseUrl,
        connectTimeout: connectTimeout ?? AppConstants.connectionTimeout,
        receiveTimeout: receiveTimeout ?? AppConstants.receiveTimeout,
        sendTimeout: sendTimeout ?? const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _setupInterceptors();
  }

  /// Setup all interceptors
  void _setupInterceptors() {
    // Auth interceptor
    _authInterceptor = AuthInterceptor(
      _prefs,
      onTokenExpired: () => onTokenExpired?.call(),
      apiService: this, // Pass the ApiService instance
    );

    // Retry interceptor
    _retryInterceptor = RetryInterceptor(dio: _dio);

    // Cache interceptor
    _cacheInterceptor = CacheInterceptor();

    // Add interceptors in order
    _dio.interceptors.addAll([
      TimingInterceptor(),
      _authInterceptor,
      _cacheInterceptor,
      if (kDebugMode) LoggingInterceptor(),
      ErrorTransformInterceptor(),
      _retryInterceptor,
    ]);
  }

  /// Get Dio instance for advanced usage
  Dio get dio => _dio;

  /// Get cache interceptor for cache management
  CacheInterceptor get cache => _cacheInterceptor;

  // ==================== CONNECTIVITY ====================

  /// Check if connected to network
  Future<bool> get isConnected => _networkInfo.isConnected;

  /// Ensure connectivity before making request
  Future<void> _ensureConnectivity() async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException.noInternet();
    }
  }

  // ==================== HTTP METHODS ====================

  /// GET request
  Future<Either<Failure, ApiResponse<T>>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
    bool useCache = true,
  }) async {
    try {
      await _ensureConnectivity();

      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: _buildOptions(options, requiresAuth, noCache: !useCache),
        cancelToken: cancelToken,
      );
      if (kDebugMode && response.requestOptions.extra['fromCache'] != true) {
        debugPrint(
            'APIService: Fresh GET Response for $path: ${response.data}');
      }
      return Right(_parseResponse<T>(response, fromJson));
    } catch (e, stackTrace) {
      return Left(_handleError(e, stackTrace));
    }
  }

  /// POST request
  Future<Either<Failure, ApiResponse<T>>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
    bool isRetryable = false,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      await _ensureConnectivity();

      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(options, requiresAuth, retryable: isRetryable),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return Right(_parseResponse<T>(response, fromJson));
    } catch (e, stackTrace) {
      return Left(_handleError(e, stackTrace));
    }
  }

  /// PUT request
  Future<Either<Failure, ApiResponse<T>>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
    bool isRetryable = false,
  }) async {
    try {
      await _ensureConnectivity();

      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(options, requiresAuth, retryable: isRetryable),
        cancelToken: cancelToken,
      );

      return Right(_parseResponse<T>(response, fromJson));
    } catch (e, stackTrace) {
      return Left(_handleError(e, stackTrace));
    }
  }

  /// PATCH request
  Future<Either<Failure, ApiResponse<T>>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
  }) async {
    try {
      await _ensureConnectivity();

      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(options, requiresAuth),
        cancelToken: cancelToken,
      );

      return Right(_parseResponse<T>(response, fromJson));
    } catch (e, stackTrace) {
      return Left(_handleError(e, stackTrace));
    }
  }

  /// DELETE request
  Future<Either<Failure, ApiResponse<T>>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
  }) async {
    try {
      await _ensureConnectivity();

      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(options, requiresAuth),
        cancelToken: cancelToken,
      );

      return Right(_parseResponse<T>(response, fromJson));
    } catch (e, stackTrace) {
      return Left(_handleError(e, stackTrace));
    }
  }

  // ==================== FILE OPERATIONS ====================

  /// Upload file
  Future<Either<Failure, ApiResponse<T>>> uploadFile<T>(
    String path, {
    required String filePath,
    required String fieldName,
    String? fileName,
    Map<String, dynamic>? data,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
    bool requiresAuth = true,
    void Function(int, int)? onProgress,
  }) async {
    try {
      await _ensureConnectivity();

      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
        if (data != null) ...data,
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: _buildOptions(
          Options(contentType: 'multipart/form-data'),
          requiresAuth,
        ),
        cancelToken: cancelToken,
        onSendProgress: onProgress,
      );

      return Right(_parseResponse<T>(response, fromJson));
    } catch (e, stackTrace) {
      return Left(_handleError(e, stackTrace));
    }
  }

  /// Upload multiple files
  Future<Either<Failure, ApiResponse<T>>> uploadFiles<T>(
    String path, {
    required List<String> filePaths,
    required String fieldName,
    Map<String, dynamic>? data,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
    bool requiresAuth = true,
    void Function(int, int)? onProgress,
  }) async {
    try {
      await _ensureConnectivity();

      final files = await Future.wait(
        filePaths.map((path) => MultipartFile.fromFile(path)),
      );

      final formData = FormData.fromMap({
        fieldName: files,
        if (data != null) ...data,
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: _buildOptions(
          Options(contentType: 'multipart/form-data'),
          requiresAuth,
        ),
        cancelToken: cancelToken,
        onSendProgress: onProgress,
      );

      return Right(_parseResponse<T>(response, fromJson));
    } catch (e, stackTrace) {
      return Left(_handleError(e, stackTrace));
    }
  }

  /// Download file
  Future<Either<Failure, String>> downloadFile(
    String url,
    String savePath, {
    CancelToken? cancelToken,
    bool requiresAuth = true,
    void Function(int, int)? onProgress,
  }) async {
    try {
      await _ensureConnectivity();

      await _dio.download(
        url,
        savePath,
        options: _buildOptions(null, requiresAuth),
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
      );

      return Right(savePath);
    } catch (e, stackTrace) {
      return Left(_handleError(e, stackTrace));
    }
  }

  // ==================== PAGINATED REQUESTS ====================

  /// GET paginated list
  Future<Either<Failure, PaginatedResponse<T>>> getPaginated<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    int page = 1,
    int perPage = 20,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
  }) async {
    try {
      await _ensureConnectivity();

      final params = {
        'page': page,
        'per_page': perPage,
        ...?queryParameters,
      };

      final response = await _dio.get(
        path,
        queryParameters: params,
        options: _buildOptions(options, requiresAuth),
        cancelToken: cancelToken,
      );

      final paginatedResponse = PaginatedResponse<T>.fromJson(
        response.data as Map<String, dynamic>,
        fromJson,
      );

      return Right(paginatedResponse);
    } catch (e, stackTrace) {
      return Left(_handleError(e, stackTrace));
    }
  }

  // ==================== BATCH REQUESTS ====================

  /// Execute multiple requests in parallel
  Future<List<Either<Failure, ApiResponse<dynamic>>>> batch(
    List<Future<Either<Failure, ApiResponse<dynamic>>>> requests,
  ) async {
    return await Future.wait(requests);
  }

  /// Execute requests sequentially
  Future<List<Either<Failure, ApiResponse<dynamic>>>> sequential(
    List<Future<Either<Failure, ApiResponse<dynamic>>> Function()>
        requestFactories,
  ) async {
    final results = <Either<Failure, ApiResponse<dynamic>>>[];

    for (final factory in requestFactories) {
      results.add(await factory());
    }

    return results;
  }

  // ==================== HELPER METHODS ====================

  /// Build request options
  Options _buildOptions(
    Options? options,
    bool requiresAuth, {
    bool noCache = false,
    bool retryable = false,
  }) {
    final extra = <String, dynamic>{
      if (noCache) 'noCache': true,
      if (retryable) 'retryable': true,
      if (!requiresAuth) 'skipAuth': true,
    };

    if (options != null) {
      return options.copyWith(
        extra: {...options.extra ?? {}, ...extra},
      );
    }

    return Options(extra: extra);
  }

  /// Parse API response
  ApiResponse<T> _parseResponse<T>(
    Response response,
    T Function(dynamic)? fromJson,
  ) {
    final data = response.data;

    // Handle non-JSON responses
    if (data is! Map<String, dynamic>) {
      return ApiResponse<T>(
        success: response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300,
        data: data as T?,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.fromJson(data, fromJsonT: fromJson);
  }

  /// Handle errors and convert to Failure
  Failure _handleError(dynamic error, StackTrace stackTrace) {
    if (kDebugMode) {
      // Use more concise logging for server errors in offline mode
      if (error.toString().contains('500')) {
        debugPrint('📡 Server returned 500 (Server unavailable)');
      } else {
        debugPrint('API Error: $error');
      }
    }

    if (error is DioException) {
      return _handleDioError(error);
    }

    if (error is NetworkException) {
      return NetworkFailure(
        message: error.message,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is AppException) {
      return _handleAppException(error, stackTrace);
    }

    if (error is SocketException) {
      return NetworkFailure(
        message: 'Network error: ${error.message}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is TimeoutException) {
      return const NetworkFailure(message: 'Request timed out');
    }

    return UnknownFailure(
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Handle Dio-specific errors
  Failure _handleDioError(DioException error) {
    // Check for transformed exception
    final appException = error.requestOptions.extra['appException'];
    if (appException is AppException) {
      return _handleAppException(appException, error.stackTrace);
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure(
          message: 'Connection timed out. Please try again.',
          code: 408,
        );

      case DioExceptionType.connectionError:
        return const NetworkFailure(
          message: 'Unable to connect. Please check your internet.',
        );

      case DioExceptionType.badCertificate:
        return const ServerFailure(
          message: 'Security certificate error.',
          code: 495,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);

      case DioExceptionType.cancel:
        return const ServerFailure(
          message: 'Request was cancelled.',
          code: 499,
        );

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return const NetworkFailure();
        }
        return UnknownFailure(
          message: error.message ?? 'Unknown error occurred',
          originalError: error,
        );
    }
  }

  /// Handle bad HTTP response
  Failure _handleBadResponse(Response? response) {
    if (response == null) {
      return const ServerFailure(message: 'No response from server');
    }

    final statusCode = response.statusCode ?? 500;
    final data = response.data;

    String message = 'Server error occurred';
    Map<String, List<String>>? fieldErrors;

    if (data is Map<String, dynamic>) {
      message = data['message'] as String? ?? message;

      if (data['errors'] != null) {
        final errors = data['errors'];
        if (errors is Map<String, dynamic>) {
          fieldErrors = errors.map((key, value) {
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
        if (fieldErrors != null) {
          return ValidationFailure.multiple(fieldErrors);
        }
        return ValidationFailure(message: message);

      case 401:
        return AuthFailure(message: message, code: 401);

      case 403:
        return const AuthFailure(
          message: 'Access denied',
          code: 403,
        );

      case 404:
        return ServerFailure(message: message, code: 404);

      case 422:
        if (fieldErrors != null) {
          return ValidationFailure.multiple(fieldErrors);
        }
        return ValidationFailure(message: message);

      case 429:
        return const ServerFailure(
          message: 'Too many requests. Please wait.',
          code: 429,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return ServerFailure.fromStatusCode(statusCode, message);

      default:
        return ServerFailure(message: message, code: statusCode);
    }
  }

  /// Handle app exceptions
  Failure _handleAppException(AppException exception, StackTrace? stackTrace) {
    if (exception is ServerException) {
      return ServerFailure(
        message: exception.message,
        code: exception.statusCode,
        originalError: exception,
        stackTrace: stackTrace,
      );
    }

    if (exception is NetworkException) {
      return NetworkFailure(
        message: exception.message,
        originalError: exception,
        stackTrace: stackTrace,
      );
    }

    if (exception is AuthException) {
      return AuthFailure(
        message: exception.message,
        code: exception.statusCode,
        originalError: exception,
        stackTrace: stackTrace,
      );
    }

    if (exception is ValidationException) {
      return ValidationFailure(
        message: exception.message,
        fieldErrors: exception.errors,
        originalError: exception,
        stackTrace: stackTrace,
      );
    }

    return UnknownFailure(
      message: exception.message,
      originalError: exception,
      stackTrace: stackTrace,
    );
  }

  // ==================== TOKEN MANAGEMENT ====================

  /// Set auth token
  Future<void> setToken(String token) async {
    await _prefs.setString(AppConstants.tokenKey, token);
  }

  /// Get current token
  Future<String?> getToken() async {
    return _prefs.getString(AppConstants.tokenKey);
  }

  /// Clear auth token
  Future<void> clearToken() async {
    await _prefs.remove(AppConstants.tokenKey);
  }

  /// Check if authenticated
  Future<bool> get isAuthenticated async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Clear all cache
  void clearCache() {
    _cacheInterceptor.clearCache();
  }

  /// Clear cache for specific path
  void clearCacheForPath(String path) {
    _cacheInterceptor.clearCacheForPath(path);
  }

  // ==================== CANCEL REQUESTS ====================

  /// Create cancel token
  CancelToken createCancelToken() => CancelToken();

  /// Cancel all pending requests
  void cancelAllRequests([String? reason]) {
    _dio.close(force: true);
    _setupInterceptors(); // Reinitialize interceptors
  }
}

