import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Sync state enumeration
enum SyncState {
  /// Initial state, no sync has occurred
  idle,

  /// Currently syncing data
  syncing,

  /// Sync completed successfully
  success,

  /// Sync failed with error
  error,

  /// Device is offline
  offline,

  /// Sync paused by user
  paused,

  /// Sync cancelled
  cancelled,
}

/// Sync progress phase
enum SyncPhase {
  /// Preparing sync
  preparing,

  /// Pushing local changes to server
  pushing,

  /// Pulling server changes
  pulling,

  /// Resolving conflicts
  resolving,

  /// Finalizing sync
  finalizing,

  /// Sync complete
  complete,
}

/// Sync status model
class SyncStatusModel extends Equatable {
  /// Current sync state
  final SyncState state;

  /// Current sync phase
  final SyncPhase phase;

  /// Last successful sync time
  final DateTime? lastSyncTime;

  /// Number of pending items to sync
  final int pendingCount;

  /// Number of items synced in current session
  final int syncedCount;

  /// Total items to sync in current session
  final int totalCount;

  /// Current sync progress (0.0 to 1.0)
  final double progress;

  /// Error message if sync failed
  final String? errorMessage;

  /// Error code if sync failed
  final String? errorCode;

  /// Current table being synced
  final String? currentTable;

  /// Number of conflicts detected
  final int conflictCount;

  /// Number of resolved conflicts
  final int resolvedConflictCount;

  /// Sync started at
  final DateTime? startedAt;

  /// Estimated time remaining (in seconds)
  final int? estimatedTimeRemaining;

  const SyncStatusModel({
    this.state = SyncState.idle,
    this.phase = SyncPhase.preparing,
    this.lastSyncTime,
    this.pendingCount = 0,
    this.syncedCount = 0,
    this.totalCount = 0,
    this.progress = 0.0,
    this.errorMessage,
    this.errorCode,
    this.currentTable,
    this.conflictCount = 0,
    this.resolvedConflictCount = 0,
    this.startedAt,
    this.estimatedTimeRemaining,
  });

  // ==================== GETTERS ====================

  /// Check if currently syncing
  bool get isSyncing => state == SyncState.syncing;

  /// Check if offline
  bool get isOffline => state == SyncState.offline;

  /// Check if sync was successful
  bool get isSuccess => state == SyncState.success;

  /// Check if sync failed
  bool get hasError => state == SyncState.error;

  /// Check if has pending items
  bool get hasPending => pendingCount > 0;

  /// Check if has conflicts
  bool get hasConflicts => conflictCount > 0;

  /// Check if all conflicts resolved
  bool get allConflictsResolved => conflictCount == resolvedConflictCount;

  /// Check if sync is idle and up to date
  bool get isUpToDate => state == SyncState.idle && pendingCount == 0;

  /// Get progress percentage (0-100)
  int get progressPercentage => (progress * 100).round();

  /// Get remaining items count
  int get remainingCount => totalCount - syncedCount;

  /// Get formatted last sync time
  String get lastSyncTimeFormatted {
    if (lastSyncTime == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(lastSyncTime!);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastSyncTime!.day}/${lastSyncTime!.month}/${lastSyncTime!.year}';
    }
  }

  /// Get sync duration
  Duration? get syncDuration {
    if (startedAt == null) return null;
    return DateTime.now().difference(startedAt!);
  }

  /// Get estimated time remaining formatted
  String get estimatedTimeRemainingFormatted {
    if (estimatedTimeRemaining == null) return '';

    if (estimatedTimeRemaining! < 60) {
      return '${estimatedTimeRemaining}s remaining';
    } else {
      final minutes = estimatedTimeRemaining! ~/ 60;
      return '${minutes}m remaining';
    }
  }

  /// Get status message
  String get statusMessage {
    switch (state) {
      case SyncState.idle:
        if (hasPending) {
          return '$pendingCount changes pending';
        }
        return 'Up to date';
      case SyncState.syncing:
        return _getSyncingMessage();
      case SyncState.success:
        return 'Sync complete';
      case SyncState.error:
        return errorMessage ?? 'Sync failed';
      case SyncState.offline:
        return 'Offline mode';
      case SyncState.paused:
        return 'Sync paused';
      case SyncState.cancelled:
        return 'Sync cancelled';
    }
  }

  String _getSyncingMessage() {
    switch (phase) {
      case SyncPhase.preparing:
        return 'Preparing sync...';
      case SyncPhase.pushing:
        return 'Uploading changes... ($syncedCount/$totalCount)';
      case SyncPhase.pulling:
        return 'Downloading updates...';
      case SyncPhase.resolving:
        return 'Resolving conflicts...';
      case SyncPhase.finalizing:
        return 'Finalizing...';
      case SyncPhase.complete:
        return 'Complete';
    }
  }

  /// Get status message in Sinhala
  String get statusMessageSinhala {
    switch (state) {
      case SyncState.idle:
        if (hasPending) {
          return 'වෙනස්කම් $pendingCount ක් බලාපොරොත්තුවෙන්';
        }
        return 'යාවත්කාලීනයි';
      case SyncState.syncing:
        return 'සමමුහුර්ත කරමින්...';
      case SyncState.success:
        return 'සමමුහුර්තය සම්පූර්ණයි';
      case SyncState.error:
        return 'සමමුහුර්තය අසාර්ථකයි';
      case SyncState.offline:
        return 'අන්තර්ජාල සම්බන්ධතාවය නැත';
      case SyncState.paused:
        return 'සමමුහුර්තය නතර කර ඇත';
      case SyncState.cancelled:
        return 'සමමුහුර්තය අවලංගු කරන ලදී';
    }
  }

  // ==================== COPY WITH ====================

  SyncStatusModel copyWith({
    SyncState? state,
    SyncPhase? phase,
    DateTime? lastSyncTime,
    int? pendingCount,
    int? syncedCount,
    int? totalCount,
    double? progress,
    String? errorMessage,
    String? errorCode,
    String? currentTable,
    int? conflictCount,
    int? resolvedConflictCount,
    DateTime? startedAt,
    int? estimatedTimeRemaining,
    bool clearError = false,
    bool clearLastSync = false,
  }) {
    return SyncStatusModel(
      state: state ?? this.state,
      phase: phase ?? this.phase,
      lastSyncTime: clearLastSync ? null : (lastSyncTime ?? this.lastSyncTime),
      pendingCount: pendingCount ?? this.pendingCount,
      syncedCount: syncedCount ?? this.syncedCount,
      totalCount: totalCount ?? this.totalCount,
      progress: progress ?? this.progress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      currentTable: currentTable ?? this.currentTable,
      conflictCount: conflictCount ?? this.conflictCount,
      resolvedConflictCount:
          resolvedConflictCount ?? this.resolvedConflictCount,
      startedAt: startedAt ?? this.startedAt,
      estimatedTimeRemaining:
          estimatedTimeRemaining ?? this.estimatedTimeRemaining,
    );
  }

  // ==================== FACTORY CONSTRUCTORS ====================

  /// Create idle status
  factory SyncStatusModel.idle({int pendingCount = 0, DateTime? lastSyncTime}) {
    return SyncStatusModel(
      state: SyncState.idle,
      pendingCount: pendingCount,
      lastSyncTime: lastSyncTime,
    );
  }

  /// Create syncing status
  factory SyncStatusModel.syncing({
    SyncPhase phase = SyncPhase.preparing,
    int syncedCount = 0,
    int totalCount = 0,
    String? currentTable,
  }) {
    return SyncStatusModel(
      state: SyncState.syncing,
      phase: phase,
      syncedCount: syncedCount,
      totalCount: totalCount,
      progress: totalCount > 0 ? syncedCount / totalCount : 0.0,
      currentTable: currentTable,
      startedAt: DateTime.now(),
    );
  }

  /// Create success status
  factory SyncStatusModel.success({
    int syncedCount = 0,
    DateTime? lastSyncTime,
  }) {
    return SyncStatusModel(
      state: SyncState.success,
      phase: SyncPhase.complete,
      syncedCount: syncedCount,
      progress: 1.0,
      lastSyncTime: lastSyncTime ?? DateTime.now(),
      pendingCount: 0,
    );
  }

  /// Create error status
  factory SyncStatusModel.error({
    required String message,
    String? code,
    int pendingCount = 0,
  }) {
    return SyncStatusModel(
      state: SyncState.error,
      errorMessage: message,
      errorCode: code,
      pendingCount: pendingCount,
    );
  }

  /// Create offline status
  factory SyncStatusModel.offline({int pendingCount = 0}) {
    return SyncStatusModel(
      state: SyncState.offline,
      pendingCount: pendingCount,
    );
  }

  @override
  List<Object?> get props => [
        state,
        phase,
        lastSyncTime,
        pendingCount,
        syncedCount,
        totalCount,
        progress,
        errorMessage,
        errorCode,
        currentTable,
        conflictCount,
        resolvedConflictCount,
        startedAt,
        estimatedTimeRemaining,
      ];

  @override
  String toString() {
    return 'SyncStatusModel(state: $state, phase: $phase, progress: $progressPercentage%, '
        'pending: $pendingCount, synced: $syncedCount/$totalCount)';
  }
}

// ==================== SYNC TABLE STATUS ====================

/// Status for individual table sync
class TableSyncStatus extends Equatable {
  final String tableName;
  final int pendingCount;
  final int syncedCount;
  final int failedCount;
  final int conflictCount;
  final DateTime? lastSyncTime;
  final String? lastError;
  final bool isSyncing;

  const TableSyncStatus({
    required this.tableName,
    this.pendingCount = 0,
    this.syncedCount = 0,
    this.failedCount = 0,
    this.conflictCount = 0,
    this.lastSyncTime,
    this.lastError,
    this.isSyncing = false,
  });

  bool get hasPending => pendingCount > 0;
  bool get hasFailed => failedCount > 0;
  bool get hasConflicts => conflictCount > 0;
  bool get isUpToDate => pendingCount == 0 && failedCount == 0;

  TableSyncStatus copyWith({
    String? tableName,
    int? pendingCount,
    int? syncedCount,
    int? failedCount,
    int? conflictCount,
    DateTime? lastSyncTime,
    String? lastError,
    bool? isSyncing,
  }) {
    return TableSyncStatus(
      tableName: tableName ?? this.tableName,
      pendingCount: pendingCount ?? this.pendingCount,
      syncedCount: syncedCount ?? this.syncedCount,
      failedCount: failedCount ?? this.failedCount,
      conflictCount: conflictCount ?? this.conflictCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError ?? this.lastError,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  @override
  List<Object?> get props => [
        tableName,
        pendingCount,
        syncedCount,
        failedCount,
        conflictCount,
        lastSyncTime,
        lastError,
        isSyncing,
      ];
}

// ==================== SYNC RESULT ====================

/// Result of a sync operation
class SyncResult extends Equatable {
  final bool success;
  final int pushedCount;
  final int pulledCount;
  final int conflictCount;
  final int failedCount;
  final List<SyncError> errors;
  final List<SyncConflict> conflicts;
  final Duration duration;
  final DateTime completedAt;

  const SyncResult({
    required this.success,
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.conflictCount = 0,
    this.failedCount = 0,
    this.errors = const [],
    this.conflicts = const [],
    required this.duration,
    required this.completedAt,
  });

  int get totalSynced => pushedCount + pulledCount;
  bool get hasErrors => errors.isNotEmpty;
  bool get hasConflicts => conflicts.isNotEmpty;

  factory SyncResult.success({
    int pushedCount = 0,
    int pulledCount = 0,
    required Duration duration,
  }) {
    return SyncResult(
      success: true,
      pushedCount: pushedCount,
      pulledCount: pulledCount,
      duration: duration,
      completedAt: DateTime.now(),
    );
  }

  factory SyncResult.failure({
    required List<SyncError> errors,
    int pushedCount = 0,
    int pulledCount = 0,
    required Duration duration,
  }) {
    return SyncResult(
      success: false,
      errors: errors,
      pushedCount: pushedCount,
      pulledCount: pulledCount,
      failedCount: errors.length,
      duration: duration,
      completedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        success,
        pushedCount,
        pulledCount,
        conflictCount,
        failedCount,
        errors,
        conflicts,
        duration,
        completedAt,
      ];
}

// ==================== SYNC ERROR ====================

/// Sync error model
class SyncError extends Equatable {
  final String tableName;
  final int? recordId;
  final String operation;
  final String message;
  final String? code;
  final DateTime occurredAt;
  final bool isRetryable;

  const SyncError({
    required this.tableName,
    this.recordId,
    required this.operation,
    required this.message,
    this.code,
    required this.occurredAt,
    this.isRetryable = true,
  });

  factory SyncError.create({
    required String tableName,
    int? recordId,
    required String operation,
    required String message,
    String? code,
    bool isRetryable = true,
  }) {
    return SyncError(
      tableName: tableName,
      recordId: recordId,
      operation: operation,
      message: message,
      code: code,
      occurredAt: DateTime.now(),
      isRetryable: isRetryable,
    );
  }

  @override
  List<Object?> get props => [
        tableName,
        recordId,
        operation,
        message,
        code,
        occurredAt,
        isRetryable,
      ];
}

// ==================== SYNC CONFLICT ====================

/// Sync conflict model
class SyncConflict extends Equatable {
  final String id;
  final String tableName;
  final int localId;
  final String? serverId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final DateTime localModifiedAt;
  final DateTime serverModifiedAt;
  final ConflictResolution? resolution;
  final bool isResolved;

  const SyncConflict({
    required this.id,
    required this.tableName,
    required this.localId,
    this.serverId,
    required this.localData,
    required this.serverData,
    required this.localModifiedAt,
    required this.serverModifiedAt,
    this.resolution,
    this.isResolved = false,
  });

  /// Get conflicting fields
  List<String> get conflictingFields {
    final fields = <String>[];

    for (final key in localData.keys) {
      if (serverData.containsKey(key)) {
        if (localData[key] != serverData[key]) {
          fields.add(key);
        }
      }
    }

    return fields;
  }

  SyncConflict copyWith({
    ConflictResolution? resolution,
    bool? isResolved,
  }) {
    return SyncConflict(
      id: id,
      tableName: tableName,
      localId: localId,
      serverId: serverId,
      localData: localData,
      serverData: serverData,
      localModifiedAt: localModifiedAt,
      serverModifiedAt: serverModifiedAt,
      resolution: resolution ?? this.resolution,
      isResolved: isResolved ?? this.isResolved,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tableName,
        localId,
        serverId,
        localData,
        serverData,
        localModifiedAt,
        serverModifiedAt,
        resolution,
        isResolved,
      ];
}

/// Conflict resolution strategy
enum ConflictResolution {
  /// Keep local changes
  keepLocal,

  /// Keep server changes
  keepServer,

  /// Merge changes (field by field)
  merge,

  /// Create duplicate
  duplicate,

  /// Manual resolution required
  manual,
}

// ==================== SYNC NOTIFIER ====================

/// Sync status change notifier
class SyncStatusNotifier extends ChangeNotifier {
  SyncStatusModel _status = const SyncStatusModel();
  final Map<String, TableSyncStatus> _tableStatuses = {};

  SyncStatusModel get status => _status;
  Map<String, TableSyncStatus> get tableStatuses =>
      Map.unmodifiable(_tableStatuses);

  void updateStatus(SyncStatusModel newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  void updateTableStatus(TableSyncStatus tableStatus) {
    _tableStatuses[tableStatus.tableName] = tableStatus;
    notifyListeners();
  }

  void reset() {
    _status = const SyncStatusModel();
    _tableStatuses.clear();
    notifyListeners();
  }

  void setOffline() {
    _status = _status.copyWith(state: SyncState.offline);
    notifyListeners();
  }

  void setOnline() {
    if (_status.isOffline) {
      _status = _status.copyWith(state: SyncState.idle);
      notifyListeners();
    }
  }

  void incrementPending() {
    _status = _status.copyWith(pendingCount: _status.pendingCount + 1);
    notifyListeners();
  }

  void decrementPending() {
    if (_status.pendingCount > 0) {
      _status = _status.copyWith(pendingCount: _status.pendingCount - 1);
      notifyListeners();
    }
  }

  void setPendingCount(int count) {
    _status = _status.copyWith(pendingCount: count);
    notifyListeners();
  }
}
