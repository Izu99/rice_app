// lib/features/customers/customers_injection.dart

import 'package:get_it/get_it.dart';
import '../../core/network/api_service.dart';
import '../../core/network/network_info.dart';

import '../../data/datasources/remote/customer_remote_ds.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/repositories/customer_repository.dart';
import 'presentation/cubit/customers_cubit.dart';

/// Customers feature dependency injection
class CustomersInjection {
  static final GetIt _sl = GetIt.instance;

  /// Initialize all Customers feature dependencies
  static Future<void> init() async {
    // ==================== DATA SOURCES ====================

    // Local data sources removed

    // Remote data source
    if (!_sl.isRegistered<CustomerRemoteDataSource>()) {
      _sl.registerLazySingleton<CustomerRemoteDataSource>(
        () => CustomerRemoteDataSourceImpl(apiService: _sl<ApiService>()),
      );
    }

    // ==================== REPOSITORY ====================

    if (!_sl.isRegistered<CustomerRepository>()) {
      _sl.registerLazySingleton<CustomerRepository>(
        () => CustomerRepositoryImpl(
          remoteDataSource: _sl<CustomerRemoteDataSource>(),
          networkInfo: _sl<NetworkInfo>(),
        ),
      );
    }

    // ==================== CUBIT ====================

    _sl.registerFactory<CustomersCubit>(
      () => CustomersCubit(
        customerRepository: _sl<CustomerRepository>(),
      ),
    );
  }

  /// Get CustomersCubit instance
  static CustomersCubit get customersCubit => _sl<CustomersCubit>();

  /// Get CustomerRepository instance
  static CustomerRepository get customerRepository => _sl<CustomerRepository>();

  /// Reset all Customers feature dependencies (for testing)
  static Future<void> reset() async {
    if (_sl.isRegistered<CustomersCubit>()) {
      _sl.unregister<CustomersCubit>();
    }
  }

  /// Reset all dependencies including shared ones (for testing only)
  static Future<void> resetAll() async {
    // Cubit
    if (_sl.isRegistered<CustomersCubit>()) {
      _sl.unregister<CustomersCubit>();
    }

    // Repository
    if (_sl.isRegistered<CustomerRepository>()) {
      _sl.unregister<CustomerRepository>();
    }

    // Data Sources
    if (_sl.isRegistered<CustomerRemoteDataSource>()) {
      _sl.unregister<CustomerRemoteDataSource>();
    }
  }

  /// Check if all dependencies are registered
  static bool get isInitialized {
    return _sl.isRegistered<CustomersCubit>() &&
        _sl.isRegistered<CustomerRepository>();
  }
}

