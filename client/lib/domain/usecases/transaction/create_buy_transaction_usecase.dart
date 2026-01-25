import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/constants/enums.dart';
import '../../entities/transaction_entity.dart';
import '../../repositories/transaction_repository.dart';
import '../../repositories/stock_repository.dart';
import '../../../data/models/transaction_item_model.dart';
import '../usecase.dart';

/// Create buy transaction use case
/// Creates a purchase transaction and adds stock to stock
class CreateBuyTransactionUseCase
    implements UseCase<TransactionEntity, CreateBuyTransactionParams> {
  final TransactionRepository transactionRepository;
  final StockRepository stockRepository;

  CreateBuyTransactionUseCase({
    required this.transactionRepository,
    required this.stockRepository,
  });

  @override
  Future<Either<Failure, TransactionEntity>> call(
      CreateBuyTransactionParams params) async {
    // Validate inputs
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Create transaction items
    final transactionItems = await Future.wait(
      params.items.map((item) async {
        // Get or create stock item
        final stockResult = await stockRepository.getOrCreateStockItem(
          type: item.itemType,
          variety: item.name,
          companyId: params.companyId,
        );

        return stockResult.fold(
          (failure) => null,
          (stockItem) => TransactionItemModel.create(
            transactionId: '', // Will be set when transaction is created
            stockItemId: stockItem.id,
            itemType: item.itemType,
            variety: item.name,
            bags: item.bags,
            quantity: item.weightKg,
            pricePerKg: item.pricePerKg,
          ),
        );
      }),
    );

    if (transactionItems.any((item) => item == null)) {
      return const Left(
          ValidationFailure(message: 'Failed to create stock items'));
    }

    // Create transaction
    final transactionResult = await transactionRepository.createBuyTransaction(
      customerId: params.customerId,
      companyId: params.companyId,
      createdById: params.createdById,
      items: transactionItems.whereType<TransactionItemModel>().toList(),
      paidAmount: params.paidAmount,
      paymentMethod: params.paymentMethod,
      notes: params.notes,
    );

    return transactionResult;
  }

  ValidationFailure? _validateParams(CreateBuyTransactionParams params) {
    if (params.customerId.isEmpty) {
      return const ValidationFailure(message: 'Customer is required');
    }

    if (params.items.isEmpty) {
      return const ValidationFailure(message: 'At least one item is required');
    }

    for (var item in params.items) {
      if (item.name.trim().isEmpty) {
        return const ValidationFailure(message: 'Item name is required');
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

    if (params.paidAmount < 0) {
      return const ValidationFailure(message: 'Paid amount cannot be negative');
    }

    return null;
  }
}

/// Parameters for creating a buy transaction
class CreateBuyTransactionParams extends Equatable {
  final String customerId;
  final String companyId;
  final String createdById;
  final List<BuyItemInput> items;
  final double paidAmount;
  final PaymentMethod paymentMethod;
  final String? notes;

  const CreateBuyTransactionParams({
    required this.customerId,
    required this.companyId,
    required this.createdById,
    required this.items,
    required this.paidAmount,
    this.paymentMethod = PaymentMethod.cash,
    this.notes,
  });

  double get totalAmount => items.fold(
        0.0,
        (sum, item) => sum + (item.weightKg * item.pricePerKg),
      );

  double get balance => totalAmount - paidAmount;

  @override
  List<Object?> get props => [
        customerId,
        companyId,
        createdById,
        items,
        paidAmount,
        paymentMethod,
        notes,
      ];
}

/// Input for a single buy item
class BuyItemInput extends Equatable {
  final String name;
  final ItemType itemType;
  final double weightKg;
  final int bags;
  final double pricePerKg;

  const BuyItemInput({
    required this.name,
    required this.itemType,
    required this.weightKg,
    required this.bags,
    required this.pricePerKg,
  });

  double get totalPrice => weightKg * pricePerKg;

  @override
  List<Object?> get props => [name, itemType, weightKg, bags, pricePerKg];
}

/// Buy transaction item entity
class BuyTransactionItem extends Equatable {
  final String name;
  final ItemType itemType;
  final double weightKg;
  final int bags;
  final double pricePerKg;
  final double totalPrice;

  const BuyTransactionItem({
    required this.name,
    required this.itemType,
    required this.weightKg,
    required this.bags,
    required this.pricePerKg,
    required this.totalPrice,
  });

  @override
  List<Object?> get props => [
        name,
        itemType,
        weightKg,
        bags,
        pricePerKg,
        totalPrice,
      ];
}

