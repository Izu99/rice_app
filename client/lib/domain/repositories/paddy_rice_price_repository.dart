// lib/domain/repositories/paddy_rice_price_repository.dart

import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../data/models/paddy_rice_price_model.dart';
import '../entities/paddy_rice_price_entity.dart';

/// Abstract repository interface for paddy rice price operations
/// Handles all price-related data operations
abstract class PaddyRicePriceRepository {
  /// Add a new paddy rice price
  ///
  /// Parameters:
  /// - [price]: Price to add (double)
  /// - [priceRangeEnd]: Optional end of price range
  /// - [qualityGrade]: Quality grade (premium, standard, basic)
  /// - [notes]: Optional notes about the price
  ///
  /// Returns the created [PaddyRicePriceEntity]
  Future<Either<Failure, PaddyRicePriceEntity>> addPrice({
    required double price,
    double? priceRangeEnd,
    String qualityGrade = 'standard',
    String priceType = 'paddy',
    String? notes,
  });

  /// Get paddy rice prices by district
  ///
  /// Parameters:
  /// - [district]: District name
  /// - [limit]: Number of results to return
  /// - [page]: Page number for pagination
  /// - [sortBy]: Field to sort by (default: 'createdAt')
  /// - [sortOrder]: Sort order ('asc' or 'desc', default: 'desc')
  ///
  /// Returns [PaddyRicePriceListResponse] with prices and pagination info
  Future<Either<Failure, PaddyRicePriceListResponse>> getPricesByDistrict(
    String district, {
    int limit = 50,
    int page = 1,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  });

  /// Get prices added by the current company
  ///
  /// Parameters:
  /// - [limit]: Number of results to return
  /// - [page]: Page number for pagination
  /// - [sortBy]: Field to sort by (default: 'createdAt')
  /// - [sortOrder]: Sort order ('asc' or 'desc', default: 'desc')
  ///
  /// Returns [PaddyRicePriceListResponse] with prices and pagination info
  Future<Either<Failure, PaddyRicePriceListResponse>> getMyCompanyPrices({
    int limit = 50,
    int page = 1,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  });

  /// Get all unique districts with price counts
  ///
  /// Returns list of [DistrictWithPricesResponse]
  Future<Either<Failure, List<DistrictWithPricesResponse>>> getDistrictsList();

  /// Get a price entry by ID
  ///
  /// Parameters:
  /// - [id]: Price ID
  ///
  /// Returns [PaddyRicePriceEntity] if found
  Future<Either<Failure, PaddyRicePriceEntity>> getPriceById(String id);

  /// Update a price entry (only by the company that added it)
  ///
  /// Parameters:
  /// - [id]: Price ID to update
  /// - [price]: New price value
  /// - [priceRangeEnd]: New price range end (optional)
  /// - [qualityGrade]: New quality grade (optional)
  /// - [notes]: New notes (optional)
  ///
  /// Returns the updated [PaddyRicePriceEntity]
  Future<Either<Failure, PaddyRicePriceEntity>> updatePrice(
    String id, {
    required double price,
    double? priceRangeEnd,
    String? qualityGrade,
    String? priceType,
    String? notes,
  });

  /// Get all prices (admin only)
  Future<Either<Failure, PaddyRicePriceListResponse>> getAllPricesAdmin({
    int limit = 50,
    int page = 1,
    String? district,
    String? priceType,
  });

  /// Delete a price entry (only by the company that added it)
  ///
  /// Parameters:
  /// - [id]: Price ID to delete
  ///
  /// Returns the deleted price ID
  Future<Either<Failure, String>> deletePrice(String id);
}
