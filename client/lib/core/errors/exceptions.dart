/// Base Exception class for the app
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.statusCode,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => '$runtimeType: $message';
}

// ==================== SERVER EXCEPTIONS ====================

/// Server/API Exception
class ServerException extends AppException {
  ServerException({
    super.message = 'Server error occurred.',
    super.statusCode,
    super.originalError,
    super.stackTrace,
  });

  factory ServerException.fromStatusCode(int statusCode, [String? message]) {
    return ServerException(
      message: message ?? _getMessageForStatusCode(statusCode),
      statusCode: statusCode,
    );
  }

  static String _getMessageForStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request.';
      case 401:
        return 'Unauthorized.';
      case 403:
        return 'Forbidden.';
      case 404:
        return 'Not found.';
      case 422:
        return 'Validation failed.';
      case 500:
        return 'Internal server error.';
      case 502:
        return 'Bad gateway.';
      case 503:
        return 'Service unavailable.';
      default:
        return 'Server error occurred.';
    }
  }
}

/// Timeout Exception
class TimeoutException extends AppException {
  TimeoutException({
    super.message = 'Request timed out.',
    super.statusCode = 408,
    super.originalError,
    super.stackTrace,
  });
}

// ==================== NETWORK EXCEPTIONS ====================

/// Network Exception
class NetworkException extends AppException {
  NetworkException({
    super.message = 'No internet connection.',
    super.originalError,
    super.stackTrace,
  });

  factory NetworkException.noInternet() {
    return NetworkException(
      message: 'No internet connection. Please check your network.',
    );
  }

  factory NetworkException.timeout() {
    return NetworkException(
      message: 'Connection timed out.',
    );
  }

  factory NetworkException.connectionFailed() {
    return NetworkException(
      message: 'Failed to connect to server.',
    );
  }
}

// ==================== CACHE/DATABASE EXCEPTIONS ====================

/// Cache Exception
class CacheException extends AppException {
  CacheException({
    super.message = 'Cache error occurred.',
    super.originalError,
    super.stackTrace,
  });

  factory CacheException.notFound([String? key]) {
    return CacheException(
      message: key != null ? 'Cache key "$key" not found.' : 'Cache not found.',
    );
  }

  factory CacheException.writeError() {
    return CacheException(message: 'Failed to write to cache.');
  }

  factory CacheException.readError() {
    return CacheException(message: 'Failed to read from cache.');
  }

  factory CacheException.clearError() {
    return CacheException(message: 'Failed to clear cache.');
  }
}

/// Database Exception
class DatabaseException extends AppException {
  DatabaseException({
    super.message = 'Database error occurred.',
    super.originalError,
    super.stackTrace,
  });

  factory DatabaseException.notFound([String? table]) {
    return DatabaseException(
      message:
          table != null ? 'Record not found in $table.' : 'Record not found.',
    );
  }

  factory DatabaseException.duplicateEntry([String? field]) {
    return DatabaseException(
      message:
          field != null ? 'Duplicate entry for $field.' : 'Duplicate entry.',
    );
  }

  factory DatabaseException.foreignKeyViolation([String? details]) {
    return DatabaseException(
      message: details ?? 'Foreign key constraint violation.',
    );
  }

  factory DatabaseException.insertFailed([String? table]) {
    return DatabaseException(
      message: table != null
          ? 'Failed to insert into $table.'
          : 'Insert operation failed.',
    );
  }

  factory DatabaseException.updateFailed([String? table]) {
    return DatabaseException(
      message: table != null
          ? 'Failed to update $table.'
          : 'Update operation failed.',
    );
  }

  factory DatabaseException.deleteFailed([String? table]) {
    return DatabaseException(
      message: table != null
          ? 'Failed to delete from $table.'
          : 'Delete operation failed.',
    );
  }

  factory DatabaseException.queryFailed([String? details]) {
    return DatabaseException(
      message: details ?? 'Query execution failed.',
    );
  }

  factory DatabaseException.transactionFailed() {
    return DatabaseException(
      message: 'Database transaction failed.',
    );
  }

  factory DatabaseException.migrationFailed([int? version]) {
    return DatabaseException(
      message: version != null
          ? 'Migration to version $version failed.'
          : 'Database migration failed.',
    );
  }

  factory DatabaseException.initializationFailed() {
    return DatabaseException(
      message: 'Failed to initialize database.',
    );
  }
}

// ==================== AUTH EXCEPTIONS ====================

/// Authentication Exception
class AuthException extends AppException {
  final String? code;

  AuthException({
    super.message = 'Authentication failed.',
    super.statusCode,
    this.code,
    super.originalError,
    super.stackTrace,
  });

  factory AuthException.invalidCredentials() {
    return AuthException(
      message: 'Invalid username or password.',
      statusCode: 401,
    );
  }

  factory AuthException.tokenExpired() {
    return AuthException(
      message: 'Session has expired. Please login again.',
      statusCode: 401,
    );
  }

  factory AuthException.tokenInvalid() {
    return AuthException(
      message: 'Invalid session token.',
      statusCode: 401,
    );
  }

  factory AuthException.tokenNotFound() {
    return AuthException(
      message: 'No authentication token found.',
      statusCode: 401,
    );
  }

  factory AuthException.unauthorized() {
    return AuthException(
      message: 'You are not authorized.',
      statusCode: 403,
    );
  }

  factory AuthException.forbidden() {
    return AuthException(
      message: 'Access denied.',
      statusCode: 403,
    );
  }

  factory AuthException.accountDisabled() {
    return AuthException(
      message: 'Account has been disabled.',
      statusCode: 403,
    );
  }

  factory AuthException.sessionExpired() {
    return AuthException(
      message: 'Your session has expired.',
      statusCode: 401,
    );
  }
}

// ==================== VALIDATION EXCEPTIONS ====================

/// Validation Exception
class ValidationException extends AppException {
  final Map<String, List<String>>? errors;

  ValidationException({
    super.message = 'Validation failed.',
    this.errors,
    super.originalError,
    super.stackTrace,
  });

  factory ValidationException.field(String field, String error) {
    return ValidationException(
      message: error,
      errors: {
        field: [error]
      },
    );
  }

  factory ValidationException.fields(Map<String, List<String>> errors) {
    return ValidationException(
      message:
          errors.values.expand((e) => e).firstOrNull ?? 'Validation failed.',
      errors: errors,
    );
  }

  factory ValidationException.required(String field) {
    return ValidationException.field(field, '$field is required.');
  }

  factory ValidationException.invalidFormat(String field) {
    return ValidationException.field(field, '$field format is invalid.');
  }

  factory ValidationException.minLength(String field, int minLength) {
    return ValidationException.field(
      field,
      '$field must be at least $minLength characters.',
    );
  }

  factory ValidationException.maxLength(String field, int maxLength) {
    return ValidationException.field(
      field,
      '$field must not exceed $maxLength characters.',
    );
  }

  factory ValidationException.range(String field, num min, num max) {
    return ValidationException.field(
      field,
      '$field must be between $min and $max.',
    );
  }

  /// Get first error for a field
  String? getFieldError(String field) {
    return errors?[field]?.firstOrNull;
  }

  /// Get all errors for a field
  List<String>? getFieldErrors(String field) {
    return errors?[field];
  }
}

// ==================== SYNC EXCEPTIONS ====================

/// Sync Exception
class SyncException extends AppException {
  SyncException({
    super.message = 'Sync operation failed.',
    super.originalError,
    super.stackTrace,
  });

  factory SyncException.conflict() {
    return SyncException(
      message: 'Data conflict detected during sync.',
    );
  }

  factory SyncException.pushFailed() {
    return SyncException(
      message: 'Failed to push changes to server.',
    );
  }

  factory SyncException.pullFailed() {
    return SyncException(
      message: 'Failed to pull changes from server.',
    );
  }

  factory SyncException.queueFailed() {
    return SyncException(
      message: 'Failed to queue sync operation.',
    );
  }

  factory SyncException.serverUnavailable([String? message]) {
    return SyncException(
      message: message ?? 'Server unavailable during sync.',
    );
  }
}

// ==================== BUSINESS LOGIC EXCEPTIONS ====================

/// Insufficient Stock Exception
class InsufficientStockException extends AppException {
  final double available;
  final double requested;
  final String? itemName;

  InsufficientStockException({
    required this.available,
    required this.requested,
    this.itemName,
    super.originalError,
    super.stackTrace,
  }) : super(
          message: _buildMessage(available, requested, itemName),
        );

  static String _buildMessage(
      double available, double requested, String? item) {
    final itemStr = item ?? 'Item';
    return '$itemStr: Only ${available.toStringAsFixed(2)} kg available, '
        'but ${requested.toStringAsFixed(2)} kg requested.';
  }
}

/// Customer Exception
class CustomerException extends AppException {
  CustomerException({
    super.message = 'Customer operation failed.',
    super.originalError,
    super.stackTrace,
  });

  factory CustomerException.notFound([String? identifier]) {
    return CustomerException(
      message: identifier != null
          ? 'Customer not found: $identifier'
          : 'Customer not found.',
    );
  }

  factory CustomerException.phoneExists(String phone) {
    return CustomerException(
      message: 'A customer with phone $phone already exists.',
    );
  }

  factory CustomerException.invalidPhone() {
    return CustomerException(
      message: 'Invalid phone number format.',
    );
  }
}

/// Transaction Exception
class TransactionException extends AppException {
  TransactionException({
    super.message = 'Transaction operation failed.',
    super.originalError,
    super.stackTrace,
  });

  factory TransactionException.notFound([String? transactionId]) {
    return TransactionException(
      message: transactionId != null
          ? 'Transaction $transactionId not found.'
          : 'Transaction not found.',
    );
  }

  factory TransactionException.alreadyCompleted() {
    return TransactionException(
      message: 'Transaction is already completed.',
    );
  }

  factory TransactionException.cancelled() {
    return TransactionException(
      message: 'Transaction has been cancelled.',
    );
  }

  factory TransactionException.invalidAmount() {
    return TransactionException(
      message: 'Invalid transaction amount.',
    );
  }

  factory TransactionException.emptyItems() {
    return TransactionException(
      message: 'Transaction must have at least one item.',
    );
  }
}

/// Stock Exception
class StockException extends AppException {
  StockException({
    super.message = 'Stock operation failed.',
    super.originalError,
    super.stackTrace,
  });

  factory StockException.notFound([String? item]) {
    return StockException(
      message: item != null
          ? 'Stock item not found: $item'
          : 'Stock item not found.',
    );
  }

  factory StockException.insufficientStock(
    double available,
    double requested,
  ) {
    return StockException(
      message:
          'Insufficient stock: ${available.toStringAsFixed(2)} kg available, '
          '${requested.toStringAsFixed(2)} kg requested.',
    );
  }

  factory StockException.invalidQuantity() {
    return StockException(
      message: 'Invalid quantity specified.',
    );
  }
}

// ==================== FILE EXCEPTIONS ====================

/// File Exception
class FileException extends AppException {
  FileException({
    super.message = 'File operation failed.',
    super.originalError,
    super.stackTrace,
  });

  factory FileException.notFound([String? fileName]) {
    return FileException(
      message:
          fileName != null ? 'File not found: $fileName' : 'File not found.',
    );
  }

  factory FileException.readError([String? fileName]) {
    return FileException(
      message: fileName != null
          ? 'Failed to read file: $fileName'
          : 'Failed to read file.',
    );
  }

  factory FileException.writeError([String? fileName]) {
    return FileException(
      message: fileName != null
          ? 'Failed to write file: $fileName'
          : 'Failed to write file.',
    );
  }

  factory FileException.deleteError([String? fileName]) {
    return FileException(
      message: fileName != null
          ? 'Failed to delete file: $fileName'
          : 'Failed to delete file.',
    );
  }

  factory FileException.tooLarge(int maxSizeMB) {
    return FileException(
      message: 'File size exceeds maximum limit of ${maxSizeMB}MB.',
    );
  }

  factory FileException.invalidFormat([String? format]) {
    return FileException(
      message: format != null
          ? 'Invalid file format: $format'
          : 'Invalid file format.',
    );
  }

  factory FileException.pdfGenerationFailed() {
    return FileException(
      message: 'Failed to generate PDF.',
    );
  }
}

// ==================== PERMISSION EXCEPTIONS ====================

/// Permission Exception
class PermissionException extends AppException {
  PermissionException({
    super.message = 'Permission denied.',
    super.originalError,
    super.stackTrace,
  });

  factory PermissionException.camera() {
    return PermissionException(
      message: 'Camera permission denied.',
    );
  }

  factory PermissionException.storage() {
    return PermissionException(
      message: 'Storage permission denied.',
    );
  }

  factory PermissionException.location() {
    return PermissionException(
      message: 'Location permission denied.',
    );
  }

  factory PermissionException.roleRestriction(String requiredRole) {
    return PermissionException(
      message: 'This action requires $requiredRole role.',
    );
  }
}

/// Not Found Exception
class NotFoundException extends AppException {
  NotFoundException({
    super.message = 'Resource not found.',
    super.statusCode = 404,
    super.originalError,
    super.stackTrace,
  });

  factory NotFoundException.user([String? identifier]) {
    return NotFoundException(
      message: identifier != null
          ? 'User not found: $identifier'
          : 'User not found.',
    );
  }

  factory NotFoundException.company([String? identifier]) {
    return NotFoundException(
      message: identifier != null
          ? 'Company not found: $identifier'
          : 'Company not found.',
    );
  }

  factory NotFoundException.customer([String? identifier]) {
    return NotFoundException(
      message: identifier != null
          ? 'Customer not found: $identifier'
          : 'Customer not found.',
    );
  }

  factory NotFoundException.transaction([String? identifier]) {
    return NotFoundException(
      message: identifier != null
          ? 'Transaction not found: $identifier'
          : 'Transaction not found.',
    );
  }

  factory NotFoundException.stock([String? identifier]) {
    return NotFoundException(
      message: identifier != null
          ? 'Stock item not found: $identifier'
          : 'Stock item not found.',
    );
  }
}

