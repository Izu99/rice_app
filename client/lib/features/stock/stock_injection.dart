import 'package:get_it/get_it.dart';
import '../../domain/repositories/stock_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import 'presentation/cubit/stock_cubit.dart';
import 'presentation/cubit/milling_cubit.dart';

/// Register all stock feature dependencies
void initStockInjection(GetIt sl) {
  // Cubits
  sl.registerLazySingleton<StockCubit>(
    () => StockCubit(
      stockRepository: sl<StockRepository>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  sl.registerLazySingleton<MillingCubit>(
    () => MillingCubit(
      stockRepository: sl<StockRepository>(),
    ),
  );
}

/// Dispose stock feature dependencies if needed
void disposeStockInjection(GetIt sl) {
  // Clean up if necessary
}
