import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/enums.dart';
import '../../../../data/models/stock_item_model.dart';
import '../../../../domain/repositories/stock_repository.dart';
import '../../../../domain/repositories/auth_repository.dart';
import 'stock_state.dart';

class StockCubit extends Cubit<StockState> {
  final StockRepository _stockRepository;
  final AuthRepository _authRepository;

  StockCubit({
    required StockRepository stockRepository,
    required AuthRepository authRepository,
  })  : _stockRepository = stockRepository,
        _authRepository = authRepository,
        super(const StockState());

  /// Load all stock items from local database
  Future<void> loadStock() async {
    debugPrint('🔄 [StockCubit] ====== LOAD STOCK START ======');
    debugPrint('🔄 [StockCubit] Current Status: ${state.status}');

    emit(state.copyWith(status: StockStatus.loading));

    try {
      debugPrint('🔄 [StockCubit] Step 1: Getting current user...');
      // Get current user to obtain companyId
      final userResult = await _authRepository.getCurrentUser();
      String companyId = '';
      userResult.fold(
        (failure) {
          debugPrint(
              '⚠️  [StockCubit] No user found: ${failure.message} (Failure type: ${failure.runtimeType})');
          companyId = '';
        },
        (user) {
          debugPrint(
              '✅ [StockCubit] User found: ${user.name}, Company: ${user.companyId}, User ID: ${user.id}');
          companyId = user.companyId;
          // Also set user name for better logging here, if needed for context
          // However, stock fetching only needs companyId
        },
      );

      // Fix the log message here to be more accurate
      debugPrint(
          '📊 [StockCubit] Step 2: Loading stock for companyId: $companyId');

      // Add timeout to prevent hanging
      final result = await _stockRepository.getAllStockItems().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint(
              '⏱️  [StockCubit] TIMEOUT! Stock loading took > 5 seconds');
          throw TimeoutException('Stock loading timed out');
        },
      );

      debugPrint('📊 [StockCubit] Step 3: Processing result...');
      result.fold(
        (failure) {
          debugPrint('❌ [StockCubit] Failed to load stock: ${failure.message}');
          emit(state.copyWith(
            status: StockStatus.error,
            errorMessage: failure.message,
          ));
        },
        (items) {
          debugPrint(
              '📦 [StockCubit] Loaded ${items.length} raw items from database');

          // Convert entities to models
          final models = items
              .map((entity) => StockItemModel.fromEntity(entity, companyId))
              .toList();

          // Debug: Print each stock item details
          if (models.isEmpty) {
            debugPrint('   📭 No stock items found in database');
          } else {
            for (var model in models) {
              debugPrint(
                  '   📍 ${model.variety} (${model.itemType.name}): ${model.currentBags} bags, ${model.currentQuantity.toStringAsFixed(2)} kg');
            }
          }

          final totals = _calculateTotals(models);
          debugPrint(
              '   ✅ Total Paddy: ${totals["paddyKg"]} kg (${totals["paddyBags"]} bags)');
          debugPrint(
              '   ✅ Total Rice: ${totals["riceKg"]} kg (${totals["riceBags"]} bags)');

          emit(state.copyWith(
            status: StockStatus.loaded,
            allItems: models,
            filteredItems: models,
            totalPaddyKg: totals['paddyKg'],
            totalRiceKg: totals['riceKg'],
            totalPaddyBags: totals['paddyBags'],
            totalRiceBags: totals['riceBags'],
          ));

          debugPrint('✅ [StockCubit] ====== LOAD STOCK COMPLETE ======');
        },
      );
    } on TimeoutException catch (e) {
      debugPrint('⏱️  [StockCubit] TIMEOUT ERROR: $e');
      emit(state.copyWith(
        status: StockStatus.error,
        errorMessage: 'Loading took too long. Check your connection.',
      ));
    } catch (e, stack) {
      debugPrint('❌ [StockCubit] Unexpected error: $e');
      debugPrint('Stack trace: $stack');
      emit(state.copyWith(
        status: StockStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Filter stock by type (All, Paddy, Rice)
  void filterByType(StockFilterType filterType) {
    List<StockItemModel> filtered;

    switch (filterType) {
      case StockFilterType.paddy:
        filtered = state.allItems
            .where((item) => item.itemType == ItemType.paddy)
            .toList();
        break;
      case StockFilterType.rice:
        filtered = state.allItems
            .where((item) => item.itemType == ItemType.rice)
            .toList();
        break;
      case StockFilterType.all:
        filtered = state.allItems;
        break;
    }

    // Apply search query if exists
    if (state.searchQuery.isNotEmpty) {
      filtered = filtered
          .where((item) =>
              item.name.toLowerCase().contains(state.searchQuery.toLowerCase()))
          .toList();
    }

    emit(state.copyWith(
      filterType: filterType,
      filteredItems: filtered,
    ));
  }

  /// Search stock items by name
  void searchStock(String query) {
    List<StockItemModel> filtered = state.allItems;

    // Apply type filter first
    switch (state.filterType) {
      case StockFilterType.paddy:
        filtered =
            filtered.where((item) => item.itemType == ItemType.paddy).toList();
        break;
      case StockFilterType.rice:
        filtered =
            filtered.where((item) => item.itemType == ItemType.rice).toList();
        break;
      case StockFilterType.all:
        break;
    }

    // Apply search query
    if (query.isNotEmpty) {
      filtered = filtered
          .where(
              (item) => item.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    emit(state.copyWith(
      searchQuery: query,
      filteredItems: filtered,
    ));
  }

  /// Refresh stock - Pulls latest data and attempts background sync
  Future<void> refreshStock() async {
    debugPrint('🔄 [StockCubit] Refreshing stock (Offline-First)...');
    emit(state.copyWith(isSynced: false));

    try {
      final result = await _stockRepository.syncStock();

      result.fold(
        (failure) => emit(state.copyWith(
          isSynced: false,
          errorMessage: failure.message,
        )),
        (_) async {
          emit(state.copyWith(isSynced: true));
          await loadStock();
        },
      );
    } catch (e) {
      emit(state.copyWith(isSynced: false));
    }
  }

  /// Update stock item quantity (manual adjustment)
  Future<void> updateStockQuantity({
    required String itemId,
    required double newQuantityKg,
    required int newBags,
    String? reason,
  }) async {
    emit(state.copyWith(status: StockStatus.loading));

    try {
      final result = await _stockRepository.adjustStock(
        itemId: itemId,
        newQuantity: newQuantityKg,
        newBags: newBags,
        reason: reason ?? 'Manual adjustment',
      );

      result.fold(
        (failure) => emit(state.copyWith(
          status: StockStatus.error,
          errorMessage: failure.message,
        )),
        (updatedItemEntity) {
          // Assuming companyId is consistent or can be derived from existing state.allItems
          // We need companyId to convert to StockItemModel
          final String companyId = state.allItems.isNotEmpty
              ? state.allItems.first.companyId
              : ''; // Fallback, though ideally companyId would be in cubit state

          final updatedItemModel =
              StockItemModel.fromEntity(updatedItemEntity, companyId);

          final currentItems = List<StockItemModel>.from(state.allItems);
          final index = currentItems
              .indexWhere((element) => element.id == updatedItemModel.id);
          if (index != -1) {
            currentItems[index] = updatedItemModel;
          } else {
            // This case should ideally not happen for adjustStock as it's an existing item
            debugPrint(
                '⚠️ [StockCubit] Adjusted item not found in current state for immediate update.');
            currentItems.add(updatedItemModel); // Add if somehow it was missing
          }

          final totals = _calculateTotals(currentItems);

          emit(state.copyWith(
            status:
                StockStatus.loaded, // Assuming loaded state after adjustment
            allItems: currentItems,
            filteredItems: currentItems, // Also update filtered list
            totalPaddyKg: totals['paddyKg'],
            totalRiceKg: totals['riceKg'],
            totalPaddyBags: totals['paddyBags'],
            totalRiceBags: totals['riceBags'],
          ));
          // Trigger a full load in the background to ensure consistency
          loadStock();
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: StockStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Add new stock item
  Future<void> addStockItem(StockItemModel item) async {
    emit(state.copyWith(status: StockStatus.loading));

    try {
      final result = await _stockRepository.addStockItem(item);

      result.fold(
        (failure) => emit(state.copyWith(
          status: StockStatus.error,
          errorMessage: failure.message,
        )),
        (_) => loadStock(),
      );
    } catch (e) {
      emit(state.copyWith(
        status: StockStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Delete stock item
  Future<void> deleteStockItem(String itemId) async {
    try {
      final result = await _stockRepository.deleteStockItem(itemId);

      result.fold(
        (failure) => emit(state.copyWith(errorMessage: failure.message)),
        (_) => loadStock(),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  /// Get stock summary for dashboard
  Map<String, dynamic> getStockSummary() {
    return {
      'totalPaddyKg': state.totalPaddyKg,
      'totalRiceKg': state.totalRiceKg,
      'totalPaddyBags': state.totalPaddyBags,
      'totalRiceBags': state.totalRiceBags,
      'itemCount': state.allItems.length,
      'paddyVarieties':
          state.allItems.where((i) => i.itemType == ItemType.paddy).length,
      'riceVarieties':
          state.allItems.where((i) => i.itemType == ItemType.rice).length,
    };
  }

  /// Calculate totals from items list
  Map<String, dynamic> _calculateTotals(List<StockItemModel> items) {
    double paddyKg = 0;
    double riceKg = 0;
    int paddyBags = 0;
    int riceBags = 0;

    for (var item in items) {
      if (item.itemType == ItemType.paddy) {
        paddyKg += item.totalWeightKg;
        paddyBags += item.totalBags;
      } else {
        riceKg += item.totalWeightKg;
        riceBags += item.totalBags;
      }
    }

    return {
      'paddyKg': paddyKg,
      'riceKg': riceKg,
      'paddyBags': paddyBags,
      'riceBags': riceBags,
    };
  }

  /// Get items for selling (only with available stock)
  List<StockItemModel> getAvailableItemsForSale() {
    return state.allItems.where((item) => item.totalWeightKg > 0).toList();
  }

  /// Get paddy items for milling
  List<StockItemModel> getPaddyForMilling() {
    return state.allItems
        .where(
            (item) => item.itemType == ItemType.paddy && item.totalWeightKg > 0)
        .toList();
  }

  /// Add stock manually (for receiving new stock)
  Future<void> addStock({
    required ItemType type,
    required String variety,
    required double quantity,
    required int bags,
    double? pricePerKg,
    String? notes,
  }) async {
    emit(state.copyWith(stockAddStatus: StockAddStatus.adding));

    try {
      // Get current user to obtain companyId
      final userResult = await _authRepository.getCurrentUser();
      String companyId = '';
      userResult.fold(
        (failure) => companyId = '', // Default if no user
        (user) => companyId = user.companyId,
      );

      // Get or create stock item
      final result = await _stockRepository.getOrCreateStockItem(
        type: type,
        variety: variety,
        companyId: companyId,
      );

      await result.fold(
        (failure) async => emit(state.copyWith(
          stockAddStatus: StockAddStatus.failure,
          errorMessage: failure.message,
        )),
        (item) async {
          // Add stock to the item
          final addResult = await _stockRepository.addStock(
            itemId: item.id,
            quantity: quantity,
            bags: bags,
            transactionId:
                'manual-${DateTime.now().millisecondsSinceEpoch}', // Manual transaction ID
          );

          addResult.fold(
            (failure) => emit(state.copyWith(
              stockAddStatus: StockAddStatus.failure,
              errorMessage: failure.message,
            )),
            (_) {
              // Find the updated item and replace it in the current list
              final updatedItemEntity = addResult.getOrElse(() =>
                  throw Exception(
                      "Should not happen")); // Get the updated entity
              final updatedItemModel = StockItemModel.fromEntity(
                  updatedItemEntity, companyId); // Convert to model

              final currentItems = List<StockItemModel>.from(state.allItems);
              final index = currentItems
                  .indexWhere((element) => element.id == updatedItemModel.id);
              if (index != -1) {
                currentItems[index] = updatedItemModel;
              } else {
                currentItems.add(
                    updatedItemModel); // Should not happen if item already existed
              }

              final totals = _calculateTotals(currentItems);

              emit(state.copyWith(
                stockAddStatus: StockAddStatus.success,
                allItems: currentItems,
                filteredItems: currentItems, // Also update filtered list
                totalPaddyKg: totals['paddyKg'],
                totalRiceKg: totals['riceKg'],
                totalPaddyBags: totals['paddyBags'],
                totalRiceBags: totals['riceBags'],
              ));
              // Trigger a full load in the background to ensure consistency
              loadStock();
            },
          );
        },
      );
    } catch (e) {
      emit(state.copyWith(
        stockAddStatus: StockAddStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Reset stock add status
  void resetStockAddStatus() {
    emit(state.copyWith(
        stockAddStatus: StockAddStatus.initial, errorMessage: null));
  }

  /// Clear error message
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}

