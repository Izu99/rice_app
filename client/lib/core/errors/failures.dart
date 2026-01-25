import 'package:equatable/equatable.dart';

/// Base Failure class - used with Either pattern (dartz)
/// Left side of Either represents failure
abstract class Failure extends Equatable {
  final String message;
  final int? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const Failure({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'Failure: $message (code: $code)';
}

// ==================== SERVER FAILURES ====================

/// Server/API related failures
class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Server error occurred. Please try again later.',
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory ServerFailure.fromStatusCode(int statusCode, [String? message]) {
    switch (statusCode) {
      case 400:
        return ServerFailure(
          message: message ?? 'Bad request. Please check your input.',
          code: statusCode,
        );
      case 401:
        return ServerFailure(
          message: message ?? 'Unauthorized. Please login again.',
          code: statusCode,
        );
      case 403:
        return ServerFailure(
          message: message ?? 'Access denied. You don\'t have permission.',
          code: statusCode,
        );
      case 404:
        return ServerFailure(
          message: message ?? 'Resource not found.',
          code: statusCode,
        );
      case 408:
        return ServerFailure(
          message: message ?? 'Request timeout. Please try again.',
          code: statusCode,
        );
      case 422:
        return ServerFailure(
          message: message ?? 'Validation failed. Please check your input.',
          code: statusCode,
        );
      case 429:
        return ServerFailure(
          message: message ?? 'Too many requests. Please wait a moment.',
          code: statusCode,
        );
      case 500:
        return ServerFailure(
          message: message ?? 'Internal server error. Please try again later.',
          code: statusCode,
        );
      case 502:
        return ServerFailure(
          message: message ?? 'Bad gateway. Server is temporarily unavailable.',
          code: statusCode,
        );
      case 503:
        return ServerFailure(
          message: message ?? 'Service unavailable. Please try again later.',
          code: statusCode,
        );
      case 504:
        return ServerFailure(
          message:
              message ?? 'Gateway timeout. Server took too long to respond.',
          code: statusCode,
        );
      default:
        return ServerFailure(
          message: message ?? 'Server error occurred.',
          code: statusCode,
        );
    }
  }
}

// ==================== NETWORK FAILURES ====================

/// Network connectivity failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory NetworkFailure.timeout() {
    return const NetworkFailure(
      message: 'Connection timeout. Please check your internet and try again.',
      code: 408,
    );
  }

  factory NetworkFailure.noInternet() {
    return const NetworkFailure(
      message: 'No internet connection. Please connect to the internet.',
    );
  }

  factory NetworkFailure.poorConnection() {
    return const NetworkFailure(
      message: 'Poor internet connection. Please try again.',
    );
  }
}

// ==================== CACHE/DATABASE FAILURES ====================

/// Local cache failures
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Cache error occurred.',
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory CacheFailure.notFound() {
    return const CacheFailure(
      message: 'Data not found in cache.',
      code: 404,
    );
  }

  factory CacheFailure.expired() {
    return const CacheFailure(
      message: 'Cached data has expired.',
      code: 410,
    );
  }

  factory CacheFailure.writeError() {
    return const CacheFailure(
      message: 'Failed to save data to cache.',
    );
  }
}

/// Database failures
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    super.message = 'Database error occurred.',
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory DatabaseFailure.notFound() {
    return const DatabaseFailure(
      message: 'Record not found in database.',
      code: 404,
    );
  }

  factory DatabaseFailure.duplicateEntry() {
    return const DatabaseFailure(
      message: 'Duplicate entry. This record already exists.',
      code: 409,
    );
  }

  factory DatabaseFailure.constraintViolation([String? details]) {
    return DatabaseFailure(
      message: details ?? 'Database constraint violation.',
      code: 409,
    );
  }

  factory DatabaseFailure.insertError() {
    return const DatabaseFailure(
      message: 'Failed to insert record.',
    );
  }

  factory DatabaseFailure.updateError() {
    return const DatabaseFailure(
      message: 'Failed to update record.',
    );
  }

  factory DatabaseFailure.deleteError() {
    return const DatabaseFailure(
      message: 'Failed to delete record.',
    );
  }

  factory DatabaseFailure.queryError([String? details]) {
    return DatabaseFailure(
      message: details ?? 'Failed to query database.',
    );
  }

  factory DatabaseFailure.migrationError() {
    return const DatabaseFailure(
      message: 'Database migration failed.',
    );
  }
}

// ==================== AUTH FAILURES ====================

/// Authentication/Authorization failures
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authentication failed.',
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory AuthFailure.invalidCredentials() {
    return const AuthFailure(
      message: 'Invalid username or password.',
      code: 401,
    );
  }

  factory AuthFailure.tokenExpired() {
    return const AuthFailure(
      message: 'Session expired. Please login again.',
      code: 401,
    );
  }

  factory AuthFailure.tokenInvalid() {
    return const AuthFailure(
      message: 'Invalid session. Please login again.',
      code: 401,
    );
  }

  factory AuthFailure.unauthorized() {
    return const AuthFailure(
      message: 'You are not authorized to perform this action.',
      code: 403,
    );
  }

  factory AuthFailure.accountDisabled() {
    return const AuthFailure(
      message: 'Your account has been disabled. Contact support.',
      code: 403,
    );
  }

  factory AuthFailure.accountLocked() {
    return const AuthFailure(
      message: 'Account locked due to too many failed attempts.',
      code: 423,
    );
  }

  factory AuthFailure.sessionNotFound() {
    return const AuthFailure(
      message: 'No active session found. Please login.',
      code: 401,
    );
  }
}

// ==================== VALIDATION FAILURES ====================

/// Validation failures
class ValidationFailure extends Failure {
  final Map<String, List<String>>? fieldErrors;

  const ValidationFailure({
    super.message = 'Validation error occurred.',
    super.code,
    this.fieldErrors,
    super.originalError,
    super.stackTrace,
  });

  factory ValidationFailure.field(String field, String error) {
    return ValidationFailure(
      message: error,
      fieldErrors: {
        field: [error]
      },
    );
  }

  factory ValidationFailure.multiple(Map<String, List<String>> errors) {
    final firstError = errors.values.expand((e) => e).firstOrNull;
    return ValidationFailure(
      message: firstError ?? 'Validation failed.',
      fieldErrors: errors,
    );
  }

  factory ValidationFailure.required(String field) {
    return ValidationFailure(
      message: '$field is required.',
      fieldErrors: {
        field: ['$field is required.']
      },
    );
  }

  factory ValidationFailure.invalid(String field, [String? details]) {
    return ValidationFailure(
      message: details ?? '$field is invalid.',
      fieldErrors: {
        field: [details ?? '$field is invalid.']
      },
    );
  }

  /// Get error for specific field
  String? getFieldError(String field) {
    return fieldErrors?[field]?.firstOrNull;
  }

  /// Check if field has error
  bool hasFieldError(String field) {
    return fieldErrors?.containsKey(field) ?? false;
  }

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

// ==================== SYNC FAILURES ====================

/// Sync related failures
class SyncFailure extends Failure {
  const SyncFailure({
    super.message = 'Sync failed.',
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory SyncFailure.conflict() {
    return const SyncFailure(
      message: 'Data conflict detected. Please refresh and try again.',
      code: 409,
    );
  }

  factory SyncFailure.serverUnavailable() {
    return const SyncFailure(
      message: 'Server unavailable. Changes saved locally.',
      code: 503,
    );
  }

  factory SyncFailure.pushFailed([String? details]) {
    return SyncFailure(
      message: details ?? 'Failed to push local changes to server.',
    );
  }

  factory SyncFailure.pullFailed([String? details]) {
    return SyncFailure(
      message: details ?? 'Failed to pull data from server.',
    );
  }

  factory SyncFailure.partialSync(int succeeded, int failed) {
    return SyncFailure(
      message: 'Partial sync: $succeeded succeeded, $failed failed.',
    );
  }
}

// ==================== BUSINESS LOGIC FAILURES ====================

/// Insufficient stock failure
class InsufficientStockFailure extends Failure {
  final double available;
  final double requested;
  final String? itemName;

  const InsufficientStockFailure({
    required this.available,
    required this.requested,
    this.itemName,
    super.originalError,
    super.stackTrace,
  }) : super(
          message: 'Insufficient stock',
          code: 400,
        );

  @override
  String get message {
    final item = itemName ?? 'Item';
    return '$item: Only ${available.toStringAsFixed(2)} kg available, but ${requested.toStringAsFixed(2)} kg requested.';
  }

  @override
  List<Object?> get props => [available, requested, itemName, code];
}

/// Customer not found failure
class CustomerNotFoundFailure extends Failure {
  const CustomerNotFoundFailure({
    super.message = 'Customer not found.',
    super.code = 404,
    super.originalError,
    super.stackTrace,
  });

  factory CustomerNotFoundFailure.byPhone(String phone) {
    return CustomerNotFoundFailure(
      message: 'No customer found with phone: $phone',
    );
  }

  factory CustomerNotFoundFailure.byId(int id) {
    return CustomerNotFoundFailure(
      message: 'Customer with ID $id not found.',
    );
  }
}

/// Transaction failure
class TransactionFailure extends Failure {
  const TransactionFailure({
    super.message = 'Transaction failed.',
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory TransactionFailure.notFound(String transactionId) {
    return TransactionFailure(
      message: 'Transaction $transactionId not found.',
      code: 404,
    );
  }

  factory TransactionFailure.alreadyCompleted() {
    return const TransactionFailure(
      message: 'Transaction is already completed.',
      code: 400,
    );
  }

  factory TransactionFailure.cancelled() {
    return const TransactionFailure(
      message: 'Transaction has been cancelled.',
      code: 400,
    );
  }

  factory TransactionFailure.invalidAmount() {
    return const TransactionFailure(
      message: 'Invalid transaction amount.',
      code: 400,
    );
  }
}

/// Payment failure
class PaymentFailure extends Failure {
  const PaymentFailure({
    super.message = 'Payment failed.',
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory PaymentFailure.insufficientBalance() {
    return const PaymentFailure(
      message: 'Insufficient balance for this payment.',
      code: 400,
    );
  }

  factory PaymentFailure.exceededAmount() {
    return const PaymentFailure(
      message: 'Payment amount exceeds the due amount.',
      code: 400,
    );
  }

  factory PaymentFailure.invalidAmount() {
    return const PaymentFailure(
      message: 'Invalid payment amount.',
      code: 400,
    );
  }
}

// ==================== PERMISSION FAILURES ====================

/// Permission/Feature failures
class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'Permission denied.',
    super.code = 403,
    super.originalError,
    super.stackTrace,
  });

  factory PermissionFailure.camera() {
    return const PermissionFailure(
      message: 'Camera permission denied. Please enable it in settings.',
    );
  }

  factory PermissionFailure.storage() {
    return const PermissionFailure(
      message: 'Storage permission denied. Please enable it in settings.',
    );
  }

  factory PermissionFailure.location() {
    return const PermissionFailure(
      message: 'Location permission denied.',
    );
  }

  factory PermissionFailure.notification() {
    return const PermissionFailure(
      message: 'Notification permission denied.',
    );
  }

  factory PermissionFailure.roleRestriction(String role) {
    return PermissionFailure(
      message: 'This action requires $role privileges.',
    );
  }
}

// ==================== FILE/EXPORT FAILURES ====================

/// File/PDF/Export failures
class FileFailure extends Failure {
  const FileFailure({
    super.message = 'File operation failed.',
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory FileFailure.notFound() {
    return const FileFailure(
      message: 'File not found.',
      code: 404,
    );
  }

  factory FileFailure.readError() {
    return const FileFailure(
      message: 'Failed to read file.',
    );
  }

  factory FileFailure.writeError() {
    return const FileFailure(
      message: 'Failed to write file.',
    );
  }

  factory FileFailure.pdfGeneration() {
    return const FileFailure(
      message: 'Failed to generate PDF.',
    );
  }

  factory FileFailure.exportError([String? format]) {
    return FileFailure(
      message: 'Failed to export${format != null ? ' to $format' : ''}.',
    );
  }

  factory FileFailure.tooLarge(int maxSizeMB) {
    return FileFailure(
      message: 'File size exceeds maximum limit of ${maxSizeMB}MB.',
    );
  }
}

// ==================== NOT FOUND FAILURE ====================

/// Generic not found failure
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'Resource not found.',
    super.code = 404,
    super.originalError,
    super.stackTrace,
  });
}

// ==================== UNKNOWN FAILURE ====================

/// Unknown/Unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred. Please try again.',
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory UnknownFailure.withError(dynamic error, [StackTrace? stackTrace]) {
    return UnknownFailure(
      message: 'An unexpected error occurred: ${error.toString()}',
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}

