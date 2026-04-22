import '../../core/network/api_service.dart';
import '../../core/network/network_info.dart';
import '../../domain/repositories/store_listing_repository.dart';
import '../../data/datasources/remote/store_listing_remote_ds.dart';
import '../../data/repositories/store_listing_repository_impl.dart';
import '../../injection_container.dart' as di;
import 'presentation/cubit/store_cubit.dart';

Future<void> initializeStoreDependencies() async {
  if (!di.sl.isRegistered<StoreListingRemoteDataSource>()) {
    di.sl.registerLazySingleton<StoreListingRemoteDataSource>(
      () => StoreListingRemoteDataSourceImpl(apiService: di.sl<ApiService>()),
    );
  }

  if (!di.sl.isRegistered<StoreListingRepository>()) {
    di.sl.registerLazySingleton<StoreListingRepository>(
      () => StoreListingRepositoryImpl(
        remoteDataSource: di.sl<StoreListingRemoteDataSource>(),
        networkInfo: di.sl<NetworkInfo>(),
      ),
    );
  }

  di.sl.registerFactory<StoreCubit>(
    () => StoreCubit(repository: di.sl<StoreListingRepository>()),
  );
}
