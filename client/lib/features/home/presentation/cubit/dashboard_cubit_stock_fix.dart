
  /// Load stock data from local database (Source of Truth)
  Future<void> _loadLocalStockData() async {
    // We already have stockRepository injected
    // This ensures that the dashboard shows exactly what the Stock Page shows
    final result = await _stockRepository.getAllStockItems();
    
    result.fold(
      (failure) {
        debugPrint('⚠️ [DashboardCubit] Failed to load local stock: ${failure.message}');
      },
      (items) {
        double totalPaddy = 0;
        double totalRice = 0;
        int lowStock = 0;

        for (final item in items) {
          if (item.currentQuantity < item.minQuantity) {
            lowStock++;
          }
          
          if (item.itemType == 'paddy' || item.type.name == 'paddy') {
            totalPaddy += item.currentQuantity;
          } else {
            totalRice += item.currentQuantity;
          }
        }

        emit(state.copyWith(
          totalPaddyStock: totalPaddy,
          totalRiceStock: totalRice,
          lowStockCount: lowStock,
        ));
      },
    );
  }
