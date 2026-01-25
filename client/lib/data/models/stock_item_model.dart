// lib/data/models/stock_item_model.dart

import 'package:equatable/equatable.dart';
import '../../core/constants/enums.dart';
import '../../core/constants/db_constants.dart';
import '../../domain/entities/stock_item_entity.dart';

/// Rice variety enum (common Sri Lankan rice varieties)
enum RiceVariety {
  samba, // සම්බා
  naadu, // නාඩු
  keeriSamba, // කීරි සම්බා
  suwandel, // සුවඳැල්
  rathuKekulu, // රතු කැකුළු
  suduKekulu, // සුදු කැකුළු
  basmati, // බාස්මතී
  redRaw, // රතු හාල් (Raw)
  whiteRaw, // සුදු හාල් (Raw)
  parboiled, // හැඳි හාල්
  other, // වෙනත්
}

class StockItemModel extends Equatable {
  final int? localId;
  final String id;
  final String? serverId;
  final ItemType type; // Paddy or Rice
  final String variety; // Rice variety name
  final String? description;
  final String companyId;
  final double currentQuantity; // Current stock in KG
  final int currentBags; // Current stock in bags
  final double averagePricePerKg; // Average buying price
  final double? sellingPricePerKg; // Suggested selling price
  final double? minimumStock; // Low stock threshold
  final String? warehouseLocation; // Storage location
  final DateTime? lastStockUpdateAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final SyncStatus syncStatus;
  final DateTime? syncedAt;
  final bool isDeleted;

  const StockItemModel({
    this.localId,
    required this.id,
    this.serverId,
    required this.type,
    required this.variety,
    this.description,
    required this.companyId,
    this.currentQuantity = 0.0,
    this.currentBags = 0,
    this.averagePricePerKg = 0.0,
    this.sellingPricePerKg,
    this.minimumStock,
    this.warehouseLocation,
    this.lastStockUpdateAt,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.syncStatus = SyncStatus.pending,
    this.syncedAt,
    this.isDeleted = false,
  });

  /// Create from JSON (API or Local DB)
  factory StockItemModel.fromJson(Map<String, dynamic> json) {
    return StockItemModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      serverId: json['server_id']?.toString() ?? json['_id']?.toString(),
      type: _parseItemType(json['type'] ?? json['itemType']),
      variety: json['variety']?.toString() ?? json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      companyId:
          json['company_id']?.toString() ?? json['companyId']?.toString() ?? '',
      currentQuantity: _parseDouble(json['current_quantity'] ??
          json['totalWeightKg'] ??
          json['weightKg']),
      currentBags:
          _parseInt(json['current_bags'] ?? json['totalBags'] ?? json['bags']),
      averagePricePerKg: _parseDouble(json['average_price_per_kg'] ??
          json['pricePerKg'] ??
          json['avgPurchasePrice']),
      sellingPricePerKg: json['selling_price_per_kg'] != null
          ? _parseDouble(json['selling_price_per_kg'])
          : null,
      minimumStock: json['minimum_stock'] != null
          ? _parseDouble(json['minimum_stock'] ?? json['minimumStock'])
          : null,
      warehouseLocation: json['warehouse_location']?.toString(),
      lastStockUpdateAt: _parseDateTime(json['last_stock_update_at'] ??
          json['lastUpdated'] ??
          json['updatedAt']),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']) ??
          DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']) ??
          DateTime.now(),
      isSynced: json['is_synced'] == true ||
          json['is_synced'] == 1 ||
          json['isSynced'] == true,
      syncStatus: _parseSyncStatus(json['sync_status'] ?? json['syncStatus']),
      syncedAt: _parseDateTime(json['synced_at'] ?? json['syncedAt']),
      isDeleted: json['is_deleted'] == true ||
          json['is_deleted'] == 1 ||
          json['isActive'] == false,
    );
  }

  /// Convert to JSON for Local DB
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'server_id': serverId,
      'type': type.name,
      'variety': variety,
      'description': description,
      'company_id': companyId,
      'current_quantity': currentQuantity,
      'current_bags': currentBags,
      'average_price_per_kg': averagePricePerKg,
      'selling_price_per_kg': sellingPricePerKg,
      'minimum_stock': minimumStock,
      'warehouse_location': warehouseLocation,
      'last_stock_update_at': lastStockUpdateAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'sync_status': syncStatus.value,
      'synced_at': syncedAt?.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  /// Create from DB map
  factory StockItemModel.fromMap(Map<String, dynamic> map) {
    return StockItemModel(
      localId: (map[DbConstants.colLocalId] is int)
          ? map[DbConstants.colLocalId] as int
          : (map[DbConstants.colLocalId] != null
              ? int.tryParse(map[DbConstants.colLocalId].toString())
              : null),
      id: map['id']?.toString() ??
          map[DbConstants.colServerId]?.toString() ??
          '',
      serverId: map[DbConstants.colServerId]?.toString(),
      type: _parseItemType(map[DbConstants.colItemType] ?? map['type']),
      variety: map[DbConstants.colVariety]?.toString() ?? '',
      description: map['description']?.toString(),
      companyId: map[DbConstants.colCompanyId]?.toString() ?? '',
      currentQuantity:
          _parseDouble(map[DbConstants.colQuantityKg] ?? map['quantity_kg']),
      currentBags: _parseInt(map[DbConstants.colBagCount] ?? map['bag_count']),
      averagePricePerKg: _parseDouble(
          map[DbConstants.colAverageBagWeight] ?? map['average_price_per_kg']),
      sellingPricePerKg: map['selling_price_per_kg'] != null
          ? _parseDouble(map['selling_price_per_kg'])
          : null,
      minimumStock: map[DbConstants.colMinStockLevel] != null
          ? _parseDouble(map[DbConstants.colMinStockLevel])
          : null,
      warehouseLocation: map[DbConstants.colLocation]?.toString(),
      lastStockUpdateAt: _parseDateTime(map['last_stock_update_at']),
      createdAt:
          _parseDateTime(map[DbConstants.colCreatedAt]) ?? DateTime.now(),
      updatedAt:
          _parseDateTime(map[DbConstants.colUpdatedAt]) ?? DateTime.now(),
      isSynced: (map['is_synced'] == 1) ||
          (map['is_synced'] == true) ||
          (map[DbConstants.colSyncStatus] == SyncStatus.synced.value),
      syncStatus: _parseSyncStatus(
          map[DbConstants.colSyncStatus] ?? map['sync_status']),
      syncedAt: _parseDateTime(map['synced_at']),
      isDeleted: (map[DbConstants.colIsDeleted] == 1) ||
          (map[DbConstants.colIsDeleted] == true),
    );
  }

  /// Convert to DB map
  Map<String, dynamic> toMap() {
    return {
      DbConstants.colLocalId: localId,
      'id': id,
      DbConstants.colServerId: serverId,
      DbConstants.colItemType: type.name,
      DbConstants.colItemName: variety.isNotEmpty ? variety : type.name,
      DbConstants.colVariety: variety,
      DbConstants.colQuantityKg: currentQuantity,
      DbConstants.colBagCount: currentBags,
      DbConstants.colAverageBagWeight: averagePricePerKg,
      DbConstants.colMinStockLevel: minimumStock,
      DbConstants.colLocation: warehouseLocation,
      DbConstants.colCreatedAt: createdAt.toIso8601String(),
      DbConstants.colUpdatedAt: updatedAt.toIso8601String(),
      DbConstants.colSyncStatus: syncStatus.value,
      'is_synced': isSynced ? 1 : 0,
      DbConstants.colIsDeleted: isDeleted ? 1 : 0,
    };
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJsonForApi() {
    return {
      'type': type.name,
      'variety': variety,
      'description': description,
      'current_quantity': currentQuantity,
      'current_bags': currentBags,
      'average_price_per_kg': averagePricePerKg,
      'selling_price_per_kg': sellingPricePerKg,
      'minimum_stock': minimumStock,
      'warehouse_location': warehouseLocation,
    };
  }

  /// Convert to JSON for Sync
  Map<String, dynamic> toJsonForSync() {
    return {
      'local_id': id,
      'server_id': serverId,
      'type': type.name,
      'variety': variety,
      'description': description,
      'current_quantity': currentQuantity,
      'current_bags': currentBags,
      'average_price_per_kg': averagePricePerKg,
      'selling_price_per_kg': sellingPricePerKg,
      'minimum_stock': minimumStock,
      'warehouse_location': warehouseLocation,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to Entity
  StockItemEntity toEntity() {
    return StockItemEntity(
      id: id,
      type: type,
      variety: variety,
      currentQuantity: currentQuantity,
      currentBags: currentBags,
      averagePricePerKg: averagePricePerKg,
      isActive: !isDeleted,
    );
  }

  /// Create from Entity
  factory StockItemModel.fromEntity(StockItemEntity entity, String companyId) {
    return StockItemModel(
      id: entity.id,
      type: entity.type,
      variety: entity.variety,
      companyId: companyId,
      currentQuantity: entity.currentQuantity,
      currentBags: entity.currentBags,
      averagePricePerKg: entity.averagePricePerKg,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDeleted: !entity.isActive,
    );
  }

  /// Create new stock item with generated ID
  factory StockItemModel.create({
    ItemType? type,
    String? variety,
    String? description,
    String? companyId,
    double currentQuantity = 0.0,
    int currentBags = 0,
    double averagePricePerKg = 0.0,
    double? sellingPricePerKg,
    double? minimumStock,
    String? warehouseLocation,
    // Legacy aliases used by older table code
    ItemType? itemType,
    String? itemName,
    double? quantityKg,
    int? bagCount,
  }) {
    final now = DateTime.now();
    final resolvedType = itemType ?? type ?? ItemType.paddy;
    final resolvedVariety = variety ?? itemName ?? '';
    final resolvedQuantity = quantityKg ?? currentQuantity;
    final resolvedBags = bagCount ?? currentBags;
    final resolvedCompany = companyId ?? '';
    final prefix = resolvedType == ItemType.paddy ? 'PDY' : 'RCE';
    return StockItemModel(
      id: '${prefix}_${now.millisecondsSinceEpoch}',
      type: resolvedType,
      variety: resolvedVariety,
      description: description,
      companyId: resolvedCompany,
      currentQuantity: resolvedQuantity,
      currentBags: resolvedBags,
      averagePricePerKg: averagePricePerKg,
      sellingPricePerKg: sellingPricePerKg,
      minimumStock: minimumStock,
      warehouseLocation: warehouseLocation,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Copy with new values
  StockItemModel copyWith({
    int? localId,
    String? id,
    String? serverId,
    ItemType? type,
    String? variety,
    String? description,
    String? companyId,
    double? currentQuantity,
    int? currentBags,
    double? averagePricePerKg,
    double? sellingPricePerKg,
    double? minimumStock,
    String? warehouseLocation,
    DateTime? lastStockUpdateAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    SyncStatus? syncStatus,
    DateTime? syncedAt,
    bool? isDeleted,
  }) {
    return StockItemModel(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      type: type ?? this.type,
      variety: variety ?? this.variety,
      description: description ?? this.description,
      companyId: companyId ?? this.companyId,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      currentBags: currentBags ?? this.currentBags,
      averagePricePerKg: averagePricePerKg ?? this.averagePricePerKg,
      sellingPricePerKg: sellingPricePerKg ?? this.sellingPricePerKg,
      minimumStock: minimumStock ?? this.minimumStock,
      warehouseLocation: warehouseLocation ?? this.warehouseLocation,
      lastStockUpdateAt: lastStockUpdateAt ?? this.lastStockUpdateAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      syncStatus: syncStatus ?? this.syncStatus,
      syncedAt: syncedAt ?? this.syncedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// Add stock to stock
  StockItemModel addStock(double quantity, int bags, {double? pricePerKg}) {
    final totalCurrentValue = currentQuantity * averagePricePerKg;
    final addedValue = pricePerKg != null ? (quantity * pricePerKg) : 0.0;
    final newTotalQuantity = currentQuantity + quantity;
    final newAveragePrice = (pricePerKg != null && newTotalQuantity > 0)
        ? (totalCurrentValue + addedValue) / newTotalQuantity
        : averagePricePerKg;

    return copyWith(
      currentQuantity: newTotalQuantity,
      currentBags: currentBags + bags,
      averagePricePerKg: newAveragePrice,
      lastStockUpdateAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: false,
      syncStatus: SyncStatus.pending,
    );
  }

  /// Deduct stock from stock
  StockItemModel deductStock(double quantity, int bags) {
    return copyWith(
      currentQuantity: currentQuantity - quantity,
      currentBags: (currentBags - bags).clamp(0, currentBags),
      lastStockUpdateAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: false,
      syncStatus: SyncStatus.pending,
    );
  }

  /// Helper to parse ItemType
  static ItemType _parseItemType(dynamic value) {
    if (value == null) return ItemType.paddy;
    if (value is ItemType) return value;

    final typeStr = value.toString().toLowerCase();
    switch (typeStr) {
      case 'rice':
        return ItemType.rice;
      case 'paddy':
      default:
        return ItemType.paddy;
    }
  }

  /// Helper to parse double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Helper to parse int
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Helper to parse DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static SyncStatus _parseSyncStatus(dynamic value) {
    if (value == null) return SyncStatus.pending;
    if (value is SyncStatus) return value;
    return SyncStatus.fromString(value.toString());
  }

  /// Compatibility getters expected by older DB/table code
  int? get localIdValue => localId;
  ItemType get itemType => type;
  String get itemName => variety.isNotEmpty ? variety : type.name;
  double get quantityKg => currentQuantity;
  int get bagCount => currentBags;

  /// Additional compatibility getters for stock feature
  double get totalWeightKg => currentQuantity;
  int get totalBags => currentBags;
  double get pricePerKg => averagePricePerKg;

  /// Get display type name
  String get displayType =>
      type == ItemType.paddy ? 'වී (Paddy)' : 'සහල් (Rice)';

  /// Get display type name (English only)
  String get displayTypeEn => type == ItemType.paddy ? 'Paddy' : 'Rice';

  /// Get item type display name in Sinhala
  String get typeDisplayNameSinhala => type == ItemType.paddy ? 'වී' : 'සහල්';

  /// Get full display name (variety + type in Sinhala)
  String get displayName => '$variety $typeDisplayNameSinhala';

  /// Check if stock is low
  bool get isLowStock =>
      minimumStock != null && currentQuantity <= minimumStock!;

  /// Check if stock is empty
  bool get isEmpty => currentQuantity <= 0;

  /// Getters used by widgets
  bool get isOutOfStock => isEmpty;
  String get stockStatus {
    if (isEmpty) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  /// Get formatted quantity
  String get formattedQuantity => '${currentQuantity.toStringAsFixed(2)} kg';

  /// Get formatted bags
  String get formattedBags => '$currentBags bags';

  /// Get stock value
  double get stockValue => currentQuantity * averagePricePerKg;

  /// Get formatted stock value
  String get formattedStockValue => 'Rs. ${stockValue.toStringAsFixed(2)}';

  /// Get average weight per bag
  double get averageWeightPerBag =>
      currentBags > 0 ? currentQuantity / currentBags : 0;

  /// Get item name (alias for displayName for compatibility)
  String get name => displayName;

  @override
  List<Object?> get props => [
        id,
        serverId,
        type,
        variety,
        companyId,
        currentQuantity,
        currentBags,
        isSynced,
        isDeleted,
      ];

  @override
  String toString() =>
      'StockItemModel(id: $id, type: ${type.name}, variety: $variety, qty: $currentQuantity kg)';
}

