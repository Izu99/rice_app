// lib/domain/usecases/auth/check_auth_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';
import '../usecase.dart';

/// Check authentication status use case
/// Verifies if user is currently logged in
class CheckAuthUseCase implements UseCase<bool, NoParams> {
  final AuthRepository repository;

  CheckAuthUseCase({required this.repository});

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.isLoggedIn();
  }
}

/// Get current user use case
/// Returns the currently logged in user
class GetCurrentUserUseCase implements UseCase<UserEntity?, NoParams> {
  final AuthRepository repository;

  GetCurrentUserUseCase({required this.repository});

  @override
  Future<Either<Failure, UserEntity?>> call(NoParams params) async {
    return await repository.getCurrentUser();
  }
}

/// Refresh token use case
/// Refreshes the authentication token and returns updated user
class RefreshTokenUseCase implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  RefreshTokenUseCase({required this.repository});

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) async {
    return await repository.refreshToken();
  }
}
