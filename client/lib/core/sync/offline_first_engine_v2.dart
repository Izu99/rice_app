// The entire content of this file is commented out because it relies on DbHelper,
// which is part of the removed local SQLite storage.
// This file is no longer relevant for the API-only architecture.

/*
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/sync_queue_model.dart';
import '../constants/db_constants.dart';
import '../database/db_helper.dart';
import '../network/api_service.dart';
import '../network/network_info.dart';

class OfflineFirstEngineV2 extends ChangeNotifier {
  final DbHelper _dbHelper;
  final ApiService _apiService;
  final NetworkInfo _networkInfo;
  final SharedPreferences _prefs;
  final Logger _logger = Logger();
  final uuid = Uuid();

  // Sync state
  bool _isSyncing = false;
  DateTime? _lastSuccessfulSync;
  Duration _serverTimeOffset = Duration.zero;  // ← FIX: Clock drift
  Timer? _backgroundSyncTimer;
  StreamSubscription<bool>? _connectivitySubscription;

  // Configuration
  final Duration backgroundSyncInterval;
  final int maxRetries;
  final Duration retryDelay;
  final Duration syncTimeout;

  // Callbacks
  void Function(String)? onSyncStatusChange;
  void Function(String)? onError;

  OfflineFirstEngineV2({
    required DbHelper dbHelper,
    required ApiService apiService,
    required NetworkInfo networkInfo,
    required SharedPreferences prefs,
    this.backgroundSyncInterval = const Duration(minutes: 5),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 5),
    this.syncTimeout = const Duration(seconds: 30),  // ← FIX: Timeout
    this.onSyncStatusChange,
    this.onError,
  })  : _dbHelper = dbHelper,
        _apiService = apiService,
        _networkInfo = networkInfo,
        _prefs = prefs {
    _loadLastSyncTime();
    _loadServerTimeOffset();
    _initConnectivityListener();
  }

  // ==================== GETTERS ====================

  bool get isSyncing => _isSyncing;
  DateTime? get lastSuccessfulSync => _lastSuccessfulSync;
  bool get isOnline => _networkInfo.isConnected;
  bool get hasUnsyncedChanges => _dbHelper.syncQueue.hasPendingOperations();

  // ==================== INITIALIZATION ====================

  void initialize() {
    _logger.i('🚀 Offline-First Engine V2 initialized (Production Ready)');
    _logger.i('   ✅ Clock drift handling enabled');
    _logger.i('   ✅ Conflict audit trail enabled');
    _logger.i('   ✅ Data validation enabled');
    startBackgroundSync();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = _networkInfo.onConnectivityChanged.listen((isConnected) {
      _logger.i('📡 Connectivity changed: $isConnected');
      if (isConnected && !_isSyncing) {
        _logger.i('🔄 Triggering sync due to connectivity');
        _triggerBackgroundSync();
      }
    });
  }

  void _loadLastSyncTime() {
    final lastSync = _prefs.getString('lastSuccessfulSync');
    if (lastSync != null) {
      _lastSuccessfulSync = DateTime.parse(lastSync);
      _logger.i('📅 Last successful sync: $_lastSuccessfulSync');
    }
  }

  void _loadServerTimeOffset() {
    final offset = _prefs.getInt('serverTimeOffset');
    if (offset != null) {
      _serverTimeOffset = Duration(milliseconds: offset);
      _logger.i('⏱️  Server time offset: ${_serverTimeOffset.inSeconds}s');
    }
  }

  void startBackgroundSync() {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = Timer.periodic(backgroundSyncInterval, (_) {
      if (!_isSyncing && isOnline) {
        _logger.i('⏰ Background sync timer triggered');
        _triggerBackgroundSync();
      }
    });
  }

  // ==================== MAIN OPERATIONS ====================

  Future<String> addStockItem({
    required String name,
    required String itemType,
    required double totalBags,
    required double totalWeightKg,
    required double pricePerKg,
  }) async {
    final id = uuid.v4();
    final now = _getServerTime();  // ← FIX: Use server time

    _logger.i('📦 Adding stock item: $name (offline)');

    await _dbHelper.insert('stock', {
      'id': id,
      'name': name,
      'itemType': itemType,
      'totalBags': totalBags,
      'totalWeightKg': totalWeightKg,
      'pricePerKg': pricePerKg,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'syncStatus': 'PENDING',
      'isActive': 1,
    });

    await _dbHelper.syncQueue.add(
      id: uuid.v4(),
      entityType: SyncEntityType.stock,
      entityId: id,
      operation: SyncOperation.create,
      payload: {
        '_id': id,
        'name': name,
        'itemType': itemType,
        'totalBags': totalBags,
        'totalWeightKg': totalWeightKg,
        'pricePerKg': pricePerKg,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
    );

    _logger.i('✅ Stock item added to SQLite');
    notifyListeners();
    return id;
  }

  Future<void> updateStockItem({
    required String id,
    required double totalBags,
    required double totalWeightKg,
    required double pricePerKg,
  }) async {
    final now = _getServerTime();

    _logger.i('📝 Updating stock item: $id (offline)');

    await _dbHelper.update(
      'stock',
      {
        'totalBags': totalBags,
        'totalWeightKg': totalWeightKg,
        'pricePerKg': pricePerKg,
        'updatedAt': now.toIso8601String(),
        'syncStatus': 'PENDING',
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    await _dbHelper.syncQueue.add(
      id: uuid.v4(),
      entityType: SyncEntityType.stock,
      entityId: id,
      operation: SyncOperation.update,
      payload: {
        '_id': id,
        'totalBags': totalBags,
        'totalWeightKg': totalWeightKg,
        'pricePerKg': pricePerKg,
        'updatedAt': now.toIso8601String(),
      },
    );

    _logger.i('✅ Stock item updated in SQLite');
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getStockItems() async {
    _logger.i('📦 Fetching stock items from SQLite');
    final items = await _dbHelper.query(
      'stock',
      where: 'isActive = 1',
      orderBy: 'updatedAt DESC',
    );
    _logger.i('   Found ${items.length} items');
    return items;
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    _logger.i('💳 Fetching transactions from SQLite');
    final txs = await _dbHelper.query(
      'transactions',
      where: 'isActive = 1',
      orderBy: 'createdAt DESC',
    );
    _logger.i('   Found ${txs.length} transactions');
    return txs;
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    _logger.i('👥 Fetching customers from SQLite');
    final customers = await _dbHelper.query(
      'customers',
      where: 'isActive = 1',
      orderBy: 'name ASC',
    );
    _logger.i('   Found ${customers.length} customers');
    return customers;
  }

  // ==================== BACKGROUND SYNC ====================

  void _triggerBackgroundSync() {
    if (_isSyncing || !isOnline) return;
    _backgroundSync();
  }

  Future<void> _backgroundSync() async {
    if (_isSyncing) {
      _logger.w('⚠️  Sync already in progress');
      return;
    }

    _isSyncing = true;
    onSyncStatusChange?.call('Syncing...');
    notifyListeners();

    try {
      _logger.i('🔄 === BACKGROUND SYNC START ===');

      final pending = await _dbHelper.syncQueue.getPendingOperations();

      if (pending.isEmpty) {
        _logger.i('✅ No pending operations');
        _isSyncing = false;
        onSyncStatusChange?.call('Synced');
        notifyListeners();
        return;
      }

      _logger.i('📤 Pushing ${pending.length} operations to server');

      // FIX: Correct order - push, pull, merge, THEN mark synced
      await _pushToServer(pending);
      final response = await _pullFromServer();
      await _mergeServerChanges(response);

      // FIX: Update lastSyncTime AFTER successful merge
      _lastSuccessfulSync = DateTime.now();
      await _prefs.setString('lastSuccessfulSync', _lastSuccessfulSync!.toIso8601String());

      _logger.i('✅ === BACKGROUND SYNC COMPLETE ===');
      onSyncStatusChange?.call('Synced');
    } catch (error) {
      _logger.e('❌ Sync error: $error');
      onError?.call(error.toString());
      onSyncStatusChange?.call('Sync failed (will retry)');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _pushToServer(List<SyncQueueModel> operations) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        _logger.i('📤 Push attempt $attempt/$maxRetries');

        final payload = {
          'operations': operations.map((op) => _operationToJson(op)).toList(),
          'lastSyncTime': _lastSuccessfulSync?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'deviceId': _getDeviceId(),
        };

        // FIX: Add timeout
        final response = await _apiService.post('/sync/push', data: payload)
            .timeout(syncTimeout, onTimeout: () {
          throw TimeoutException('Push timeout after ${syncTimeout.inSeconds}s');
        });

        final results = response['results'] as List? ?? [];
        for (final result in results) {
          if (result['status'] == 'success') {
            await _dbHelper.syncQueue.markSynced(result['clientId']);
            _logger.i('✅ Synced: ${result['clientId']}');
          } else {
            _logger.w('⚠️  Failed: ${result['clientId']} - ${result['error']}');
          }
        }

        _logger.i('✅ Push complete');
        return;
      } catch (error) {
        _logger.w('⚠️  Push attempt $attempt failed: $error');

        if (attempt < maxRetries) {
          await Future.delayed(retryDelay * attempt);
        } else {
          _logger.e('❌ Push failed after $maxRetries attempts');
          rethrow;
        }
      }
    }
  }

  // FIX: Pull with retry logic
  Future<Map<String, dynamic>> _pullFromServer() async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        _logger.i('📥 Pull attempt $attempt/$maxRetries');

        final lastSync = _lastSuccessfulSync ?? DateTime.now().subtract(Duration(days: 30));

        final response = await _apiService.get(
          '/sync/pull',
          queryParameters: {'lastSyncTime': lastSync.toIso8601String()},
        ).timeout(syncTimeout, onTimeout: () {
          throw TimeoutException('Pull timeout after ${syncTimeout.inSeconds}s');
        });

        // FIX: Store server time offset on first sync
        if (response['serverTime'] != null) {
          final serverTime = DateTime.parse(response['serverTime']);
          _serverTimeOffset = serverTime.difference(DateTime.now());
          await _prefs.setInt('serverTimeOffset', _serverTimeOffset.inMilliseconds);
          _logger.i('⏱️  Updated server time offset: ${_serverTimeOffset.inSeconds}s');
        }

        _logger.i('✅ Pull complete');
        return response;
      } catch (error) {
        _logger.w('⚠️  Pull attempt $attempt failed: $error');

        if (attempt < maxRetries) {
          await Future.delayed(retryDelay * attempt);
        } else {
          _logger.e('❌ Pull failed after $maxRetries attempts');
          rethrow;
        }
      }
    }

    throw Exception('Pull failed');
  }

  Future<void> _mergeServerChanges(Map<String, dynamic> changes) async {
    _logger.i('🔀 Merging server changes');

    final stockItems = changes['stockItems'] as List? ?? [];
    for (final item in stockItems) {
      await _mergeStockItem(item);
    }
    _logger.i('   Merged ${stockItems.length} stock items');

    final transactions = changes['transactions'] as List? ?? [];
    for (final tx in transactions) {
      await _mergeTransaction(tx);
    }
    _logger.i('   Merged ${transactions.length} transactions');

    final customers = changes['customers'] as List? ?? [];
    for (final customer in customers) {
      await _mergeCustomer(customer);
    }
    _logger.i('   Merged ${customers.length} customers');
  }

  Future<void> _mergeStockItem(Map<String, dynamic> serverItem) async {
    final id = serverItem['_id'] ?? serverItem['id'];
    final local = await _dbHelper.query('stock', where: 'id = ?', whereArgs: [id]);

    if (local.isEmpty) {
      await _dbHelper.insert('stock', _normalizeData(serverItem));
      _logger.d('   ✅ Inserted new stock item: $id');
      return;
    }

    final localData = local.first;
    final resolved = _resolveStockConflict(localData, serverItem);

    // FIX: Validate before saving
    if (!_validateStockData(resolved)) {
      _logger.e('   ❌ Validation failed for stock item: $id');
      await _logConflict('stock', id, localData, serverItem, 'validation_failed');
      return;
    }

    // FIX: Handle soft deletes
    if (serverItem['isActive'] == false || serverItem['isDeleted'] == true) {
      await _dbHelper.update('stock', {'isActive': 0}, where: 'id = ?', whereArgs: [id]);
      _logger.i('   🗑️  Soft deleted stock item: $id');
      return;
    }

    await _dbHelper.update('stock', resolved, where: 'id = ?', whereArgs: [id]);
    _logger.d('   ✅ Merged stock item: $id (${resolved['_conflictResolution'] ?? 'no conflict'})');

    // FIX: Log conflict if one occurred
    if (resolved['_conflictResolution'] != null) {
      await _logConflict('stock', id, localData, serverItem, resolved['_conflictResolution']);
    }
  }

  // FIX: Correct conflict resolution order
  Map<String, dynamic> _resolveStockConflict(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) {
    final lastSync = _lastSuccessfulSync ?? DateTime.now();
    final localUpdated = DateTime.parse(local['updatedAt'] ?? local['createdAt'] ?? '');
    final serverUpdated = DateTime.parse(server['updatedAt'] ?? server['createdAt'] ?? '');

    _logger.i('🔀 [CONFLICT] Stock item conflict detected');
    _logger.i('   Local:  ${local['totalBags']} bags (${localUpdated.toIso8601String()})');
    _logger.i('   Server: ${server['totalBags']} bags (${serverUpdated.toIso8601String()})');
    _logger.i('   LastSync: ${lastSync.toIso8601String()}');

    // FIX: Check BOTH updated FIRST
    if (localUpdated.isAfter(lastSync) && serverUpdated.isAfter(lastSync)) {
      if (serverUpdated.isAfter(localUpdated)) {
        _logger.w('   ⚠️  CONFLICT: Both updated, server newer (${serverUpdated.difference(localUpdated).inSeconds}s)');
        return {
          ..._normalizeData(server),
          '_conflictResolution': 'conflict_server_newer',
        };
      } else {
        _logger.w('   ⚠️  CONFLICT: Both updated, local newer');
        return {
          ...local,
          '_conflictResolution': 'conflict_local_newer',
        };
      }
    }

    // Server updated after sync
    if (serverUpdated.isAfter(lastSync)) {
      _logger.i('   → Server updated after sync, using server value');
      return {
        ..._normalizeData(server),
        '_conflictResolution': 'server_newer_than_sync',
      };
    }

    // Client updated after sync
    if (localUpdated.isAfter(lastSync)) {
      _logger.i('   → Client has new offline changes, keeping local value');
      return {
        ...local,
        '_conflictResolution': 'client_newer_than_sync',
      };
    }

    // Neither updated: use newer
    if (serverUpdated.isAfter(localUpdated)) {
      _logger.i('   → Both old, server newer, using server');
      return {
        ..._normalizeData(server),
        '_conflictResolution': 'both_old_server_newer',
      };
    }

    _logger.i('   → Both old, local newer, keeping local');
    return {
      ...local,
      '_conflictResolution': 'both_old_local_newer',
    };
  }

  Future<void> _mergeTransaction(Map<String, dynamic> serverTx) async {
    final id = serverTx['_id'] ?? serverTx['id'];
    final local = await _dbHelper.query('transactions', where: 'id = ?', whereArgs: [id]);

    if (local.isEmpty) {
      await _dbHelper.insert('transactions', _normalizeData(serverTx));
      _logger.d('   ✅ Inserted new transaction: $id');
      return;
    }

    final localData = local.first;
    final resolved = _resolveTransactionConflict(localData, serverTx);

    if (!_validateTransactionData(resolved)) {
      _logger.e('   ❌ Validation failed for transaction: $id');
      await _logConflict('transaction', id, localData, serverTx, 'validation_failed');
      return;
    }

    if (serverTx['isActive'] == false) {
      await _dbHelper.update('transactions', {'isActive': 0}, where: 'id = ?', whereArgs: [id]);
      _logger.i('   🗑️  Soft deleted transaction: $id');
      return;
    }

    await _dbHelper.update('transactions', resolved, where: 'id = ?', whereArgs: [id]);
    _logger.d('   ✅ Merged transaction: $id');

    if (resolved['_conflictResolution'] != null) {
      await _logConflict('transaction', id, localData, serverTx, resolved['_conflictResolution']);
    }
  }

  Map<String, dynamic> _resolveTransactionConflict(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) {
    final lastSync = _lastSuccessfulSync ?? DateTime.now();
    final localUpdated = DateTime.parse(local['updatedAt'] ?? local['createdAt'] ?? '');
    final serverUpdated = DateTime.parse(server['updatedAt'] ?? server['createdAt'] ?? '');

    if (localUpdated.isAfter(lastSync) && serverUpdated.isAfter(lastSync)) {
      return serverUpdated.isAfter(localUpdated)
          ? {..._normalizeData(server), '_conflictResolution': 'conflict_server_newer'}
          : {...local, '_conflictResolution': 'conflict_local_newer'};
    }

    if (serverUpdated.isAfter(lastSync)) {
      return {..._normalizeData(server), '_conflictResolution': 'server_newer_than_sync'};
    }

    if (localUpdated.isAfter(lastSync)) {
      return {...local, '_conflictResolution': 'client_newer_than_sync'};
    }

    return serverUpdated.isAfter(localUpdated)
        ? {..._normalizeData(server), '_conflictResolution': 'both_old_server_newer'}
        : {...local, '_conflictResolution': 'both_old_local_newer'};
  }

  Future<void> _mergeCustomer(Map<String, dynamic> serverCustomer) async {
    final id = serverCustomer['_id'] ?? serverCustomer['id'];
    final local = await _dbHelper.query('customers', where: 'id = ?', whereArgs: [id]);

    if (local.isEmpty) {
      await _dbHelper.insert('customers', _normalizeData(serverCustomer));
      _logger.d('   ✅ Inserted new customer: $id');
      return;
    }

    final localData = local.first;
    final resolved = _resolveCustomerConflict(localData, serverCustomer);

    if (serverCustomer['isActive'] == false) {
      await _dbHelper.update('customers', {'isActive': 0}, where: 'id = ?', whereArgs: [id]);
      _logger.i('   🗑️  Soft deleted customer: $id');
      return;
    }

    await _dbHelper.update('customers', resolved, where: 'id = ?', whereArgs: [id]);
    _logger.d('   ✅ Merged customer: $id');

    if (resolved['_conflictResolution'] != null) {
      await _logConflict('customer', id, localData, serverCustomer, resolved['_conflictResolution']);
    }
  }

  Map<String, dynamic> _resolveCustomerConflict(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) {
    final lastSync = _lastSuccessfulSync ?? DateTime.now();
    final localUpdated = DateTime.parse(local['updatedAt'] ?? local['createdAt'] ?? '');
    final serverUpdated = DateTime.parse(server['updatedAt'] ?? server['createdAt'] ?? '');

    if (localUpdated.isAfter(lastSync) && serverUpdated.isAfter(lastSync)) {
      return serverUpdated.isAfter(localUpdated)
          ? {..._normalizeData(server), '_conflictResolution': 'conflict_server_newer'}
          : {...local, '_conflictResolution': 'conflict_local_newer'};
    }

    if (serverUpdated.isAfter(lastSync)) {
      return {..._normalizeData(server), '_conflictResolution': 'server_newer_than_sync'};
    }

    if (localUpdated.isAfter(lastSync)) {
      return {...local, '_conflictResolution': 'client_newer_than_sync'};
    }

    return serverUpdated.isAfter(localUpdated)
        ? {..._normalizeData(server), '_conflictResolution': 'both_old_server_newer'}
        : {...local, '_conflictResolution': 'both_old_local_newer'};
  }

  // ==================== VALIDATION ====================

  bool _validateStockData(Map<String, dynamic> data) {
    if ((data['totalBags'] ?? 0) < 0) {
      _logger.e('   ❌ Validation: totalBags is negative');
      return false;
    }
    if ((data['totalWeightKg'] ?? 0) < 0) {
      _logger.e('   ❌ Validation: totalWeightKg is negative');
      return false;
    }
    if ((data['pricePerKg'] ?? 0) < 0) {
      _logger.e('   ❌ Validation: pricePerKg is negative');
      return false;
    }
    return true;
  }

  bool _validateTransactionData(Map<String, dynamic> data) {
    if ((data['totalAmount'] ?? 0) < 0) {
      _logger.e('   ❌ Validation: totalAmount is negative');
      return false;
    }
    if ((data['items'] as List?)?.isEmpty ?? true) {
      _logger.e('   ❌ Validation: items list is empty');
      return false;
    }
    return true;
  }

  // ==================== AUDIT TRAIL ====================

  Future<void> _logConflict(
    String entityType,
    String entityId,
    Map<String, dynamic> local,
    Map<String, dynamic> server,
    String resolution,
  ) async {
    try {
      await _dbHelper.insert('sync_conflicts', {
        'id': uuid.v4(),
        'entityType': entityType,
        'entityId': entityId,
        'localValue': jsonEncode(local),
        'serverValue': jsonEncode(server),
        'resolution': resolution,
        'resolvedAt': DateTime.now().toIso8601String(),
        'deviceId': _getDeviceId(),
      });
      _logger.i('📝 Conflict logged: $entityType/$entityId → $resolution');
    } catch (error) {
      _logger.e('❌ Failed to log conflict: $error');
    }
  }

  // ==================== HELPERS ====================

  DateTime _getServerTime() {
    return DateTime.now().add(_serverTimeOffset);
  }

  Map<String, dynamic> _operationToJson(SyncQueueModel op) {
    return {
      'clientId': op.id,
      'entityType': _entityTypeToString(op.entityType),
      'operation': _operationToString(op.operation),
      'data': op.payload,
      'clientCreatedAt': op.createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _normalizeData(Map<String, dynamic> data) {
    return {
      ...data,
      'id': data['_id'] ?? data['id'],
      'syncStatus': 'SYNCED',
    };
  }

  String _getDeviceId() {
    var deviceId = _prefs.getString('deviceId');
    if (deviceId == null) {
      deviceId = uuid.v4();
      _prefs.setString('deviceId', deviceId);
    }
    return deviceId;
  }

  String _entityTypeToString(SyncEntityType type) {
    switch (type) {
      case SyncEntityType.customer:
        return 'customer';
      case SyncEntityType.stock:
        return 'stock_item';
      case SyncEntityType.transaction:
        return 'transaction';
      case SyncEntityType.payment:
        return 'payment';
      case SyncEntityType.milling:
        return 'milling_record';
      case SyncEntityType.user:
        return 'user';
    }
  }

  String _operationToString(SyncOperation op) {
    switch (op) {
      case SyncOperation.create:
        return 'create';
      case SyncOperation.update:
        return 'update';
      case SyncOperation.delete:
        return 'delete';
    }
  }

  @override
  void dispose() {
    _backgroundSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

enum SyncEntityType { customer, stock, transaction, payment, milling, user }
enum SyncOperation { create, update, delete }
*/
