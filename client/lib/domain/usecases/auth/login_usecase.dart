import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';
import '../usecase.dart';

// lib/domain/usecases/auth/login_usecase.dart

/// Login use case
/// Handles user authentication with email/phone and password
class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final AuthRepository repository;

  LoginUseCase({required this.repository});

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    // Validate inputs before calling repository
    if (params.identifier.isEmpty) {
      return const Left(
          ValidationFailure(message: 'Email or phone is required'));
    }

    if (params.password.isEmpty) {
      return const Left(ValidationFailure(message: 'Password is required'));
    }

    if (params.password.length < 6) {
      return const Left(
          ValidationFailure(message: 'Password must be at least 6 characters'));
    }

    return await repository.login(
      phone: params.identifier,
      password: params.password,
      rememberMe: params.rememberMe,
    );
  }
}

/// Parameters for login use case
class LoginParams extends Equatable {
  final String identifier; // Email or Phone
  final String password;
  final bool rememberMe;

  const LoginParams({
    required this.identifier,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [identifier, password, rememberMe];
}
