// lib/data/datasources/remote/stock_remote_ds.dart

import 'dart:io';
import '../../../core/network/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/enums.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../models/stock_item_model.dart';

abstract class StockRemoteDataSource {
  /// Get all stock items from server
  Future<List<StockItemModel>> getAllStockItems({
    int page = 1,
    int limit = 50,
  });

  /// Get stock item by ID from server
  Future<StockItemModel> getStockItemById(String id);

  /// Get stock by type (Paddy/Rice)
  Future<List<StockItemModel>> getStockByType(ItemType type);

  /// Search stock items
  Future<List<StockItemModel>> searchStock(String query);

  /// Create new stock item on server
  Future<StockItemModel> createStockItem(StockItemModel item);

  /// Update stock item on server
  Future<StockItemModel> updateStockItem(StockItemModel item);

  /// Add stock on server
  Future<StockItemModel> addStock({
    required String itemId,
    required double quantity,
    required int bags,
    required String transactionId,
    String? notes,
  });

  /// Deduct stock on server
  Future<StockItemModel> deductStock({
    required String itemId,
    required double quantity,
    required int bags,
    required String transactionId,
    String? notes,
  });

  /// Delete stock item on server
  Future<bool> deleteStockItem(String id);

  /// Sync stock items
  Future<List<StockItemModel>> syncStock(List<StockItemModel> items);

  /// Get stock updated after a specific date
  Future<List<StockItemModel>> getStockUpdatedAfter(DateTime dateTime);

  /// Get stock summary
  Future<Map<String, dynamic>> getStockSummary();

  /// Get low stock items
  Future<List<StockItemModel>> getLowStockItems(double threshold);

  /// Get stock movement history
  Future<List<Map<String, dynamic>>> getStockMovementHistory({
    required String itemId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  });

  /// Start milling on server
  Future<Map<String, dynamic>> startMilling({
    required String paddyItemId,
    required double paddyQuantity,
    required int paddyBags,
    String? notes,
    required DateTime millingDate,
    double? outputRiceKg,
    int? outputRiceBags,
    String? outputRiceName,
    String? status,
  });

  /// Complete milling operation (receive rice from mill)
  Future<Map<String, dynamic>> completeMilling({
    required String id,
    required double riceQuantity,
    required int riceBags,
    required String outputRiceName,
    required double brokenRiceKg,
    required double huskKg,
    required double millingPercentage,
  });

  /// Get milling history
  Future<List<Map<String, dynamic>>> getMillingHistory({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  });
}

class StockRemoteDataSourceImpl implements StockRemoteDataSource {
  final ApiService apiService;

  StockRemoteDataSourceImpl({required this.apiService});

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
    } else {
      return ServerException(message: failure.message);
    }
  }

  @override
  Future<List<StockItemModel>> getAllStockItems({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final either = await apiService.get(
        ApiEndpoints.stock,
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
        useCache: false, // Explicitly bypass cache
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> stockJson =
                response.data['items'] ?? response.data;
            return stockJson
                .map((json) =>
                    StockItemModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          throw ServerException(
            message: response.message ?? 'Failed to fetch stock',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to fetch stock: ${e.toString()}');
    }
  }

  @override
  Future<StockItemModel> getStockItemById(String id) async {
    try {
      final either = await apiService.get(
        '${ApiEndpoints.stock}/$id',
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return StockItemModel.fromJson(response.data);
          }

          if (response.statusCode == 404) {
            throw NotFoundException(message: 'Stock item not found');
          }

          throw ServerException(
            message: response.message ?? 'Failed to fetch stock item',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on ServerException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to fetch stock item: ${e.toString()}');
    }
  }

  @override
  Future<List<StockItemModel>> getStockByType(ItemType type) async {
    try {
      final either = await apiService.get(
        ApiEndpoints.stockByType(type.name),
        queryParameters: {'type': type.name},
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> stockJson =
                response.data['items'] ?? response.data;
            return stockJson
                .map((json) =>
                    StockItemModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          throw ServerException(
            message: response.message ?? 'Failed to fetch stock by type',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to fetch stock by type: ${e.toString()}');
    }
  }

  @override
  Future<List<StockItemModel>> searchStock(String query) async {
    try {
      final either = await apiService.get(
        ApiEndpoints.searchStock,
        queryParameters: {'q': query},
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> stockJson =
                response.data['items'] ?? response.data;
            return stockJson
                .map((json) =>
                    StockItemModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          throw ServerException(
            message: response.message ?? 'Failed to search stock',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to search stock: ${e.toString()}');
    }
  }

  @override
  Future<StockItemModel> createStockItem(StockItemModel item) async {
    try {
      final either = await apiService.post(
        ApiEndpoints.stock,
        data: item.toJsonForApi(),
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return StockItemModel.fromJson(response.data);
          }

          if (response.statusCode == 409) {
            throw ValidationException(
              message: 'Stock item with this variety already exists',
              errors: {
                'variety': ['Already exists']
              },
            );
          }

          if (response.statusCode == 422) {
            throw ValidationException(
              message: response.message ?? 'Validation failed',
              errors: _parseValidationErrors(response.data),
            );
          }

          throw ServerException(
            message: response.message ?? 'Failed to create stock item',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on ServerException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to create stock item: ${e.toString()}');
    }
  }

  @override
  Future<StockItemModel> updateStockItem(StockItemModel item) async {
    try {
      final serverId = item.serverId ?? item.id;

      final either = await apiService.put(
        '${ApiEndpoints.stock}/$serverId',
        data: item.toJsonForApi(),
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return StockItemModel.fromJson(response.data);
          }

          if (response.statusCode == 404) {
            throw NotFoundException(message: 'Stock item not found');
          }

          throw ServerException(
            message: response.message ?? 'Failed to update stock item',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on ServerException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to update stock item: ${e.toString()}');
    }
  }

  @override
  Future<StockItemModel> addStock({
    required String itemId,
    required double quantity,
    required int bags,
    required String transactionId,
    String? notes,
  }) async {
    try {
      final either = await apiService.post(
        ApiEndpoints.stockAddStock,
        data: {
          'item_id': itemId,
          'quantity': quantity,
          'bags': bags,
          'transaction_id': transactionId,
          'notes': notes,
          'movement_type': MovementType.stockIn.name,
        },
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return StockItemModel.fromJson(response.data);
          }

          if (response.statusCode == 404) {
            throw NotFoundException(message: 'Stock item not found');
          }

          throw ServerException(
            message: response.message ?? 'Failed to add stock',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on ServerException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to add stock: ${e.toString()}');
    }
  }

  @override
  Future<StockItemModel> deductStock({
    required String itemId,
    required double quantity,
    required int bags,
    required String transactionId,
    String? notes,
  }) async {
    try {
      final either = await apiService.post(
        ApiEndpoints.stockDeductStock,
        data: {
          'item_id': itemId,
          'quantity': quantity,
          'bags': bags,
          'transaction_id': transactionId,
          'notes': notes,
          'movement_type': MovementType.stockOut.name,
        },
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return StockItemModel.fromJson(response.data);
          }

          if (response.statusCode == 404) {
            throw NotFoundException(message: 'Stock item not found');
          }

          if (response.statusCode == 400) {
            throw ValidationException(
              message: response.message ?? 'Insufficient stock',
              errors: {
                'quantity': ['Insufficient stock']
              },
            );
          }

          throw ServerException(
            message: response.message ?? 'Failed to deduct stock',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on ServerException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to deduct stock: ${e.toString()}');
    }
  }

  @override
  Future<bool> deleteStockItem(String id) async {
    try {
      final either = await apiService.delete(
        '${ApiEndpoints.stock}/$id',
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success) {
            return true;
          }

          if (response.statusCode == 404) {
            throw NotFoundException(message: 'Stock item not found');
          }

          throw ServerException(
            message: response.message ?? 'Failed to delete stock item',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on ServerException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to delete stock item: ${e.toString()}');
    }
  }

  @override
  Future<List<StockItemModel>> syncStock(List<StockItemModel> items) async {
    try {
      final either = await apiService.post(
        ApiEndpoints.stockSync,
        data: {
          'items': items.map((i) => i.toJsonForSync()).toList(),
        },
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> syncedJson = response.data['synced'] ?? [];
            return syncedJson
                .map((json) =>
                    StockItemModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          throw SyncException(
            message: response.message ?? 'Failed to sync stock',
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on SyncException {
      rethrow;
    } catch (e) {
      throw SyncException(message: 'Failed to sync stock: ${e.toString()}');
    }
  }

  @override
  Future<List<StockItemModel>> getStockUpdatedAfter(DateTime dateTime) async {
    try {
      final either = await apiService.get(
        ApiEndpoints.stockUpdates,
        queryParameters: {
          'updated_after': dateTime.toIso8601String(),
        },
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> stockJson =
                response.data['items'] ?? response.data;
            return stockJson
                .map((json) =>
                    StockItemModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          throw ServerException(
            message: response.message ?? 'Failed to fetch stock updates',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to fetch stock updates: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getStockSummary() async {
    try {
      final either = await apiService.get(
        ApiEndpoints.stockSummary,
        useCache: false, // Explicitly bypass cache
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return response.data as Map<String, dynamic>;
          }

          throw ServerException(
            message: response.message ?? 'Failed to fetch stock summary',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to fetch stock summary: ${e.toString()}');
    }
  }

  @override
  Future<List<StockItemModel>> getLowStockItems(double threshold) async {
    try {
      final either = await apiService.get(
        ApiEndpoints.lowStock,
        queryParameters: {'threshold': threshold.toString()},
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> stockJson =
                response.data['items'] ?? response.data;
            return stockJson
                .map((json) =>
                    StockItemModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          throw ServerException(
            message: response.message ?? 'Failed to fetch low stock items',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to fetch low stock items: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStockMovementHistory({
    required String itemId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final either = await apiService.get(
        '${ApiEndpoints.stock}/$itemId/movements',
        queryParameters: queryParams,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> movementsJson =
                response.data['movements'] ?? response.data;
            return movementsJson.cast<Map<String, dynamic>>();
          }

          throw ServerException(
            message:
                response.message ?? 'Failed to fetch stock movement history',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to fetch stock movement history: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> startMilling({
    required String paddyItemId,
    required double paddyQuantity,
    required int paddyBags,
    String? notes,
    required DateTime millingDate,
    double? outputRiceKg,
    int? outputRiceBags,
    String? outputRiceName,
    String? status,
  }) async {
    try {
      final either = await apiService.post(
        ApiEndpoints.milling,
        data: {
          'paddyItemId': paddyItemId,
          'inputPaddyKg': paddyQuantity,
          'inputPaddyBags': paddyBags,
          'notes': notes,
          'millingDate': millingDate.toIso8601String(),
          'outputRiceKg': outputRiceKg,
          'outputRiceBags': outputRiceBags,
          'outputRiceName': outputRiceName,
          'status': status ?? 'completed',
        },
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return response.data as Map<String, dynamic>;
          }

          if (response.statusCode == 400) {
            throw ValidationException(
              message:
                  response.message ?? 'Insufficient paddy stock for milling',
              errors: {
                'inputPaddyKg': ['Insufficient stock']
              },
            );
          }

          throw ServerException(
            message: response.message ?? 'Failed to record milling',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on ServerException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to record milling: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> completeMilling({
    required String id,
    required double riceQuantity,
    required int riceBags,
    required String outputRiceName,
    required double brokenRiceKg,
    required double huskKg,
    required double millingPercentage,
  }) async {
    try {
      final either = await apiService.put(
        '${ApiEndpoints.milling}/$id/complete',
        data: {
          'outputRiceKg': riceQuantity,
          'outputRiceBags': riceBags,
          'outputRiceName': outputRiceName,
          'brokenRiceKg': brokenRiceKg,
          'huskKg': huskKg,
          'millingPercentage': millingPercentage,
        },
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return response.data as Map<String, dynamic>;
          }

          throw ServerException(
            message: response.message ?? 'Failed to complete milling',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to complete milling: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMillingHistory({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final either = await apiService.get(
        ApiEndpoints.milling,
        queryParameters: queryParams,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> millingJson =
                response.data['milling_records'] ?? response.data;
            return millingJson.cast<Map<String, dynamic>>();
          }

          throw ServerException(
            message: response.message ?? 'Failed to fetch milling history',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to fetch milling history: ${e.toString()}');
    }
  }

  /// Parse validation errors from API response
  Map<String, List<String>>? _parseValidationErrors(dynamic data) {
    if (data is Map && data.containsKey('errors')) {
      final errors = data['errors'];
      if (errors is Map) {
        return errors.map((key, value) => MapEntry(
              key.toString(),
              value is List
                  ? value.map((e) => e.toString()).toList()
                  : [value.toString()],
            ));
      }
    }
    return null;
  }
}

