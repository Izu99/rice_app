import 'package:get_it/get_it.dart';
import '../../domain/repositories/admin_repository.dart';
import 'presentation/cubit/admin_cubit.dart';

/// Register all super admin feature dependencies
void initAdminInjection(GetIt sl) {
  // Cubit
  sl.registerFactory<AdminCubit>(
    () => AdminCubit(adminRepository: sl<AdminRepository>()),
  );
}

/// Dispose admin feature dependencies if needed
void disposeAdminInjection(GetIt sl) {
  // Clean up if necessary
}

