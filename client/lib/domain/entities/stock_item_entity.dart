// lib/domain/entities/stock_item_entity.dart

import 'package:equatable/equatable.dart';
import '../../core/constants/enums.dart';

/// Stock Item Entity - Core business representation of stock items
/// Represents both Paddy and Rice stock
class StockItemEntity extends Equatable {
  final String id;
  final ItemType type; // Paddy or Rice
  final String variety; // e.g., "Samba", "Nadu", "Keeri Samba"
  final double currentQuantity; // in kg
  final int currentBags;
  final double averagePricePerKg;
  final bool isActive;

  const StockItemEntity({
    required this.id,
    required this.type,
    required this.variety,
    this.currentQuantity = 0,
    this.currentBags = 0,
    this.averagePricePerKg = 0,
    this.isActive = true,
  });

  /// Check if this is paddy
  bool get isPaddy => type == ItemType.paddy;

  /// Check if this is rice
  bool get isRice => type == ItemType.rice;

  /// Check if stock is available
  bool get hasStock => currentQuantity > 0;

  /// Check if out of stock
  bool get isOutOfStock => currentQuantity <= 0;

  /// Check if low stock (below 100kg threshold)
  bool get isLowStock => currentQuantity > 0 && currentQuantity <= 100;

  /// Check if sufficient stock for a given quantity
  bool hasSufficientStock(double requiredQuantity) {
    return currentQuantity >= requiredQuantity;
  }

  /// Get stock status
  StockStatus get stockStatus {
    if (currentQuantity <= 0) return StockStatus.outOfStock;
    if (currentQuantity <= 100) return StockStatus.low;
    if (currentQuantity <= 500) return StockStatus.medium;
    return StockStatus.high;
  }

  /// Get stock status text
  String get stockStatusText {
    switch (stockStatus) {
      case StockStatus.outOfStock:
        return 'Out of Stock';
      case StockStatus.low:
        return 'Low Stock';
      case StockStatus.medium:
        return 'Medium Stock';
      case StockStatus.high:
        return 'In Stock';
    }
  }

  /// Get stock status text in Sinhala
  String get stockStatusTextSinhala {
    switch (stockStatus) {
      case StockStatus.outOfStock:
        return 'තොගයේ නැත';
      case StockStatus.low:
        return 'අඩු තොගය';
      case StockStatus.medium:
        return 'මධ්‍යම තොගය';
      case StockStatus.high:
        return 'තොගයේ ඇත';
    }
  }

  /// Get item type display name
  String get typeDisplayName => isPaddy ? 'Paddy' : 'Rice';

  /// Get item type display name in Sinhala
  String get typeDisplayNameSinhala => isPaddy ? 'වී' : 'සහල්';

  /// Get full display name (variety + type)
  String get displayName => '$variety $typeDisplayNameSinhala';

  /// Get full display name in English
  String get displayNameEnglish => '$variety $typeDisplayName';

  /// Get item name (alias for displayName for compatibility)
  String get name => displayName;

  /// Get formatted quantity
  String get formattedQuantity => '${currentQuantity.toStringAsFixed(2)} kg';

  /// Get formatted quantity with bags
  String get formattedQuantityWithBags {
    if (currentBags > 0) {
      return '${currentQuantity.toStringAsFixed(2)} kg ($currentBags bags)';
    }
    return formattedQuantity;
  }

  /// Get formatted bags
  String get formattedBags => '$currentBags bags';

  /// Get formatted price per kg
  String get formattedPricePerKg =>
      'Rs. ${averagePricePerKg.toStringAsFixed(2)}/kg';

  /// Get stock value (current quantity × average price)
  double get stockValue => currentQuantity * averagePricePerKg;

  /// Get formatted stock value
  String get formattedStockValue => 'Rs. ${stockValue.toStringAsFixed(2)}';

  /// Get average weight per bag
  double get averageWeightPerBag {
    if (currentBags == 0) return 0;
    return currentQuantity / currentBags;
  }

  /// Get formatted average weight per bag
  String get formattedAverageWeightPerBag =>
      '${averageWeightPerBag.toStringAsFixed(2)} kg/bag';

  /// Calculate new average price after adding stock
  double calculateNewAveragePrice({
    required double addedQuantity,
    required double addedPricePerKg,
  }) {
    if (currentQuantity + addedQuantity == 0) return 0;

    final currentValue = currentQuantity * averagePricePerKg;
    final addedValue = addedQuantity * addedPricePerKg;
    final totalQuantity = currentQuantity + addedQuantity;

    return (currentValue + addedValue) / totalQuantity;
  }

  /// Create a copy with updated fields
  StockItemEntity copyWith({
    String? id,
    ItemType? type,
    String? variety,
    double? currentQuantity,
    int? currentBags,
    double? averagePricePerKg,
    bool? isActive,
  }) {
    return StockItemEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      variety: variety ?? this.variety,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      currentBags: currentBags ?? this.currentBags,
      averagePricePerKg: averagePricePerKg ?? this.averagePricePerKg,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Add stock to this item (returns new entity)
  StockItemEntity addStock({
    required double quantity,
    required int bags,
    required double pricePerKg,
  }) {
    final newQuantity = currentQuantity + quantity;
    final newBags = currentBags + bags;
    final newAveragePrice = calculateNewAveragePrice(
      addedQuantity: quantity,
      addedPricePerKg: pricePerKg,
    );

    return copyWith(
      currentQuantity: newQuantity,
      currentBags: newBags,
      averagePricePerKg: newAveragePrice,
    );
  }

  /// Deduct stock from this item (returns new entity)
  /// Throws exception if insufficient stock
  StockItemEntity deductStock({
    required double quantity,
    required int bags,
  }) {
    if (quantity > currentQuantity) {
      throw InsufficientStockException(
        available: currentQuantity,
        requested: quantity,
        itemName: displayName,
      );
    }

    final newQuantity = currentQuantity - quantity;
    final newBags = (currentBags - bags).clamp(0, currentBags);

    return copyWith(
      currentQuantity: newQuantity,
      currentBags: newBags,
    );
  }

  /// Create an empty stock item entity
  factory StockItemEntity.empty() {
    return const StockItemEntity(
      id: '',
      type: ItemType.paddy,
      variety: '',
    );
  }

  /// Check if entity is empty/invalid
  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  /// Validate stock item data
  StockValidationResult validate() {
    final errors = <String, String>{};

    if (variety.trim().isEmpty) {
      errors['variety'] = 'Variety is required';
    }

    if (currentQuantity < 0) {
      errors['quantity'] = 'Quantity cannot be negative';
    }

    if (currentBags < 0) {
      errors['bags'] = 'Bags cannot be negative';
    }

    if (averagePricePerKg < 0) {
      errors['price'] = 'Price cannot be negative';
    }

    return StockValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        variety,
        currentQuantity,
        currentBags,
        averagePricePerKg,
        isActive,
      ];

  @override
  String toString() {
    return 'StockItemEntity(id: $id, type: $type, variety: $variety, qty: $currentQuantity kg, bags: $currentBags)';
  }
}

/// Stock status enum
enum StockStatus {
  outOfStock,
  low,
  medium,
  high,
}

/// Stock validation result
class StockValidationResult {
  final bool isValid;
  final Map<String, String> errors;

  const StockValidationResult({
    required this.isValid,
    this.errors = const {},
  });

  String? getError(String field) => errors[field];

  bool hasError(String field) => errors.containsKey(field);
}

/// Exception for insufficient stock
class InsufficientStockException implements Exception {
  final double available;
  final double requested;
  final String itemName;

  const InsufficientStockException({
    required this.available,
    required this.requested,
    required this.itemName,
  });

  @override
  String toString() {
    return 'Insufficient stock for $itemName. Available: ${available.toStringAsFixed(2)} kg, Requested: ${requested.toStringAsFixed(2)} kg';
  }

  String get message => toString();
}

