// lib/features/buy/presentation/cubit/buy_state.dart

import 'package:equatable/equatable.dart';
import '../../../../core/constants/enums.dart';
import '../../../../data/models/customer_model.dart';
import '../../../../data/models/stock_item_model.dart';
import '../../../../data/models/transaction_item_model.dart';
import '../../../../data/models/transaction_model.dart';

/// Buy process status
enum BuyStatus {
  initial,
  loading,
  customerSelected,
  addingItems,
  reviewing,
  processing,
  success,
  error,
}

/// Buy process step
enum BuyStep {
  selectCustomer,
  selectItem,
  enterWeight,
  review,
  complete,
}

/// Temporary item for current buy session
class TempBuyItem extends Equatable {
  final String id;
  final ItemType itemType;
  final String variety;
  final String stockItemId;
  final List<double> bagWeights; // Individual bag weights
  final double totalWeight;
  final double pricePerKg;
  final double totalPrice;
  final bool isPriceSet;

  const TempBuyItem({
    required this.id,
    required this.itemType,
    required this.variety,
    required this.stockItemId,
    this.bagWeights = const [],
    this.totalWeight = 0,
    this.pricePerKg = 0,
    this.totalPrice = 0,
    this.isPriceSet = false,
  });

  /// Get bags count
  int get bagsCount => bagWeights.length;

  /// Get average weight per bag
  double get averageWeightPerBag => bagsCount > 0 ? totalWeight / bagsCount : 0;

  /// Get formatted weight
  String get formattedWeight => '${totalWeight.toStringAsFixed(2)} kg';

  /// Get formatted price
  String get formattedPrice => 'Rs. ${pricePerKg.toStringAsFixed(2)}/kg';

  /// Get formatted total
  String get formattedTotal => 'Rs. ${totalPrice.toStringAsFixed(2)}';

  /// Get display name
  String get displayName =>
      '$variety ${itemType == ItemType.paddy ? 'වී' : 'සහල්'}';

  /// Backward compatibility getters
  double get weightKg => totalWeight;
  int get bagCount => bagsCount;

  /// Copy with method
  TempBuyItem copyWith({
    String? id,
    ItemType? itemType,
    String? variety,
    String? stockItemId,
    List<double>? bagWeights,
    double? totalWeight,
    double? pricePerKg,
    double? totalPrice,
    bool? isPriceSet,
  }) {
    return TempBuyItem(
      id: id ?? this.id,
      itemType: itemType ?? this.itemType,
      variety: variety ?? this.variety,
      stockItemId: stockItemId ?? this.stockItemId,
      bagWeights: bagWeights ?? this.bagWeights,
      totalWeight: totalWeight ?? this.totalWeight,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalPrice: totalPrice ?? this.totalPrice,
      isPriceSet: isPriceSet ?? this.isPriceSet,
    );
  }

  /// Add bag weight
  TempBuyItem addBagWeight(double weight) {
    final newBagWeights = [...bagWeights, weight];
    final newTotalWeight = newBagWeights.fold<double>(0, (sum, w) => sum + w);
    final newTotalPrice = newTotalWeight * pricePerKg;

    return copyWith(
      bagWeights: newBagWeights,
      totalWeight: newTotalWeight,
      totalPrice: newTotalPrice,
    );
  }

  /// Remove last bag weight
  TempBuyItem removeLastBagWeight() {
    if (bagWeights.isEmpty) return this;

    final newBagWeights = bagWeights.sublist(0, bagWeights.length - 1);
    final newTotalWeight = newBagWeights.fold<double>(0, (sum, w) => sum + w);
    final newTotalPrice = newTotalWeight * pricePerKg;

    return copyWith(
      bagWeights: newBagWeights,
      totalWeight: newTotalWeight,
      totalPrice: newTotalPrice,
    );
  }

  /// Set price per kg
  TempBuyItem setPrice(double price) {
    return copyWith(
      pricePerKg: price,
      totalPrice: totalWeight * price,
      isPriceSet: true,
    );
  }

  /// Convert to TransactionItemModel
  TransactionItemModel toTransactionItem(String transactionId) {
    return TransactionItemModel.create(
      transactionId: transactionId,
      stockItemId: stockItemId,
      itemType: itemType,
      variety: variety,
      bags: bagWeights.length,
      quantity: totalWeight,
      pricePerKg: pricePerKg,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemType': itemType.name,
      'variety': variety,
      'stockItemId': stockItemId,
      'bagWeights': bagWeights,
      'totalWeight': totalWeight,
      'pricePerKg': pricePerKg,
      'totalPrice': totalPrice,
      'isPriceSet': isPriceSet,
    };
  }

  /// Create from JSON
  factory TempBuyItem.fromJson(Map<String, dynamic> json) {
    return TempBuyItem(
      id: json['id'] as String,
      itemType: ItemType.values.firstWhere(
        (e) => e.name == json['itemType'],
        orElse: () => ItemType.paddy,
      ),
      variety: json['variety'] as String,
      stockItemId: json['stockItemId'] as String,
      bagWeights: (json['bagWeights'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [],
      totalWeight: (json['totalWeight'] as num).toDouble(),
      pricePerKg: (json['pricePerKg'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      isPriceSet: json['isPriceSet'] as bool,
    );
  }

  @override
  List<Object?> get props => [
        id,
        itemType,
        variety,
        stockItemId,
        bagWeights,
        totalWeight,
        pricePerKg,
        totalPrice,
        isPriceSet,
      ];
}

/// Buy State
class BuyState extends Equatable {
  final BuyStatus status;
  final String? errorMessage;
  final String? successMessage;

  // Navigation
  final BuyStep currentStep;

  // Customer
  final List<CustomerModel> customers;
  final CustomerModel? selectedCustomer;
  final bool isSearchingCustomer;
  final String? savedPhone;
  final String? savedPassword;
  final bool rememberMe;

  // Current item being added
  final ItemType? selectedItemType;
  final String? selectedVariety;
  final String? currentStockItemId;
  final double currentWeight;
  final int currentBags;
  final List<double> currentBagWeights;
  final String currentWeightInput;

  // Temporary items list (Table 1)
  final List<TempBuyItem> tempItems;

  // Summary totals
  final double totalPaddyWeight;
  final double totalRiceWeight;
  final int totalBags;
  final double totalAmount;
  final double pricePerKg;

  // Price input
  final int? editingItemIndex;
  final String priceInput;

  // Transaction details
  final double discount;
  final double discountPercentage;
  final double paidAmount;
  final PaymentMethod? paymentMethod;
  final String? notes;
  final String? vehicleNumber;

  // Processing state
  final bool isSaving;

  // Available varieties
  final List<String> paddyVarieties;
  final List<String> riceVarieties;
  final List<StockItemModel> stockItems;

  // Recent transactions
  final List<TransactionModel> recentTransactions;

  // Created transaction
  final String? transactionId;
  final String? createdTransactionId;
  final String? createdTransactionNumber;

  // Local Session Batches (Table 2 - Not yet in MongoDB)
  final List<TransactionModel> sessionBatches;

  const BuyState({
    this.status = BuyStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.currentStep = BuyStep.selectCustomer,
    this.customers = const [],
    this.selectedCustomer,
    this.isSearchingCustomer = false,
    this.savedPhone,
    this.savedPassword,
    this.rememberMe = false,
    this.selectedItemType,
    this.selectedVariety,
    this.currentStockItemId,
    this.currentWeight = 0.0,
    this.currentBags = 0,
    this.currentBagWeights = const [],
    this.currentWeightInput = '',
    this.tempItems = const [],
    this.totalPaddyWeight = 0.0,
    this.totalRiceWeight = 0.0,
    this.totalBags = 0,
    this.totalAmount = 0.0,
    this.pricePerKg = 0.0,
    this.editingItemIndex,
    this.priceInput = '',
    this.discount = 0,
    this.discountPercentage = 0,
    this.paidAmount = 0,
    this.paymentMethod,
    this.notes,
    this.vehicleNumber,
    this.isSaving = false,
    this.paddyVarieties = const [],
    this.riceVarieties = const [],
    this.stockItems = const [],
    this.recentTransactions = const [],
    this.transactionId,
    this.createdTransactionId,
    this.createdTransactionNumber,
    this.sessionBatches = const [],
  });

  /// Initial state
  factory BuyState.initial() {
    return const BuyState();
  }

  /// Get current bags count
  int get currentBagsCount => currentBagWeights.length;

  /// Get current total weight
  double get currentTotalWeight =>
      currentBagWeights.fold<double>(0, (sum, w) => sum + w);

  /// Get formatted current weight
  String get formattedCurrentWeight =>
      '${currentTotalWeight.toStringAsFixed(2)} kg';

  /// Get subtotal (before discount)
  double get subtotal =>
      tempItems.fold<double>(0, (sum, item) => sum + item.totalPrice);

  /// Get session subtotal (Table 2)
  double get sessionTotalAmount =>
      sessionBatches.fold<double>(0, (sum, batch) => sum + batch.totalAmount);

  /// Get session total weight (Table 2)
  double get sessionTotalWeight => sessionBatches.fold<double>(
      0,
      (sum, batch) =>
          sum +
          batch
              .subtotal); // subtotal in TransactionModel is often used for weight in these Buy sessions

  /// Get calculated discount amount
  double get calculatedDiscount {
    if (discountPercentage > 0) {
      return subtotal * (discountPercentage / 100);
    }
    return discount;
  }

  /// Get due amount
  double get dueAmount => totalAmount - paidAmount;

  /// Get total weight
  double get totalWeight =>
      tempItems.fold<double>(0, (sum, item) => sum + item.totalWeight);

  /// Get formatted subtotal
  String get formattedSubtotal => 'Rs. ${subtotal.toStringAsFixed(2)}';

  /// Get formatted discount
  String get formattedDiscount =>
      'Rs. ${calculatedDiscount.toStringAsFixed(2)}';

  /// Get formatted total
  String get formattedTotal => 'Rs. ${totalAmount.toStringAsFixed(2)}';

  /// Get formatted paid
  String get formattedPaid => 'Rs. ${paidAmount.toStringAsFixed(2)}';

  /// Get formatted due
  String get formattedDue => 'Rs. ${dueAmount.toStringAsFixed(2)}';

  /// Check if can proceed to review
  bool get canProceedToReview {
    return selectedCustomer != null &&
        tempItems.isNotEmpty &&
        tempItems.every((item) => item.isPriceSet);
  }

  /// Check if has items
  bool get hasItems => tempItems.isNotEmpty;

  /// Check if all prices set
  bool get allPricesSet => tempItems.every((item) => item.isPriceSet);

  /// Check if is loading
  bool get isLoading =>
      status == BuyStatus.loading || status == BuyStatus.processing;

  /// Check if is processing
  bool get isProcessing => status == BuyStatus.processing;

  /// Check if is success
  bool get isSuccess => status == BuyStatus.success;

  /// Get varieties by type
  List<String> getVarietiesByType(ItemType type) {
    return type == ItemType.paddy ? paddyVarieties : riceVarieties;
  }

  /// Backward compatibility aliases
  ItemType? get currentItemType => selectedItemType;
  String? get currentVariety => selectedVariety;

  /// Check if can add Table 1 items to Table 2 (ADD BATCH)
  bool get canAddBatch {
    return selectedCustomer != null &&
        tempItems.isNotEmpty &&
        tempItems.every((item) => item.isPriceSet);
  }

  /// Check if can finalize the entire session (CONFIRM / ADD TO STOCK)
  bool get canConfirmStock {
    return selectedCustomer != null &&
        (sessionBatches.isNotEmpty || tempItems.isNotEmpty);
  }

  /// Copy with method
  BuyState copyWith({
    BuyStatus? status,
    String? errorMessage,
    String? successMessage,
    BuyStep? currentStep,
    List<CustomerModel>? customers,
    CustomerModel? selectedCustomer,
    bool? isSearchingCustomer,
    String? savedPhone,
    String? savedPassword,
    bool? rememberMe,
    ItemType? selectedItemType,
    String? selectedVariety,
    String? currentStockItemId,
    double? currentWeight,
    int? currentBags,
    List<double>? currentBagWeights,
    String? currentWeightInput,
    List<TempBuyItem>? tempItems,
    double? totalPaddyWeight,
    double? totalRiceWeight,
    int? totalBags,
    double? totalAmount,
    double? pricePerKg,
    int? editingItemIndex,
    String? priceInput,
    double? discount,
    double? discountPercentage,
    double? paidAmount,
    PaymentMethod? paymentMethod,
    String? notes,
    String? vehicleNumber,
    bool? isSaving,
    List<String>? paddyVarieties,
    List<String>? riceVarieties,
    List<StockItemModel>? stockItems,
    List<TransactionModel>? recentTransactions,
    String? transactionId,
    String? createdTransactionId,
    String? createdTransactionNumber,
    List<TransactionModel>? sessionBatches,
    bool clearError = false,
    bool clearCustomer = false,
    bool clearCurrentItem = false,
    bool clearEditingItem = false,
  }) {
    return BuyState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: successMessage,
      currentStep: currentStep ?? this.currentStep,
      customers: customers ?? this.customers,
      selectedCustomer:
          clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      isSearchingCustomer: isSearchingCustomer ?? this.isSearchingCustomer,
      savedPhone: savedPhone ?? this.savedPhone,
      savedPassword: savedPassword ?? this.savedPassword,
      rememberMe: rememberMe ?? this.rememberMe,
      selectedItemType:
          clearCurrentItem ? null : (selectedItemType ?? this.selectedItemType),
      selectedVariety:
          clearCurrentItem ? null : (selectedVariety ?? this.selectedVariety),
      currentStockItemId: clearCurrentItem
          ? null
          : (currentStockItemId ?? this.currentStockItemId),
      currentWeight:
          clearCurrentItem ? 0.0 : (currentWeight ?? this.currentWeight),
      currentBags: clearCurrentItem ? 0 : (currentBags ?? this.currentBags),
      currentBagWeights: clearCurrentItem
          ? const []
          : (currentBagWeights ?? this.currentBagWeights),
      currentWeightInput: clearCurrentItem
          ? ''
          : (currentWeightInput ?? this.currentWeightInput),
      tempItems: tempItems ?? this.tempItems,
      totalPaddyWeight: totalPaddyWeight ?? this.totalPaddyWeight,
      totalRiceWeight: totalRiceWeight ?? this.totalRiceWeight,
      totalBags: totalBags ?? this.totalBags,
      totalAmount: totalAmount ?? this.totalAmount,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      editingItemIndex:
          clearEditingItem ? null : (editingItemIndex ?? this.editingItemIndex),
      priceInput: clearEditingItem ? '' : (priceInput ?? this.priceInput),
      discount: discount ?? this.discount,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      isSaving: isSaving ?? this.isSaving,
      paddyVarieties: paddyVarieties ?? this.paddyVarieties,
      riceVarieties: riceVarieties ?? this.riceVarieties,
      stockItems: stockItems ?? this.stockItems,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      transactionId: transactionId ?? this.transactionId,
      createdTransactionId: createdTransactionId ?? this.createdTransactionId,
      createdTransactionNumber:
          createdTransactionNumber ?? this.createdTransactionNumber,
      sessionBatches: sessionBatches ?? this.sessionBatches,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        successMessage,
        currentStep,
        customers,
        selectedCustomer,
        isSearchingCustomer,
        savedPhone,
        savedPassword,
        rememberMe,
        selectedItemType,
        selectedVariety,
        currentStockItemId,
        currentWeight,
        currentBags,
        currentBagWeights,
        currentWeightInput,
        tempItems,
        totalPaddyWeight,
        totalRiceWeight,
        totalBags,
        totalAmount,
        pricePerKg,
        editingItemIndex,
        priceInput,
        discount,
        discountPercentage,
        paidAmount,
        paymentMethod,
        notes,
        vehicleNumber,
        isSaving,
        paddyVarieties,
        riceVarieties,
        stockItems,
        recentTransactions,
        transactionId,
        createdTransactionId,
        createdTransactionNumber,
        sessionBatches,
      ];
}
