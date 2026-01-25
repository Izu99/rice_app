// lib/data/models/sync_queue_model.dart

import 'dart:convert';

import 'package:equatable/equatable.dart';
import '../../core/constants/enums.dart';
import '../../core/constants/db_constants.dart';

/// Type of entity being synced
enum SyncEntityType {
  customer,
  stock,
  transaction,
  payment,
  milling,
  user,
}

/// Priority levels for sync
enum SyncPriority {
  low,
  normal,
  high,
  critical,
}

class SyncQueueModel extends Equatable {
  final int? localId;
  final String id;
  final SyncEntityType entityType;
  final String entityId;
  final String? entityServerId;
  final SyncOperation operation;
  final SyncStatus status;
  final SyncPriority priority;
  final Map<String, dynamic> payload;
  final String? errorMessage;
  final int retryCount;
  final int maxRetries;
  final DateTime? lastAttemptAt;
  final DateTime? nextRetryAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SyncQueueModel({
    this.localId,
    required this.id,
    required this.entityType,
    required this.entityId,
    this.entityServerId,
    required this.operation,
    this.status = SyncStatus.pending,
    this.priority = SyncPriority.normal,
    required this.payload,
    this.errorMessage,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.lastAttemptAt,
    this.nextRetryAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON
  factory SyncQueueModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> payload = {};
    if (json['payload'] != null) {
      if (json['payload'] is String) {
        // Parse JSON string
        try {
          payload = Map<String, dynamic>.from(
            json['payload'] is Map ? json['payload'] : {},
          );
        } catch (_) {
          payload = {};
        }
      } else if (json['payload'] is Map) {
        payload = Map<String, dynamic>.from(json['payload']);
      }
    }

    return SyncQueueModel(
      id: json['id']?.toString() ?? '',
      entityType: _parseEntityType(json['entity_type']),
      entityId: json['entity_id']?.toString() ?? '',
      entityServerId: json['entity_server_id']?.toString(),
      operation: _parseOperation(json['operation']),
      status: _parseSyncStatus(json['status']),
      priority: _parsePriority(json['priority']),
      payload: payload,
      errorMessage: json['error_message']?.toString(),
      retryCount: _parseInt(json['retry_count']),
      maxRetries: _parseInt(json['max_retries'], defaultValue: 3),
      lastAttemptAt: _parseDateTime(json['last_attempt_at']),
      nextRetryAt: _parseDateTime(json['next_retry_at']),
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType.name,
      'entity_id': entityId,
      'entity_server_id': entityServerId,
      'operation': operation.name,
      'status': status.name,
      'priority': priority.name,
      'payload': payload,
      'error_message': errorMessage,
      'retry_count': retryCount,
      'max_retries': maxRetries,
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'next_retry_at': nextRetryAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from DB map
  factory SyncQueueModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> payload = {};
    final rawData = map['data'];
    if (rawData != null) {
      if (rawData is String) {
        try {
          payload = Map<String, dynamic>.from(jsonDecode(rawData));
        } catch (_) {
          // Try to parse simple map string
          try {
            payload = Map<String, dynamic>.from(map['data'] as Map);
          } catch (_) {
            payload = {};
          }
        }
      } else if (rawData is Map) {
        payload = Map<String, dynamic>.from(rawData);
      }
    }

    return SyncQueueModel(
      localId: (map[DbConstants.colLocalId] is int)
          ? map[DbConstants.colLocalId] as int
          : (map[DbConstants.colLocalId] != null
              ? int.tryParse(map[DbConstants.colLocalId].toString())
              : null),
      id: map['id']?.toString() ??
          'SYNC_${DateTime.now().millisecondsSinceEpoch}',
      entityType: _parseEntityType(map['table_name'] ?? map['entity_type']),
      entityId: (map['record_local_id'] ?? map['entity_id'])?.toString() ?? '',
      entityServerId: map['entity_server_id']?.toString(),
      operation: _parseOperation(map['operation']),
      status: _parseSyncStatus(map['status']),
      priority: _parsePriority(map['priority']),
      payload: payload,
      errorMessage:
          map['last_error']?.toString() ?? map['error_message']?.toString(),
      retryCount: _parseInt(map['retry_count']),
      maxRetries: _parseInt(map['max_retries'], defaultValue: 3),
      lastAttemptAt: _parseDateTime(map['last_attempt_at']),
      nextRetryAt: _parseDateTime(map['next_retry_at']),
      createdAt:
          _parseDateTime(map[DbConstants.colCreatedAt]) ?? DateTime.now(),
      updatedAt:
          _parseDateTime(map[DbConstants.colUpdatedAt]) ?? DateTime.now(),
    );
  }

  /// Convert to DB map
  Map<String, dynamic> toMap() {
    return {
      DbConstants.colLocalId: localId,
      'table_name': tableName,
      'record_local_id': int.tryParse(entityId) ?? entityId,
      'operation': operation.name,
      'data': jsonEncode(payload),
      'retry_count': retryCount,
      'last_error': errorMessage,
      DbConstants.colCreatedAt: createdAt.toIso8601String(),
      DbConstants.colUpdatedAt: updatedAt.toIso8601String(),
    };
  }

  /// Create new sync queue item
  factory SyncQueueModel.create({
    // Primary (new) API
    SyncEntityType? entityType,
    String? entityId,
    String? entityServerId,
    required SyncOperation operation,
    Map<String, dynamic>? payload,
    SyncPriority priority = SyncPriority.normal,
    // Legacy/compat aliases used by table code
    String? tableName,
    int? recordLocalId,
    Map<String, dynamic>? data,
  }) {
    final now = DateTime.now();
    final resolvedEntityType = entityType ?? _parseEntityType(tableName);
    final resolvedEntityId =
        entityId ?? (recordLocalId != null ? recordLocalId.toString() : '');
    final resolvedPayload = payload ?? data ?? <String, dynamic>{};
    return SyncQueueModel(
      id: 'SYNC_${now.millisecondsSinceEpoch}',
      entityType: resolvedEntityType,
      entityId: resolvedEntityId,
      entityServerId: entityServerId,
      operation: operation,
      priority: priority,
      payload: resolvedPayload,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Copy with new values
  SyncQueueModel copyWith({
    int? localId,
    String? id,
    SyncEntityType? entityType,
    String? entityId,
    String? entityServerId,
    SyncOperation? operation,
    SyncStatus? status,
    SyncPriority? priority,
    Map<String, dynamic>? payload,
    String? errorMessage,
    int? retryCount,
    int? maxRetries,
    DateTime? lastAttemptAt,
    DateTime? nextRetryAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SyncQueueModel(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      entityServerId: entityServerId ?? this.entityServerId,
      operation: operation ?? this.operation,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      payload: payload ?? this.payload,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Mark as synced
  SyncQueueModel markAsSynced(String serverId) {
    return copyWith(
      status: SyncStatus.synced,
      entityServerId: serverId,
      updatedAt: DateTime.now(),
    );
  }

  /// Mark as failed
  SyncQueueModel markAsFailed(String error) {
    final now = DateTime.now();
    final newRetryCount = retryCount + 1;

    // Calculate next retry time with exponential backoff
    final backoffMinutes = (2 << retryCount).clamp(1, 60);
    final nextRetry = now.add(Duration(minutes: backoffMinutes));

    return copyWith(
      status:
          newRetryCount >= maxRetries ? SyncStatus.failed : SyncStatus.pending,
      errorMessage: error,
      retryCount: newRetryCount,
      lastAttemptAt: now,
      nextRetryAt: nextRetry,
      updatedAt: now,
    );
  }

  /// Mark as conflict
  SyncQueueModel markAsConflict(String details) {
    return copyWith(
      status: SyncStatus.conflict,
      errorMessage: details,
      lastAttemptAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Reset for retry
  SyncQueueModel resetForRetry() {
    return copyWith(
      status: SyncStatus.pending,
      retryCount: 0,
      errorMessage: null,
      nextRetryAt: null,
      updatedAt: DateTime.now(),
    );
  }

  /// Parse helpers
  static SyncEntityType _parseEntityType(dynamic value) {
    if (value == null) return SyncEntityType.customer;
    if (value is SyncEntityType) return value;

    switch (value.toString().toLowerCase()) {
      case 'stock':
        return SyncEntityType.stock;
      case 'transaction':
        return SyncEntityType.transaction;
      case 'payment':
        return SyncEntityType.payment;
      case 'milling':
        return SyncEntityType.milling;
      case 'user':
        return SyncEntityType.user;
      default:
        return SyncEntityType.customer;
    }
  }

  static SyncOperation _parseOperation(dynamic value) {
    if (value == null) return SyncOperation.create;
    if (value is SyncOperation) return value;

    switch (value.toString().toLowerCase()) {
      case 'update':
        return SyncOperation.update;
      case 'delete':
        return SyncOperation.delete;
      default:
        return SyncOperation.create;
    }
  }

  static SyncStatus _parseSyncStatus(dynamic value) {
    if (value == null) return SyncStatus.pending;
    if (value is SyncStatus) return value;

    switch (value.toString().toLowerCase()) {
      case 'synced':
        return SyncStatus.synced;
      case 'failed':
        return SyncStatus.failed;
      case 'conflict':
        return SyncStatus.conflict;
      default:
        return SyncStatus.pending;
    }
  }

  static SyncPriority _parsePriority(dynamic value) {
    if (value == null) return SyncPriority.normal;
    if (value is SyncPriority) return value;

    switch (value.toString().toLowerCase()) {
      case 'low':
        return SyncPriority.low;
      case 'high':
        return SyncPriority.high;
      case 'critical':
        return SyncPriority.critical;
      default:
        return SyncPriority.normal;
    }
  }

  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Check if can retry
  bool get canRetry => status == SyncStatus.pending && retryCount < maxRetries;

  /// Check if ready to sync
  bool get isReadyToSync {
    if (status != SyncStatus.pending) return false;
    if (nextRetryAt == null) return true;
    return DateTime.now().isAfter(nextRetryAt!);
  }

  /// Check if has reached max retries
  bool get hasReachedMaxRetries => retryCount >= maxRetries;

  /// Get display status
  String get displayStatus {
    switch (status) {
      case SyncStatus.pending:
        return 'Pending';
      case SyncStatus.syncing:
        return 'Syncing';
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.failed:
        return 'Failed';
      case SyncStatus.conflict:
        return 'Conflict';
    }
  }

  @override
  List<Object?> get props => [
        localId,
        id,
        entityType,
        entityId,
        operation,
        status,
        retryCount,
      ];

  @override
  String toString() =>
      'SyncQueueModel(localId: $localId, id: $id, type: ${entityType.name}, operation: ${operation.name}, status: ${status.name})';

  // Compatibility helpers expected by DB/table code
  String get tableName => entityType.name;
  int? get recordLocalId => int.tryParse(entityId);
  Map<String, dynamic> get data => payload;

  /// Create sync queue item for legacy table compatibility
  factory SyncQueueModel.createForTable({
    required String tableName,
    required int recordLocalId,
    required SyncOperation operation,
    required Map<String, dynamic> data,
  }) {
    return SyncQueueModel(
      id: 'SYNC_${DateTime.now().millisecondsSinceEpoch}',
      entityType: _parseEntityType(tableName),
      entityId: recordLocalId.toString(),
      operation: operation,
      payload: data,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

extension SyncOperationValue on SyncOperation {
  String get value => name;
}

