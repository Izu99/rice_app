// lib/data/datasources/remote/paddy_rice_price_remote_ds.dart

import 'dart:convert';
import '../../../core/network/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../models/paddy_rice_price_model.dart';

abstract class PaddyRicePriceRemoteDataSource {
  /// Add a new paddy rice price
  Future<PaddyRicePriceModel> addPrice({
    required double price,
    double? priceRangeEnd,
    String qualityGrade = 'standard',
    String priceType = 'paddy',
    String? notes,
  });

  /// Get prices by district
  Future<PaddyRicePriceListResponse> getPricesByDistrict(
    String district, {
    int limit = 50,
    int page = 1,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  });

  /// Get prices added by current company
  Future<PaddyRicePriceListResponse> getMyCompanyPrices({
    int limit = 50,
    int page = 1,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  });

  /// Get all districts with price counts
  Future<List<DistrictWithPricesResponse>> getDistrictsList();

  /// Get price by ID
  Future<PaddyRicePriceModel> getPriceById(String id);

  /// Update a price entry
  Future<PaddyRicePriceModel> updatePrice(
    String id, {
    required double price,
    double? priceRangeEnd,
    String? qualityGrade,
    String? priceType,
    String? notes,
  });

  /// Get all prices (admin only)
  Future<PaddyRicePriceListResponse> getAllPricesAdmin({
    int limit = 50,
    int page = 1,
    String? district,
    String? priceType,
  });

  /// Delete a price entry
  Future<String> deletePrice(String id);
}

class PaddyRicePriceRemoteDataSourceImpl
    implements PaddyRicePriceRemoteDataSource {
  final ApiService apiService;

  PaddyRicePriceRemoteDataSourceImpl({required this.apiService});

  static const String _endpoint = '/api/paddy-rice-price';

  /// Helper method to convert Failure to appropriate exception
  Exception _mapFailureToException(Failure failure) {
    if (failure is NetworkFailure) {
      return NetworkException(message: failure.message);
    } else if (failure is AuthFailure) {
      return AuthException(
        message: failure.message,
        statusCode: failure.code,
      );
    } else if (failure is ValidationFailure) {
      return ValidationException(
        message: failure.message,
        errors: failure.fieldErrors,
      );
    } else if (failure is ServerFailure) {
      return ServerException(
        message: failure.message,
        statusCode: failure.code,
      );
    } else if (failure is NotFoundFailure) {
      return NotFoundException(message: failure.message);
    } else {
      return ServerException(message: failure.message);
    }
  }

  @override
  Future<PaddyRicePriceModel> addPrice({
    required double price,
    double? priceRangeEnd,
    String qualityGrade = 'standard',
    String priceType = 'paddy',
    String? notes,
  }) async {
    try {
      final body = {
        'price': price,
        'qualityGrade': qualityGrade,
        'priceType': priceType,
      };

      if (priceRangeEnd != null) {
        body['priceRangeEnd'] = priceRangeEnd;
      }
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }

      final either = await apiService.post(
        _endpoint,
        data: body,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return PaddyRicePriceModel.fromJson(response.data);
          }
          throw ServerException(message: response.message ?? 'Unknown error');
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PaddyRicePriceListResponse> getPricesByDistrict(
    String district, {
    int limit = 50,
    int page = 1,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      final either = await apiService.get(
        '$_endpoint/district/$district',
        queryParameters: {
          'limit': limit.toString(),
          'page': page.toString(),
          'sortBy': sortBy,
          'sortOrder': sortOrder,
        },
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return PaddyRicePriceListResponse.fromJson(response.data);
          }
          throw ServerException(message: response.message ?? 'Unknown error');
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PaddyRicePriceListResponse> getMyCompanyPrices({
    int limit = 50,
    int page = 1,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      final either = await apiService.get(
        '$_endpoint/company/my-prices',
        queryParameters: {
          'limit': limit.toString(),
          'page': page.toString(),
          'sortBy': sortBy,
          'sortOrder': sortOrder,
        },
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return PaddyRicePriceListResponse.fromJson(response.data);
          }
          throw ServerException(message: response.message ?? 'Unknown error');
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<DistrictWithPricesResponse>> getDistrictsList() async {
    try {
      final either = await apiService.get(
        '$_endpoint/districts/list',
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> districtsList =
                response.data['districts'] ?? [];
            return districtsList
                .map((d) =>
                    DistrictWithPricesResponse.fromJson(d as Map<String, dynamic>))
                .toList();
          }
          throw ServerException(message: response.message ?? 'Unknown error');
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PaddyRicePriceModel> getPriceById(String id) async {
    try {
      final either = await apiService.get('$_endpoint/$id');

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return PaddyRicePriceModel.fromJson(response.data);
          }
          throw ServerException(message: response.message ?? 'Unknown error');
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PaddyRicePriceModel> updatePrice(
    String id, {
    required double price,
    double? priceRangeEnd,
    String? qualityGrade,
    String? priceType,
    String? notes,
  }) async {
    try {
      final body = {
        'price': price.toString(),
      };

      if (priceRangeEnd != null) {
        body['priceRangeEnd'] = priceRangeEnd.toString();
      }
      if (qualityGrade != null) {
        body['qualityGrade'] = qualityGrade;
      }
      if (priceType != null) {
        body['priceType'] = priceType;
      }
      if (notes != null) {
        body['notes'] = notes;
      }

      final either = await apiService.put(
        '$_endpoint/$id',
        data: body,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return PaddyRicePriceModel.fromJson(response.data);
          }
          throw ServerException(message: response.message ?? 'Unknown error');
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> deletePrice(String id) async {
    try {
      final either = await apiService.delete('$_endpoint/$id');

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success) {
            return id;
          }
          throw ServerException(message: response.message ?? 'Unknown error');
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PaddyRicePriceListResponse> getAllPricesAdmin({
    int limit = 50,
    int page = 1,
    String? district,
    String? priceType,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'page': page.toString(),
      };
      if (district != null && district.isNotEmpty) queryParams['district'] = district;
      if (priceType != null && priceType.isNotEmpty) queryParams['priceType'] = priceType;

      final either = await apiService.get(
        '$_endpoint/admin/all',
        queryParameters: queryParams,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return PaddyRicePriceListResponse.fromJson(response.data);
          }
          throw ServerException(message: response.message ?? 'Unknown error');
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}
