// lib/data/models/transaction_model.dart

import 'package:equatable/equatable.dart';
import '../../core/constants/db_constants.dart';
import '../../core/constants/enums.dart';
import '../../domain/entities/transaction_entity.dart';
import 'transaction_item_model.dart';

class TransactionModel extends Equatable {
  final int? localId;
  final String id;
  final String? serverId;
  final String transactionNumber;
  final TransactionType type; // Buy or Sell
  final TransactionStatus status;
  final String customerId;
  final int? customerLocalId; // Added field for FK
  final String? customerName;
  final String? customerPhone;
  final String companyId;
  final List<TransactionItemModel> items;
  final double subtotal; // Total before adjustments
  final double discount; // Discount amount
  final double totalAmount; // Final amount
  final double paidAmount; // Amount paid
  final double dueAmount; // Remaining amount
  final PaymentStatus paymentStatus;
  final PaymentMethod? paymentMethod;
  final String? notes;
  final String? cancelReason;
  final String? invoicePath; // Local path to PDF invoice
  final String createdBy; // User ID who created
  final String? createdByName;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final DateTime? syncedAt;
  final bool isDeleted;
  final SyncStatus syncStatus;

  const TransactionModel({
    this.localId,
    required this.id,
    this.serverId,
    required this.transactionNumber,
    required this.type,
    this.status = TransactionStatus.pending,
    required this.customerId,
    this.customerLocalId,
    this.customerName,
    this.customerPhone,
    required this.companyId,
    this.items = const [],
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.totalAmount = 0.0,
    this.paidAmount = 0.0,
    this.dueAmount = 0.0,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentMethod,
    this.notes,
    this.cancelReason,
    this.invoicePath,
    required this.createdBy,
    this.createdByName,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.syncStatus = SyncStatus.pending,
    this.syncedAt,
    this.isDeleted = false,
  });

  /// Create from JSON (API or Local DB)
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    List<TransactionItemModel> items = [];
    if (json['items'] != null && json['items'] is List) {
      items = (json['items'] as List)
          .map((item) =>
              TransactionItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return TransactionModel(
      id: json['transaction_id']?.toString() ??
          json['id']?.toString() ??
          json['_id']?.toString() ??
          '',
      serverId: json['server_id']?.toString() ?? json['_id']?.toString(),
      transactionNumber: json['transaction_number']?.toString() ??
          json['transactionNumber']?.toString() ??
          '',
      type: _parseTransactionType(json['transaction_type'] ?? json['type']),
      status:
          _parseTransactionStatus(json['status'] ?? json['transaction_status']),
      customerId: (json['customer_id'] ?? json['customerId'])?.toString() ?? '',
      customerLocalId: json['customer_local_id'] is int
          ? json['customer_local_id']
          : int.tryParse(json['customer_local_id']?.toString() ?? ''),
      customerName:
          json['customer_name']?.toString() ?? json['customerName']?.toString(),
      customerPhone: json['customer_phone']?.toString() ??
          json['customerPhone']?.toString(),
      companyId:
          json['company_id']?.toString() ?? json['companyId']?.toString() ?? '',
      items: items,
      subtotal: _parseDouble(
          json['subtotal'] ?? json['total_weight_kg'] ?? json['totalWeightKg']),
      discount: _parseDouble(json['discount']),
      totalAmount: _parseDouble(json['total_amount'] ?? json['totalAmount']),
      paidAmount: _parseDouble(json['paid_amount'] ?? json['paidAmount']),
      dueAmount: _parseDouble(json['due_amount'] ?? json['balance'] ?? 0.0),
      paymentStatus:
          _parsePaymentStatus(json['payment_status'] ?? json['paymentStatus']),
      paymentMethod: (json['payment_method'] ?? json['paymentMethod']) != null
          ? _parsePaymentMethod(json['payment_method'] ?? json['paymentMethod'])
          : null,
      notes: json['notes']?.toString(),
      cancelReason:
          json['cancel_reason']?.toString() ?? json['cancelReason']?.toString(),
      invoicePath:
          json['invoice_path']?.toString() ?? json['invoicePath']?.toString(),
      createdBy:
          json['created_by']?.toString() ?? json['createdBy']?.toString() ?? '',
      createdByName: json['created_by_name']?.toString() ??
          json['createdByName']?.toString(),
      transactionDate:
          _parseDateTime(json['transaction_date'] ?? json['transactionDate']) ??
              DateTime.now(),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']) ??
          DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']) ??
          DateTime.now(),
      isSynced: json['is_synced'] == true ||
          json['is_synced'] == 1 ||
          json['isSynced'] == true,
      syncedAt: _parseDateTime(json['synced_at'] ?? json['syncedAt']),
      isDeleted: json['is_deleted'] == true ||
          json['is_deleted'] == 1 ||
          json['isDeleted'] == true,
    );
  }

  /// Convert to JSON for Local DB (without items)
  Map<String, dynamic> toJsonWithoutItems() {
    final map = {
      'transaction_id': id,
      'server_id': serverId,
      'transaction_number': transactionNumber,
      'transaction_type': type.name,
      'status': status.name,
      'customer_local_id': customerLocalId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'company_id': companyId,
      'subtotal': subtotal,
      'discount': discount,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'due_amount': dueAmount,
      'total_bags': items.fold<int>(0, (sum, item) => sum + item.bags),
      'payment_status': paymentStatus.name,
      'payment_method': paymentMethod?.name,
      'notes': notes,
      'cancel_reason': cancelReason,
      'invoice_path': invoicePath,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'sync_status': syncStatus.value,
      'synced_at': syncedAt?.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };

    if (localId != null) {
      map[DbConstants.colLocalId] = localId;
    }

    return map;
  }

  /// Convert to JSON with items
  Map<String, dynamic> toJson() {
    final json = toJsonWithoutItems();
    json['items'] = items.map((item) => item.toJson()).toList();
    return json;
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJsonForApi() {
    return {
      'id': id, // Send local UUID to prevent duplicates
      'transactionNumber': transactionNumber,
      'type': type.name,
      'customerId': customerId,
      'companyId': companyId,
      'items': items.map((item) => item.toJsonForApi()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'paymentMethod': paymentMethod?.name ?? 'cash',
      'notes': notes,
      'transactionDate': transactionDate.toIso8601String(),
    };
  }

  /// Convert to JSON for Sync
  Map<String, dynamic> toJsonForSync() {
    return {
      'local_id': id,
      'server_id': serverId,
      'transaction_number': transactionNumber,
      'type': type.name,
      'status': status.name,
      'customer_id': customerId,
      'items': items.map((item) => item.toJsonForSync()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'due_amount': dueAmount,
      'payment_status': paymentStatus.name,
      'payment_method': paymentMethod?.name,
      'notes': notes,
      'cancel_reason': cancelReason,
      'is_deleted': isDeleted,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to Entity
  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      transactionNumber: transactionNumber,
      type: type,
      status: status,
      customerId: customerId,
      customerName: customerName ?? '',
      items: items.map((item) => item.toEntity()).toList(),
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      transactionDate: transactionDate,
    );
  }

  /// Create new buy transaction
  factory TransactionModel.createBuy({
    required String transactionNumber,
    required String customerId,
    int? customerLocalId,
    String? customerName,
    String? customerPhone,
    required String companyId,
    required String createdBy,
    String? createdByName,
    List<TransactionItemModel> items = const [],
    double discount = 0.0,
    String? notes,
  }) {
    final now = DateTime.now();
    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + item.totalAmount,
    );
    final totalAmount = subtotal - discount;

    return TransactionModel(
      id: 'TXN_BUY_${now.millisecondsSinceEpoch}',
      transactionNumber: transactionNumber,
      type: TransactionType.buy,
      status: TransactionStatus.pending,
      customerId: customerId,
      customerLocalId: customerLocalId,
      customerName: customerName,
      customerPhone: customerPhone,
      companyId: companyId,
      items: items,
      subtotal: subtotal,
      discount: discount,
      totalAmount: totalAmount,
      dueAmount: totalAmount,
      notes: notes,
      createdBy: createdBy,
      createdByName: createdByName,
      transactionDate: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create new sell transaction
  factory TransactionModel.createSell({
    required String transactionNumber,
    required String customerId,
    int? customerLocalId,
    String? customerName,
    String? customerPhone,
    required String companyId,
    required String createdBy,
    String? createdByName,
    List<TransactionItemModel> items = const [],
    double discount = 0.0,
    String? notes,
  }) {
    final now = DateTime.now();
    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + item.totalAmount,
    );
    final totalAmount = subtotal - discount;

    return TransactionModel(
      id: 'TXN_SELL_${now.millisecondsSinceEpoch}',
      transactionNumber: transactionNumber,
      type: TransactionType.sell,
      status: TransactionStatus.pending,
      customerId: customerId,
      customerLocalId: customerLocalId,
      customerName: customerName,
      customerPhone: customerPhone,
      companyId: companyId,
      items: items,
      subtotal: subtotal,
      discount: discount,
      totalAmount: totalAmount,
      dueAmount: totalAmount,
      notes: notes,
      createdBy: createdBy,
      createdByName: createdByName,
      transactionDate: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Copy with new values
  TransactionModel copyWith({
    int? localId,
    String? id,
    String? serverId,
    String? transactionNumber,
    TransactionType? type,
    TransactionStatus? status,
    String? customerId,
    int? customerLocalId,
    String? customerName,
    String? customerPhone,
    String? companyId,
    List<TransactionItemModel>? items,
    double? subtotal,
    double? discount,
    double? totalAmount,
    double? paidAmount,
    double? dueAmount,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    String? notes,
    String? cancelReason,
    String? invoicePath,
    String? createdBy,
    String? createdByName,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    SyncStatus? syncStatus,
    DateTime? syncedAt,
    bool? isDeleted,
  }) {
    return TransactionModel(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      transactionNumber: transactionNumber ?? this.transactionNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      customerId: customerId ?? this.customerId,
      customerLocalId: customerLocalId ?? this.customerLocalId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      companyId: companyId ?? this.companyId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      cancelReason: cancelReason ?? this.cancelReason,
      invoicePath: invoicePath ?? this.invoicePath,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      syncStatus: syncStatus ?? this.syncStatus,
      syncedAt: syncedAt ?? this.syncedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// Create from DB map
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      localId: (map[DbConstants.colLocalId] is int)
          ? map[DbConstants.colLocalId] as int
          : (map[DbConstants.colLocalId] != null
              ? int.tryParse(map[DbConstants.colLocalId].toString())
              : null),
      id: map['transaction_id']?.toString() ?? map['id']?.toString() ?? '',
      serverId: map[DbConstants.colServerId]?.toString(),
      transactionNumber: map['transaction_number']?.toString() ?? '',
      type: _parseTransactionType(map['transaction_type'] ?? map['type']),
      status:
          _parseTransactionStatus(map['status'] ?? map['transaction_status']),
      customerId: (map['customer_id'])?.toString() ?? '',
      customerLocalId: map['customer_local_id'] is int
          ? map['customer_local_id']
          : int.tryParse(map['customer_local_id']?.toString() ?? ''),
      customerName: map['customer_name']?.toString(),
      customerPhone: map['customer_phone']?.toString(),
      companyId: map['company_id']?.toString() ?? '',
      items: const [],
      subtotal: _parseDouble(map['total_weight_kg'] ?? map['subtotal']),
      discount: _parseDouble(map['discount']),
      totalAmount: _parseDouble(map['total_amount']),
      paidAmount: _parseDouble(map['paid_amount']),
      dueAmount: _parseDouble(map['due_amount'] ?? 0.0),
      paymentStatus:
          _parsePaymentStatus(map['payment_status'] ?? map['payment_status']),
      paymentMethod: map['payment_method'] != null
          ? _parsePaymentMethod(map['payment_method'])
          : null,
      notes: map['notes']?.toString(),
      cancelReason: map['cancel_reason']?.toString(),
      invoicePath: map['invoice_path']?.toString(),
      createdBy: map['created_by']?.toString() ?? '',
      createdByName: map['created_by_name']?.toString(),
      transactionDate:
          _parseDateTime(map['transaction_date']) ?? DateTime.now(),
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
    return toJsonWithoutItems();
  }

  /// Backwards-compatible getters used by older code
  String get transactionId => transactionNumber;
  TransactionType get transactionType => type;
  double get totalWeightKg => subtotal;
  double get pricePerKg {
    final w = totalWeightKg;
    if (w > 0) return totalAmount / w;
    return 0.0;
  }

  double get balanceDue => dueAmount;

  /// Add item to transaction
  TransactionModel addItem(TransactionItemModel item) {
    final newItems = [...items, item.copyWith(transactionId: id)];
    return _recalculateTotals(newItems);
  }

  /// Update item in transaction
  TransactionModel updateItem(TransactionItemModel updatedItem) {
    final newItems = items.map((item) {
      return item.id == updatedItem.id ? updatedItem : item;
    }).toList();
    return _recalculateTotals(newItems);
  }

  /// Remove item from transaction
  TransactionModel removeItem(String itemId) {
    final newItems = items.where((item) => item.id != itemId).toList();
    return _recalculateTotals(newItems);
  }

  /// Recalculate totals
  TransactionModel _recalculateTotals(List<TransactionItemModel> newItems) {
    final newSubtotal = newItems.fold<double>(
      0,
      (sum, item) => sum + item.totalAmount,
    );
    final newTotal = newSubtotal - discount;
    final newDue = newTotal - paidAmount;

    return copyWith(
      items: newItems,
      subtotal: newSubtotal,
      totalAmount: newTotal,
      dueAmount: newDue,
      paymentStatus: _calculatePaymentStatus(paidAmount, newTotal),
      updatedAt: DateTime.now(),
      isSynced: false,
    );
  }

  /// Add payment
  TransactionModel addPayment({
    required double amount,
    PaymentMethod? method,
  }) {
    final newPaidAmount = paidAmount + amount;
    final newDueAmount = totalAmount - newPaidAmount;
    final newPaymentStatus =
        _calculatePaymentStatus(newPaidAmount, totalAmount);

    return copyWith(
      paidAmount: newPaidAmount,
      dueAmount: newDueAmount,
      paymentStatus: newPaymentStatus,
      paymentMethod: method ?? paymentMethod,
      status: newPaymentStatus == PaymentStatus.completed
          ? TransactionStatus.completed
          : status,
      updatedAt: DateTime.now(),
      isSynced: false,
    );
  }

  /// Calculate payment status
  PaymentStatus _calculatePaymentStatus(double paid, double total) {
    if (paid <= 0) return PaymentStatus.pending;
    if (paid >= total) return PaymentStatus.completed;
    return PaymentStatus.partial;
  }

  /// Parse helpers
  static TransactionType _parseTransactionType(dynamic value) {
    if (value == null) return TransactionType.buy;
    if (value is TransactionType) return value;
    return value.toString().toLowerCase() == 'sell'
        ? TransactionType.sell
        : TransactionType.buy;
  }

  static TransactionStatus _parseTransactionStatus(dynamic value) {
    if (value == null) return TransactionStatus.pending;
    if (value is TransactionStatus) return value;

    switch (value.toString().toLowerCase()) {
      case 'completed':
        return TransactionStatus.completed;
      case 'cancelled':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.pending;
    }
  }

  static PaymentStatus _parsePaymentStatus(dynamic value) {
    if (value == null) return PaymentStatus.pending;
    if (value is PaymentStatus) return value;

    switch (value.toString().toLowerCase()) {
      case 'completed':
        return PaymentStatus.completed;
      case 'partial':
        return PaymentStatus.partial;
      default:
        return PaymentStatus.pending;
    }
  }

  static PaymentMethod _parsePaymentMethod(dynamic value) {
    if (value is PaymentMethod) return value;

    switch (value.toString().toLowerCase()) {
      case 'banktransfer':
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'cheque':
        return PaymentMethod.cheque;
      case 'credit':
        return PaymentMethod.credit;
      default:
        return PaymentMethod.cash;
    }
  }

  static SyncStatus _parseSyncStatus(dynamic value) {
    if (value == null) return SyncStatus.pending;
    if (value is SyncStatus) return value;

    switch (value.toString().toLowerCase()) {
      case 'syncing':
        return SyncStatus.syncing;
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

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Display helpers
  String get displayType => type == TransactionType.buy ? 'Purchase' : 'Sale';
  String get displayTypeSi =>
      type == TransactionType.buy ? 'මිලදී ගැනීම' : 'විකිණීම';

  String get displayStatus {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get displayPaymentStatus {
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

  bool get isPending => status == TransactionStatus.pending;
  bool get isCompleted => status == TransactionStatus.completed;
  bool get isCancelled => status == TransactionStatus.cancelled;
  bool get isPaid => paymentStatus == PaymentStatus.completed;
  bool get hasItems => items.isNotEmpty;

  int get totalBags => items.fold<int>(0, (sum, item) => sum + item.bags);
  double get totalWeight =>
      items.fold<double>(0, (sum, item) => sum + item.quantity);

  @override
  List<Object?> get props => [
        id,
        serverId,
        transactionNumber,
        type,
        status,
        customerId,
        totalAmount,
        paymentStatus,
        isSynced,
        isDeleted,
      ];

  @override
  String toString() =>
      'TransactionModel(id: $id, number: $transactionNumber, type: ${type.name}, amount: $totalAmount)';
}

