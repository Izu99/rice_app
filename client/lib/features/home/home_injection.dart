// lib/features/home/home_injection.dart

import 'package:get_it/get_it.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/stock_repository.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import 'presentation/cubit/dashboard_cubit.dart';

/// Home feature dependency injection
class HomeInjection {
  static final GetIt _sl = GetIt.instance;

  /// Register all home dependencies
  static Future<void> init() async {
    // ==================== CUBIT ====================

    _sl.registerLazySingleton<DashboardCubit>(
      () => DashboardCubit(
        transactionRepository: _sl<TransactionRepository>(),
        stockRepository: _sl<StockRepository>(),
        customerRepository: _sl<CustomerRepository>(),
        reportRepository: _sl<ReportRepository>(),
        authRepository: _sl<AuthRepository>(),
        expenseRepository: _sl<ExpenseRepository>(),
      ),
    );
  }

  /// Get DashboardCubit instance
  static DashboardCubit get dashboardCubit => _sl<DashboardCubit>();

  /// Reset home dependencies (for testing)
  static Future<void> reset() async {
    if (_sl.isRegistered<DashboardCubit>()) {
      await _sl.unregister<DashboardCubit>();
    }
  }
}
