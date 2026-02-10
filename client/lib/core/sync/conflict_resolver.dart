// The entire content of this file is commented out because it relies on DbHelper,
// which is part of the removed local SQLite storage.
// This file is no longer relevant for the API-only architecture.

/*
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../constants/db_constants.dart';
import '../database/db_helper.dart';
import 'sync_status.dart';

/// Conflict resolution strategy configuration
class ConflictResolutionConfig {
  /// Default resolution strategy
  final ConflictResolution defaultStrategy;

  /// Table-specific strategies
  final Map<String, ConflictResolution> tableStrategies;

  /// Field-specific strategies (table.field -> strategy)
  final Map<String, ConflictResolution> fieldStrategies;

  /// Fields to always keep local value
  final Set<String> alwaysLocalFields;

  /// Fields to always keep server value
  final Set<String> alwaysServerFields;

  /// Whether to auto-resolve conflicts
  final bool autoResolve;

  /// Callback for manual resolution
  final Future<ConflictResolution> Function(SyncConflict)? onManualResolution;

  const ConflictResolutionConfig({
    this.defaultStrategy = ConflictResolution.keepServer,
    this.tableStrategies = const {},
    this.fieldStrategies = const {},
    this.alwaysLocalFields = const {},
    this.alwaysServerFields = const {},
    this.autoResolve = true,
    this.onManualResolution,
  });

  /// Get strategy for a specific table
  ConflictResolution getStrategyForTable(String tableName) {
    return tableStrategies[tableName] ?? defaultStrategy;
  }

  /// Get strategy for a specific field
  ConflictResolution? getStrategyForField(String tableName, String fieldName) {
    return fieldStrategies['$tableName.$fieldName'];
  }
}

/// Conflict resolver for handling sync conflicts
class ConflictResolver {
  final DbHelper _dbHelper;
  final ConflictResolutionConfig _config;
  final Logger _logger = Logger();

  /// List of detected conflicts
  final List<SyncConflict> _conflicts = [];

  /// List of resolved conflicts
  final List<SyncConflict> _resolvedConflicts = [];

  ConflictResolver({
    required DbHelper dbHelper,
    ConflictResolutionConfig? config,
  })  : _dbHelper = dbHelper,
        _config = config ?? const ConflictResolutionConfig();

  // ==================== GETTERS ====================

  List<SyncConflict> get conflicts => List.unmodifiable(_conflicts);
  List<SyncConflict> get resolvedConflicts =>
      List.unmodifiable(_resolvedConflicts);
  int get conflictCount => _conflicts.length;
  int get resolvedCount => _resolvedConflicts.length;
  bool get hasUnresolvedConflicts => _conflicts.any((c) => !c.isResolved);

  // ==================== CONFLICT DETECTION ====================

  /// Detect conflict between local and server data
  Future<SyncConflict?> detectConflict({
    required String tableName,
    required int localId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
  }) async {
    // Get timestamps
    final localModifiedAt = _parseDateTime(localData[DbConstants.colUpdatedAt]);
    final serverModifiedAt = _parseDateTime(serverData['updated_at']);

    if (localModifiedAt == null || serverModifiedAt == null) {
      return null;
    }

    // Check if there's a conflict (both modified after last sync)
    final hasConflict = _hasConflict(localData, serverData);

    if (!hasConflict) {
      return null;
    }

    final conflict = SyncConflict(
      id: '${tableName}_${localId}_${DateTime.now().millisecondsSinceEpoch}',
      tableName: tableName,
      localId: localId,
      serverId: serverData['id']?.toString(),
      localData: localData,
      serverData: serverData,
      localModifiedAt: localModifiedAt,
      serverModifiedAt: serverModifiedAt,
    );

    _conflicts.add(conflict);
    _logger.w('Conflict detected: ${conflict.id}');

    return conflict;
  }

  /// Check if there's an actual conflict
  bool _hasConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
  ) {
    // Compare relevant fields
    final fieldsToCompare = _getComparableFields(localData, serverData);

    for (final field in fieldsToCompare) {
      final localValue = localData[field];
      final serverValue = serverData[field];

      if (!_valuesEqual(localValue, serverValue)) {
        return true;
      }
    }

    return false;
  }

  /// Get fields that should be compared
  List<String> _getComparableFields(
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
  ) {
    final excludeFields = {
      DbConstants.colLocalId,
      DbConstants.colServerId,
      DbConstants.colCreatedAt,
      DbConstants.colUpdatedAt,
      DbConstants.colSyncStatus,
      'id',
    };

    final localFields = localData.keys.toSet();
    final serverFields = serverData.keys.toSet();
    final allFields = localFields.union(serverFields);

    return allFields.where((f) => !excludeFields.contains(f)).toList();
  }

  /// Check if two values are equal
  bool _valuesEqual(dynamic a, dynamic b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;

    if (a is Map && b is Map) {
      return mapEquals(a as Map<String, dynamic>, b as Map<String, dynamic>);
    }

    if (a is List && b is List) {
      return listEquals(a, b);
    }

    return a.toString() == b.toString();
  }

  // ==================== CONFLICT RESOLUTION ====================

  /// Resolve all conflicts using configured strategy
  Future<List<ResolvedConflict>> resolveAllConflicts() async {
    final results = <ResolvedConflict>[];

    for (final conflict in _conflicts.where((c) => !c.isResolved)) {
      final result = await resolveConflict(conflict);
      if (result != null) {
        results.add(result);
      }
    }

    return results;
  }

  /// Resolve a single conflict
  Future<ResolvedConflict?> resolveConflict(
    SyncConflict conflict, {
    ConflictResolution? strategy,
  }) async {
    try {
      // Determine resolution strategy
      final resolution = strategy ?? await _determineResolution(conflict);

      Map<String, dynamic> resolvedData;

      switch (resolution) {
        case ConflictResolution.keepLocal:
          resolvedData = Map.from(conflict.localData);
          break;

        case ConflictResolution.keepServer:
          resolvedData = _mapServerDataToLocal(conflict.serverData);
          break;

        case ConflictResolution.merge:
          resolvedData = await _mergeData(conflict);
          break;

        case ConflictResolution.duplicate:
          resolvedData = await _createDuplicate(conflict);
          break;

        case ConflictResolution.manual:
          if (_config.onManualResolution != null) {
            final manualResolution =
                await _config.onManualResolution!(conflict);
            return resolveConflict(conflict, strategy: manualResolution);
          }
          return null;
      }

      // Apply resolution to database
      await _applyResolution(conflict, resolvedData);

      // Mark as resolved
      final resolvedConflict = conflict.copyWith(
        resolution: resolution,
        isResolved: true,
      );

      _conflicts.remove(conflict);
      _resolvedConflicts.add(resolvedConflict);

      _logger.i('Conflict resolved: ${conflict.id} with $resolution');

      return ResolvedConflict(
        conflict: resolvedConflict,
        resolvedData: resolvedData,
        resolution: resolution,
      );
    } catch (e, stackTrace) {
      _logger.e('Error resolving conflict: ${conflict.id}',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Determine resolution strategy for a conflict
  Future<ConflictResolution> _determineResolution(SyncConflict conflict) async {
    // Check table-specific strategy
    final tableStrategy = _config.tableStrategies[conflict.tableName];
    if (tableStrategy != null) {
      return tableStrategy;
    }

    // If not auto-resolve, return manual
    if (!_config.autoResolve) {
      return ConflictResolution.manual;
    }

    // Default: use timestamp-based resolution
    // Keep the more recent change
    if (conflict.localModifiedAt.isAfter(conflict.serverModifiedAt)) {
      return ConflictResolution.keepLocal;
    }

    return _config.defaultStrategy;
  }

  /// Map server data to local format
  Map<String, dynamic> _mapServerDataToLocal(Map<String, dynamic> serverData) {
    final localData = Map<String, dynamic>.from(serverData);

    // Map server 'id' to 'server_id'
    if (serverData.containsKey('id')) {
      localData[DbConstants.colServerId] = serverData['id'].toString();
      localData.remove('id');
    }

    // Map timestamp fields
    if (serverData.containsKey('created_at')) {
      localData[DbConstants.colCreatedAt] = serverData['created_at'];
    }
    if (serverData.containsKey('updated_at')) {
      localData[DbConstants.colUpdatedAt] = serverData['updated_at'];
    }

    // Set sync status
    localData[DbConstants.colSyncStatus] = 'synced';

    return localData;
  }

  /// Merge local and server data
  Future<Map<String, dynamic>> _mergeData(SyncConflict conflict) async {
    final merged = <String, dynamic>{};
    final localData = conflict.localData;
    final serverData = conflict.serverData;

    // Get all fields
    final allFields = {...localData.keys, ...serverData.keys};

    for (final field in allFields) {
      final localValue = localData[field];
      final serverValue = serverData[field];

      // Check field-specific strategy
      final fieldStrategy = _config.getStrategyForField(
        conflict.tableName,
        field,
      );

      if (fieldStrategy == ConflictResolution.keepLocal ||
          _config.alwaysLocalFields.contains(field)) {
        merged[field] = localValue;
      } else if (fieldStrategy == ConflictResolution.keepServer ||
          _config.alwaysServerFields.contains(field)) {
        merged[field] = serverValue;
      } else if (_valuesEqual(localValue, serverValue)) {
        // Values are same, use either
        merged[field] = localValue ?? serverValue;
      } else {
        // Conflict on this field - use newer value
        if (conflict.localModifiedAt.isAfter(conflict.serverModifiedAt)) {
          merged[field] = localValue;
        } else {
          merged[field] = serverValue;
        }
      }
    }

    // Ensure sync status is set
    merged[DbConstants.colSyncStatus] = 'pending';
    merged[DbConstants.colUpdatedAt] = DateTime.now().toIso8601String();

    return merged;
  }

  /// Create a duplicate record
  Future<Map<String, dynamic>> _createDuplicate(SyncConflict conflict) async {
    // Apply server data as the main record
    final serverMapped = _mapServerDataToLocal(conflict.serverData);

    // Keep local data as a new record (will be synced as new)
    final localData = Map<String, dynamic>.from(conflict.localData);
    localData.remove(DbConstants.colLocalId);
    localData.remove(DbConstants.colServerId);
    localData[DbConstants.colSyncStatus] = 'pending';
    localData[DbConstants.colCreatedAt] = DateTime.now().toIso8601String();
    localData[DbConstants.colUpdatedAt] = DateTime.now().toIso8601String();

    // Insert local as new record
    await _dbHelper.insert(conflict.tableName, localData);

    return serverMapped;
  }

  /// Apply resolution to database
  Future<void> _applyResolution(
    SyncConflict conflict,
    Map<String, dynamic> resolvedData,
  ) async {
    await _dbHelper.update(
      conflict.tableName,
      resolvedData,
      where: '${DbConstants.colLocalId} = ?',
      whereArgs: [conflict.localId],
    );
  }

  // ==================== BATCH OPERATIONS ====================

  /// Resolve conflicts for a specific table
  Future<List<ResolvedConflict>> resolveTableConflicts(
    String tableName, {
    ConflictResolution? strategy,
  }) async {
    final tableConflicts = _conflicts
        .where((c) => c.tableName == tableName && !c.isResolved)
        .toList();

    final results = <ResolvedConflict>[];

    for (final conflict in tableConflicts) {
      final result = await resolveConflict(conflict, strategy: strategy);
      if (result != null) {
        results.add(result);
      }
    }

    return results;
  }

  /// Resolve all conflicts with a specific strategy
  Future<List<ResolvedConflict>> resolveAllWithStrategy(
    ConflictResolution strategy,
  ) async {
    final results = <ResolvedConflict>[];

    for (final conflict in _conflicts.where((c) => !c.isResolved).toList()) {
      final result = await resolveConflict(conflict, strategy: strategy);
      if (result != null) {
        results.add(result);
      }
    }

    return results;
  }

  // ==================== UTILITIES ====================

  /// Parse datetime from string or DateTime
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Clear all conflicts
  void clearConflicts() {
    _conflicts.clear();
    _resolvedConflicts.clear();
  }

  /// Remove resolved conflicts
  void clearResolvedConflicts() {
    _resolvedConflicts.clear();
  }

  /// Get conflicts for a specific table
  List<SyncConflict> getConflictsForTable(String tableName) {
    return _conflicts.where((c) => c.tableName == tableName).toList();
  }

  /// Get unresolved conflicts
  List<SyncConflict> getUnresolvedConflicts() {
    return _conflicts.where((c) => !c.isResolved).toList();
  }

  /// Export conflicts to JSON
  String exportConflictsToJson() {
    return jsonEncode({
      'conflicts': _conflicts
          .map((c) => {
                'id': c.id,
                'table': c.tableName,
                'localId': c.localId,
                'serverId': c.serverId,
                'localData': c.localData,
                'serverData': c.serverData,
                'localModifiedAt': c.localModifiedAt.toIso8601String(),
                'serverModifiedAt': c.serverModifiedAt.toIso8601String(),
                'isResolved': c.isResolved,
                'resolution': c.resolution?.name,
              })
          .toList(),
      'resolved': _resolvedConflicts
          .map((c) => {
                'id': c.id,
                'table': c.tableName,
                'resolution': c.resolution?.name,
              })
          .toList(),
    });
  }
}

// ==================== RESOLVED CONFLICT ====================

/// Result of conflict resolution
class ResolvedConflict {
  final SyncConflict conflict;
  final Map<String, dynamic> resolvedData;
  final ConflictResolution resolution;
  final DateTime resolvedAt;

  ResolvedConflict({
    required this.conflict,
    required this.resolvedData,
    required this.resolution,
    DateTime? resolvedAt,
  }) : resolvedAt = resolvedAt ?? DateTime.now();
}

// ==================== CONFLICT DIALOG DATA ====================

/// Data for conflict resolution dialog
class ConflictDialogData {
  final SyncConflict conflict;
  final List<ConflictFieldDiff> fieldDiffs;

  ConflictDialogData({
    required this.conflict,
  }) : fieldDiffs = _generateFieldDiffs(conflict);

  static List<ConflictFieldDiff> _generateFieldDiffs(SyncConflict conflict) {
    final diffs = <ConflictFieldDiff>[];
    final allFields = {
      ...conflict.localData.keys,
      ...conflict.serverData.keys,
    };

    final excludeFields = {
      DbConstants.colLocalId,
      DbConstants.colServerId,
      DbConstants.colSyncStatus,
      'id',
    };

    for (final field in allFields) {
      if (excludeFields.contains(field)) continue;

      final localValue = conflict.localData[field];
      final serverValue = conflict.serverData[field];

      if (localValue?.toString() != serverValue?.toString()) {
        diffs.add(ConflictFieldDiff(
          fieldName: field,
          localValue: localValue,
          serverValue: serverValue,
        ));
      }
    }

    return diffs;
  }
}

/// Field difference in conflict
class ConflictFieldDiff {
  final String fieldName;
  final dynamic localValue;
  final dynamic serverValue;
  dynamic selectedValue;

  ConflictFieldDiff({
    required this.fieldName,
    this.localValue,
    this.serverValue,
  }) : selectedValue = serverValue; // Default to server

  bool get hasConflict => localValue?.toString() != serverValue?.toString();

  String get localValueString => _formatValue(localValue);
  String get serverValueString => _formatValue(serverValue);

  String _formatValue(dynamic value) {
    if (value == null) return '(empty)';
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is double) return value.toStringAsFixed(2);
    return value.toString();
  }

  void selectLocal() => selectedValue = localValue;
  void selectServer() => selectedValue = serverValue;
}
*/
