/// Database constants for SQLite
class DbConstants {
  DbConstants._();

  // ==================== DATABASE INFO ====================

  /// Database file name
  static const String databaseName = 'rice_mill_erp.db';

  /// Current database version
  static const int databaseVersion = 16;

  /// Database path (relative to app documents directory)
  static const String databasePath = '';

  // ==================== TABLE NAMES ====================

  /// Users table
  static const String usersTable = 'users';

  /// Customers table
  static const String customersTable = 'customers';

  /// Stock table (was stock)
  static const String stockTable = 'stock';

  /// Transactions table
  static const String transactionsTable = 'transactions';

  /// Transaction items table
  static const String transactionItemsTable = 'transaction_items';

  /// Payments table
  static const String paymentsTable = 'payments';

  /// Companies table
  static const String companiesTable = 'companies';

  /// Milling records table
  static const String millingTable = 'milling_records';

  /// Sync queue table
  static const String syncQueueTable = 'sync_queue';

  /// Settings table
  static const String settingsTable = 'settings';

  /// Audit log table
  static const String auditLogTable = 'audit_log';

  // ==================== COMMON COLUMNS ====================

  /// Local ID column (primary key)
  static const String colLocalId = 'local_id';

  /// Server ID column
  static const String colServerId = 'server_id';

  /// Created at timestamp column
  static const String colCreatedAt = 'created_at';

  /// Updated at timestamp column
  static const String colUpdatedAt = 'updated_at';

  /// Deleted at timestamp column (soft delete)
  static const String colDeletedAt = 'deleted_at';

  /// Sync status column
  static const String colSyncStatus = 'sync_status';

  /// Is deleted flag column
  static const String colIsDeleted = 'is_deleted';

  /// Is active flag column
  static const String colIsActive = 'is_active';

  // ==================== USER COLUMNS ====================

  static const String colUserId = 'user_id';
  static const String colUsername = 'username';
  static const String colEmail = 'email';
  static const String colPassword = 'password';
  static const String colRole = 'role';
  static const String colCompanyId = 'company_id';

  // ==================== CUSTOMER COLUMNS ====================

  static const String colCustomerId = 'customer_id';
  static const String colName = 'name';
  static const String colPhone = 'phone';
  static const String colAddress = 'address';
  static const String colCity = 'city';
  static const String colNic = 'nic';
  static const String colCustomerType = 'customer_type';
  static const String colBalance = 'balance';
  static const String colSecondaryPhone = 'secondary_phone';
  static const String colTotalPurchases = 'total_purchases';
  static const String colTotalSales = 'total_sales';
  static const String colSyncedAt = 'synced_at';
  static const String colNotes = 'notes';

  // ==================== STOCK COLUMNS ====================

  static const String colItemType = 'item_type';
  static const String colItemName = 'item_name';
  static const String colVariety = 'variety';
  static const String colQuantityKg = 'quantity_kg';
  static const String colBagCount = 'bag_count';
  static const String colAverageBagWeight = 'average_bag_weight';
  static const String colMinStockLevel = 'min_stock_level';
  static const String colLocation = 'location';

  // ==================== TRANSACTION COLUMNS ====================

  static const String colTransactionId = 'transaction_id';
  static const String colTransactionType = 'transaction_type';
  static const String colCustomerLocalId = 'customer_local_id';
  static const String colCustomerName = 'customer_name';
  static const String colCustomerPhone = 'customer_phone';
  static const String colTotalWeightKg = 'total_weight_kg';
  static const String colTotalBags = 'total_bags';
  static const String colPricePerKg = 'price_per_kg';
  static const String colTotalAmount = 'total_amount';
  static const String colPaidAmount = 'paid_amount';
  static const String colPaymentStatus = 'payment_status';
  static const String colTransactionDate = 'transaction_date';

  // ==================== TRANSACTION ITEM COLUMNS ====================

  static const String colTransactionLocalId = 'transaction_local_id';
  static const String colWeightKg = 'weight_kg';
  static const String colAmount = 'amount';

  // ==================== MILLING COLUMNS ====================

  static const String colMillingId = 'milling_id';
  static const String colPaddyWeight = 'paddy_weight';
  static const String colRiceWeight = 'rice_weight';
  static const String colBranWeight = 'bran_weight';
  static const String colHuskWeight = 'husk_weight';
  static const String colMillingRatio = 'milling_ratio';
  static const String colMillingDate = 'milling_date';

  // ==================== SYNC QUEUE COLUMNS ====================

  static const String colTableName = 'table_name';
  static const String colRecordLocalId = 'record_local_id';
  static const String colOperation = 'operation';
  static const String colData = 'data';
  static const String colRetryCount = 'retry_count';
  static const String colLastError = 'last_error';

  // ==================== PAYMENT COLUMNS ====================

  static const String colPaymentId = 'payment_id';
  static const String colPaymentMethod = 'payment_method';
  static const String colPaymentDate = 'payment_date';
  static const String colReferenceNumber = 'reference_number';

  // ==================== SETTINGS COLUMNS ====================

  static const String colKey = 'key';
  static const String colValue = 'value';

  // ==================== AUDIT LOG COLUMNS ====================

  static const String colAction = 'action';
  static const String colEntityType = 'entity_type';
  static const String colEntityId = 'entity_id';
  static const String colOldValues = 'old_values';
  static const String colNewValues = 'new_values';
  static const String colIpAddress = 'ip_address';
  static const String colUserAgent = 'user_agent';

  // ==================== SQL DATA TYPES ====================

  static const String typeInteger = 'INTEGER';
  static const String typeText = 'TEXT';
  static const String typeReal = 'REAL';
  static const String typeBlob = 'BLOB';
  static const String typeNumeric = 'NUMERIC';

  // ==================== SQL CONSTRAINTS ====================

  static const String primaryKey = 'PRIMARY KEY';
  static const String autoIncrement = 'AUTOINCREMENT';
  static const String notNull = 'NOT NULL';
  static const String unique = 'UNIQUE';
  static const String defaultValue = 'DEFAULT';
  static const String foreignKey = 'FOREIGN KEY';
  static const String references = 'REFERENCES';
  static const String onDelete = 'ON DELETE';
  static const String onUpdate = 'ON UPDATE';
  static const String cascade = 'CASCADE';
  static const String setNull = 'SET NULL';
  static const String restrict = 'RESTRICT';

  // ==================== SYNC STATUS VALUES ====================

  static const String syncStatusPending = 'pending';
  static const String syncStatusSyncing = 'syncing';
  static const String syncStatusSynced = 'synced';
  static const String syncStatusFailed = 'failed';
  static const String syncStatusConflict = 'conflict';

  // ==================== OPERATION VALUES ====================

  static const String operationCreate = 'create';
  static const String operationUpdate = 'update';
  static const String operationDelete = 'delete';

  // ==================== INDEX NAMES ====================

  static const String idxCustomersPhone = 'idx_customers_phone';
  static const String idxCustomersName = 'idx_customers_name';
  static const String idxCustomersSync = 'idx_customers_sync';
  static const String idxStockType = 'idx_stock_type';
  static const String idxStockName = 'idx_stock_name';
  static const String idxStockSync = 'idx_stock_sync';
  static const String idxTransactionsType = 'idx_transactions_type';
  static const String idxTransactionsDate = 'idx_transactions_date';
  static const String idxTransactionsCustomer = 'idx_transactions_customer';
  static const String idxTransactionsSync = 'idx_transactions_sync';
  static const String idxTransactionItemsTxn = 'idx_transaction_items_txn';
  static const String idxSyncQueueTable = 'idx_sync_queue_table';
  static const String idxSyncQueueOperation = 'idx_sync_queue_operation';
  static const String idxSyncQueueRetry = 'idx_sync_queue_retry';

  // ==================== DEFAULT VALUES ====================

  static const int defaultIntValue = 0;
  static const double defaultDoubleValue = 0.0;
  static const String defaultStringValue = '';
  static const String defaultSyncStatus = syncStatusPending;
  static const int defaultIsDeleted = 0;
  static const int defaultIsActive = 1;
}

