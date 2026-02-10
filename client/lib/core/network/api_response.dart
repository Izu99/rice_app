import 'package:equatable/equatable.dart';

/// Generic API Response wrapper
class ApiResponse<T> extends Equatable {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? errors;
  final PaginationMeta? pagination;
  final Map<String, dynamic>? meta;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.errors,
    this.pagination,
    this.meta,
  });

  /// Create success response
  factory ApiResponse.success(
    T data, {
    String? message,
    PaginationMeta? pagination,
    Map<String, dynamic>? meta,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      pagination: pagination,
      meta: meta,
    );
  }

  /// Create error response
  factory ApiResponse.error(
    String message, {
    int? statusCode,
    Map<String, dynamic>? errors,
  }) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }

  /// Create from JSON with generic type parser
  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic)? fromJsonT,
  }) {
    // Handle different API response formats
    final bool isSuccess = json['success'] as bool? ??
        json['status'] == 'success' ||
            json['status'] == true ||
            (json['data'] != null && json['error'] == null);

    T? parsedData;
    if (fromJsonT != null && json['data'] != null) {
      parsedData = fromJsonT(json['data']);
    } else if (json['data'] != null) {
      parsedData = json['data'] as T?;
    }

    return ApiResponse(
      success: isSuccess,
      data: parsedData,
      message: json['message'] as String? ?? json['msg'] as String?,
      statusCode: json['status_code'] as int? ?? json['code'] as int?,
      errors: _parseErrors(json['errors']),
      pagination: json['pagination'] != null
          ? PaginationMeta.fromJson(json['pagination'] as Map<String, dynamic>)
          : json['meta'] != null && json['meta']['pagination'] != null
              ? PaginationMeta.fromJson(
                  json['meta']['pagination'] as Map<String, dynamic>)
              : null,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  /// Parse errors from various formats
  static Map<String, dynamic>? _parseErrors(dynamic errors) {
    if (errors == null) return null;
    if (errors is Map<String, dynamic>) return errors;
    if (errors is String) return {'error': errors};
    if (errors is List) {
      return {'errors': errors};
    }
    return null;
  }

  /// Check if response has data
  bool get hasData => data != null;

  /// Check if response has errors
  bool get hasErrors => errors != null && errors!.isNotEmpty;

  /// Check if response has pagination
  bool get hasPagination => pagination != null;

  /// Get first error message
  String? get firstError {
    if (errors == null) return null;

    for (final value in errors!.values) {
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }
      if (value is String) {
        return value;
      }
    }
    return null;
  }

  /// Get error for specific field
  String? getFieldError(String field) {
    if (errors == null) return null;
    final fieldErrors = errors![field];
    if (fieldErrors is List && fieldErrors.isNotEmpty) {
      return fieldErrors.first.toString();
    }
    if (fieldErrors is String) {
      return fieldErrors;
    }
    return null;
  }

  /// Convert to map
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (data != null) 'data': data,
      if (message != null) 'message': message,
      if (statusCode != null) 'status_code': statusCode,
      if (errors != null) 'errors': errors,
      if (pagination != null) 'pagination': pagination!.toJson(),
      if (meta != null) 'meta': meta,
    };
  }

  @override
  List<Object?> get props => [
        success,
        data,
        message,
        statusCode,
        errors,
        pagination,
        meta,
      ];

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, hasData: $hasData)';
  }
}

/// Pagination metadata
class PaginationMeta extends Equatable {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;

  const PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.from,
    this.to,
  });

  /// Check if has next page
  bool get hasNextPage => currentPage < lastPage;

  /// Check if has previous page
  bool get hasPreviousPage => currentPage > 1;

  /// Check if is first page
  bool get isFirstPage => currentPage == 1;

  /// Check if is last page
  bool get isLastPage => currentPage == lastPage;

  /// Get next page number
  int? get nextPage => hasNextPage ? currentPage + 1 : null;

  /// Get previous page number
  int? get previousPage => hasPreviousPage ? currentPage - 1 : null;

  /// Get total pages
  int get totalPages => lastPage;

  /// Get items showing text (e.g., "1-10 of 100")
  String get showingText {
    if (from != null && to != null) {
      return '$from-$to of $total';
    }
    final start = (currentPage - 1) * perPage + 1;
    final end = (start + perPage - 1).clamp(1, total);
    return '$start-$end of $total';
  }

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] as int? ?? json['page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? json['total_pages'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? json['total_count'] as int? ?? 0,
      from: json['from'] as int?,
      to: json['to'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    };
  }

  PaginationMeta copyWith({
    int? currentPage,
    int? lastPage,
    int? perPage,
    int? total,
    int? from,
    int? to,
  }) {
    return PaginationMeta(
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      perPage: perPage ?? this.perPage,
      total: total ?? this.total,
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }

  @override
  List<Object?> get props => [currentPage, lastPage, perPage, total, from, to];
}

/// List response with pagination
class PaginatedResponse<T> extends Equatable {
  final List<T> items;
  final PaginationMeta pagination;

  const PaginatedResponse({
    required this.items,
    required this.pagination,
  });

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get length => items.length;
  bool get hasMore => pagination.hasNextPage;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    final items =
        dataList.map((e) => fromJsonT(e as Map<String, dynamic>)).toList();

    return PaginatedResponse(
      items: items,
      pagination: PaginationMeta.fromJson(
        json['pagination'] as Map<String, dynamic>? ??
            json['meta'] as Map<String, dynamic>? ??
            {},
      ),
    );
  }

  @override
  List<Object?> get props => [items, pagination];
}

/// Auth response
class AuthResponse extends Equatable {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final int? expiresIn;
  final DateTime? expiresAt;
  final Map<String, dynamic>? user;

  const AuthResponse({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn,
    this.expiresAt,
    this.user,
  });

  /// Check if token is expired
  bool get isExpired {
    if (expiresAt != null) {
      return DateTime.now().isAfter(expiresAt!);
    }
    return false;
  }

  /// Get authorization header value
  String get authorizationHeader => '$tokenType $accessToken';

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final expiresIn = json['expires_in'] as int?;

    return AuthResponse(
      accessToken:
          json['access_token'] as String? ?? json['token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String?,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresIn: expiresIn,
      expiresAt: expiresIn != null
          ? DateTime.now().add(Duration(seconds: expiresIn))
          : json['expires_at'] != null
              ? DateTime.parse(json['expires_at'] as String)
              : null,
      user: json['user'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      if (refreshToken != null) 'refresh_token': refreshToken,
      'token_type': tokenType,
      if (expiresIn != null) 'expires_in': expiresIn,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      if (user != null) 'user': user,
    };
  }

  @override
  List<Object?> get props => [
        accessToken,
        refreshToken,
        tokenType,
        expiresIn,
        expiresAt,
        user,
      ];
}
