// lib/features/auth/auth_injection.dart

import 'package:get_it/get_it.dart';

import '../../data/datasources/remote/auth_remote_ds.dart';
import '../../domain/repositories/auth_repository.dart';
import 'presentation/cubit/auth_cubit.dart';

/// Auth feature dependency injection
class AuthInjection {
  static final GetIt _sl = GetIt.instance;

  /// Register all auth dependencies
  static Future<void> init() async {
    // ==================== REPOSITORY ====================
    // Note: Data sources are registered in main injection_container.dart
    // Only register feature-specific dependencies here

    // AuthRepository is already registered in main container,
    // but we need a feature-specific one if different implementation needed
    // For now, we'll use the global one

    // ==================== CUBIT ====================

    _sl.registerLazySingleton<AuthCubit>(
      () => AuthCubit(
        authRepository: _sl<AuthRepository>(),
      ),
    );
  }

  /// Get AuthCubit instance
  static AuthCubit get authCubit => _sl<AuthCubit>();

  /// Get AuthRepository instance
  static AuthRepository get authRepository => _sl<AuthRepository>();

  /// Reset auth (for testing)
  static Future<void> reset() async {
    if (_sl.isRegistered<AuthCubit>()) {
      await _sl.unregister<AuthCubit>();
    }
    if (_sl.isRegistered<AuthRepository>()) {
      await _sl.unregister<AuthRepository>();
    }
    if (_sl.isRegistered<AuthRemoteDataSource>()) {
      await _sl.unregister<AuthRemoteDataSource>();
    }
  }
}
