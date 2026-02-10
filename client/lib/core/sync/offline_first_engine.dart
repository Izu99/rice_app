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

class OfflineFirstEngine extends ChangeNotifier {
  final DbHelper _dbHelper;
  final ApiService _apiService;
  final NetworkInfo _networkInfo;
  final SharedPreferences _prefs;
  final Logger _logger = Logger();
  final uuid = Uuid();

  // Sync state
  bool _isSyncing = false;
  DateTime? _lastSuccessfulSync;
  Timer? _backgroundSyncTimer;
  StreamSubscription<bool>? _connectivitySubscription;

  // Configuration
  final Duration backgroundSyncInterval;
  final int maxRetries;
  final Duration retryDelay;

  // Callbacks
  void Function(String)? onSyncStatusChange;
  void Function(String)? onError;

  OfflineFirstEngine({
    required DbHelper dbHelper,
    required ApiService apiService,
    required NetworkInfo networkInfo,
    required SharedPreferences prefs,
    this.backgroundSyncInterval = const Duration(minutes: 5),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 5),
    this.onSyncStatusChange,
    this.onError,
  })  : _dbHelper = dbHelper,
        _apiService = apiService,
        _networkInfo = networkInfo,
        _prefs = prefs {
    _loadLastSyncTime();
    _initConnectivityListener();
  }

  // ==================== GETTERS ====================

  bool get isSyncing => _isSyncing;
  DateTime? get lastSuccessfulSync => _lastSuccessfulSync;
  bool get isOnline => _networkInfo.isConnected;
  bool get hasUnsyncedChanges => _dbHelper.syncQueue.hasPendingOperations();

  // ==================== INITIALIZATION ====================

  void initialize() {
    _logger.i('🚀 Offline-First Engine initialized');
    _logger.i('   SQLite is source of truth');
    _logger.i('   MongoDB is optional backup');
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

  void startBackgroundSync() {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = Timer.periodic(backgroundSyncInterval, (_) {
      if (!_isSyncing && isOnline) {
        _logger.i('⏰ Background sync timer triggered');
        _triggerBackgroundSync();
      }
    });
  }

  // ==================== MAIN OPERATIONS (OFFLINE-FIRST) ====================

  /// Add stock item - WORKS OFFLINE IMMEDIATELY
  Future<String> addStockItem({
    required String name,
    required String itemType,
    required double totalBags,
    required double totalWeightKg,
    required double pricePerKg,
  }) async {
    final id = uuid.v4();
    final now = DateTime.now();

    _logger.i('📦 Adding stock item: $name (offline)');

    // 1. Insert into SQLite immediately (OFFLINE)
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

    // 2. Add to sync queue (for later server sync)
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

    _logger.i('✅ Stock item added to SQLite (will sync when online)');
    notifyListeners();
    return id;
  }

  /// Update stock item - WORKS OFFLINE IMMEDIATELY
  Future<void> updateStockItem({
    required String id,
    required double totalBags,
    required double totalWeightKg,
    required double pricePerKg,
  }) async {
    final now = DateTime.now();

    _logger.i('📝 Updating stock item: $id (offline)');

    // 1. Update SQLite immediately (OFFLINE)
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

    // 2. Add to sync queue
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

    _logger.i('✅ Stock item updated in SQLite (will sync when online)');
    notifyListeners();
  }

  /// Add transaction - WORKS OFFLINE IMMEDIATELY
  Future<String> addTransaction({
    required String type,
    required String customerId,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
  }) async {
    final id = uuid.v4();
    final now = DateTime.now();

    _logger.i('💳 Adding transaction: $type (offline)');

    // 1. Insert transaction into SQLite
    await _dbHelper.insert('transactions', {
      'id': id,
      'type': type,
      'customerId': customerId,
      'customerName': customerName,
      'totalAmount': totalAmount,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'syncStatus': 'PENDING',
      'isActive': 1,
    });

    // 2. Insert transaction items
    for (final item in items) {
      await _dbHelper.insert('transaction_items', {
        'id': uuid.v4(),
        'transactionId': id,
        'itemName': item['itemName'],
        'itemType': item['itemType'],
        'weightKg': item['weightKg'],
        'bags': item['bags'],
        'pricePerKg': item['pricePerKg'],
        'totalPrice': item['totalPrice'],
      });
    }

    // 3. Add to sync queue
    await _dbHelper.syncQueue.add(
      id: uuid.v4(),
      entityType: SyncEntityType.transaction,
      entityId: id,
      operation: SyncOperation.create,
      payload: {
        '_id': id,
        'type': type,
        'customerId': customerId,
        'customerName': customerName,
        'items': items,
        'totalAmount': totalAmount,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
    );

    _logger.i('✅ Transaction added to SQLite (will sync when online)');
    notifyListeners();
    return id;
  }

  /// Get all stock items - FROM SQLITE (ALWAYS WORKS)
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

  /// Get all transactions - FROM SQLITE (ALWAYS WORKS)
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

  /// Get all customers - FROM SQLITE (ALWAYS WORKS)
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

  // ==================== BACKGROUND SYNC (OPTIONAL) ====================

  /// Trigger background sync (fire-and-forget)
  void _triggerBackgroundSync() {
    if (_isSyncing || !isOnline) return;
    _backgroundSync();
  }

  /// Background sync - doesn't block user operations
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

      // Get pending operations
      final pending = await _dbHelper.syncQueue.getPendingOperations();

      if (pending.isEmpty) {
        _logger.i('✅ No pending operations');
        _isSyncing = false;
        onSyncStatusChange?.call('Synced');
        notifyListeners();
        return;
      }

      _logger.i('📤 Pushing ${pending.length} operations to server');

      // Push to server (with retries)
      await _pushToServer(pending);

      // Pull changes from server
      await _pullFromServer();

      // Mark sync as successful
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

  /// Push pending operations to server (with retries)
  Future<void> _pushToServer(List<SyncQueueModel> operations) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        _logger.i('📤 Push attempt $attempt/$maxRetries');

        final payload = {
          'operations': operations.map((op) => _operationToJson(op)).toList(),
          'lastSyncTime': _lastSuccessfulSync?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'deviceId': _getDeviceId(),
        };

        final response = await _apiService.post('/sync/push', data: payload);

        // Process results
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

  /// Pull changes from server
  Future<void> _pullFromServer() async {
    try {
      _logger.i('📥 Pulling changes from server');

      final lastSync = _lastSuccessfulSync ?? DateTime.now().subtract(Duration(days: 30));

      final response = await _apiService.get(
        '/sync/pull',
        queryParameters: {'lastSyncTime': lastSync.toIso8601String()},
      );

      // Merge server changes into SQLite
      await _mergeServerChanges(response);

      _logger.i('✅ Pull complete');
    } catch (error) {
      _logger.e('❌ Pull error: $error');
      // Don't rethrow - pull failure shouldn't block sync
    }
  }

  /// Merge server changes into SQLite
  Future<void> _mergeServerChanges(Map<String, dynamic> changes) async {
    _logger.i('🔀 Merging server changes');

    // Merge stock items
    final stockItems = changes['stockItems'] as List? ?? [];
    for (final item in stockItems) {
      await _mergeStockItem(item);
    }
    _logger.i('   Merged ${stockItems.length} stock items');

    // Merge transactions
    final transactions = changes['transactions'] as List? ?? [];
    for (final tx in transactions) {
      await _mergeTransaction(tx);
    }
    _logger.i('   Merged ${transactions.length} transactions');

    // Merge customers
    final customers = changes['customers'] as List? ?? [];
    for (final customer in customers) {
      await _mergeCustomer(customer);
    }
    _logger.i('   Merged ${customers.length} customers');
  }

  /// Merge stock item from server with conflict resolution
  Future<void> _mergeStockItem(Map<String, dynamic> serverItem) async {
    final id = serverItem['_id'] ?? serverItem['id'];
    final local = await _dbHelper.query('stock', where: 'id = ?', whereArgs: [id]);

    if (local.isEmpty) {
      // New item from server
      await _dbHelper.insert('stock', _normalizeData(serverItem));
      _logger.d('   ✅ Inserted new stock item: $id');
      return;
    }

    // Item exists locally - check for conflict
    final localData = local.first;
    final resolved = _resolveStockConflict(localData, serverItem);

    await _dbHelper.update('stock', resolved, where: 'id = ?', whereArgs: [id]);
    _logger.d('   ✅ Merged stock item: $id (${resolved['_conflictResolution'] ?? 'no conflict'})');
  }

  /// Resolve stock item conflict using timestamp-based strategy
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

    // Scenario 1: Server updated AFTER lastSync
    if (serverUpdated.isAfter(lastSync)) {
      _logger.i('   → Server updated after sync, using server value');
      return {
        ..._normalizeData(server),
        '_conflictResolution': 'server_newer_than_sync',
      };
    }

    // Scenario 2: Client updated AFTER lastSync
    if (localUpdated.isAfter(lastSync)) {
      _logger.i('   → Client has new offline changes, keeping local value');
      return {
        ...local,
        '_conflictResolution': 'client_newer_than_sync',
      };
    }

    // Scenario 3: Both updated AFTER lastSync (true conflict)
    if (localUpdated.isAfter(lastSync) && serverUpdated.isAfter(lastSync)) {
      if (serverUpdated.isAfter(localUpdated)) {
        _logger.w('   ⚠️  CONFLICT: Both updated, server newer, using server');
        return {
          ..._normalizeData(server),
          '_conflictResolution': 'conflict_server_newer',
        };
      } else {
        _logger.w('   ⚠️  CONFLICT: Both updated, local newer, keeping local');
        return {
          ...local,
          '_conflictResolution': 'conflict_local_newer',
        };
      }
    }

    // Scenario 4: Neither updated after sync (use newer)
    if (serverUpdated.isAfter(localUpdated)) {
      _logger.i('   → Both old, server newer, using server');
      return {
        ..._normalizeData(server),
        '_conflictResolution': 'both_old_server_newer',
      };
    }

    _logger.i('   → Both old, local newer');
    return {
      ...local,
      '_conflictResolution': 'both_old_local_newer',
    };
  }

  /// Merge transaction from server with conflict resolution
  Future<void> _mergeTransaction(Map<String, dynamic> serverTx) async {
    final id = serverTx['_id'] ?? serverTx['id'];
    final local = await _dbHelper.query('transactions', where: 'id = ?', whereArgs: [id]);

    if (local.isEmpty) {
      // New transaction from server
      await _dbHelper.insert('transactions', _normalizeData(serverTx));
      _logger.d('   ✅ Inserted new transaction: $id');
    } else {
      // Transaction exists - resolve conflict
      final localData = local.first;
      final resolved = _resolveTransactionConflict(localData, serverTx);

      await _dbHelper.update('transactions', resolved, where: 'id = ?', whereArgs: [id]);
      _logger.d('   ✅ Merged transaction: $id (${resolved['_conflictResolution'] ?? 'no conflict'})');
    }
  }

  /// Resolve transaction conflict
  Map<String, dynamic> _resolveTransactionConflict(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) {
    final lastSync = _lastSuccessfulSync ?? DateTime.now();
    final localUpdated = DateTime.parse(local['updatedAt'] ?? local['createdAt'] ?? '');
    final serverUpdated = DateTime.parse(server['updatedAt'] ?? server['createdAt'] ?? '');

    _logger.i('🔀 [CONFLICT] Transaction conflict detected');
    _logger.i('   Local:  ${local['totalAmount']} (${localUpdated.toIso8601String()})');
    _logger.i('   Server: ${server['totalAmount']} (${serverUpdated.toIso8601String()})');

    // Server updated after sync → use server
    if (serverUpdated.isAfter(lastSync)) {
      _logger.i('   → Server updated after sync, using server value');
      return {
        ..._normalizeData(server),
        '_conflictResolution': 'server_newer_than_sync',
      };
    }

    // Client updated after sync → keep local
    if (localUpdated.isAfter(lastSync)) {
      _logger.i('   → Client has new offline changes, keeping local value');
      return {
        ...local,
        '_conflictResolution': 'client_newer_than_sync',
      };
    }

    // Both updated after sync → use newer
    if (localUpdated.isAfter(lastSync) && serverUpdated.isAfter(lastSync)) {
      if (serverUpdated.isAfter(localUpdated)) {
        _logger.w('   ⚠️  CONFLICT: Both updated, server newer');
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

    // Neither updated after sync → use newer
    if (serverUpdated.isAfter(localUpdated)) {
      _logger.i('   → Both old, server newer');
      return {
        ..._normalizeData(server),
        '_conflictResolution': 'both_old_server_newer',
      };
    }

    _logger.i('   → Both old, local newer');
    return {
      ...local,
      '_conflictResolution': 'both_old_local_newer',
    };
  }

  /// Merge customer from server with conflict resolution
  Future<void> _mergeCustomer(Map<String, dynamic> serverCustomer) async {
    final id = serverCustomer['_id'] ?? serverCustomer['id'];
    final local = await _dbHelper.query('customers', where: 'id = ?', whereArgs: [id]);

    if (local.isEmpty) {
      // New customer from server
      await _dbHelper.insert('customers', _normalizeData(serverCustomer));
      _logger.d('   ✅ Inserted new customer: $id');
    } else {
      // Customer exists - resolve conflict
      final localData = local.first;
      final resolved = _resolveCustomerConflict(localData, serverCustomer);

      await _dbHelper.update('customers', resolved, where: 'id = ?', whereArgs: [id]);
      _logger.d('   ✅ Merged customer: $id (${resolved['_conflictResolution'] ?? 'no conflict'})');
    }
  }

  /// Resolve customer conflict
  Map<String, dynamic> _resolveCustomerConflict(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) {
    final lastSync = _lastSuccessfulSync ?? DateTime.now();
    final localUpdated = DateTime.parse(local['updatedAt'] ?? local['createdAt'] ?? '');
    final serverUpdated = DateTime.parse(server['updatedAt'] ?? server['createdAt'] ?? '');

    _logger.i('🔀 [CONFLICT] Customer conflict detected');
    _logger.i('   Local:  ${local['name']} (${localUpdated.toIso8601String()})');
    _logger.i('   Server: ${server['name']} (${serverUpdated.toIso8601String()})');

    // Server updated after sync → use server
    if (serverUpdated.isAfter(lastSync)) {
      _logger.i('   → Server updated after sync, using server value');
      return {
        ..._normalizeData(server),
        '_conflictResolution': 'server_newer_than_sync',
      };
    }

    // Client updated after sync → keep local
    if (localUpdated.isAfter(lastSync)) {
      _logger.i('   → Client has new offline changes, keeping local value');
      return {
        ...local,
        '_conflictResolution': 'client_newer_than_sync',
      };
    }

    // Both updated after sync → use newer
    if (localUpdated.isAfter(lastSync) && serverUpdated.isAfter(lastSync)) {
      if (serverUpdated.isAfter(localUpdated)) {
        _logger.w('   ⚠️  CONFLICT: Both updated, server newer');
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

    // Neither updated after sync → use newer
    if (serverUpdated.isAfter(localUpdated)) {
      _logger.i('   → Both old, server newer');
      return {
        ..._normalizeData(server),
        '_conflictResolution': 'both_old_server_newer',
      };
    }

    _logger.i('   → Both old, local newer');
    return {
      ...local,
      '_conflictResolution': 'both_old_local_newer',
    };
  }

  // ==================== HELPERS ====================

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

// ==================== ENUMS ====================

enum SyncEntityType { customer, stock, transaction, payment, milling, user }
enum SyncOperation { create, update, delete }
*/
