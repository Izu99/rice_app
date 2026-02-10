import 'package:get_it/get_it.dart';
import '../../core/network/api_service.dart';
import '../../data/datasources/remote/expense_remote_ds.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/repositories/expense_repository.dart';
import 'presentation/cubit/expenses_cubit.dart';

void initExpensesInjection(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<ExpenseRemoteDataSource>(
    () => ExpenseRemoteDataSourceImpl(apiService: sl<ApiService>()),
  );

  // Repository
  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(remoteDataSource: sl<ExpenseRemoteDataSource>()),
  );

  // Cubit
  sl.registerLazySingleton<ExpensesCubit>(
    () => ExpensesCubit(repository: sl<ExpenseRepository>()),
  );
}
