import 'package:equatable/equatable.dart';
import '../../../../core/constants/enums.dart';
import '../../../../data/models/stock_item_model.dart';

enum StockStatus { initial, loading, loaded, error }

enum StockFilterType { all, paddy, rice }

class StockState extends Equatable {
  final StockStatus status;
  final StockAddStatus stockAddStatus;
  final List<StockItemModel> allItems;
  final List<StockItemModel> filteredItems;
  final StockFilterType filterType;
  final String searchQuery;
  final double totalPaddyKg;
  final double totalRiceKg;
  final int totalPaddyBags;
  final int totalRiceBags;
  final String? errorMessage;
  final bool isSynced;

  const StockState({
    this.status = StockStatus.initial,
    this.stockAddStatus = StockAddStatus.initial,
    this.allItems = const [],
    this.filteredItems = const [],
    this.filterType = StockFilterType.paddy,
    this.searchQuery = '',
    this.totalPaddyKg = 0.0,
    this.totalRiceKg = 0.0,
    this.totalPaddyBags = 0,
    this.totalRiceBags = 0,
    this.errorMessage,
    this.isSynced = true,
  });

  StockState copyWith({
    StockStatus? status,
    StockAddStatus? stockAddStatus,
    List<StockItemModel>? allItems,
    List<StockItemModel>? filteredItems,
    StockFilterType? filterType,
    String? searchQuery,
    double? totalPaddyKg,
    double? totalRiceKg,
    int? totalPaddyBags,
    int? totalRiceBags,
    String? errorMessage,
    bool? isSynced,
  }) {
    return StockState(
      status: status ?? this.status,
      stockAddStatus: stockAddStatus ?? this.stockAddStatus,
      allItems: allItems ?? this.allItems,
      filteredItems: filteredItems ?? this.filteredItems,
      filterType: filterType ?? this.filterType,
      searchQuery: searchQuery ?? this.searchQuery,
      totalPaddyKg: totalPaddyKg ?? this.totalPaddyKg,
      totalRiceKg: totalRiceKg ?? this.totalRiceKg,
      totalPaddyBags: totalPaddyBags ?? this.totalPaddyBags,
      totalRiceBags: totalRiceBags ?? this.totalRiceBags,
      errorMessage: errorMessage,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [
        status,
        stockAddStatus,
        allItems,
        filteredItems,
        filterType,
        searchQuery,
        totalPaddyKg,
        totalRiceKg,
        totalPaddyBags,
        totalRiceBags,
        errorMessage,
        isSynced,
      ];
}
