import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import 'exceptions.dart';
import 'failures.dart';

/// Central Error Handler for the application
class ErrorHandler {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  ErrorHandler._();

  // ==================== EXCEPTION TO FAILURE CONVERSION ====================

  /// Convert any exception to appropriate Failure
  static Failure handleException(dynamic exception, [StackTrace? stackTrace]) {
    _logError(exception, stackTrace);

    // Dio exceptions (Network/API)
    if (exception is DioException) {
      return _handleDioException(exception);
    }

    // App exceptions
    if (exception is AppException) {
      return _handleAppException(exception);
    }

    // Database exceptions (sqflite)
    if (exception is sqflite.DatabaseException) {
      return DatabaseFailure(
        message: exception.toString(),
        originalError: exception,
        stackTrace: stackTrace,
      );
    }

    // SQLite exceptions (sqflite)
    if (exception is sqflite.DatabaseException) {
      return _handleSqliteException(exception, stackTrace);
    }

    // Socket exceptions
    if (exception is SocketException) {
      return NetworkFailure(
        message: 'Network error: ${exception.message}',
        originalError: exception,
        stackTrace: stackTrace,
      );
    }

    // Timeout exceptions
    if (exception is TimeoutException) {
      return NetworkFailure.timeout();
    }

    // Format exceptions
    if (exception is FormatException) {
      return ValidationFailure(
        message: 'Invalid data format: ${exception.message}',
        originalError: exception,
        stackTrace: stackTrace,
      );
    }

    // Type errors
    if (exception is TypeError) {
      return UnknownFailure(
        message: 'Type error occurred.',
        originalError: exception,
        stackTrace: stackTrace,
      );
    }

    // Unknown exceptions
    return UnknownFailure.withError(exception, stackTrace);
  }

  /// Handle Dio exceptions
  static Failure _handleDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
        return const NetworkFailure(
          message: 'Connection timeout. Please try again.',
          code: 408,
        );

      case DioExceptionType.sendTimeout:
        return const NetworkFailure(
          message: 'Request timeout. Please try again.',
          code: 408,
        );

      case DioExceptionType.receiveTimeout:
        return const NetworkFailure(
          message: 'Response timeout. Please try again.',
          code: 408,
        );

      case DioExceptionType.connectionError:
        return const NetworkFailure(
          message: 'Connection failed. Please check your internet.',
        );

      case DioExceptionType.badCertificate:
        return const ServerFailure(
          message: 'Security certificate error.',
          code: 495,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(exception.response);

      case DioExceptionType.cancel:
        return const ServerFailure(
          message: 'Request was cancelled.',
          code: 499,
        );

      case DioExceptionType.unknown:
        if (exception.error is SocketException) {
          return const NetworkFailure(
            message: 'No internet connection.',
          );
        }
        return UnknownFailure(
          message: exception.message ?? 'Unknown network error.',
          originalError: exception,
        );
    }
  }

  /// Handle bad HTTP responses
  static Failure _handleBadResponse(Response? response) {
    if (response == null) {
      return const ServerFailure(message: 'No response from server.');
    }

    final statusCode = response.statusCode ?? 500;
    final data = response.data;

    String message = 'Server error occurred.';
    Map<String, List<String>>? fieldErrors;

    // Extract error message from response
    if (data is Map<String, dynamic>) {
      message = data['message'] as String? ?? message;

      // Extract validation errors
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

    // Return appropriate failure based on status code
    switch (statusCode) {
      case 400:
        if (fieldErrors != null) {
          return ValidationFailure.multiple(fieldErrors);
        }
        return ValidationFailure(message: message);

      case 401:
        return AuthFailure(message: message, code: 401);

      case 403:
        return AuthFailure.unauthorized();

      case 404:
        return ServerFailure(message: message, code: 404);

      case 422:
        if (fieldErrors != null) {
          return ValidationFailure.multiple(fieldErrors);
        }
        return ValidationFailure(message: message);

      case 429:
        return const ServerFailure(
          message: 'Too many requests. Please wait a moment.',
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

  /// Handle App exceptions
  static Failure _handleAppException(AppException exception) {
    if (exception is ServerException) {
      return ServerFailure(
        message: exception.message,
        code: exception.statusCode,
        originalError: exception,
      );
    }

    if (exception is NetworkException) {
      return NetworkFailure(
        message: exception.message,
        originalError: exception,
      );
    }

    if (exception is CacheException) {
      return CacheFailure(
        message: exception.message,
        originalError: exception,
      );
    }

    if (exception is DatabaseException) {
      return DatabaseFailure(
        message: exception.message,
        originalError: exception,
      );
    }

    if (exception is AuthException) {
      return AuthFailure(
        message: exception.message,
        code: exception.statusCode,
        originalError: exception,
      );
    }

    if (exception is ValidationException) {
      return ValidationFailure(
        message: exception.message,
        fieldErrors: exception.errors,
        originalError: exception,
      );
    }

    if (exception is SyncException) {
      return SyncFailure(
        message: exception.message,
        originalError: exception,
      );
    }

    if (exception is InsufficientStockException) {
      return InsufficientStockFailure(
        available: exception.available,
        requested: exception.requested,
        itemName: exception.itemName,
        originalError: exception,
      );
    }

    if (exception is FileException) {
      return FileFailure(
        message: exception.message,
        originalError: exception,
      );
    }

    if (exception is PermissionException) {
      return PermissionFailure(
        message: exception.message,
        originalError: exception,
      );
    }

    return UnknownFailure(
      message: exception.message,
      originalError: exception,
    );
  }

  /// Handle SQLite exceptions
  static Failure _handleSqliteException(
    dynamic exception,
    StackTrace? stackTrace,
  ) {
    final message = exception.toString().toLowerCase();

    if (message.contains('unique constraint')) {
      return DatabaseFailure.duplicateEntry();
    }

    if (message.contains('foreign key')) {
      return DatabaseFailure.constraintViolation(
          'Foreign key constraint failed.');
    }

    if (message.contains('not null')) {
      return DatabaseFailure.constraintViolation('Required field is missing.');
    }

    return DatabaseFailure(
      message: 'Database error occurred.',
      originalError: exception,
      stackTrace: stackTrace,
    );
  }

  // ==================== LOGGING ====================

  /// Log error with appropriate level
  static void _logError(dynamic error, StackTrace? stackTrace) {
    if (error is DioException && error.type == DioExceptionType.cancel) {
      // Don't log cancelled requests
      return;
    }

    _logger.e(
      'Error occurred',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log info
  static void logInfo(String message) {
    _logger.i(message);
  }

  /// Log warning
  static void logWarning(String message) {
    _logger.w(message);
  }

  /// Log debug
  static void logDebug(String message) {
    _logger.d(message);
  }

  // ==================== UI ERROR DISPLAY ====================

  /// Show error snackbar
  static void showErrorSnackBar(BuildContext context, Failure failure) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.white),
            const SizedBox(width: AppDimensions.paddingS),
            Expanded(
              child: Text(
                getSinhalaMessage(failure),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        action: SnackBarAction(
          label: 'ඉවත් කරන්න', // Dismiss
          textColor: AppColors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }


  /// Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.white),
            const SizedBox(width: AppDimensions.paddingS),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show warning snackbar
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: AppColors.black),
            const SizedBox(width: AppDimensions.paddingS),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.black,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show error dialog
  static Future<void> showErrorDialog(
    BuildContext context,
    Failure failure, {
    String? title,
    VoidCallback? onRetry,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: AppDimensions.paddingS),
            Expanded(
              child: Text(
                title ?? 'Error',
                style: AppTextStyles.h5.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
        content: Text(
          failure.message,
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show network error dialog with retry option
  static Future<bool> showNetworkErrorDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        title: Row(
          children: [
            const Icon(Icons.wifi_off, color: AppColors.error),
            const SizedBox(width: AppDimensions.paddingS),
            Text(
              'No Connection',
              style: AppTextStyles.h5.copyWith(color: AppColors.error),
            ),
          ],
        ),
        content: const Text(
          'Please check your internet connection and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ==================== FAILURE TYPE CHECKS ====================

  /// Check if failure is due to network issues
  static bool isNetworkFailure(Failure failure) {
    return failure is NetworkFailure;
  }

  /// Check if failure is due to authentication
  static bool isAuthFailure(Failure failure) {
    return failure is AuthFailure;
  }

  /// Check if failure is due to validation
  static bool isValidationFailure(Failure failure) {
    return failure is ValidationFailure;
  }

  /// Check if failure requires re-login
  static bool requiresReLogin(Failure failure) {
    if (failure is AuthFailure) {
      return failure.code == 401;
    }
    return false;
  }

  /// Check if failure is retryable
  static bool isRetryable(Failure failure) {
    if (failure is NetworkFailure) return true;
    if (failure is ServerFailure) {
      final code = failure.code;
      return code == 408 ||
          code == 429 ||
          code == 500 ||
          code == 502 ||
          code == 503 ||
          code == 504;
    }
    if (failure is SyncFailure) return true;
    return false;
  }

  // ==================== USER-FRIENDLY MESSAGES ====================

  /// Get user-friendly message for failure
  static String getUserMessage(Failure failure) {
    // Already user-friendly in most cases
    return failure.message;
  }

  /// Get Sinhala message for failure (for localization)
  static String getSinhalaMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'අන්තර්ජාල සම්බන්ධතාවය නැත. කරුණාකර ඔබගේ අන්තර්ජාලය පරීක්ෂා කරන්න.';
    }

    if (failure is AuthFailure) {
      if (failure.code == 401) {
        return 'පිවිසුම අවලංගුයි. කරුණාකර නැවත පුරනය වන්න.';
      }
      return 'ප්‍රවේශය ප්‍රතික්ෂේප විය.';
    }

    if (failure is ValidationFailure) {
      return 'කරුණාකර ඔබගේ ආදානය පරීක්ෂා කරන්න.';
    }

    if (failure is InsufficientStockFailure) {
      return 'ප්‍රමාණවත් තොගයක් නැත.';
    }

    if (failure is DatabaseFailure) {
      return 'දත්ත සමුදා දෝෂයකි.';
    }

    return 'දෝෂයක් සිදු විය. කරුණාකර නැවත උත්සාහ කරන්න.';
  }
}

// ==================== EXTENSION FOR EASY ERROR HANDLING ====================

/// Extension on Either for easy error handling in Cubits
extension EitherErrorHandler<L extends Failure, R> on Future<dynamic> {
  /// Handle errors and convert to Failure
  Future<dynamic> handleErrors() async {
    try {
      return await this;
    } catch (e, stackTrace) {
      return ErrorHandler.handleException(e, stackTrace);
    }
  }
}

/// Extension on BuildContext for showing errors
extension ErrorContextExtension on BuildContext {
  void showError(Failure failure) {
    ErrorHandler.showErrorSnackBar(this, failure);
  }

  void showSuccess(String message) {
    ErrorHandler.showSuccessSnackBar(this, message);
  }

  void showWarning(String message) {
    ErrorHandler.showWarningSnackBar(this, message);
  }

  Future<void> showErrorDialog(Failure failure, {VoidCallback? onRetry}) {
    return ErrorHandler.showErrorDialog(this, failure, onRetry: onRetry);
  }

  Future<bool> showNetworkError() {
    return ErrorHandler.showNetworkErrorDialog(this);
  }
}
