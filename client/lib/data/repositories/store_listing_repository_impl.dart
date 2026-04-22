import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/store_listing_entity.dart';
import '../../domain/repositories/store_listing_repository.dart';
import '../datasources/remote/store_listing_remote_ds.dart';

class StoreListingRepositoryImpl implements StoreListingRepository {
  final StoreListingRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  StoreListingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<StoreListingEntity>>> getListings({
    StoreCategory? category,
    int page = 1,
    int limit = 50,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final response = await remoteDataSource.getListings(category: category, page: page, limit: limit);
      return Right(response.items.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getStats() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final stats = await remoteDataSource.getStats();
      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StoreListingEntity>>> getMyListings() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final items = await remoteDataSource.getMyListings();
      return Right(items.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, StoreListingEntity>> createListing({
    required StoreCategory category,
    required String variety,
    required String district,
    required String contactPhone,
    double quantityKg = 0,
    double pricePerKg = 0,
    String description = '',
    String? clientId,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final model = await remoteDataSource.createListing(
        category: _catToString(category),
        variety: variety,
        district: district,
        contactPhone: contactPhone,
        quantityKg: quantityKg,
        pricePerKg: pricePerKg,
        description: description,
        clientId: clientId,
      );
      return Right(model.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message, fieldErrors: e.errors));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, StoreListingEntity>> updateListing(
    String id, {
    String? variety,
    double? quantityKg,
    double? pricePerKg,
    String? district,
    String? description,
    String? contactPhone,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final data = <String, dynamic>{
        if (variety != null) 'variety': variety,
        if (quantityKg != null) 'quantityKg': quantityKg,
        if (pricePerKg != null) 'pricePerKg': pricePerKg,
        if (district != null) 'district': district,
        if (description != null) 'description': description,
        if (contactPhone != null) 'contactPhone': contactPhone,
      };
      final model = await remoteDataSource.updateListing(id, data);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteListing(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.deleteListing(id);
      return const Right(true);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  static String _catToString(StoreCategory cat) {
    switch (cat) {
      case StoreCategory.paddy:
        return 'paddy';
      case StoreCategory.rice:
        return 'rice';
      case StoreCategory.riceMeal:
        return 'riceMeal';
      case StoreCategory.other:
        return 'other';
    }
  }
}
