import '../../../core/network/api_service.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/store_listing_entity.dart';
import '../../models/store_listing_model.dart';

abstract class StoreListingRemoteDataSource {
  Future<StoreListingsResponse> getListings({StoreCategory? category, int page = 1, int limit = 50});
  Future<Map<String, dynamic>> getStats();
  Future<List<StoreListingModel>> getMyListings();
  Future<StoreListingModel> createListing({
    required String category,
    required String variety,
    required String district,
    required String contactPhone,
    double quantityKg = 0,
    double pricePerKg = 0,
    String description = '',
    String? clientId,
  });
  Future<StoreListingModel> updateListing(String id, Map<String, dynamic> data);
  Future<void> deleteListing(String id);
}

class StoreListingRemoteDataSourceImpl implements StoreListingRemoteDataSource {
  final ApiService apiService;

  StoreListingRemoteDataSourceImpl({required this.apiService});

  static const _base = '/store/listings';

  Exception _mapFailure(Failure f) {
    if (f is NetworkFailure) return NetworkException(message: f.message);
    if (f is AuthFailure) return AuthException(message: f.message, statusCode: f.code);
    return ServerException(message: f.message);
  }

  @override
  Future<StoreListingsResponse> getListings({
    StoreCategory? category,
    int page = 1,
    int limit = 50,
  }) async {
    final params = <String, dynamic>{'page': page.toString(), 'limit': limit.toString()};
    if (category != null) params['category'] = _catToString(category);

    final either = await apiService.get(_base, queryParameters: params);
    return either.fold(
      (f) => throw _mapFailure(f),
      (response) {
        if (response.success && response.data != null) {
          return StoreListingsResponse.fromJson(response.data as Map<String, dynamic>);
        }
        throw ServerException(message: response.message ?? 'Unknown error');
      },
    );
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    final either = await apiService.get('$_base/stats');
    return either.fold(
      (f) => throw _mapFailure(f),
      (response) {
        if (response.success && response.data != null) {
          return response.data as Map<String, dynamic>;
        }
        throw ServerException(message: response.message ?? 'Unknown error');
      },
    );
  }

  @override
  Future<List<StoreListingModel>> getMyListings() async {
    final either = await apiService.get('$_base/my');
    return either.fold(
      (f) => throw _mapFailure(f),
      (response) {
        if (response.success && response.data != null) {
          final list = response.data as List<dynamic>;
          return list.map((e) => StoreListingModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        throw ServerException(message: response.message ?? 'Unknown error');
      },
    );
  }

  @override
  Future<StoreListingModel> createListing({
    required String category,
    required String variety,
    required String district,
    required String contactPhone,
    double quantityKg = 0,
    double pricePerKg = 0,
    String description = '',
    String? clientId,
  }) async {
    final body = <String, dynamic>{
      'category': category,
      'variety': variety,
      'district': district,
      'contactPhone': contactPhone,
      'quantityKg': quantityKg,
      'pricePerKg': pricePerKg,
      'description': description,
      if (clientId != null) 'clientId': clientId,
    };

    final either = await apiService.post(_base, data: body);
    return either.fold(
      (f) => throw _mapFailure(f),
      (response) {
        if (response.success && response.data != null) {
          return StoreListingModel.fromJson(response.data as Map<String, dynamic>);
        }
        throw ServerException(message: response.message ?? 'Unknown error');
      },
    );
  }

  @override
  Future<StoreListingModel> updateListing(String id, Map<String, dynamic> data) async {
    final either = await apiService.put('$_base/$id', data: data);
    return either.fold(
      (f) => throw _mapFailure(f),
      (response) {
        if (response.success && response.data != null) {
          return StoreListingModel.fromJson(response.data as Map<String, dynamic>);
        }
        throw ServerException(message: response.message ?? 'Unknown error');
      },
    );
  }

  @override
  Future<void> deleteListing(String id) async {
    final either = await apiService.delete('$_base/$id');
    either.fold((f) => throw _mapFailure(f), (_) {});
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
