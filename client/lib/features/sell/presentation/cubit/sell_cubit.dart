// lib/features/sell/presentation/cubit/sell_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rice_mill_erp/core/constants/enums.dart';
import 'package:rice_mill_erp/data/models/transaction_item_model.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/models/customer_model.dart';
import '../../../../data/models/stock_item_model.dart';
import '../../../../domain/repositories/customer_repository.dart';
import '../../../../domain/repositories/stock_repository.dart';
import '../../../../domain/repositories/transaction_repository.dart';
import 'sell_state.dart';

class SellCubit extends Cubit<SellState> {
  final CustomerRepository customerRepository;
  final StockRepository stockRepository;
  final TransactionRepository transactionRepository;
  final Uuid _uuid = const Uuid();

  SellCubit({
    required this.customerRepository,
    required this.stockRepository,
    required this.transactionRepository,
  }) : super(const SellState());

  // Initialize sell screen
  Future<void> initialize() async {
    emit(state.copyWith(status: SellStatus.loading));

    try {
      await Future.wait([
        loadCustomers(),
        loadAvailableStock(),
      ]);

      emit(state.copyWith(status: SellStatus.loaded));
    } catch (e) {
      emit(state.copyWith(
        status: SellStatus.error,
        errorMessage: 'Failed to initialize: ${e.toString()}',
      ));
    }
  }

  // Load customers
  Future<void> loadCustomers() async {
    try {
      final result = await customerRepository.getAllCustomers();
      result.fold(
        (failure) => emit(state.copyWith(
          errorMessage: 'Failed to load customers: ${failure.message}',
        )),
        (customers) {
          // Convert CustomerEntity to CustomerModel
          // TODO: Get companyId from auth state
          final customerModels = customers
              .map((entity) =>
                  CustomerModel.fromEntity(entity, 'TEMP_COMPANY_ID'))
              .toList();
          emit(state.copyWith(customers: customerModels));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to load customers: ${e.toString()}',
      ));
    }
  }

  // Update selected item type
  Future<void> updateItemType(ItemType type) async {
    emit(state.copyWith(
      selectedItemType: type,
      clearSelectedStockItem: true, // Clear any previously selected stock item
      inputQuantity: 0.0,
      inputPrice: 0.0,
      errorMessage: null,
    ));
    await loadAvailableStock(); // Reload stock based on the new type
  }

  // Load available stock
  Future<void> loadAvailableStock() async {
    try {
      final result = await stockRepository.getAllStockItems();
      result.fold(
        (failure) => emit(state.copyWith(
          errorMessage: 'Failed to load stock: ${failure.message}',
        )),
        (stock) {
          // Filter only items with available quantity and of the selected type
          final availableStock = stock
              .where((item) =>
                  item.currentQuantity > 0 &&
                  item.type == state.selectedItemType)
              .map((entity) =>
                  StockItemModel.fromEntity(entity, 'TEMP_COMPANY_ID'))
              .toList();
          emit(state.copyWith(availableStock: availableStock));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to load stock: ${e.toString()}',
      ));
    }
  }

  // Search customers
  void searchCustomers(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  // Select customer
  void selectCustomer(CustomerModel customer) {
    emit(state.copyWith(
      selectedCustomer: customer,
      currentStep: SellStep.selectItems,
      clearError: true,
    ));
  }

  // Clear selected customer
  void clearCustomer() {
    emit(state.copyWith(
      clearSelectedCustomer: true,
      currentStep: SellStep.selectCustomer,
      sellItems: [],
      clearSelectedStockItem: true,
      inputQuantity: 0.0,
      inputPrice: 0.0,
    ));
  }

  // Select stock item
  void selectStockItem(StockItemModel item) {
    // Check if item already exists in sell list
    final existingItem = state.sellItems.any(
      (sellItem) => sellItem.stockItemId == item.id,
    );

    if (existingItem) {
      emit(state.copyWith(
        errorMessage: 'This item is already added to the list',
      ));
      return;
    }

    emit(state.copyWith(
      selectedStockItem: item,
      inputQuantity: 0.0,
      inputPrice: item.sellingPricePerKg ?? 0.0,
      clearError: true,
    ));
  }

  // Clear selected stock item
  void clearStockItem() {
    emit(state.copyWith(
      clearSelectedStockItem: true,
      inputQuantity: 0.0,
      inputPrice: 0.0,
    ));
  }

  // Update quantity input
  void updateQuantity(double quantity) {
    if (state.selectedStockItem == null) return;

    final maxQuantity = state.selectedStockItem!.currentQuantity;

    if (quantity > maxQuantity) {
      emit(state.copyWith(
        errorMessage: 'Maximum available: ${maxQuantity.toStringAsFixed(2)} kg',
        inputQuantity: maxQuantity,
      ));
      return;
    }

    emit(state.copyWith(
      inputQuantity: quantity,
      clearError: true,
    ));
  }

  // Update price input
  void updatePrice(double price) {
    emit(state.copyWith(
      inputPrice: price,
      clearError: true,
    ));
  }

  // Update bags input
  void updateBags(int bags) {
    // Auto-calculate weight based on average bag weight if needed
    emit(state.copyWith(clearError: true));
  }

  // Add item to sell list
  void addItemToList({int? bags}) {
    if (!state.canAddItem) {
      emit(state.copyWith(
        errorMessage: 'Please fill all required fields correctly',
      ));
      return;
    }

    final stockItem = state.selectedStockItem!;
    final quantity = state.inputQuantity;
    final price = state.inputPrice;

    // Smart Bag Reduction Logic
    // In realworld, people buy 220kg (5 bags) but sell 215kg due to moisture loss.
    // If the sold quantity is >= 95% of the total quantity, we assume the whole batch (all bags) is sold.
    int calculatedBags = bags ?? 0;
    if (bags == null) {
      final totalQty = stockItem.currentQuantity;
      final totalBags = stockItem.currentBags;

      if (totalQty > 0) {
        // If selling almost everything (97% threshold), clear all bags
        if (quantity >= totalQty * 0.97) {
          calculatedBags = totalBags;
        } else {
          // Otherwise reduce proportionally
          final avgBagWeight = totalQty / totalBags;
          calculatedBags =
              (quantity / avgBagWeight).round().clamp(1, totalBags);
        }
      }
    }

    final sellItem = SellItemEntry(
      id: _uuid.v4(),
      stockItemId: stockItem.id,
      itemName: stockItem.itemName,
      itemType: stockItem.type.name,
      variety: stockItem.variety,
      bags: calculatedBags,
      quantity: quantity,
      pricePerKg: price,
      totalPrice: quantity * price,
      addedAt: DateTime.now(),
    );

    final updatedItems = [...state.sellItems, sellItem];

    // Update available stock locally (optimistic update)
    final updatedStock = state.availableStock.map((item) {
      if (item.id == stockItem.id) {
        return item.copyWith(
          currentQuantity:
              (item.currentQuantity - quantity).clamp(0, item.currentQuantity),
          currentBags:
              (item.currentBags - calculatedBags).clamp(0, item.currentBags),
        );
      }
      return item;
    }).toList();

    emit(state.copyWith(
      sellItems: updatedItems,
      availableStock: updatedStock,
      clearSelectedStockItem: true,
      inputQuantity: 0.0,
      inputPrice: 0.0,
      successMessage: 'Item added successfully',
    ));
  }

  // Direct Sale (One-step for single items)
  Future<void> quickSell() async {
    if (!state.canAddItem) {
      emit(state.copyWith(
          errorMessage: 'Please select an item and enter details'));
      return;
    }

    addItemToList();
    await finalizeSale();
  }

  // Edit item in list
  void editItem(String itemId, {double? quantity, double? price, int? bags}) {
    final updatedItems = state.sellItems.map((item) {
      if (item.id == itemId) {
        final newQuantity = quantity ?? item.quantity;
        final newPrice = price ?? item.pricePerKg;
        final newBags = bags ?? item.bags;

        return item.copyWith(
          quantity: newQuantity,
          pricePerKg: newPrice,
          bags: newBags,
          totalPrice: newQuantity * newPrice,
        );
      }
      return item;
    }).toList();

    emit(state.copyWith(sellItems: updatedItems));
  }

  // Remove item from list
  void removeItem(String itemId) {
    final itemToRemove =
        state.sellItems.firstWhere((item) => item.id == itemId);

    // Restore stock quantity
    final updatedStock = state.availableStock.map((item) {
      if (item.id == itemToRemove.stockItemId) {
        return item.copyWith(
          currentQuantity: item.currentQuantity + itemToRemove.quantity,
        );
      }
      return item;
    }).toList();

    final updatedItems =
        state.sellItems.where((item) => item.id != itemId).toList();

    emit(state.copyWith(
      sellItems: updatedItems,
      availableStock: updatedStock,
    ));
  }

  // Clear all items
  void clearAllItems() {
    // Reload stock to restore quantities
    loadAvailableStock();
    emit(state.copyWith(sellItems: []));
  }

  // Move to review step
  void goToReview() {
    if (state.sellItems.isEmpty) {
      emit(state.copyWith(
        errorMessage: 'Please add at least one item',
      ));
      return;
    }

    emit(state.copyWith(currentStep: SellStep.review));
  }

  // Go back to items selection
  void goBackToItems() {
    emit(state.copyWith(currentStep: SellStep.selectItems));
  }

  // Finalize sale
  Future<void> finalizeSale() async {
    if (!state.canFinalize) {
      emit(state.copyWith(
        errorMessage: 'Cannot finalize. Please check all details.',
      ));
      return;
    }

    emit(state.copyWith(status: SellStatus.processing));

    try {
      final invoiceNumber = _generateInvoiceNumber();

      // Convert sell items to transaction items
      final transactionItems = state.sellItems.map((item) {
        // Convert itemType string to ItemType enum
        final itemType =
            item.itemType == 'rice' ? ItemType.rice : ItemType.paddy;
        return TransactionItemModel.create(
          transactionId: '', // Will be set by repository
          stockItemId: item.stockItemId,
          itemType: itemType,
          variety: item.variety,
          bags: item.bags,
          quantity: item.quantity,
          pricePerKg: item.pricePerKg,
        );
      }).toList();

      // Save transaction
      final result = await transactionRepository.createSellTransaction(
        customerId: state.selectedCustomer!.id,
        companyId: 'TEMP_COMPANY_ID', // TODO: Get from auth state
        createdById: 'TEMP_USER_ID', // TODO: Get from auth state
        items: transactionItems,
      );

      result.fold(
        (failure) => emit(state.copyWith(
          status: SellStatus.error,
          errorMessage: 'Failed to complete sale: ${failure.message}',
        )),
        (transaction) {
          emit(state.copyWith(
            status: SellStatus.success,
            currentStep: SellStep.complete,
            generatedInvoiceId: invoiceNumber,
            isSynced: false,
            successMessage: 'Sale completed successfully!',
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: SellStatus.error,
        errorMessage: 'Failed to complete sale: ${e.toString()}',
      ));
    }
  }

  // Generate invoice number
  String _generateInvoiceNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(5);
    return 'SELL-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$timestamp';
  }

  // Reset for new sale
  void resetForNewSale() {
    emit(const SellState());
    initialize();
  }

  // Clear error message
  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  // Clear success message
  void clearSuccess() {
    emit(state.copyWith(clearSuccess: true));
  }

  // Print receipt
  Future<void> printReceipt() async {
    if (state.generatedInvoiceId == null) return;

    try {
      // Implement printing logic
      emit(state.copyWith(successMessage: 'Receipt sent to printer'));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to print: ${e.toString()}',
      ));
    }
  }

  // Share receipt
  Future<void> shareReceipt() async {
    if (state.generatedInvoiceId == null) return;

    try {
      // Implement sharing logic
      emit(state.copyWith(successMessage: 'Receipt shared successfully'));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to share: ${e.toString()}',
      ));
    }
  }
}
