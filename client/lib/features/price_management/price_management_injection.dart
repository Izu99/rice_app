// lib/features/price_management/price_management_injection.dart

import '../../domain/repositories/paddy_rice_price_repository.dart';
import '../../data/repositories/paddy_rice_price_repository_impl.dart';
import '../../data/datasources/remote/paddy_rice_price_remote_ds.dart';
import '../../core/network/network_info.dart';
import '../../core/network/api_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../injection_container.dart' as di;
import 'presentation/cubit/price_management_cubit.dart';

/// Initialize price management feature dependencies
Future<void> initializePriceManagementDependencies() async {
  // Register Remote Data Source
  di.sl.registerSingleton<PaddyRicePriceRemoteDataSource>(
    PaddyRicePriceRemoteDataSourceImpl(
      apiService: di.sl<ApiService>(),
    ),
  );

  // Register Repository
  di.sl.registerSingleton<PaddyRicePriceRepository>(
    PaddyRicePriceRepositoryImpl(
      remoteDataSource: di.sl<PaddyRicePriceRemoteDataSource>(),
      networkInfo: di.sl<NetworkInfo>(),
    ),
  );

  // Register Cubit
  di.sl.registerFactory<PriceManagementCubit>(
    () => PriceManagementCubit(
      priceRepository: di.sl<PaddyRicePriceRepository>(),
      authRepository: di.sl<AuthRepository>(),
    ),
  );
}
