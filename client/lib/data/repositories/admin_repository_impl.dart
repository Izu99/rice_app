import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/network_info.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/remote/admin_remote_ds.dart';
import '../models/company_model.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AdminRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDashboardStats() async {
    if (await networkInfo.isConnected) {
      try {
        final stats = await remoteDataSource.getDashboardStats();
        return Right(stats);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<CompanyModel>>> getAllCompanies() async {
    if (await networkInfo.isConnected) {
      try {
        final companies = await remoteDataSource.getAllCompanies();
        return Right(companies);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, CompanyModel>> createCompany({
    required String name,
    required String ownerName,
    required String email,
    required String phone,
    required String password,
    String? address,
    String? registrationNumber,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final company = await remoteDataSource.createCompany(
          name: name,
          ownerName: ownerName,
          email: email,
          phone: phone,
          password: password,
          address: address,
          registrationNumber: registrationNumber,
        );
        return Right(company);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, CompanyModel>> updateCompany(
      CompanyModel company) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedCompany = await remoteDataSource.updateCompany(company);
        return Right(updatedCompany);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateCompanyStatus(
      String companyId, String status) async {
    if (await networkInfo.isConnected) {
      try {
        final success =
            await remoteDataSource.updateCompanyStatus(companyId, status);
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteCompany(String companyId) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.deleteCompany(companyId);
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> resetCompanyPassword(
      String companyId, String newPassword) async {
    if (await networkInfo.isConnected) {
      try {
        final success =
            await remoteDataSource.resetCompanyPassword(companyId, newPassword);
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}

