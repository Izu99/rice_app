// lib/features/home/presentation/cubit/dashboard_cubit.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/transaction_repository.dart';
import '../../../../domain/repositories/stock_repository.dart';
import '../../../../domain/repositories/customer_repository.dart';
import '../../../../domain/repositories/report_repository.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../../data/models/transaction_model.dart';
import 'dashboard_state.dart';

/// Dashboard Cubit - Manages dashboard business logic
class DashboardCubit extends Cubit<DashboardState> {
  final TransactionRepository _transactionRepository;
  final StockRepository _stockRepository;
  final CustomerRepository _customerRepository;
  final ReportRepository _reportRepository;
  final AuthRepository _authRepository;

  DashboardCubit({
    required TransactionRepository transactionRepository,
    required StockRepository stockRepository,
    required CustomerRepository customerRepository,
    required ReportRepository reportRepository,
    required AuthRepository authRepository,
  })  : _transactionRepository = transactionRepository,
        _stockRepository = stockRepository,
        _customerRepository = customerRepository,
        _reportRepository = reportRepository,
        _authRepository = authRepository,
        super(DashboardState.initial());

  /// Load dashboard data
  Future<void> loadDashboard() async {
    emit(state.copyWith(status: DashboardStatus.loading, clearError: true));

    try {
      // Fetch main dashboard summary from backend which includes weekly trend
      // We'll use ReportRepository for this as it maps to /api/reports/dashboard
      final dashboardResult = await _reportRepository.getDashboardSummary();
      
      dashboardResult.fold(
        (failure) {
           emit(state.copyWith(
            status: DashboardStatus.error,
            errorMessage: 'Failed to load dashboard: ${failure.message}',
          ));
        },
        (summary) {
          // Parse Weekly Trend from backend response
          final List<dynamic> trendList = summary['weeklyTrend'] ?? [];
          final List<Map<String, dynamic>> weeklyTrend = List<Map<String, dynamic>>.from(trendList);
          
          // Map to chart format (0-6 index)
          final Map<int, Map<String, double>> weeklyActivity = {};
          for (int i = 0; i < weeklyTrend.length; i++) {
             final day = weeklyTrend[i];
             weeklyActivity[i] = {
               'buy': (day['buy'] as num?)?.toDouble() ?? 0.0,
               'sell': (day['sell'] as num?)?.toDouble() ?? 0.0,
             };
          }

          // Parse other summaries if available in the same response to avoid parallel calls
          // The backend returns: { today: {...}, thisMonth: {...}, stock: {...}, ... }
          
          final today = summary['today'] ?? {};
          final thisMonth = summary['thisMonth'] ?? {};
          final stock = summary['stock'] ?? {};
          final perf = summary['performance'] ?? {};
          final recentList = summary['recentTransactions'] ?? summary['recent_transactions'] ?? [];

          // Map recent transactions from summary
          final List<TransactionModel> recentTransactions = [];
          for (final txnJson in recentList) {
            try {
              // Handle potential population of customerId
              final dynamic customerData = txnJson['customerId'] ?? txnJson['customer_id'];
              String customerId = '';
              String? customerName;

              if (customerData is Map) {
                customerId = customerData['_id']?.toString() ?? customerData['id']?.toString() ?? '';
                customerName = customerData['name']?.toString();
              } else {
                customerId = customerData?.toString() ?? '';
                customerName = txnJson['customer_name']?.toString() ?? txnJson['customerName']?.toString();
              }

              recentTransactions.add(TransactionModel.fromJson({
                ...txnJson as Map<String, dynamic>,
                'customer_id': customerId,
                'customer_name': customerName,
              }));
            } catch (e) {
              debugPrint('⚠️ Error parsing recent transaction: $e');
            }
          }

          emit(state.copyWith(
            // Today
            todayPurchases: (today['buyAmount'] as num?)?.toDouble() ?? 0,
            todaySales: (today['sellAmount'] as num?)?.toDouble() ?? 0,
            todayProfit: (today['profit'] as num?)?.toDouble() ?? 0,
            todayBuyCount: today['buyTransactions'] as int? ?? 0,
            todaySellCount: today['sellTransactions'] as int? ?? 0,
            
            // Month
            monthlyPurchases: (thisMonth['buyAmount'] as num?)?.toDouble() ?? 0,
            monthlySales: (thisMonth['sellAmount'] as num?)?.toDouble() ?? 0,
            monthlyProfit: (thisMonth['profit'] as num?)?.toDouble() ?? 0,
            monthlyBuyCount: thisMonth['buyTransactions'] as int? ?? 0,
            monthlySellCount: thisMonth['sellTransactions'] as int? ?? 0,

            // Stock
            totalPaddyStock: (stock['totalPaddyKg'] as num?)?.toDouble() ?? 0,
            totalRiceStock: (stock['totalRiceKg'] as num?)?.toDouble() ?? 0,
            lowStockCount: stock['lowStockItems'] as int? ?? 0,

            // Performance
            totalPaddyBoughtKg: (perf['totalPaddyBoughtKg'] as num?)?.toDouble() ?? 0,
            totalRiceSoldKg: (perf['totalRiceSoldKg'] as num?)?.toDouble() ?? 0,

            // Recent Transactions
            recentTransactions: recentTransactions.isNotEmpty ? recentTransactions : state.recentTransactions,

            // Charts
            weeklyTrend: weeklyTrend,
            weeklyActivity: weeklyActivity,

            // Customer summary from dashboard summary if available
            totalCustomers: summary['totalCustomers'] as int? ?? state.totalCustomers,
          ));
        },
      );

      // Load other local data if needed (Sync status, etc)
      // We skip _loadRecentTransactions if we already got them from backend
      await Future.wait([
        _loadCustomerSummary(),
        _loadSyncStatus(),
      ]);

      emit(state.copyWith(status: DashboardStatus.loaded));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to load dashboard: ${e.toString()}',
      ));
    }
  }

  /// Refresh dashboard data
  Future<void> refreshDashboard() async {
    emit(state.copyWith(status: DashboardStatus.refreshing));
    await loadDashboard();
  }

  /// Load customer summary
  Future<void> _loadCustomerSummary() async {
    // Get customer count
    final countResult = await _customerRepository.getCustomersCount();
    countResult.fold(
      (failure) {},
      (count) {
        emit(state.copyWith(totalCustomers: count));
      },
    );

    // Get customers with balance for receivables/payables
    final receivablesResult = await _customerRepository.getCustomersWithBalance(
      type: 'receivable',
    );
    receivablesResult.fold(
      (failure) {},
      (customers) {
        double totalReceivables = 0;
        for (final customer in customers) {
          if (customer.balance > 0) {
            totalReceivables += customer.balance;
          }
        }
        emit(state.copyWith(totalReceivables: totalReceivables));
      },
    );

    final payablesResult = await _customerRepository.getCustomersWithBalance(
      type: 'payable',
    );
    payablesResult.fold(
      (failure) {},
      (customers) {
        double totalPayables = 0;
        for (final customer in customers) {
          if (customer.balance < 0) {
            totalPayables += customer.balance.abs();
          }
        }
        emit(state.copyWith(totalPayables: totalPayables));
      },
    );
  }

  /// Load sync status
  Future<void> _loadSyncStatus() async {
    // Get last sync time
    final lastSyncResult = await _authRepository.getLastSyncTime();
    lastSyncResult.fold(
      (failure) {},
      (lastSync) {
        emit(state.copyWith(lastSyncTime: lastSync));
      },
    );

    // Get pending sync count
    int pendingCount = 0;

    final unsyncedTransactions =
        await _transactionRepository.getUnsyncedTransactions();
    unsyncedTransactions.fold((l) {}, (transactions) {
      pendingCount += transactions.length;
    });

    emit(state.copyWith(
      pendingSyncCount: pendingCount,
      isSynced: pendingCount == 0,
    ));
  }

  /// Sync all pending data
  Future<void> syncData() async {
    emit(state.copyWith(status: DashboardStatus.refreshing));

    try {
      // Sync transactions
      await _transactionRepository.syncTransactions();

      // Sync stock
      await _stockRepository.syncStock();

      // Save sync time
      await _authRepository.saveLastSyncTime(DateTime.now());

      // Reload dashboard
      await refreshDashboard();
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.loaded,
        errorMessage: 'Sync failed: ${e.toString()}',
      ));
    }
  }

  /// Change selected date
  void changeDate(DateTime date) {
    emit(state.copyWith(selectedDate: date));
    // Re-load data if needed or filter locally
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}

