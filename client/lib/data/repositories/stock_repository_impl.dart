// lib/data/repositories/stock_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../core/constants/enums.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/stock_item_entity.dart';
import '../../domain/repositories/stock_repository.dart';
import '../datasources/remote/stock_remote_ds.dart';
import '../models/stock_item_model.dart';

class StockRepositoryImpl implements StockRepository {
  final StockRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  StockRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<StockItemEntity>>> getAllStockItems() async {
    try {
      final items = await remoteDataSource.getAllStockItems();
      return Right(items.map((i) => i.toEntity()).toList());
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
  Future<Either<Failure, StockItemEntity>> getStockItemById(String id) async {
    try {
      final item = await remoteDataSource.getStockItemById(id);
      return Right(item.toEntity());
    } catch (e) {
      if (e is NotFoundException) {
        return const Left(NotFoundFailure(message: 'Stock item not found'));
      } else if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StockItemEntity>>> getStockByType(
      ItemType type) async {
    try {
      final items = await remoteDataSource.getAllStockItems();
      final filtered = items.where((i) => i.type == type).toList();
      return Right(filtered.map((i) => i.toEntity()).toList());
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StockItemEntity>>> searchStock(
      String query) async {
    try {
      final items = await remoteDataSource.searchStock(query);
      return Right(items.map((i) => i.toEntity()).toList());
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, StockItemEntity>> addStockItem(
      StockItemModel item) async {
    try {
      final createdItem = await remoteDataSource.createStockItem(item);
      return Right(createdItem.toEntity());
    } catch (e) {
      if (e is ValidationException) {
        return Left(ValidationFailure(message: e.message));
      } else if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, StockItemEntity>> updateStockItem(
      StockItemModel item) async {
    try {
      final updatedItem = await remoteDataSource.updateStockItem(item);
      return Right(updatedItem.toEntity());
    } catch (e) {
      if (e is NotFoundException) {
        return const Left(NotFoundFailure(message: 'Stock item not found'));
      } else if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, StockItemEntity>> addStock({
    required String itemId,
    required double quantity,
    required int bags,
    required String transactionId,
  }) async {
    // This operation should be atomic on server but here we probably just rely on transaction flows usually.
    // However, for manual add/deduct:
    // We can fetch, update, save.
    try {
      final item = await remoteDataSource.getStockItemById(itemId);
      final updatedItem = item.copyWith(
        currentQuantity: item.currentQuantity + quantity,
        currentBags: item.currentBags + bags,
        updatedAt: DateTime.now(),
      );
      final result = await remoteDataSource.updateStockItem(updatedItem);
      return Right(result.toEntity());
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, StockItemEntity>> deductStock({
    required String itemId,
    required double quantity,
    required int bags,
    required String transactionId,
  }) async {
    try {
      final item = await remoteDataSource.getStockItemById(itemId);
      if (item.currentQuantity < quantity) {
        return const Left(ValidationFailure(message: 'Insufficient stock'));
      }
      final updatedItem = item.copyWith(
        currentQuantity: item.currentQuantity - quantity,
        currentBags: item.currentBags - bags,
        updatedAt: DateTime.now(),
      );
      final result = await remoteDataSource.updateStockItem(updatedItem);
      return Right(result.toEntity());
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteStockItem(String id) async {
    try {
      final result = await remoteDataSource.deleteStockItem(id);
      return Right(result);
    } catch (e) {
      if (e is NotFoundException) {
        return const Left(NotFoundFailure(message: 'Stock item not found'));
      } else if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<ItemType, double>>> getTotalStockByType() async {
    try {
      // Manual aggregation from all items if no endpoint
      final items = await remoteDataSource.getAllStockItems();
      final Map<ItemType, double> totals = {};
      for (var item in items) {
        totals[item.type] = (totals[item.type] ?? 0) + item.currentQuantity;
      }
      return Right(totals);
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StockItemEntity>>> getLowStockItems(
      double threshold) async {
    try {
      final items = await remoteDataSource.getAllStockItems();
      final lowStock =
          items.where((i) => i.currentQuantity <= threshold).toList();
      return Right(lowStock.map((i) => i.toEntity()).toList());
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, StockItemModel>> getOrCreateStockItem({
    required ItemType type,
    required String variety,
    required String companyId,
  }) async {
    try {
      final items = await remoteDataSource.getAllStockItems();
      final exists = items.firstWhere(
        (i) =>
            i.type == type && i.variety.toLowerCase() == variety.toLowerCase(),
        orElse: () => StockItemModel(
          id: '', // Empty ID indicates new
          localId: null,
          type: type,
          variety: variety,
          companyId: companyId,
          currentQuantity: 0,
          currentBags: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (exists.id.isEmpty) {
        // Create new
        final created = await remoteDataSource.createStockItem(exists);
        return Right(created);
      }
      return Right(exists);
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getStockMovementHistory(
      String itemId) async {
    // Requires endpoint
    return const Right([]);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> startMilling({
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
      final result = await remoteDataSource.startMilling(
        paddyItemId: paddyItemId,
        paddyQuantity: paddyQuantity,
        paddyBags: paddyBags,
        notes: notes,
        millingDate: millingDate,
        outputRiceKg: outputRiceKg,
        outputRiceBags: outputRiceBags,
        outputRiceName: outputRiceName,
        status: status,
      );

      return Right({
        'status': 'success',
        'timestamp': DateTime.now().toIso8601String(),
        ...result
      });
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      } else if (e is ValidationException) {
        return Left(ValidationFailure(message: e.message));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> completeMilling({
    required String id,
    required double riceQuantity,
    required int riceBags,
    required String outputRiceName,
    required double brokenRiceKg,
    required double huskKg,
    required double millingPercentage,
  }) async {
    try {
      final result = await remoteDataSource.completeMilling(
        id: id,
        riceQuantity: riceQuantity,
        riceBags: riceBags,
        outputRiceName: outputRiceName,
        brokenRiceKg: brokenRiceKg,
        huskKg: huskKg,
        millingPercentage: millingPercentage,
      );

      return Right({
        'status': 'success',
        'timestamp': DateTime.now().toIso8601String(),
        ...result
      });
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getMillingHistory({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final result = await remoteDataSource.getMillingHistory(
        startDate: startDate,
        endDate: endDate,
        page: page,
        limit: limit,
      );
      return Right(result);
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncStock() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<StockItemModel>>> getUnsyncedStockItems() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getStockSummary() async {
    try {
      // Ideally backend endpoint
      final items = await remoteDataSource.getAllStockItems();
      // Calculate locally
      final totalItems = items.length;
      final totalQuantity =
          items.fold(0.0, (sum, i) => sum + i.currentQuantity);
      final totalValue = items.fold(
          0.0, (sum, i) => sum + (i.currentQuantity * i.averagePricePerKg));

      return Right({
        'totalItems': totalItems,
        'totalQuantity': totalQuantity,
        'totalValue': totalValue,
      });
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<ItemType, double>>> getStockValueByType() async {
    try {
      final items = await remoteDataSource.getAllStockItems();
      final Map<ItemType, double> result = {};
      for (final type in ItemType.values) {
        final typeItems = items.where((i) => i.type == type);
        final val = typeItems.fold(
            0.0, (sum, i) => sum + (i.currentQuantity * i.averagePricePerKg));
        result[type] = val;
      }
      return Right(result);
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getVarieties({ItemType? type}) async {
    try {
      final items = await remoteDataSource.getAllStockItems();
      var filtered = items;
      if (type != null) {
        filtered = items.where((i) => i.type == type).toList();
      }
      final varSet = filtered.map((i) => i.variety).toSet().toList()..sort();
      return Right(varSet);
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isVarietyExists({
    required String variety,
    required ItemType type,
  }) async {
    try {
      final items = await remoteDataSource.getAllStockItems();
      final exists = items.any((i) =>
          i.type == type && i.variety.toLowerCase() == variety.toLowerCase());
      return Right(exists);
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, StockItemEntity>> adjustStock({
    required String itemId,
    required double newQuantity,
    required int newBags,
    required String reason,
  }) async {
    try {
      final item = await remoteDataSource.getStockItemById(itemId);
      final updatedItem = item.copyWith(
        currentQuantity: newQuantity,
        currentBags: newBags,
        updatedAt: DateTime.now(),
      );
      final result = await remoteDataSource.updateStockItem(updatedItem);
      return Right(result.toEntity());
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
