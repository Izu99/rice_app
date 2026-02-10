import 'package:get_it/get_it.dart';
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
import 'presentation/cubit/sell_cubit.dart';

/// Sell feature dependency injection (API-only)
class SellInjection {
  static final GetIt _sl = GetIt.instance;

  static Future<void> init() async {
    // Remote data sources
    if (!_sl.isRegistered<CustomerRemoteDataSource>()) {
      _sl.registerLazySingleton<CustomerRemoteDataSource>(
        () => CustomerRemoteDataSourceImpl(apiService: _sl()),
      );
    }
    if (!_sl.isRegistered<StockRemoteDataSource>()) {
      _sl.registerLazySingleton<StockRemoteDataSource>(
        () => StockRemoteDataSourceImpl(apiService: _sl()),
      );
    }
    if (!_sl.isRegistered<TransactionRemoteDataSource>()) {
      _sl.registerLazySingleton<TransactionRemoteDataSource>(
        () => TransactionRemoteDataSourceImpl(apiService: _sl()),
      );
    }

    // Repositories
    if (!_sl.isRegistered<CustomerRepository>()) {
      _sl.registerLazySingleton<CustomerRepository>(
        () => CustomerRepositoryImpl(
            remoteDataSource: _sl<CustomerRemoteDataSource>(),
            networkInfo: _sl<NetworkInfo>()),
      );
    }
    if (!_sl.isRegistered<StockRepository>()) {
      _sl.registerLazySingleton<StockRepository>(
        () => StockRepositoryImpl(
            remoteDataSource: _sl<StockRemoteDataSource>(),
            networkInfo: _sl<NetworkInfo>()),
      );
    }
    if (!_sl.isRegistered<TransactionRepository>()) {
      _sl.registerLazySingleton<TransactionRepository>(
        () => TransactionRepositoryImpl(
            remoteDataSource: _sl<TransactionRemoteDataSource>(),
            networkInfo: _sl<NetworkInfo>()),
      );
    }

    // Cubits
    _sl.registerLazySingleton<SellCubit>(
      () => SellCubit(
        customerRepository: _sl<CustomerRepository>(),
        stockRepository: _sl<StockRepository>(),
        transactionRepository: _sl<TransactionRepository>(),
      ),
    );
  }
}
