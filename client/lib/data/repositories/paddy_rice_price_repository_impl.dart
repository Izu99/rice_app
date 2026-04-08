// lib/data/repositories/paddy_rice_price_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/paddy_rice_price_entity.dart';
import '../../domain/repositories/paddy_rice_price_repository.dart';
import '../datasources/remote/paddy_rice_price_remote_ds.dart';
import '../models/paddy_rice_price_model.dart';

class PaddyRicePriceRepositoryImpl implements PaddyRicePriceRepository {
  final PaddyRicePriceRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  PaddyRicePriceRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, PaddyRicePriceEntity>> addPrice({
    required double price,
    double? priceRangeEnd,
    String qualityGrade = 'standard',
    String priceType = 'paddy',
    String? notes,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final model = await remoteDataSource.addPrice(
        price: price,
        priceRangeEnd: priceRangeEnd,
        qualityGrade: qualityGrade,
        priceType: priceType,
        notes: notes,
      );
      return Right(model.toEntity());
    } catch (e) {
      if (e is ValidationException) {
        return Left(
            ValidationFailure(message: e.message, fieldErrors: e.errors));
      } else if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      } else if (e is NetworkException) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaddyRicePriceListResponse>> getPricesByDistrict(
    String district, {
    int limit = 50,
    int page = 1,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final response = await remoteDataSource.getPricesByDistrict(
        district,
        limit: limit,
        page: page,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
      return Right(response);
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      } else if (e is NetworkException) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaddyRicePriceListResponse>> getMyCompanyPrices({
    int limit = 50,
    int page = 1,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final response = await remoteDataSource.getMyCompanyPrices(
        limit: limit,
        page: page,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
      return Right(response);
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      } else if (e is NetworkException) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DistrictWithPricesResponse>>>
      getDistrictsList() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final districts = await remoteDataSource.getDistrictsList();
      return Right(districts);
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      } else if (e is NetworkException) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaddyRicePriceEntity>> getPriceById(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final model = await remoteDataSource.getPriceById(id);
      return Right(model.toEntity());
    } catch (e) {
      if (e is NotFoundException) {
        return const Left(NotFoundFailure(message: 'Price not found'));
      } else if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      } else if (e is NetworkException) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaddyRicePriceEntity>> updatePrice(
    String id, {
    required double price,
    double? priceRangeEnd,
    String? qualityGrade,
    String? priceType,
    String? notes,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final model = await remoteDataSource.updatePrice(
        id,
        price: price,
        priceRangeEnd: priceRangeEnd,
        qualityGrade: qualityGrade,
        priceType: priceType,
        notes: notes,
      );
      return Right(model.toEntity());
    } catch (e) {
      if (e is NotFoundException) {
        return const Left(NotFoundFailure(message: 'Price not found'));
      } else if (e is ValidationException) {
        return Left(
            ValidationFailure(message: e.message, fieldErrors: e.errors));
      } else if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      } else if (e is NetworkException) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaddyRicePriceListResponse>> getAllPricesAdmin({
    int limit = 50,
    int page = 1,
    String? district,
    String? priceType,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final response = await remoteDataSource.getAllPricesAdmin(
        limit: limit,
        page: page,
        district: district,
        priceType: priceType,
      );
      return Right(response);
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      } else if (e is NetworkException) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> deletePrice(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.deletePrice(id);
      return Right(result);
    } catch (e) {
      if (e is NotFoundException) {
        return const Left(NotFoundFailure(message: 'Price not found'));
      } else if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      } else if (e is NetworkException) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
