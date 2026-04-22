import 'package:dartz/dartz.dart';
import '../entities/store_listing_entity.dart';
import '../../core/errors/failures.dart';

abstract class StoreListingRepository {
  Future<Either<Failure, List<StoreListingEntity>>> getListings({
    StoreCategory? category,
    int page = 1,
    int limit = 50,
  });

  Future<Either<Failure, Map<String, dynamic>>> getStats();

  Future<Either<Failure, List<StoreListingEntity>>> getMyListings();

  Future<Either<Failure, StoreListingEntity>> createListing({
    required StoreCategory category,
    required String variety,
    required String district,
    required String contactPhone,
    double quantityKg = 0,
    double pricePerKg = 0,
    String description = '',
    String? clientId,
  });

  Future<Either<Failure, StoreListingEntity>> updateListing(
    String id, {
    String? variety,
    double? quantityKg,
    double? pricePerKg,
    String? district,
    String? description,
    String? contactPhone,
  });

  Future<Either<Failure, bool>> deleteListing(String id);
}
