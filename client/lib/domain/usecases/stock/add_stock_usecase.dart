import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../entities/stock_item_entity.dart';
import '../../repositories/stock_repository.dart';
import '../usecase.dart';

// lib/domain/usecases/stock/add_stock_usecase.dart

/// Add stock use case
/// Adds stock quantity to an existing stock item
class AddStockUseCase implements UseCase<StockItemEntity, AddStockParams> {
  final StockRepository repository;

  AddStockUseCase({required this.repository});

  @override
  Future<Either<Failure, StockItemEntity>> call(AddStockParams params) async {
    // Validate inputs
    if (params.itemId.isEmpty) {
      return const Left(ValidationFailure(message: 'Item ID is required'));
    }

    if (params.quantity <= 0) {
      return const Left(
          ValidationFailure(message: 'Quantity must be greater than 0'));
    }

    if (params.bags < 0) {
      return const Left(ValidationFailure(message: 'Bags cannot be negative'));
    }

    if (params.transactionId.isEmpty) {
      return const Left(
          ValidationFailure(message: 'Transaction ID is required'));
    }

    // Add stock using the repository method
    return await repository.addStock(
      itemId: params.itemId,
      quantity: params.quantity,
      bags: params.bags,
      transactionId: params.transactionId,
    );
  }
}

/// Parameters for adding stock
class AddStockParams extends Equatable {
  final String itemId;
  final double quantity;
  final int bags;
  final String transactionId;

  const AddStockParams({
    required this.itemId,
    required this.quantity,
    required this.bags,
    required this.transactionId,
  });

  @override
  List<Object?> get props => [itemId, quantity, bags, transactionId];
}

/// Adjust stock use case
/// For manual stock adjustments (corrections, damage, etc.)
class AdjustStockUseCase
    implements UseCase<StockItemEntity, AdjustStockParams> {
  final StockRepository repository;

  AdjustStockUseCase({required this.repository});

  @override
  Future<Either<Failure, StockItemEntity>> call(
      AdjustStockParams params) async {
    if (params.itemId.isEmpty) {
      return const Left(ValidationFailure(message: 'Item ID is required'));
    }

    return await repository.adjustStock(
      itemId: params.itemId,
      newQuantity: params.newQuantity,
      newBags: params.newBags,
      reason: params.reason,
    );
  }
}

/// Parameters for adjusting stock
class AdjustStockParams extends Equatable {
  final String itemId;
  final double newQuantity;
  final int newBags;
  final String reason;

  const AdjustStockParams({
    required this.itemId,
    required this.newQuantity,
    required this.newBags,
    required this.reason,
  });

  @override
  List<Object?> get props => [itemId, newQuantity, newBags, reason];
}
