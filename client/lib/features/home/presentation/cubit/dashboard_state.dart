// lib/features/home/presentation/cubit/dashboard_state.dart

import 'package:equatable/equatable.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/models/stock_item_model.dart';
import '../../../../data/models/expense_model.dart';

/// Dashboard loading status
enum DashboardStatus {
  initial,
  loading,
  loaded,
  refreshing,
  error,
}

/// Dashboard State - Manages dashboard data
class DashboardState extends Equatable {
  final DashboardStatus status;
  final String? errorMessage;

  // Today's Summary
  final double todayPurchases;
  final double todaySales;
  final double todayExpenses;
  final double todayProfit;
  final int todayBuyCount;
  final int todaySellCount;

  // Monthly Summary
  final double monthlyPurchases;
  final double monthlySales;
  final double monthlyExpenses;
  final double monthlyProfit;
  final int monthlyBuyCount;
  final int monthlySellCount;

  // Stock Summary
  final double totalPaddyStock;
  final double totalRiceStock;
  final double totalStockValue;
  final int lowStockCount;
  final List<StockItemModel> lowStockItems;

  // Performance Metrics
  final double totalPaddyBoughtKg;
  final double totalRiceSoldKg;

  // Customer Summary
  final int totalCustomers;
  final double totalReceivables;
  final double totalPayables;

  // Recent Transactions
  final List<TransactionModel> recentTransactions;
  final List<ExpenseModel> recentExpenses;

  // Sync Status
  final bool isSynced;
  final DateTime? lastSyncTime;
  final int pendingSyncCount;

  // Selected Date Range
  final DateTime selectedDate;

  // Weekly Activity (for chart)
  final Map<int, Map<String, double>> _weeklyActivity;
  // Detailed Weekly Trend (List of daily stats from backend)
  final List<Map<String, dynamic>> _weeklyTrend;

  // Safe Getters to prevent null errors during hot-reload transitions
  Map<int, Map<String, double>> get weeklyActivity =>
      _weeklyActivity ?? const {};
  List<Map<String, dynamic>> get weeklyTrend => _weeklyTrend ?? const [];

  DashboardState({
    this.status = DashboardStatus.initial,
    this.errorMessage,
    this.todayPurchases = 0,
    this.todaySales = 0,
    this.todayExpenses = 0,
    this.todayProfit = 0,
    this.todayBuyCount = 0,
    this.todaySellCount = 0,
    this.monthlyPurchases = 0,
    this.monthlySales = 0,
    this.monthlyExpenses = 0,
    this.monthlyProfit = 0,
    this.monthlyBuyCount = 0,
    this.monthlySellCount = 0,
    this.totalPaddyStock = 0,
    this.totalRiceStock = 0,
    this.totalStockValue = 0,
    this.lowStockCount = 0,
    this.lowStockItems = const [],
    this.totalPaddyBoughtKg = 0,
    this.totalRiceSoldKg = 0,
    this.totalCustomers = 0,
    this.totalReceivables = 0,
    this.totalPayables = 0,
    this.recentTransactions = const [],
    this.recentExpenses = const [],
    this.isSynced = true,
    this.lastSyncTime,
    this.pendingSyncCount = 0,
    DateTime? selectedDate,
    Map<int, Map<String, double>> weeklyActivity = const {},
    List<Map<String, dynamic>> weeklyTrend = const [],
  })  : _weeklyActivity = weeklyActivity,
        _weeklyTrend = weeklyTrend,
        selectedDate = selectedDate ?? DateTime.now();

  /// Initial state
  factory DashboardState.initial() {
    return DashboardState(selectedDate: DateTime.now());
  }

  /// Check if loading
  bool get isLoading => status == DashboardStatus.loading;

  /// Check if refreshing
  bool get isRefreshing => status == DashboardStatus.refreshing;

  /// Check if loaded
  bool get isLoaded => status == DashboardStatus.loaded;

  /// Check if has error
  bool get hasError => status == DashboardStatus.error;

  /// Get today's transaction count
  int get todayTransactionCount => todayBuyCount + todaySellCount;

  /// Get monthly transaction count
  int get monthlyTransactionCount => monthlyBuyCount + monthlySellCount;

  /// Get total stock in kg
  double get totalStock => totalPaddyStock + totalRiceStock;

  /// Get net balance (receivables - payables)
  double get netBalance => totalReceivables - totalPayables;

  /// Check if has low stock items
  bool get hasLowStock => lowStockCount > 0;

  /// Check if has pending sync
  bool get hasPendingSync => pendingSyncCount > 0;

  /// Formatted today's purchases
  String get formattedTodayPurchases => 'Rs. ${_formatNumber(todayPurchases)}';

  /// Formatted today's sales
  String get formattedTodaySales => 'Rs. ${_formatNumber(todaySales)}';

  /// Formatted today's expenses
  String get formattedTodayExpenses => 'Rs. ${_formatNumber(todayExpenses)}';

  /// Formatted today's profit
  String get formattedTodayProfit => 'Rs. ${_formatNumber(todayProfit)}';

  /// Formatted monthly purchases
  String get formattedMonthlyPurchases =>
      'Rs. ${_formatNumber(monthlyPurchases)}';

  /// Formatted monthly sales
  String get formattedMonthlySales => 'Rs. ${_formatNumber(monthlySales)}';

  /// Formatted monthly expenses
  String get formattedMonthlyExpenses => 'Rs. ${_formatNumber(monthlyExpenses)}';

  /// Formatted monthly profit
  String get formattedMonthlyProfit => 'Rs. ${_formatNumber(monthlyProfit)}';

  /// Formatted paddy stock
  String get formattedPaddyStock => '${_formatNumber(totalPaddyStock)} kg';

  /// Formatted rice stock
  String get formattedRiceStock => '${_formatNumber(totalRiceStock)} kg';

  /// Formatted stock value
  String get formattedStockValue => 'Rs. ${_formatNumber(totalStockValue)}';

  /// Formatted receivables
  String get formattedReceivables => 'Rs. ${_formatNumber(totalReceivables)}';

  /// Formatted payables
  String get formattedPayables => 'Rs. ${_formatNumber(totalPayables)}';

  /// Format number with commas
  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(2);
  }

  /// Get greeting based on time of day
  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'සුභ උදෑසනක්'; // Good Morning
    } else if (hour < 17) {
      return 'සුභ දහවලක්'; // Good Afternoon
    } else {
      return 'සුභ සන්ධ්‍යාවක්'; // Good Evening
    }
  }

  /// Get formatted last sync time
  String? get formattedLastSyncTime {
    if (lastSyncTime == null) return null;
    final now = DateTime.now();
    final difference = now.difference(lastSyncTime!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  /// Copy with method
  DashboardState copyWith({
    DashboardStatus? status,
    String? errorMessage,
    double? todayPurchases,
    double? todaySales,
    double? todayExpenses,
    double? todayProfit,
    int? todayBuyCount,
    int? todaySellCount,
    double? monthlyPurchases,
    double? monthlySales,
    double? monthlyExpenses,
    double? monthlyProfit,
    int? monthlyBuyCount,
    int? monthlySellCount,
    double? totalPaddyStock,
    double? totalRiceStock,
    double? totalStockValue,
    int? lowStockCount,
    List<StockItemModel>? lowStockItems,
    double? totalPaddyBoughtKg,
    double? totalRiceSoldKg,
    int? totalCustomers,
    double? totalReceivables,
    double? totalPayables,
    List<TransactionModel>? recentTransactions,
    List<ExpenseModel>? recentExpenses,
    bool? isSynced,
    DateTime? lastSyncTime,
    int? pendingSyncCount,
    DateTime? selectedDate,
    Map<int, Map<String, double>>? weeklyActivity,
    List<Map<String, dynamic>>? weeklyTrend,
    bool clearError = false,
  }) {
    return DashboardState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      todayPurchases: todayPurchases ?? this.todayPurchases,
      todaySales: todaySales ?? this.todaySales,
      todayExpenses: todayExpenses ?? this.todayExpenses,
      todayProfit: todayProfit ?? this.todayProfit,
      todayBuyCount: todayBuyCount ?? this.todayBuyCount,
      todaySellCount: todaySellCount ?? this.todaySellCount,
      monthlyPurchases: monthlyPurchases ?? this.monthlyPurchases,
      monthlySales: monthlySales ?? this.monthlySales,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      monthlyProfit: monthlyProfit ?? this.monthlyProfit,
      monthlyBuyCount: monthlyBuyCount ?? this.monthlyBuyCount,
      monthlySellCount: monthlySellCount ?? this.monthlySellCount,
      totalPaddyStock: totalPaddyStock ?? this.totalPaddyStock,
      totalRiceStock: totalRiceStock ?? this.totalRiceStock,
      totalStockValue: totalStockValue ?? this.totalStockValue,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      lowStockItems: lowStockItems ?? this.lowStockItems,
      totalPaddyBoughtKg: totalPaddyBoughtKg ?? this.totalPaddyBoughtKg,
      totalRiceSoldKg: totalRiceSoldKg ?? this.totalRiceSoldKg,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      totalReceivables: totalReceivables ?? this.totalReceivables,
      totalPayables: totalPayables ?? this.totalPayables,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      recentExpenses: recentExpenses ?? this.recentExpenses,
      isSynced: isSynced ?? this.isSynced,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      selectedDate: selectedDate ?? this.selectedDate,
      weeklyActivity: weeklyActivity ?? this.weeklyActivity,
      weeklyTrend: weeklyTrend ?? this.weeklyTrend,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        todayPurchases,
        todaySales,
        todayExpenses,
        todayProfit,
        todayBuyCount,
        todaySellCount,
        monthlyPurchases,
        monthlySales,
        monthlyExpenses,
        monthlyProfit,
        monthlyBuyCount,
        monthlySellCount,
        totalPaddyStock,
        totalRiceStock,
        totalStockValue,
        lowStockCount,
        lowStockItems,
        totalPaddyBoughtKg,
        totalRiceSoldKg,
        totalCustomers,
        totalReceivables,
        totalPayables,
        recentTransactions,
        recentExpenses,
        isSynced,
        lastSyncTime,
        pendingSyncCount,
        selectedDate,
        weeklyActivity,
        weeklyTrend,
      ];

  @override
  String toString() {
    return 'DashboardState(status: $status, todaySales: $todaySales, todayPurchases: $todayPurchases)';
  }
}
