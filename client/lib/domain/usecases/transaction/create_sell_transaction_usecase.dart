import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/constants/enums.dart';
import '../../entities/transaction_entity.dart';
import '../../repositories/transaction_repository.dart';
import '../../repositories/stock_repository.dart';
import '../../../data/models/transaction_item_model.dart';
import '../usecase.dart';

/// Create sell transaction use case
/// Creates a sales transaction and deducts stock from stock
class CreateSellTransactionUseCase
    implements UseCase<TransactionEntity, CreateSellTransactionParams> {
  final TransactionRepository transactionRepository;
  final StockRepository stockRepository;

  CreateSellTransactionUseCase({
    required this.transactionRepository,
    required this.stockRepository,
  });

  @override
  Future<Either<Failure, TransactionEntity>> call(
      CreateSellTransactionParams params) async {
    // Validate inputs
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Check stock availability and create transaction items
    final transactionItems = <TransactionItemModel>[];

    for (var item in params.items) {
      final stockResult =
          await stockRepository.getStockItemById(item.stockItemId);

      final stockItem = stockResult.fold(
        (failure) => null,
        (stock) => stock,
      );

      if (stockItem == null) {
        return Left(ValidationFailure(
            message: 'Stock item not found: ${item.stockItemName}'));
      }

      if (stockItem.currentQuantity < item.weightKg) {
        return Left(InsufficientStockFailure(
          available: stockItem.currentQuantity,
          requested: item.weightKg,
          itemName: item.stockItemName,
        ));
      }

      // Create transaction item
      final transactionItem = TransactionItemModel.create(
        transactionId: '', // Will be set when transaction is created
        stockItemId: item.stockItemId,
        itemType: item.itemType,
        variety: item.stockItemName,
        bags: item.bags,
        quantity: item.weightKg,
        pricePerKg: item.pricePerKg,
      );

      transactionItems.add(transactionItem);
    }

    // Create transaction
    final transactionResult = await transactionRepository.createSellTransaction(
      customerId: params.customerId,
      companyId: params.companyId,
      createdById: params.createdById,
      items: transactionItems,
      paidAmount: params.receivedAmount,
      paymentMethod: params.paymentMethod,
      notes: params.notes,
    );

    return transactionResult;
  }

  ValidationFailure? _validateParams(CreateSellTransactionParams params) {
    if (params.customerId.isEmpty) {
      return const ValidationFailure(message: 'Customer/Buyer is required');
    }

    if (params.items.isEmpty) {
      return const ValidationFailure(message: 'At least one item is required');
    }

    for (var item in params.items) {
      if (item.stockItemId.isEmpty) {
        return const ValidationFailure(message: 'Stock item is required');
      }
      if (item.weightKg <= 0) {
        return const ValidationFailure(
            message: 'Item weight must be greater than 0');
      }
      if (item.pricePerKg <= 0) {
        return const ValidationFailure(
            message: 'Item price must be greater than 0');
      }
    }

    if (params.receivedAmount < 0) {
      return const ValidationFailure(
          message: 'Received amount cannot be negative');
    }

    return null;
  }
}

/// Parameters for creating a sell transaction
class CreateSellTransactionParams extends Equatable {
  final String customerId;
  final String companyId;
  final String createdById;
  final List<SellItemInput> items;
  final double receivedAmount;
  final PaymentMethod paymentMethod;
  final String? notes;

  const CreateSellTransactionParams({
    required this.customerId,
    required this.companyId,
    required this.createdById,
    required this.items,
    required this.receivedAmount,
    this.paymentMethod = PaymentMethod.cash,
    this.notes,
  });

  double get totalAmount => items.fold(
        0.0,
        (sum, item) => sum + (item.weightKg * item.pricePerKg),
      );

  double get balance => totalAmount - receivedAmount;

  @override
  List<Object?> get props => [
        customerId,
        companyId,
        createdById,
        items,
        receivedAmount,
        paymentMethod,
        notes,
      ];
}

/// Input for a single sell item
class SellItemInput extends Equatable {
  final String stockItemId;
  final String stockItemName;
  final ItemType itemType;
  final double weightKg;
  final int bags;
  final double pricePerKg;

  const SellItemInput({
    required this.stockItemId,
    required this.stockItemName,
    required this.itemType,
    required this.weightKg,
    required this.bags,
    required this.pricePerKg,
  });

  double get totalPrice => weightKg * pricePerKg;

  @override
  List<Object?> get props => [
        stockItemId,
        stockItemName,
        itemType,
        weightKg,
        bags,
        pricePerKg,
      ];
}

/// Sell transaction item entity
class SellTransactionItem extends Equatable {
  final String stockItemId;
  final String stockItemName;
  final ItemType itemType;
  final double weightKg;
  final int bags;
  final double pricePerKg;
  final double totalPrice;

  const SellTransactionItem({
    required this.stockItemId,
    required this.stockItemName,
    required this.itemType,
    required this.weightKg,
    required this.bags,
    required this.pricePerKg,
    required this.totalPrice,
  });

  @override
  List<Object?> get props => [
        stockItemId,
        stockItemName,
        itemType,
        weightKg,
        bags,
        pricePerKg,
        totalPrice,
      ];
}

