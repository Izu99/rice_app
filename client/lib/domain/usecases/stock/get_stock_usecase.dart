import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/constants/enums.dart';
import '../../entities/stock_item_entity.dart';
import '../../repositories/stock_repository.dart';
import '../usecase.dart';

// lib/domain/usecases/stock/get_stock_usecase.dart

/// Get all stock use case
/// Returns all stock items
class GetStockUseCase implements UseCase<List<StockItemEntity>, NoParams> {
  final StockRepository repository;

  GetStockUseCase({required this.repository});

  @override
  Future<Either<Failure, List<StockItemEntity>>> call(NoParams params) async {
    return await repository.getAllStockItems();
  }
}

/// Get stock by ID use case
class GetStockByIdUseCase implements UseCase<StockItemEntity, String> {
  final StockRepository repository;

  GetStockByIdUseCase({required this.repository});

  @override
  Future<Either<Failure, StockItemEntity>> call(String itemId) async {
    if (itemId.isEmpty) {
      return const Left(ValidationFailure(message: 'Item ID is required'));
    }

    return await repository.getStockItemById(itemId);
  }
}

/// Get stock by type use case
class GetStockByTypeUseCase
    implements UseCase<List<StockItemEntity>, ItemType> {
  final StockRepository repository;

  GetStockByTypeUseCase({required this.repository});

  @override
  Future<Either<Failure, List<StockItemEntity>>> call(ItemType itemType) async {
    return await repository.getStockByType(itemType);
  }
}

/// Search stock use case
class SearchStockUseCase implements UseCase<List<StockItemEntity>, String> {
  final StockRepository repository;

  SearchStockUseCase({required this.repository});

  @override
  Future<Either<Failure, List<StockItemEntity>>> call(String query) async {
    if (query.trim().isEmpty) {
      return await repository.getAllStockItems();
    }

    return await repository.searchStock(query.trim());
  }
}
