import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../entities/stock_item_entity.dart';
import '../../repositories/stock_repository.dart';
import '../usecase.dart';

// lib/domain/usecases/stock/deduct_stock_usecase.dart

/// Deduct stock use case
/// Reduces stock quantity from an existing stock item
class DeductStockUseCase
    implements UseCase<StockItemEntity, DeductStockParams> {
  final StockRepository repository;

  DeductStockUseCase({required this.repository});

  @override
  Future<Either<Failure, StockItemEntity>> call(
      DeductStockParams params) async {
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

    // Deduct stock using the repository method
    return await repository.deductStock(
      itemId: params.itemId,
      quantity: params.quantity,
      bags: params.bags,
      transactionId: params.transactionId,
    );
  }
}

/// Parameters for deducting stock
class DeductStockParams extends Equatable {
  final String itemId;
  final double quantity;
  final int bags;
  final String transactionId;

  const DeductStockParams({
    required this.itemId,
    required this.quantity,
    required this.bags,
    required this.transactionId,
  });

  @override
  List<Object?> get props => [itemId, quantity, bags, transactionId];
}
