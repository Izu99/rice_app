import 'package:dartz/dartz.dart';
import '../../core/constants/enums.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/security/token_storage.dart';
import '../datasources/remote/auth_remote_ds.dart';
import '../models/company_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final TokenStorage tokenStorage;

  AuthRepositoryImpl(
      {required this.remoteDataSource,
      required this.networkInfo,
      required this.tokenStorage});

  @override
  Future<Either<Failure, UserEntity>> login(
      {required String phone,
      required String password,
      bool rememberMe = false}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
    try {
      final authResponse =
          await remoteDataSource.login(identifier: phone, password: password);
      await tokenStorage.saveToken(authResponse.accessToken);
      await tokenStorage.saveRefreshToken(authResponse.refreshToken);

      final userEntity = authResponse.user.toEntity();
      await tokenStorage.saveUser(userEntity);

      if (authResponse.company != null) {
        await tokenStorage.saveCompany(authResponse.company!);
      }

      print(
          '📦 [AuthRepo] Login success: user=${userEntity.name}, companyId=${userEntity.companyId}');
      return Right(userEntity);
    } catch (e) {
      if (e is AuthException) {
        return Left(AuthFailure(message: e.message, code: e.statusCode));
      }
      if (e is ServerException) return Left(ServerFailure(message: e.message));
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register(
      {required String name,
      required String phone,
      required String password,
      required String companyId,
      UserRole role = UserRole.operator}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
    try {
      final authResponse = await remoteDataSource.register(
          name: name,
          phone: phone,
          password: password,
          companyId: companyId,
          role: role);
      await tokenStorage.saveToken(authResponse.accessToken);
      await tokenStorage.saveRefreshToken(authResponse.refreshToken);

      final userEntity = authResponse.user.toEntity();
      await tokenStorage.saveUser(userEntity);

      if (authResponse.company != null) {
        await tokenStorage.saveCompany(authResponse.company!);
      }

      return Right(userEntity);
    } catch (e) {
      if (e is AuthException) {
        return Left(AuthFailure(message: e.message, code: e.statusCode));
      }
      if (e is ValidationException) {
        return Left(
            ValidationFailure(message: e.message, fieldErrors: e.errors));
      }
      if (e is NetworkException) return const Left(NetworkFailure());
      if (e is ServerException) return Left(ServerFailure(message: e.message));
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    await tokenStorage.clearAll();
    if (await networkInfo.isConnected) {
      remoteDataSource.logout().catchError((e) {});
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    final token = await tokenStorage.getToken();
    final user = await tokenStorage.getUser();
    return Right(token != null && token.isNotEmpty && user != null);
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    // Check local storage first
    final cachedUser = await tokenStorage.getUser();

    if (!await networkInfo.isConnected) {
      if (cachedUser != null) return Right(cachedUser);
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final remoteUser = await remoteDataSource.getCurrentUser();
      final userEntity = remoteUser.toEntity();
      await tokenStorage.saveUser(userEntity);
      return Right(userEntity);
    } catch (e) {
      if (cachedUser != null) return Right(cachedUser);

      if (e is AuthException) {
        return Left(AuthFailure(message: e.message, code: e.statusCode));
      }
      if (e is ServerException) return Left(ServerFailure(message: e.message));
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile(
      {String? name, String? email, String? avatar}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
    try {
      final updatedUser = await remoteDataSource.updateProfile(
          name: name, email: email, avatar: avatar);
      final entity = updatedUser.toEntity();
      await tokenStorage.saveUser(entity);
      return Right(entity);
    } catch (e) {
      if (e is AuthException) return Left(AuthFailure(message: e.message));
      if (e is ServerException) return Left(ServerFailure(message: e.message));
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> changePassword(
      {required String currentPassword, required String newPassword}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
    try {
      await remoteDataSource.changePassword(
          currentPassword: currentPassword, newPassword: newPassword);
      return const Right(true);
    } catch (e) {
      if (e is AuthException) {
        return Left(AuthFailure(message: e.message, code: e.statusCode));
      }
      if (e is ServerException) return Left(ServerFailure(message: e.message));
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> requestPasswordReset(String phone) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
    try {
      await remoteDataSource.requestPasswordReset(phone);
      return const Right(true);
    } catch (e) {
      if (e is AuthException) {
        return Left(AuthFailure(message: e.message, code: e.statusCode));
      }
      if (e is ServerException) return Left(ServerFailure(message: e.message));
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyOtp(
      {required String phone, required String otp}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
    try {
      await remoteDataSource.verifyOtp(phone: phone, otp: otp);
      return const Right(true);
    } catch (e) {
      if (e is AuthException) {
        return Left(AuthFailure(message: e.message, code: e.statusCode));
      }
      if (e is ServerException) return Left(ServerFailure(message: e.message));
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> resetPassword(
      {required String phone,
      required String otp,
      required String newPassword}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
    try {
      await remoteDataSource.resetPassword(
          phone: phone, otp: otp, newPassword: newPassword);
      return const Right(true);
    } catch (e) {
      if (e is AuthException) {
        return Left(AuthFailure(message: e.message, code: e.statusCode));
      }
      if (e is ServerException) return Left(ServerFailure(message: e.message));
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> resendOtp(String phone) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
    try {
      await remoteDataSource.resendOtp(phone);
      return const Right(true);
    } catch (e) {
      if (e is AuthException) {
        return Left(AuthFailure(message: e.message, code: e.statusCode));
      }
      if (e is ServerException) return Left(ServerFailure(message: e.message));
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getToken() async {
    final token = await tokenStorage.getToken();
    return Right(token);
  }

  @override
  Future<Either<Failure, UserEntity>> refreshToken() async {
    final refresh = await tokenStorage.getRefreshToken();
    if (refresh == null) {
      return const Left(AuthFailure(message: 'No refresh token available'));
    }
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final authResponse = await remoteDataSource.refreshToken(refresh);
      await tokenStorage.saveToken(authResponse.accessToken);
      await tokenStorage.saveRefreshToken(authResponse.refreshToken);

      final userEntity = authResponse.user.toEntity();
      await tokenStorage.saveUser(userEntity);

      return Right(userEntity);
    } catch (e) {
      if (e is AuthException) {
        return Left(AuthFailure(message: e.message, code: e.statusCode));
      }
      if (e is ServerException) return Left(ServerFailure(message: e.message));
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> getSavedCredentials() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, CompanyModel?>> getCompany() async {
    // Check local storage first
    final cachedCompany = await tokenStorage.getCompany();

    if (!await networkInfo.isConnected) {
      if (cachedCompany != null) return Right(cachedCompany);
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final remoteUser = await remoteDataSource.getCurrentUser();
      final companyId = remoteUser.companyId;
      print('🔍 [AuthRepo] getCompany: companyId="$companyId"');
      if (companyId.isNotEmpty) {
        final company = await remoteDataSource.getCompanyDetails(companyId);
        await tokenStorage.saveCompany(company);
        return Right(company);
      }
      return const Right(null);
    } catch (e) {
      if (cachedCompany != null) return Right(cachedCompany);

      if (e is AuthException) {
        return Left(AuthFailure(message: e.message, code: e.statusCode));
      }
      if (e is ServerException) return Left(ServerFailure(message: e.message));
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CompanyModel>> updateCompany(
      {required CompanyModel company}) async {
    try {
      final updated = await remoteDataSource.updateCompany(company);
      await tokenStorage.saveCompany(updated);
      return Right(updated);
    } catch (e) {
      if (e is ServerException) return Left(ServerFailure(message: e.message));
      if (e is AuthException) {
        return Left(AuthFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateFcmToken(String fcmToken) async {
    try {
      await remoteDataSource.updateFcmToken(fcmToken);
      return const Right(true);
    } catch (e) {
      return const Right(false); // Fail silently for FCM
    }
  }

  @override
  Future<Either<Failure, bool>> isPhoneRegistered(String phone) async {
    try {
      final exists = await remoteDataSource.isPhoneRegistered(phone);
      return Right(exists);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DateTime?>> getLastSyncTime() async {
    // Local storage
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveLastSyncTime(DateTime dateTime) async {
    // Local storage
    return const Right(null);
  }
}
