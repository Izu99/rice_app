// lib/features/buy/buy_injection.dart

import 'package:get_it/get_it.dart';
import '../../core/network/api_service.dart';
import '../../core/network/network_info.dart';

import '../../data/datasources/remote/customer_remote_ds.dart';
import '../../data/datasources/remote/stock_remote_ds.dart';
import '../../data/datasources/remote/transaction_remote_ds.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../data/repositories/stock_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/stock_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import 'presentation/cubit/buy_cubit.dart';
import 'presentation/cubit/customer_cubit.dart';

/// Buy feature dependency injection
/// Registers all dependencies required for the Buy module
class BuyInjection {
  static final GetIt _sl = GetIt.instance;

  /// Initialize all Buy feature dependencies
  static Future<void> init() async {
    // ==================== DATA SOURCES ====================
    // Local data sources removed; API-first path
    // Register remote data sources if not already registered
    _registerRemoteDataSources();

    // ==================== REPOSITORIES ====================

    _registerRepositories();

    // ==================== CUBITS ====================

    _registerCubits();
  }

  // Local data sources registration removed for API-first path

  /// Register remote data sources
  static void _registerRemoteDataSources() {
    // Customer Remote Data Source
    if (!_sl.isRegistered<CustomerRemoteDataSource>()) {
      _sl.registerLazySingleton<CustomerRemoteDataSource>(
        () => CustomerRemoteDataSourceImpl(
          apiService: _sl<ApiService>(),
        ),
      );
    }

    // Stock Remote Data Source
    if (!_sl.isRegistered<StockRemoteDataSource>()) {
      _sl.registerLazySingleton<StockRemoteDataSource>(
        () => StockRemoteDataSourceImpl(
          apiService: _sl<ApiService>(),
        ),
      );
    }

    // Transaction Remote Data Source
    if (!_sl.isRegistered<TransactionRemoteDataSource>()) {
      _sl.registerLazySingleton<TransactionRemoteDataSource>(
        () => TransactionRemoteDataSourceImpl(
          apiService: _sl<ApiService>(),
        ),
      );
    }
  }

  /// Register repositories
  static void _registerRepositories() {
    // Customer Repository
    if (!_sl.isRegistered<CustomerRepository>()) {
      _sl.registerLazySingleton<CustomerRepository>(
        () => CustomerRepositoryImpl(
          remoteDataSource: _sl<CustomerRemoteDataSource>(),
          networkInfo: _sl<NetworkInfo>(),
        ),
      );
    }

    // Stock Repository
    if (!_sl.isRegistered<StockRepository>()) {
      _sl.registerLazySingleton<StockRepository>(
        () => StockRepositoryImpl(
          remoteDataSource: _sl<StockRemoteDataSource>(),
          networkInfo: _sl<NetworkInfo>(),
        ),
      );
    }

    // Transaction Repository
    if (!_sl.isRegistered<TransactionRepository>()) {
      _sl.registerLazySingleton<TransactionRepository>(
        () => TransactionRepositoryImpl(
          remoteDataSource: _sl<TransactionRemoteDataSource>(),
          networkInfo: _sl<NetworkInfo>(),
        ),
      );
    }
  }

  /// Register cubits
  static void _registerCubits() {
    // Buy Cubit - Lazy Singleton
    _sl.registerLazySingleton<BuyCubit>(
      () => BuyCubit(
        transactionRepository: _sl<TransactionRepository>(),
        customerRepository: _sl<CustomerRepository>(),
        authRepository: _sl<AuthRepository>(),
        stockRepository: _sl<StockRepository>(),
      ),
    );

    // Customer Cubit - Lazy Singleton
    _sl.registerLazySingleton<CustomerCubit>(
      () => CustomerCubit(
        customerRepository: _sl<CustomerRepository>(),
        authRepository: _sl<AuthRepository>(),
      ),
    );
  }

  /// Get BuyCubit instance
  static BuyCubit get buyCubit => _sl<BuyCubit>();

  /// Get CustomerCubit instance
  static CustomerCubit get customerCubit => _sl<CustomerCubit>();

  /// Get CustomerRepository instance
  static CustomerRepository get customerRepository => _sl<CustomerRepository>();

  /// Get TransactionRepository instance
  static TransactionRepository get transactionRepository =>
      _sl<TransactionRepository>();

  /// Reset all Buy feature dependencies (for testing)
  static Future<void> reset() async {
    // Unregister cubits
    if (_sl.isRegistered<BuyCubit>()) {
      _sl.unregister<BuyCubit>();
    }
    if (_sl.isRegistered<CustomerCubit>()) {
      _sl.unregister<CustomerCubit>();
    }

    // Note: We don't unregister repositories and data sources
    // as they might be used by other features
  }

  /// Reset all dependencies including shared ones (for testing only)
  static Future<void> resetAll() async {
    // Cubits
    if (_sl.isRegistered<BuyCubit>()) {
      _sl.unregister<BuyCubit>();
    }
    if (_sl.isRegistered<CustomerCubit>()) {
      _sl.unregister<CustomerCubit>();
    }

    // Repositories
    if (_sl.isRegistered<TransactionRepository>()) {
      _sl.unregister<TransactionRepository>();
    }
    if (_sl.isRegistered<StockRepository>()) {
      _sl.unregister<StockRepository>();
    }
    if (_sl.isRegistered<CustomerRepository>()) {
      _sl.unregister<CustomerRepository>();
    }

    // Remote Data Sources
    if (_sl.isRegistered<TransactionRemoteDataSource>()) {
      _sl.unregister<TransactionRemoteDataSource>();
    }
    if (_sl.isRegistered<StockRemoteDataSource>()) {
      _sl.unregister<StockRemoteDataSource>();
    }
    if (_sl.isRegistered<CustomerRemoteDataSource>()) {
      _sl.unregister<CustomerRemoteDataSource>();
    }

    // Local Data Sources purged in API-only path
  }

  /// Check if all dependencies are registered
  static bool get isInitialized {
    return _sl.isRegistered<BuyCubit>() &&
        _sl.isRegistered<CustomerCubit>() &&
        _sl.isRegistered<TransactionRepository>() &&
        _sl.isRegistered<CustomerRepository>();
  }
}
