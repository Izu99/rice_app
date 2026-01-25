import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/constants/paddy_constants.dart';
import '../../../../data/models/customer_model.dart';
import '../../../../data/models/stock_item_model.dart';
import '../../../../data/models/transaction_item_model.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../domain/repositories/customer_repository.dart';
import '../../../../domain/repositories/stock_repository.dart';
import '../../../../domain/repositories/transaction_repository.dart';
import '../../../../domain/repositories/auth_repository.dart'; // Import AuthRepository
import 'buy_state.dart';

class BuyCubit extends Cubit<BuyState> {
  final CustomerRepository _customerRepository; // Add back CustomerRepository
  final TransactionRepository _transactionRepository;
  final AuthRepository _authRepository;
  final StockRepository _stockRepository;
  final Uuid _uuid = const Uuid();

  String _companyId = ''; // To store the current user's company ID

  BuyCubit({
    required CustomerRepository customerRepository,
    required TransactionRepository transactionRepository,
    required AuthRepository authRepository,
    required StockRepository stockRepository,
  })  : _customerRepository = customerRepository,
        _transactionRepository = transactionRepository,
        _authRepository = authRepository,
        _stockRepository = stockRepository,
        super(const BuyState(
          paddyVarieties: PaddyConstants.paddyVarieties,
          riceVarieties: PaddyConstants.riceVarieties,
        ));

  // Initialize / Load customers
  Future<void> initialize() async {
    emit(state.copyWith(status: BuyStatus.loading));

    // 1. Try to get company ID from LOCAL storage first (FAST - no network)
    if (_companyId.isEmpty) {
      final companyResult = await _authRepository.getCompany();
      companyResult.fold(
        (_) => null,
        (company) {
          if (company != null) {
            _companyId = company.id;
            debugPrint('✅ [BuyCubit] Found company ID: $_companyId');
          }
        },
      );
    }

    // 2. If still empty, try from user (local first, remote fallback)
    if (_companyId.isEmpty) {
      final userResult = await _authRepository.getCurrentUser();
      userResult.fold(
        (failure) =>
            debugPrint('⚠️ [BuyCubit] Could not get user: ${failure.message}'),
        (user) {
          _companyId = user.companyId;
          debugPrint('✅ [BuyCubit] Found company ID from user: $_companyId');
        },
      );
    }

    if (_companyId.isEmpty) {
      debugPrint(
          '⚠️ [BuyCubit] No company ID - may be offline, continuing anyway...');
    }

    // 3. Load data from LOCAL storage (this is always FAST)
    final result = await _customerRepository.getAllCustomers();
    final transactionsResult = await _transactionRepository
        .getTodayTransactions(type: TransactionType.buy);

    // Load Stock Items to ensure state is fresh
    final stockResult = await _stockRepository.getAllStockItems();
    List<StockItemModel> stockItems = [];
    stockResult.fold(
      (_) => null,
      (items) => stockItems =
          items.map((e) => StockItemModel.fromEntity(e, _companyId)).toList(),
    );

    List<TransactionModel> recentTransactions = [];
    transactionsResult.fold(
      (failure) => null,
      (transactions) {
        recentTransactions = transactions
            .map((e) => TransactionModel(
                  id: e.id,
                  transactionNumber: e.transactionNumber,
                  type: e.type,
                  status: e.status,
                  customerId: e.customerId,
                  customerName: e.customerName,
                  companyId: '',
                  items: e.items
                      .map((item) => TransactionItemModel(
                            id: item.id,
                            transactionId: e.id,
                            stockItemId: '',
                            itemType: item.itemType,
                            variety: item.variety,
                            bags: item.bags,
                            quantity: item.totalWeight,
                            pricePerKg: item.pricePerKg,
                            totalAmount: item.totalPrice,
                            createdAt: e.transactionDate,
                          ))
                      .toList(),
                  subtotal: e.totalWeight,
                  totalAmount: e.totalAmount,
                  paidAmount: e.paidAmount,
                  createdBy: '',
                  transactionDate: e.transactionDate,
                  createdAt: e.transactionDate,
                  updatedAt: e.transactionDate,
                ))
            .toList();
      },
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: BuyStatus.error,
        errorMessage: failure.message,
      )),
      (customers) => emit(state.copyWith(
        status: BuyStatus.success,
        customers: customers
            .map((e) => CustomerModel.fromEntity(e, _companyId))
            .toList(),
        recentTransactions: recentTransactions,
        stockItems: stockItems,
      )),
    );
  }

  // Search customers
  Future<void> searchCustomers(String query) async {
    if (query.isEmpty) {
      emit(state.copyWith(isSearchingCustomer: false));
      await initialize();
      return;
    }

    emit(state.copyWith(isSearchingCustomer: true));

    final result = await _customerRepository.searchCustomers(query);

    result.fold(
      (failure) => emit(state.copyWith(
        isSearchingCustomer: false,
        errorMessage: failure.message,
      )),
      (customers) => emit(state.copyWith(
        isSearchingCustomer: false,
        customers:
            customers.map((e) => CustomerModel.fromEntity(e, '')).toList(),
      )),
    );
  }

  // Check if phone exists
  Future<CustomerModel?> checkPhoneExists(String phone) async {
    final result = await _customerRepository.getCustomerByPhone(phone);
    return result.fold(
      (failure) => null,
      (customer) =>
          customer != null ? CustomerModel.fromEntity(customer, '') : null,
    );
  }

  // Select customer
  Future<void> selectCustomer(CustomerModel customer) async {
    emit(state.copyWith(
      selectedCustomer: customer,
      selectedItemType: ItemType.paddy, // Mill only buys paddy
      selectedVariety: 'Nadu', // Default variety
      currentStep: BuyStep.selectItem,
      clearError: true,
    ));
    if (customer.id.isNotEmpty) {
      await _loadPendingItems(customer.id);
      await _loadSessionBatches(customer.id);
      // await _loadRecentTransactions(customer.id); // This method doesn't exist, assuming it was a placeholder
    }
  }

  // Clear selected customer
  void clearCustomer() {
    emit(state.copyWith(
      clearCustomer: true,
      currentStep: BuyStep.selectCustomer,
    ));
  }

  // Select item type
  void selectItemType(ItemType type, {String? variety}) {
    final stockItemId = variety != null
        ? state.stockItems
            .firstWhere(
              (item) => item.type == type && item.variety == variety,
              orElse: () => StockItemModel.create(
                type: state.selectedItemType,
                variety: variety,
                companyId: _companyId,
              ),
            )
            .id
        : null;

    emit(state.copyWith(
      selectedItemType: type,
      selectedVariety: variety,
      currentStockItemId: stockItemId,
      currentStep: BuyStep.enterWeight,
      currentWeight: 0.0,
      currentBags: 0,
      clearError: true,
    ));
  }

  // Clear item selection
  void clearItemType() {
    emit(state.copyWith(
      clearCurrentItem: true,
      currentStep: BuyStep.selectItem,
      currentWeight: 0.0,
      currentBags: 0,
    ));
  }

  // Select item variety
  void updateVariety(String variety) {
    if (state.selectedVariety == variety) return;

    final stockItemId = state.stockItems
        .firstWhere(
          (item) =>
              item.type == state.selectedItemType && item.variety == variety,
          orElse: () => StockItemModel.create(
            type: state.selectedItemType ?? ItemType.paddy,
            variety: variety,
            companyId: _companyId,
          ),
        )
        .id;

    emit(state.copyWith(
      selectedVariety: variety,
      currentStockItemId: stockItemId,
      currentWeight: 0.0,
      currentBags: 0,
      clearError: true,
    ));
  }

  // Update current weight
  void updateWeight(double weight) {
    emit(state.copyWith(currentWeight: weight));
  }

  // Update current bags
  void updateBags(int bags) {
    emit(state.copyWith(currentBags: bags));
  }

  // Clear only the current batch inputs
  void clearCurrentBatch() {
    emit(state.copyWith(
      currentWeight: 0.0,
      currentBags: 0,
    ));
  }

  // Add bag with weight
  void addBagWithWeight(double weight) {
    if (weight <= 0) return;

    final existingItemIndex = state.tempItems.indexWhere(
      (item) =>
          item.itemType == state.selectedItemType &&
          item.variety == state.selectedVariety,
    );

    List<TempBuyItem> updatedItems;
    if (existingItemIndex != -1) {
      final existingItem = state.tempItems[existingItemIndex];
      final updatedItem = existingItem.addBagWeight(weight);
      updatedItems = List.from(state.tempItems);
      updatedItems[existingItemIndex] = updatedItem;
    } else {
      final newItem = TempBuyItem(
        id: _uuid.v4(),
        itemType: state.selectedItemType!,
        variety: (state.selectedVariety ?? '').trim(),
        stockItemId: state.currentStockItemId ?? '',
        bagWeights: [weight],
        totalWeight: weight,
      );
      updatedItems = [...state.tempItems, newItem];
    }

    _updateStateWithNewTotals(updatedItems);
  }

  void _updateStateWithNewTotals(List<TempBuyItem> updatedItems,
      {bool clearCurrent = false}) {
    double paddyWeight = 0.0;
    double riceWeight = 0.0;
    int totalBags = 0;
    double totalAmount = 0.0;

    for (final item in updatedItems) {
      if (item.itemType == ItemType.paddy) {
        paddyWeight += item.totalWeight;
      } else if (item.itemType == ItemType.rice) {
        riceWeight += item.totalWeight;
      }
      totalBags += item.bagsCount;
      totalAmount += item.totalPrice;
    }

    emit(state.copyWith(
      tempItems: updatedItems,
      currentWeight: clearCurrent ? 0.0 : state.currentWeight,
      currentBags: clearCurrent ? 0 : state.currentBags,
      totalPaddyWeight: paddyWeight,
      totalRiceWeight: riceWeight,
      totalBags: totalBags,
      totalAmount: totalAmount,
    ));

    // Save pending items
    _savePendingItems(updatedItems);
  }

  // Add current entry to temp list
  void addToTempList() {
    if (state.currentWeight <= 0 || state.selectedItemType == null) return;

    final bagCount = state.currentBags > 0 ? state.currentBags : 1;
    final averageWeight = state.currentWeight / bagCount;
    final bagWeights = List<double>.filled(bagCount, averageWeight);

    final newItem = TempBuyItem(
      id: _uuid.v4(),
      itemType: state.selectedItemType!,
      variety: (state.selectedVariety ?? 'Nadu').trim(),
      stockItemId: state.currentStockItemId ?? '',
      bagWeights: bagWeights,
      totalWeight: state.currentWeight,
      pricePerKg: state.pricePerKg,
      totalPrice: state.currentWeight * state.pricePerKg,
      isPriceSet: state.pricePerKg > 0,
    );

    final updatedItems = [...state.tempItems, newItem];

    _updateStateWithNewTotals(updatedItems, clearCurrent: true);
  }

  // Remove temp item
  void removeTempItem(String id) {
    final updatedItems =
        state.tempItems.where((item) => item.id != id).toList();
    _updateStateWithNewTotals(updatedItems);
  }

  // Set price per kg
  void setPricePerKg(double price) {
    // Update all current temp items with this price if needed, or just set for next
    final updatedItems = state.tempItems.map((item) {
      return item.copyWith(
        pricePerKg: price,
        totalPrice: item.totalWeight * price,
        isPriceSet: price > 0,
      );
    }).toList();

    emit(state.copyWith(pricePerKg: price));
    _updateStateWithNewTotals(updatedItems);
  }

  // Clear for next variety but keep customer
  void clearForNextVariety() {
    emit(state.copyWith(
      tempItems: [],
      currentWeight: 0.0,
      currentBags: 0,
      totalPaddyWeight: 0.0,
      totalRiceWeight: 0.0,
      totalBags: 0,
      totalAmount: 0.0,
      pricePerKg: 0.0,
      status: BuyStatus.initial, // Reset status to allow more additions
    ));
  }

  // Go to review step
  void goToReview() {
    if (state.tempItems.isNotEmpty) {
      emit(state.copyWith(
        status: BuyStatus.reviewing,
        currentStep: BuyStep.review,
      ));
    }
  }

  // Reset for new transaction
  void resetForNewTransaction() {
    emit(const BuyState(
      paddyVarieties: PaddyConstants.paddyVarieties,
      riceVarieties: PaddyConstants.riceVarieties,
    ));
    initialize();
  }

  // Go back to adding items from review
  void backToAddingItems() {
    emit(state.copyWith(status: BuyStatus.addingItems));
  }

  // Go back to previous step
  void goBack() {
    switch (state.currentStep) {
      case BuyStep.selectItem:
        emit(state.copyWith(currentStep: BuyStep.selectCustomer));
        break;
      case BuyStep.enterWeight:
        emit(state.copyWith(
          currentStep: BuyStep.selectItem,
          clearCurrentItem: true,
          currentWeight: 0.0,
          currentBags: 0,
        ));
        break;
      case BuyStep.review:
        emit(state.copyWith(currentStep: BuyStep.selectItem));
        break;
      case BuyStep.complete:
        resetForNewTransaction();
        break;
      default:
        break;
    }
  }

  // Clear error message
  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  // Add current batches (Table 1) to Session (Table 2) - LOCAL ONLY
  Future<void> addBatchToSession() async {
    if (!state.canAddBatch) {
      debugPrint('❌ BuyCubit: Cannot add batch. State: $state');
      return;
    }

    // Explicitly check for customer ID to ensure it's not null or empty
    if (state.selectedCustomer == null || state.selectedCustomer!.id.isEmpty) {
      emit(state.copyWith(
        status: BuyStatus.error,
        errorMessage:
            'Customer not selected or invalid. Please select a valid customer.',
      ));
      return;
    }

    // Explicitly check for customer ID
    if (state.selectedCustomer == null || state.selectedCustomer!.id.isEmpty) {
      emit(state.copyWith(
          status: BuyStatus.error,
          errorMessage: 'Customer not selected or invalid.'));
      return;
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final transactionNumber =
          '${AppConstants.buyTransactionPrefix}-$timestamp';

      final transactionItems = state.tempItems.map((item) {
        return TransactionItemModel.create(
          transactionId: transactionNumber,
          stockItemId: item.stockItemId,
          itemType: item.itemType,
          variety: item.variety,
          bags: item.bagsCount,
          quantity: item.totalWeight,
          pricePerKg: item.pricePerKg,
        );
      }).toList();

      debugPrint(
          '🚀 BuyCubit: Creating local session batch $transactionNumber');

      // Create a local TransactionModel for Table 2
      final newBatch = TransactionModel(
        id: transactionNumber,
        transactionNumber: transactionNumber,
        type: TransactionType.buy,
        status: TransactionStatus.pending,
        customerId:
            state.selectedCustomer!.id, // Already checked for null/empty
        companyId: _companyId,
        items: transactionItems,
        subtotal: state.totalPaddyWeight + state.totalRiceWeight,
        totalAmount: state.totalAmount,
        paidAmount: 0,
        createdBy: '',
        transactionDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      final updatedSessionBatches = [...state.sessionBatches, newBatch];

      emit(state.copyWith(
        sessionBatches: updatedSessionBatches,
        // Clear Table 1 items and reset totals for the next variety
        tempItems: [],
        totalPaddyWeight: 0.0,
        totalRiceWeight: 0.0,
        totalBags: 0,
        totalAmount: 0.0,
        successMessage: 'Batch added to current session locally',
      ));

      // Persist both Table 1 (now empty) and Table 2
      await _savePendingItems([]);
      await _saveSessionBatches(updatedSessionBatches);
    } catch (e, stack) {
      debugPrint('❌ BuyCubit: Error adding batch: $e');
      debugPrint(stack.toString());
      emit(state.copyWith(
        status: BuyStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // Finalize the entire session - Save multiple batches to MongoDB
  Future<void> finalizeSessionToStock() async {
    if (!state.canConfirmStock) {
      debugPrint('❌ BuyCubit: Nothing to finalize');
      return;
    }

    // Explicitly check for customer ID to ensure it's not null or empty
    if (state.selectedCustomer == null || state.selectedCustomer!.id.isEmpty) {
      emit(state.copyWith(
        status: BuyStatus.error,
        errorMessage:
            'Customer not selected or invalid. Please select a valid customer to finalize the session.',
      ));
      return;
    }

    emit(state.copyWith(status: BuyStatus.processing));

    try {
      // 1. Prepare data ONCE before the loop for speed (PURE LOCAL - NO NETWORK)
      final userResult = await _authRepository.getCurrentUser();
      String currentUserId = '';
      userResult.fold((_) => null, (user) => currentUserId = user.id);

      final batchesToSave = [...state.sessionBatches];

      // If Table 1 has items, add them as a last batch
      if (state.tempItems.isNotEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final transactionNumber =
            '${AppConstants.buyTransactionPrefix}-$timestamp';
        final transactionItems = state.tempItems.map((item) {
          return TransactionItemModel.create(
            transactionId: transactionNumber,
            stockItemId: item.stockItemId,
            itemType: item.itemType,
            variety: item.variety.trim(),
            bags: item.bagsCount,
            quantity: item.totalWeight,
            pricePerKg: item.pricePerKg,
          );
        }).toList();

        final lastBatch = TransactionModel(
          id: transactionNumber,
          transactionNumber: transactionNumber,
          type: TransactionType.buy,
          status: TransactionStatus.pending,
          customerId: state.selectedCustomer!.id,
          customerName: state.selectedCustomer!.name,
          companyId: _companyId,
          items: transactionItems,
          subtotal: state.totalPaddyWeight + state.totalRiceWeight,
          totalAmount: state.totalAmount,
          paidAmount: 0,
          createdBy: currentUserId,
          transactionDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        batchesToSave.add(lastBatch);
      }

      if (batchesToSave.isEmpty) {
        emit(state.copyWith(status: BuyStatus.initial));
        return;
      }

      debugPrint(
          '🚀 [BuyCubit] Finalizing ${batchesToSave.length} batches locally (INSTANT)');

      // 2. Save ALL batches to LOCAL SQLite ONLY (this is FAST - no network)
      for (final batch in batchesToSave) {
        if (batch.customerId.isEmpty) continue;

        final result = await _transactionRepository.createBuyTransaction(
          customerId: batch.customerId,
          companyId: _companyId,
          createdById: currentUserId,
          items: batch.items,
          discount: batch.discount,
          paidAmount: batch.paidAmount,
          paymentMethod: batch.paymentMethod ?? PaymentMethod.cash,
          notes: batch.notes,
        );

        bool hadError = false;
        result.fold(
          (failure) {
            debugPrint('❌ [BuyCubit] FAILED to save batch: ${failure.message}');
            emit(state.copyWith(
              status: BuyStatus.error,
              errorMessage: 'Failed to save batch: ${failure.message}',
            ));
            hadError = true;
          },
          (saved) => debugPrint(
              '✅ [BuyCubit] Batch saved locally: ${saved.transactionNumber}'),
        );
        if (hadError) return;
      }

      // 3. ⚡ INSTANT SUCCESS - Show popup immediately (don't wait for anything else)
      final customerId = state.selectedCustomer!.id;

      emit(state.copyWith(
        status: BuyStatus.success,
        successMessage: 'Stock updated successfully!',
        sessionBatches: [],
        tempItems: [],
        totalPaddyWeight: 0.0,
        totalRiceWeight: 0.0,
        totalBags: 0,
        totalAmount: 0.0,
        pricePerKg: 0.0,
        clearCustomer: true,
        clearCurrentItem: true,
        currentStep: BuyStep.selectCustomer,
      ));

      // 4. 🔄 Background cleanup & refresh (DON'T AWAIT - runs asynchronously)
      _cleanupAndRefreshInBackground(customerId);
    } catch (e, stack) {
      debugPrint('❌ BuyCubit: Unexpected error during finalization: $e');
      debugPrint(stack.toString());
      emit(state.copyWith(status: BuyStatus.error, errorMessage: e.toString()));
    }
  }

  /// Background cleanup - runs asynchronously, doesn't block UI
  void _cleanupAndRefreshInBackground(String customerId) async {
    try {
      debugPrint('🧹 [BuyCubit] Starting background cleanup...');

      // Clear session data
      await _clearPendingItems(customerId);
      await _clearSessionBatches(customerId);

      // Refresh data for next transaction (pure local, should be fast)
      debugPrint('🔄 [BuyCubit] Refreshing data in background...');
      await initialize();

      debugPrint('✅ [BuyCubit] Background cleanup complete');
    } catch (e) {
      debugPrint('⚠️ [BuyCubit] Background cleanup error (non-critical): $e');
      // Don't emit error - this happens in background and shouldn't affect user
    }
  }

  // Finish session (Sync and Clear)
  Future<void> finishSession() async {
    emit(state.copyWith(status: BuyStatus.processing));

    // 1. Trigger Sync (Best effort)
    try {
      await _transactionRepository.syncTransactions();
    } catch (e) {
      debugPrint('Sync failed during finish session (offline?): $e');
      // Continue anyway, data is already saved locally
    }

    // 2. Clear Session Data
    emit(state.copyWith(
      recentTransactions: [], // Clear history table
      selectedCustomer: null, // Deselect customer
      selectedItemType: ItemType.paddy, // Reset type
      selectedVariety: 'Nadu', // Reset variety
      currentStockItemId: null,
      tempItems: [], // Ensure temp items are cleared
      currentWeight: 0.0,
      currentBags: 0,
      totalPaddyWeight: 0.0,
      totalRiceWeight: 0.0,
      totalBags: 0,
      totalAmount: 0.0,
      pricePerKg: 0.0,
      status: BuyStatus.initial, // Ready for next customer
      successMessage: 'Session completed successfully',
    ));
  }

  // Helper methods for persistence
  Future<void> _loadPendingItems(String customerId) async {
    debugPrint('🔄 [BuyCubit] Loading pending items for customer: $customerId');
    final result = await _transactionRepository.getPendingBuyItems(customerId);
    result.fold(
      (failure) {
        debugPrint(
            '❌ [BuyCubit] Failed to load pending items: ${failure.message}');
      },
      (itemsJson) {
        if (itemsJson.isNotEmpty) {
          debugPrint('✅ [BuyCubit] Loaded ${itemsJson.length} pending items');
          final items = itemsJson.map((e) => TempBuyItem.fromJson(e)).toList();

          // Restore pricePerKg from the first item if available
          final restoredPrice = items.first.pricePerKg;
          final restoredVariety = items.first.variety;

          emit(state.copyWith(
            pricePerKg: restoredPrice,
            selectedVariety: restoredVariety,
          ));

          _updateStateWithNewTotals(items);
        } else {
          debugPrint('ℹ️ [BuyCubit] No pending items found for customer');
        }
      },
    );
  }

  Future<void> _savePendingItems(List<TempBuyItem> items) async {
    if (state.selectedCustomer == null) return;
    debugPrint(
        '💾 [BuyCubit] Saving ${items.length} pending items for customer: ${state.selectedCustomer!.id}');
    final itemsJson = items.map((e) => e.toJson()).toList();
    final result = await _transactionRepository.savePendingBuyItems(
        state.selectedCustomer!.id, itemsJson);
    result.fold(
      (failure) => debugPrint(
          '❌ [BuyCubit] Failed to save pending items: ${failure.message}'),
      (_) => debugPrint('✅ [BuyCubit] Pending items saved successfully'),
    );
  }

  Future<void> _clearPendingItems(String customerId) async {
    debugPrint(
        '🧹 [BuyCubit] Clearing pending items for customer: $customerId');
    final result =
        await _transactionRepository.clearPendingBuyItems(customerId);
    result.fold(
      (failure) => debugPrint(
          '❌ [BuyCubit] Failed to clear pending items: ${failure.message}'),
      (_) => debugPrint('✅ [BuyCubit] Pending items cleared successfully'),
    );
  }

  // Session Batch Persistence (Table 2)
  Future<void> _loadSessionBatches(String customerId) async {
    debugPrint(
        '🔄 [BuyCubit] Loading session batches for customer: $customerId');
    final result = await _transactionRepository.getSessionBatches(customerId);
    result.fold(
      (failure) => debugPrint(
          '❌ [BuyCubit] Failed to load session batches: ${failure.message}'),
      (batchesJson) {
        if (batchesJson.isNotEmpty) {
          debugPrint(
              '✅ [BuyCubit] Loaded ${batchesJson.length} session batches');
          final batches =
              batchesJson.map((e) => TransactionModel.fromJson(e)).toList();
          emit(state.copyWith(sessionBatches: batches));
        }
      },
    );
  }

  Future<void> _saveSessionBatches(List<TransactionModel> batches) async {
    if (state.selectedCustomer == null) return;
    debugPrint(
        '💾 [BuyCubit] Saving ${batches.length} session batches for customer: ${state.selectedCustomer!.id}');
    final batchesJson = batches.map((e) => e.toJson()).toList();
    final result = await _transactionRepository.saveSessionBatches(
        state.selectedCustomer!.id, batchesJson);
    result.fold(
      (failure) => debugPrint(
          '❌ [BuyCubit] Failed to save session batches: ${failure.message}'),
      (_) => debugPrint('✅ [BuyCubit] Session batches saved successfully'),
    );
  }

  Future<void> _clearSessionBatches(String customerId) async {
    debugPrint(
        '🧹 [BuyCubit] Clearing session batches for customer: $customerId');
    final result = await _transactionRepository.clearSessionBatches(customerId);
    result.fold(
      (failure) => debugPrint(
          '❌ [BuyCubit] Failed to clear session batches: ${failure.message}'),
      (_) => debugPrint('✅ [BuyCubit] Session batches cleared successfully'),
    );
  }
}

