// lib/domain/repositories/stock_repository.dart

import 'package:dartz/dartz.dart';
import '../../core/constants/enums.dart';
import '../../core/errors/failures.dart';
import '../../data/models/stock_item_model.dart';
import '../entities/stock_item_entity.dart';

/// Abstract repository interface for stock operations
/// Handles all stock management operations with offline-first support
abstract class StockRepository {
  /// Get all stock items
  ///
  /// Returns list of [StockItemEntity] from local database
  /// Triggers background sync if online
  Future<Either<Failure, List<StockItemEntity>>> getAllStockItems();

  /// Get stock item by ID
  ///
  /// Parameters:
  /// - [id]: Stock item's unique identifier
  ///
  /// Returns [StockItemEntity] if found
  Future<Either<Failure, StockItemEntity>> getStockItemById(String id);

  /// Get stock items by type
  ///
  /// Parameters:
  /// - [type]: Item type (paddy or rice)
  ///
  /// Returns list of stock items of the specified type
  Future<Either<Failure, List<StockItemEntity>>> getStockByType(
    ItemType type,
  );

  /// Search stock items
  ///
  /// Parameters:
  /// - [query]: Search query string
  ///
  /// Returns list of matching stock items
  Future<Either<Failure, List<StockItemEntity>>> searchStock(
    String query,
  );

  /// Add a new stock item
  ///
  /// Parameters:
  /// - [item]: Stock item model to add
  ///
  /// Returns the created [StockItemEntity]
  Future<Either<Failure, StockItemEntity>> addStockItem(
    StockItemModel item,
  );

  /// Update an existing stock item
  ///
  /// Parameters:
  /// - [item]: Stock item model with updated data
  ///
  /// Returns the updated [StockItemEntity]
  Future<Either<Failure, StockItemEntity>> updateStockItem(
    StockItemModel item,
  );

  /// Add stock to an stock item (for Buy operations)
  ///
  /// Parameters:
  /// - [itemId]: Stock item's unique identifier
  /// - [quantity]: Quantity to add in kg
  /// - [bags]: Number of bags
  /// - [transactionId]: Associated transaction ID
  ///
  /// Returns the updated [StockItemEntity]
  Future<Either<Failure, StockItemEntity>> addStock({
    required String itemId,
    required double quantity,
    required int bags,
    required String transactionId,
  });

  /// Deduct stock from an stock item (for Sell operations)
  ///
  /// Parameters:
  /// - [itemId]: Stock item's unique identifier
  /// - [quantity]: Quantity to deduct in kg
  /// - [bags]: Number of bags
  /// - [transactionId]: Associated transaction ID
  ///
  /// Returns the updated [StockItemEntity]
  /// Fails if insufficient stock
  Future<Either<Failure, StockItemEntity>> deductStock({
    required String itemId,
    required double quantity,
    required int bags,
    required String transactionId,
  });

  /// Delete an stock item (soft delete)
  ///
  /// Parameters:
  /// - [id]: Stock item's unique identifier
  ///
  /// Returns true if successful
  Future<Either<Failure, bool>> deleteStockItem(String id);

  /// Get total stock by item type
  ///
  /// Returns a map with ItemType as key and total quantity as value
  Future<Either<Failure, Map<ItemType, double>>> getTotalStockByType();

  /// Get low stock items
  ///
  /// Parameters:
  /// - [threshold]: Minimum quantity threshold (default 100kg)
  ///
  /// Returns list of items below the threshold
  Future<Either<Failure, List<StockItemEntity>>> getLowStockItems(
    double threshold,
  );

  /// Get or create stock item by type and variety
  ///
  /// If item doesn't exist, creates a new one with zero quantity
  ///
  /// Parameters:
  /// - [type]: Item type (paddy or rice)
  /// - [variety]: Variety name
  /// - [companyId]: Company ID
  ///
  /// Returns existing or newly created [StockItemModel]
  Future<Either<Failure, StockItemModel>> getOrCreateStockItem({
    required ItemType type,
    required String variety,
    required String companyId,
  });

  /// Get stock movement history for an item
  ///
  /// Parameters:
  /// - [itemId]: Stock item's unique identifier
  ///
  /// Returns list of stock movements
  Future<Either<Failure, List<Map<String, dynamic>>>> getStockMovementHistory(
    String itemId,
  );

  /// Start milling operation (convert paddy to rice)
  ///
  /// Parameters:
  /// - [paddyItemId]: Paddy stock item ID
  /// - [paddyQuantity]: Paddy quantity to mill (kg)
  /// - [paddyBags]: Paddy bags count
  /// - [notes]: Optional notes
  /// - [millingDate]: Date of milling
  /// - [outputRiceKg]: Optional rice quantity produced (kg)
  /// - [outputRiceBags]: Optional rice bags count
  /// - [outputRiceName]: Optional name of output rice item
  /// - [status]: Optional status ('completed' or 'in_progress')
  ///
  /// Returns milling result
  Future<Either<Failure, Map<String, dynamic>>> startMilling({
    required String paddyItemId,
    required double paddyQuantity,
    required int paddyBags,
    String? notes,
    required DateTime millingDate,
    double? outputRiceKg,
    int? outputRiceBags,
    String? outputRiceName,
    String? status,
  });

  /// Complete milling operation
  ///
  /// Parameters:
  /// - [id]: Milling record ID
  /// - [riceQuantity]: Rice quantity produced (kg)
  /// - [riceBags]: Rice bags count
  /// - [outputRiceName]: Name of output rice item
  /// - [brokenRiceKg]: Broken rice amount
  /// - [huskKg]: Husk amount
  /// - [millingPercentage]: Expected milling percentage
  ///
  /// Returns completed milling result
  Future<Either<Failure, Map<String, dynamic>>> completeMilling({
    required String id,
    required double riceQuantity,
    required int riceBags,
    required String outputRiceName,
    required double brokenRiceKg,
    required double huskKg,
    required double millingPercentage,
  });

  /// Get milling history
  Future<Either<Failure, List<Map<String, dynamic>>>> getMillingHistory({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  });

  /// Sync stock with server
  ///
  /// Uploads unsynced items and downloads updates from server
  Future<Either<Failure, void>> syncStock();

  /// Get unsynced stock items
  ///
  /// Returns list of items that haven't been synced to server
  Future<Either<Failure, List<StockItemModel>>> getUnsyncedStockItems();

  /// Get stock summary
  ///
  /// Returns summary with total stock, value, and breakdown by type
  Future<Either<Failure, Map<String, dynamic>>> getStockSummary();

  /// Get stock value by type
  ///
  /// Returns total monetary value of stock by type
  Future<Either<Failure, Map<ItemType, double>>> getStockValueByType();

  /// Get varieties list
  ///
  /// Parameters:
  /// - [type]: Optional filter by item type
  ///
  /// Returns list of unique varieties
  Future<Either<Failure, List<String>>> getVarieties({ItemType? type});

  /// Check if variety exists
  ///
  /// Parameters:
  /// - [variety]: Variety name
  /// - [type]: Item type
  ///
  /// Returns true if variety exists
  Future<Either<Failure, bool>> isVarietyExists({
    required String variety,
    required ItemType type,
  });

  /// Adjust stock (for corrections/adjustments)
  ///
  /// Parameters:
  /// - [itemId]: Stock item's unique identifier
  /// - [newQuantity]: New quantity to set
  /// - [newBags]: New bags count
  /// - [reason]: Reason for adjustment
  ///
  /// Returns the updated [StockItemEntity]
  Future<Either<Failure, StockItemEntity>> adjustStock({
    required String itemId,
    required double newQuantity,
    required int newBags,
    required String reason,
  });
}

