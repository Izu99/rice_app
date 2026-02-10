// lib/features/home/presentation/cubit/dashboard_cubit.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/enums.dart';
import '../../../../domain/repositories/transaction_repository.dart';
import '../../../../domain/repositories/stock_repository.dart';
import '../../../../domain/repositories/customer_repository.dart';
import '../../../../domain/repositories/report_repository.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/models/expense_model.dart';
import 'dashboard_state.dart';

import '../../../../domain/repositories/expense_repository.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../../domain/entities/expense_entity.dart';

/// Dashboard Cubit - Manages dashboard business logic
class DashboardCubit extends Cubit<DashboardState> {
  final TransactionRepository _transactionRepository;
  final StockRepository _stockRepository;
  final CustomerRepository _customerRepository;
  final ReportRepository _reportRepository;
  final AuthRepository _authRepository;
  final ExpenseRepository _expenseRepository;

  DashboardCubit({
    required TransactionRepository transactionRepository,
    required StockRepository stockRepository,
    required CustomerRepository customerRepository,
    required ReportRepository reportRepository,
    required AuthRepository authRepository,
    required ExpenseRepository expenseRepository,
  })  : _transactionRepository = transactionRepository,
        _stockRepository = stockRepository,
        _customerRepository = customerRepository,
        _reportRepository = reportRepository,
        _authRepository = authRepository,
        _expenseRepository = expenseRepository,
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
          final List<Map<String, dynamic>> weeklyTrend =
              List<Map<String, dynamic>>.from(trendList);

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
          final recentList = summary['recentTransactions'] ??
              summary['recent_transactions'] ??
              [];
          final recentExpenseList = summary['recentExpenses'] ?? [];

          // Map recent transactions from summary
          final List<TransactionModel> recentTransactions = [];
          for (final txnJson in recentList) {
            try {
              // Handle potential population of customerId
              final dynamic customerData =
                  txnJson['customerId'] ?? txnJson['customer_id'];
              String customerId = '';
              String? customerName;

              if (customerData is Map) {
                customerId = customerData['_id']?.toString() ??
                    customerData['id']?.toString() ??
                    '';
                customerName = customerData['name']?.toString();
              } else {
                customerId = customerData?.toString() ?? '';
                customerName = txnJson['customer_name']?.toString() ??
                    txnJson['customerName']?.toString();
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

          // Map recent expenses from summary
          final List<ExpenseModel> recentExpenses = [];
          for (final expenseJson in recentExpenseList) {
            try {
              recentExpenses.add(ExpenseModel.fromJson(expenseJson));
            } catch (e) {
              debugPrint('⚠️ Error parsing recent expense: $e');
            }
          }

          emit(state.copyWith(
            // Today
            todayPurchases: (today['buyAmount'] as num?)?.toDouble() ?? 0,
            todaySales: (today['sellAmount'] as num?)?.toDouble() ?? 0,
            todayExpenses:
                (today['operatingExpenses'] as num?)?.toDouble() ?? 0,
            todayProfit: (today['netAmount'] as num?)?.toDouble() ?? 0,
            todayBuyCount: today['buyTransactions'] as int? ?? 0,
            todaySellCount: today['sellTransactions'] as int? ?? 0,

            // Month
            monthlyPurchases: (thisMonth['buyAmount'] as num?)?.toDouble() ?? 0,
            monthlySales: (thisMonth['sellAmount'] as num?)?.toDouble() ?? 0,
            monthlyExpenses:
                (thisMonth['operatingExpenses'] as num?)?.toDouble() ?? 0,
            monthlyProfit: (thisMonth['profit'] as num?)?.toDouble() ?? 0,
            monthlyBuyCount: thisMonth['buyTransactions'] as int? ?? 0,
            monthlySellCount: thisMonth['sellTransactions'] as int? ?? 0,

            // Stock - Will be updated from local source below for consistency
            totalPaddyStock: (stock['totalPaddyKg'] as num?)?.toDouble() ?? 0,
            totalRiceStock: (stock['totalRiceKg'] as num?)?.toDouble() ?? 0,
            lowStockCount: stock['lowStockItems'] as int? ?? 0,

            // Performance
            totalPaddyBoughtKg:
                (perf['totalPaddyBoughtKg'] as num?)?.toDouble() ?? 0,
            totalRiceSoldKg: (perf['totalRiceSoldKg'] as num?)?.toDouble() ?? 0,

            // Recent Transactions & Expenses
            recentTransactions: recentTransactions.isNotEmpty
                ? recentTransactions
                : state.recentTransactions,
            recentExpenses: recentExpenses.isNotEmpty
                ? recentExpenses
                : state.recentExpenses,

            // Charts
            weeklyTrend: weeklyTrend,
            weeklyActivity: weeklyActivity,

            // Customer summary from dashboard summary if available
            totalCustomers:
                summary['totalCustomers'] as int? ?? state.totalCustomers,
          ));
        },
      );

      // Load other local data if needed (Sync status, etc)
      // We skip _loadRecentTransactions if we already got them from backend
      await Future.wait([
        _loadCustomerSummary(),
        _loadSyncStatus(),
        _loadLocalStockData(), // Override with local stock data
        _loadLocalActivityData(), // Override stats with local data
      ]);

      emit(state.copyWith(status: DashboardStatus.loaded));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to load dashboard: ${e.toString()}',
      ));
    }
  }

  /// Refresh dashboard data - syncs data then loads
  Future<void> refreshDashboard() async {
    await syncData();
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
      await loadDashboard();
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.loaded, // Revert to loaded state
        errorMessage: 'Sync failed: ${e.toString()}',
      ));
      
      // Still try to load data even if sync failed (offline mode support)
      await loadDashboard();
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

  /// Load local activity (transactions, expenses) for graph and summaries
  Future<void> _loadLocalActivityData() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      // We need data for the graph (last 7 days including today)
      // AND for the month stats (from startOfMonth)
      final sevenDaysAgo = today.subtract(const Duration(days: 6));
      final fetchStart = startOfMonth.isBefore(sevenDaysAgo) ? startOfMonth : sevenDaysAgo;

      // Fetch transactions
      final txnResult = await _transactionRepository.getTransactionsByDateRange(
        startDate: fetchStart,
        endDate: now,
      );

      // Fetch expenses
      final expResult = await _expenseRepository.getExpenses(
        startDate: fetchStart,
        endDate: now,
      );

      // Process Transactions
      txnResult.fold(
        (l) => debugPrint('⚠️ [DashboardCubit] create local transactions error: ${l.message}'),
        (transactions) {
            // Filter valid transactions
            final validTxns = transactions.where((t) => t.status != TransactionStatus.cancelled).toList();

            // Handle Expenses
            List<ExpenseEntity> expenses = [];
            expResult.fold(
              (l) => debugPrint('⚠️ [DashboardCubit] create local expenses error: ${l.message}'),
              (r) => expenses = r,
            );


            // 1. Weekly Activity (Last 7 days)
            final Map<int, Map<String, double>> localWeeklyActivity = {};
            final List<Map<String, dynamic>> localWeeklyTrend = [];
            
            for (int i = 0; i < 7; i++) {
              final date = today.subtract(Duration(days: 6 - i));
              
              double buy = 0;
              double sell = 0;
              
              for (final t in validTxns) {
                  final tDate = t.transactionDate;
                  if (tDate.year == date.year && tDate.month == date.month && tDate.day == date.day) {
                      if (t.type == TransactionType.buy) buy += t.totalAmount;
                      if (t.type == TransactionType.sell) sell += t.totalAmount;
                  }
              }
              localWeeklyActivity[i] = {'buy': buy, 'sell': sell};
              localWeeklyTrend.add({
                '_id': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                'buy': buy,
                'sell': sell,
              });
            }

            // 2. Month & Today Stats
            double localTodayPurchases = 0;
            double localTodaySales = 0;
            int localTodayBuyCount = 0;
            int localTodaySellCount = 0;
            
            double localMonthPurchases = 0;
            double localMonthSales = 0;
            int localMonthBuyCount = 0;
            int localMonthSellCount = 0;

            // Transactions totals
            for (final t in validTxns) {
               final tDate = t.transactionDate;
               
               // Month
               if (tDate.year == today.year && tDate.month == today.month) {
                   if (t.type == TransactionType.buy) {
                       localMonthPurchases += t.totalAmount;
                       localMonthBuyCount++;
                   } else if (t.type == TransactionType.sell) {
                       localMonthSales += t.totalAmount;
                       localMonthSellCount++;
                   }
               }

               // Today
               if (tDate.year == today.year && tDate.month == today.month && tDate.day == today.day) {
                   if (t.type == TransactionType.buy) {
                       localTodayPurchases += t.totalAmount;
                       localTodayBuyCount++;
                   } else if (t.type == TransactionType.sell) {
                       localTodaySales += t.totalAmount;
                       localTodaySellCount++;
                   }
               }
            }

            // Expenses totals
            double localTodayExpenses = 0;
            double localMonthExpenses = 0;

            for (final e in expenses) {
                final eDate = e.date;
                // Month
                if (eDate.year == today.year && eDate.month == today.month) {
                    localMonthExpenses += e.amount;
                }
                // Today
                if (eDate.year == today.year && eDate.month == today.month && eDate.day == today.day) {
                    localTodayExpenses += e.amount;
                }
            }
            
            // Calculate Profits
            final localTodayProfit = localTodaySales - localTodayPurchases - localTodayExpenses;
            final localMonthProfit = localMonthSales - localMonthPurchases - localMonthExpenses;

            emit(state.copyWith(
                weeklyActivity: localWeeklyActivity,
                weeklyTrend: localWeeklyTrend,
                todayPurchases: localTodayPurchases,
                todaySales: localTodaySales,
                todayExpenses: localTodayExpenses,
                todayProfit: localTodayProfit,
                todayBuyCount: localTodayBuyCount,
                todaySellCount: localTodaySellCount,
                monthlyPurchases: localMonthPurchases,
                monthlySales: localMonthSales,
                monthlyExpenses: localMonthExpenses,
                monthlyProfit: localMonthProfit,
                monthlyBuyCount: localMonthBuyCount,
                monthlySellCount: localMonthSellCount,
            ));

        }
      );
    } catch (e) {
      debugPrint('⚠️ [DashboardCubit] Error in _loadLocalActivityData: $e');
    }
  }

  /// Load stock data from local database (Source of Truth)
  Future<void> _loadLocalStockData() async {
    // We already have stockRepository injected
    // This ensures that the dashboard shows exactly what the Stock Page shows
    final result = await _stockRepository.getAllStockItems();

    result.fold(
      (failure) {
        debugPrint(
            '⚠️ [DashboardCubit] Failed to load local stock: ${failure.message}');
      },
      (items) {
        double totalPaddy = 0;
        double totalRice = 0;
        int lowStock = 0;

        for (final item in items) {
          if (item.isLowStock) {
            lowStock++;
          }

          if (item.isPaddy) {
            totalPaddy += item.currentQuantity;
          } else if (item.isRice) {
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
}
