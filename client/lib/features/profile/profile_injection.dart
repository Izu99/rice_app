// lib/features/profile/profile_injection.dart

import 'package:get_it/get_it.dart';
import '../../domain/repositories/auth_repository.dart';
import 'presentation/cubit/profile_cubit.dart';

/// Profile feature dependency injection
class ProfileInjection {
  static final GetIt _sl = GetIt.instance;

  /// Initialize profile dependencies
  static Future<void> init() async {
    _sl.registerLazySingleton<ProfileCubit>(
      () => ProfileCubit(authRepository: _sl<AuthRepository>()),
    );
  }

  static ProfileCubit get profileCubit => _sl<ProfileCubit>();

  static Future<void> reset() async {
    if (_sl.isRegistered<ProfileCubit>()) {
      _sl.unregister<ProfileCubit>();
    }
  }
}
