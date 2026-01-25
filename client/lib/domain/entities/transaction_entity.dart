// lib/domain/entities/transaction_entity.dart

import 'package:equatable/equatable.dart';
import '../../core/constants/enums.dart';

/// Transaction Entity - Core business representation of a transaction
/// Represents both Buy (purchase from farmers) and Sell (sale to buyers) transactions
class TransactionEntity extends Equatable {
  /// Get subtotal (total weight for buy transactions)
  double get subtotal => totalWeight;
  final String id;
  final String transactionNumber;
  final TransactionType type;
  final String customerId;
  final String customerName;
  final List<TransactionItemEntity> items;
  final double totalAmount;
  final double paidAmount;
  final TransactionStatus status;
  final DateTime transactionDate;

  const TransactionEntity({
    required this.id,
    required this.transactionNumber,
    required this.type,
    required this.customerId,
    required this.customerName,
    this.items = const [],
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.status = TransactionStatus.pending,
    required this.transactionDate,
  });

  /// Check if this is a buy transaction
  bool get isBuyTransaction => type == TransactionType.buy;

  /// Check if this is a sell transaction
  bool get isSellTransaction => type == TransactionType.sell;

  /// Get due amount
  double get dueAmount => totalAmount - paidAmount;

  /// Check if transaction is fully paid
  bool get isFullyPaid => paidAmount >= totalAmount;

  /// Check if transaction is partially paid
  bool get isPartiallyPaid => paidAmount > 0 && paidAmount < totalAmount;

  /// Check if transaction is unpaid
  bool get isUnpaid => paidAmount <= 0;

  /// Get payment status
  PaymentStatus get paymentStatus {
    if (isFullyPaid) return PaymentStatus.completed;
    if (isPartiallyPaid) return PaymentStatus.partial;
    return PaymentStatus.pending;
  }

  /// Check if transaction is pending
  bool get isPending => status == TransactionStatus.pending;

  /// Check if transaction is completed
  bool get isCompleted => status == TransactionStatus.completed;

  /// Check if transaction is cancelled
  bool get isCancelled => status == TransactionStatus.cancelled;

  /// Check if transaction can be edited
  bool get canEdit => isPending;

  /// Check if transaction can be cancelled
  bool get canCancel => !isCancelled;

  /// Check if transaction can be deleted
  bool get canDelete => isPending;

  /// Get transaction type display name
  String get typeDisplayName => isBuyTransaction ? 'Purchase' : 'Sale';

  /// Get transaction type display name in Sinhala
  String get typeDisplayNameSinhala =>
      isBuyTransaction ? 'මිලදී ගැනීම' : 'විකිණීම';

  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get status display name in Sinhala
  String get statusDisplayNameSinhala {
    switch (status) {
      case TransactionStatus.pending:
        return 'පොරොත්තුවෙන්';
      case TransactionStatus.completed:
        return 'සම්පූර්ණයි';
      case TransactionStatus.cancelled:
        return 'අවලංගුයි';
    }
  }

  /// Get payment status display name
  String get paymentStatusDisplayName {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Unpaid';
      case PaymentStatus.partial:
        return 'Partial';
      case PaymentStatus.completed:
        return 'Paid';
      case PaymentStatus.overdue:
        return 'Overdue';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get payment status display name in Sinhala
  String get paymentStatusDisplayNameSinhala {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'ගෙවා නැත';
      case PaymentStatus.partial:
        return 'අර්ධ වශයෙන්';
      case PaymentStatus.completed:
        return 'ගෙවා ඇත';
      case PaymentStatus.overdue:
        return 'ප්‍රමාද';
      case PaymentStatus.cancelled:
        return 'අවලංගු';
    }
  }

  /// Get formatted total amount
  String get formattedTotalAmount => 'Rs. ${totalAmount.toStringAsFixed(2)}';

  /// Get formatted paid amount
  String get formattedPaidAmount => 'Rs. ${paidAmount.toStringAsFixed(2)}';

  /// Get formatted due amount
  String get formattedDueAmount => 'Rs. ${dueAmount.toStringAsFixed(2)}';

  /// Get total bags across all items
  int get totalBags => items.fold(0, (sum, item) => sum + item.bags);

  /// Get total weight across all items
  double get totalWeight =>
      items.fold(0.0, (sum, item) => sum + item.totalWeight);

  /// Get formatted total weight
  String get formattedTotalWeight => '${totalWeight.toStringAsFixed(2)} kg';

  /// Get formatted total bags
  String get formattedTotalBags => '$totalBags bags';

  /// Get items count
  int get itemsCount => items.length;

  /// Get formatted transaction date
  String get formattedDate {
    final d = transactionDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Get formatted transaction time
  String get formattedTime {
    final d = transactionDate;
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  /// Get formatted date and time
  String get formattedDateTime => '$formattedDate $formattedTime';

  /// Get relative date text
  String get relativeDateText {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txnDate = DateTime(
      transactionDate.year,
      transactionDate.month,
      transactionDate.day,
    );

    final difference = today.difference(txnDate).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).floor()} weeks ago';
    if (difference < 365) return '${(difference / 30).floor()} months ago';
    return '${(difference / 365).floor()} years ago';
  }

  /// Get summary text
  String get summaryText {
    return '$formattedTotalBags • $formattedTotalWeight • $formattedTotalAmount';
  }

  /// Create a copy with updated fields
  TransactionEntity copyWith({
    String? id,
    String? transactionNumber,
    TransactionType? type,
    String? customerId,
    String? customerName,
    List<TransactionItemEntity>? items,
    double? totalAmount,
    double? paidAmount,
    TransactionStatus? status,
    DateTime? transactionDate,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      transactionNumber: transactionNumber ?? this.transactionNumber,
      type: type ?? this.type,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      transactionDate: transactionDate ?? this.transactionDate,
    );
  }

  /// Add item to transaction
  TransactionEntity addItem(TransactionItemEntity item) {
    final newItems = [...items, item];
    final newTotal = newItems.fold(0.0, (sum, i) => sum + i.totalPrice);
    return copyWith(
      items: newItems,
      totalAmount: newTotal,
    );
  }

  /// Remove item from transaction
  TransactionEntity removeItem(String itemId) {
    final newItems = items.where((i) => i.id != itemId).toList();
    final newTotal = newItems.fold(0.0, (sum, i) => sum + i.totalPrice);
    return copyWith(
      items: newItems,
      totalAmount: newTotal,
    );
  }

  /// Update item in transaction
  TransactionEntity updateItem(TransactionItemEntity updatedItem) {
    final newItems =
        items.map((i) => i.id == updatedItem.id ? updatedItem : i).toList();
    final newTotal = newItems.fold(0.0, (sum, i) => sum + i.totalPrice);
    return copyWith(
      items: newItems,
      totalAmount: newTotal,
    );
  }

  /// Add payment
  TransactionEntity addPayment(double amount) {
    return copyWith(
      paidAmount: paidAmount + amount,
    );
  }

  /// Create an empty transaction entity
  factory TransactionEntity.empty() {
    return TransactionEntity(
      id: '',
      transactionNumber: '',
      type: TransactionType.buy,
      customerId: '',
      customerName: '',
      transactionDate: DateTime.now(),
    );
  }

  /// Check if entity is empty/invalid
  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  /// Validate transaction data
  TransactionValidationResult validate() {
    final errors = <String, String>{};

    if (customerId.isEmpty) {
      errors['customer'] = 'Customer is required';
    }

    if (items.isEmpty) {
      errors['items'] = 'At least one item is required';
    }

    if (totalAmount <= 0 && items.isNotEmpty) {
      errors['amount'] = 'Total amount must be greater than zero';
    }

    return TransactionValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  @override
  List<Object?> get props => [
        id,
        transactionNumber,
        type,
        customerId,
        customerName,
        items,
        totalAmount,
        paidAmount,
        status,
        transactionDate,
      ];

  @override
  String toString() {
    return 'TransactionEntity(id: $id, number: $transactionNumber, type: $type, total: $totalAmount, status: $status)';
  }
}

/// Transaction Item Entity - Individual line item in a transaction
class TransactionItemEntity extends Equatable {
  final String id;
  final String stockItemId;
  final ItemType itemType;
  final String variety;
  final int bags;
  final double totalWeight; // in kg
  final double pricePerKg;
  final double totalPrice;

  const TransactionItemEntity({
    required this.id,
    required this.stockItemId,
    required this.itemType,
    required this.variety,
    required this.bags,
    required this.totalWeight,
    required this.pricePerKg,
    required this.totalPrice,
  });

  /// Check if this is paddy
  bool get isPaddy => itemType == ItemType.paddy;

  /// Check if this is rice
  bool get isRice => itemType == ItemType.rice;

  /// Get item type display name
  String get typeDisplayName {
    switch (itemType) {
      case ItemType.paddy:
        return 'Paddy';
      case ItemType.rice:
        return 'Rice';
      case ItemType.bran:
        return 'Rice Bran';
      case ItemType.husk:
        return 'Rice Husk';
    }
  }

  /// Get item type display name in Sinhala
  String get typeDisplayNameSinhala {
    switch (itemType) {
      case ItemType.paddy:
        return 'වී';
      case ItemType.rice:
        return 'සහල්';
      case ItemType.bran:
        return 'කුඩු';
      case ItemType.husk:
        return 'දහල්';
    }
  }

  /// Get full display name
  String get displayName => '$variety $typeDisplayNameSinhala';

  /// Get formatted weight
  String get formattedWeight => '${totalWeight.toStringAsFixed(2)} kg';

  /// Get formatted price per kg
  String get formattedPricePerKg => 'Rs. ${pricePerKg.toStringAsFixed(2)}/kg';

  /// Get formatted total price
  String get formattedTotalPrice => 'Rs. ${totalPrice.toStringAsFixed(2)}';

  /// Get formatted bags
  String get formattedBags => '$bags bags';

  /// Get average weight per bag
  double get averageWeightPerBag => bags > 0 ? totalWeight / bags : 0;

  /// Get formatted average weight per bag
  String get formattedAverageWeightPerBag =>
      '${averageWeightPerBag.toStringAsFixed(2)} kg/bag';

  /// Get summary text
  String get summaryText {
    return '$formattedBags × $formattedAverageWeightPerBag = $formattedWeight @ $formattedPricePerKg';
  }

  /// Create a copy with updated fields
  TransactionItemEntity copyWith({
    String? id,
    String? stockItemId,
    ItemType? itemType,
    String? variety,
    int? bags,
    double? totalWeight,
    double? pricePerKg,
    double? totalPrice,
  }) {
    return TransactionItemEntity(
      id: id ?? this.id,
      stockItemId: stockItemId ?? this.stockItemId,
      itemType: itemType ?? this.itemType,
      variety: variety ?? this.variety,
      bags: bags ?? this.bags,
      totalWeight: totalWeight ?? this.totalWeight,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  /// Create with calculated total price
  factory TransactionItemEntity.create({
    required String id,
    required String stockItemId,
    required ItemType itemType,
    required String variety,
    required int bags,
    required double totalWeight,
    required double pricePerKg,
  }) {
    return TransactionItemEntity(
      id: id,
      stockItemId: stockItemId,
      itemType: itemType,
      variety: variety,
      bags: bags,
      totalWeight: totalWeight,
      pricePerKg: pricePerKg,
      totalPrice: totalWeight * pricePerKg,
    );
  }

  /// Update weight and recalculate total price
  TransactionItemEntity updateWeight(double newWeight) {
    return copyWith(
      totalWeight: newWeight,
      totalPrice: newWeight * pricePerKg,
    );
  }

  /// Update price and recalculate total price
  TransactionItemEntity updatePrice(double newPricePerKg) {
    return copyWith(
      pricePerKg: newPricePerKg,
      totalPrice: totalWeight * newPricePerKg,
    );
  }

  /// Create an empty transaction item entity
  factory TransactionItemEntity.empty() {
    return const TransactionItemEntity(
      id: '',
      stockItemId: '',
      itemType: ItemType.paddy,
      variety: '',
      bags: 0,
      totalWeight: 0,
      pricePerKg: 0,
      totalPrice: 0,
    );
  }

  /// Check if entity is empty/invalid
  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        stockItemId,
        itemType,
        variety,
        bags,
        totalWeight,
        pricePerKg,
        totalPrice,
      ];

  @override
  String toString() {
    return 'TransactionItemEntity(id: $id, variety: $variety, bags: $bags, weight: $totalWeight kg, total: $totalPrice)';
  }
}

/// Transaction validation result
class TransactionValidationResult {
  final bool isValid;
  final Map<String, String> errors;

  const TransactionValidationResult({
    required this.isValid,
    this.errors = const {},
  });

  String? getError(String field) => errors[field];

  bool hasError(String field) => errors.containsKey(field);
}

