// lib/features/sell/presentation/cubit/sell_state.dart

import 'package:equatable/equatable.dart';
import '../../../../data/models/customer_model.dart';
import '../../../../data/models/stock_item_model.dart';
import '../../../../core/constants/enums.dart';

enum SellStatus {
  initial,
  loading,
  loaded,
  processing,
  success,
  error,
}

enum SellStep {
  selectCustomer,
  selectItems,
  review,
  complete,
}

class SellState extends Equatable {
  final SellStatus status;
  final SellStep currentStep;
  final List<CustomerModel> customers;
  final CustomerModel? selectedCustomer;
  final List<StockItemModel> availableStock;
  final List<SellItemEntry> sellItems;
  final StockItemModel? selectedStockItem;
  final ItemType selectedItemType; // New field
  final double inputQuantity;
  final double inputPrice;
  final String? errorMessage;
  final String? successMessage;
  final String? generatedInvoiceId;
  final bool isSynced;
  final String searchQuery;
  final double totalAmount;
  final double totalWeight;
  final int totalBags;

  const SellState({
    this.status = SellStatus.initial,
    this.currentStep = SellStep.selectCustomer,
    this.customers = const [],
    this.selectedCustomer,
    this.availableStock = const [],
    this.sellItems = const [],
    this.selectedStockItem,
    this.selectedItemType = ItemType.paddy, // Initialize new field
    this.inputQuantity = 0.0,
    this.inputPrice = 0.0,
    this.errorMessage,
    this.successMessage,
    this.generatedInvoiceId,
    this.isSynced = true,
    this.searchQuery = '',
    this.totalAmount = 0.0,
    this.totalWeight = 0.0,
    this.totalBags = 0,
  });

  // Calculated getters
  double get currentItemTotal => inputQuantity * inputPrice;

  double get grandTotal {
    return sellItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get grandTotalWeight {
    return sellItems.fold(0.0, (sum, item) => sum + item.quantity);
  }

  int get grandTotalBags {
    return sellItems.fold(0, (sum, item) => sum + item.bags);
  }

  bool get canAddItem {
    return selectedStockItem != null &&
        inputQuantity > 0 &&
        inputPrice > 0 &&
        inputQuantity <= (selectedStockItem?.currentQuantity ?? 0);
  }

  bool get canFinalize {
    return selectedCustomer != null && sellItems.isNotEmpty;
  }

  List<CustomerModel> get filteredCustomers {
    if (searchQuery.isEmpty) return customers;
    final query = searchQuery.toLowerCase();
    return customers.where((c) {
      return c.name.toLowerCase().contains(query) || c.phone.contains(query);
    }).toList();
  }

  SellState copyWith({
    SellStatus? status,
    SellStep? currentStep,
    List<CustomerModel>? customers,
    CustomerModel? selectedCustomer,
    bool clearSelectedCustomer = false,
    List<StockItemModel>? availableStock,
    List<SellItemEntry>? sellItems,
    StockItemModel? selectedStockItem,
    bool clearSelectedStockItem = false,
    ItemType? selectedItemType,
    double? inputQuantity,
    double? inputPrice,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
    String? generatedInvoiceId,
    bool clearInvoiceId = false,
    bool? isSynced,
    String? searchQuery,
    double? totalAmount,
    double? totalWeight,
    int? totalBags,
  }) {
    return SellState(
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      customers: customers ?? this.customers,
      selectedCustomer: clearSelectedCustomer
          ? null
          : (selectedCustomer ?? this.selectedCustomer),
      availableStock: availableStock ?? this.availableStock,
      sellItems: sellItems ?? this.sellItems,
      selectedStockItem: clearSelectedStockItem
          ? null
          : (selectedStockItem ?? this.selectedStockItem),
      inputQuantity: inputQuantity ?? this.inputQuantity,
      inputPrice: inputPrice ?? this.inputPrice,
      selectedItemType: selectedItemType ?? this.selectedItemType,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      generatedInvoiceId: clearInvoiceId
          ? null
          : (generatedInvoiceId ?? this.generatedInvoiceId),
      isSynced: isSynced ?? this.isSynced,
      searchQuery: searchQuery ?? this.searchQuery,
      totalAmount: totalAmount ?? grandTotal,
      totalWeight: totalWeight ?? grandTotalWeight,
      totalBags: totalBags ?? grandTotalBags,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentStep,
        customers,
        selectedCustomer,
        availableStock,
        sellItems,
        selectedStockItem,
        selectedItemType,
        inputQuantity,
        inputPrice,
        errorMessage,
        successMessage,
        generatedInvoiceId,
        isSynced,
        searchQuery,
        totalAmount,
        totalWeight,
        totalBags,
      ];
}

// Sell Item Entry Model
class SellItemEntry extends Equatable {
  final String id;
  final String stockItemId;
  final String itemName;
  final String itemType; // 'paddy' or 'rice'
  final String variety;
  final int bags;
  final double quantity; // in kg
  final double pricePerKg;
  final double totalPrice;
  final DateTime addedAt;

  const SellItemEntry({
    required this.id,
    required this.stockItemId,
    required this.itemName,
    required this.itemType,
    required this.variety,
    required this.bags,
    required this.quantity,
    required this.pricePerKg,
    required this.totalPrice,
    required this.addedAt,
  });

  SellItemEntry copyWith({
    String? id,
    String? stockItemId,
    String? itemName,
    String? itemType,
    String? variety,
    int? bags,
    double? quantity,
    double? pricePerKg,
    double? totalPrice,
    DateTime? addedAt,
  }) {
    return SellItemEntry(
      id: id ?? this.id,
      stockItemId: stockItemId ?? this.stockItemId,
      itemName: itemName ?? this.itemName,
      itemType: itemType ?? this.itemType,
      variety: variety ?? this.variety,
      bags: bags ?? this.bags,
      quantity: quantity ?? this.quantity,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalPrice: totalPrice ?? this.totalPrice,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stock_item_id': stockItemId,
      'item_name': itemName,
      'item_type': itemType,
      'variety': variety,
      'bags': bags,
      'quantity': quantity,
      'price_per_kg': pricePerKg,
      'total_price': totalPrice,
      'added_at': addedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        stockItemId,
        itemName,
        itemType,
        variety,
        bags,
        quantity,
        pricePerKg,
        totalPrice,
        addedAt,
      ];
}
