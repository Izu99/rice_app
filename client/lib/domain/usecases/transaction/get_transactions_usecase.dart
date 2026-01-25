import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/constants/enums.dart';
import '../../entities/transaction_entity.dart';
import '../../repositories/transaction_repository.dart';
import '../usecase.dart';

/// Get all transactions use case
/// Returns all transactions
class GetAllTransactionsUseCase
    implements UseCase<List<TransactionEntity>, void> {
  final TransactionRepository repository;

  GetAllTransactionsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<TransactionEntity>>> call(void params) async {
    return await repository.getAllTransactions();
  }
}

/// Parameters for getting transactions
class GetTransactionsParams extends Equatable {
  final TransactionType? transactionType;
  final TransactionStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? customerId;
  final TransactionSortBy sortBy;
  final SortOrder sortOrder;
  final int limit;
  final int offset;

  const GetTransactionsParams({
    this.transactionType,
    this.status,
    this.startDate,
    this.endDate,
    this.customerId,
    this.sortBy = TransactionSortBy.createdAt,
    this.sortOrder = SortOrder.descending,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [
        transactionType,
        status,
        startDate,
        endDate,
        customerId,
        sortBy,
        sortOrder,
        limit,
        offset,
      ];
}

/// Transaction sort options
enum TransactionSortBy {
  createdAt,
  totalAmount,
  customerName,
  status,
}

/// Sort order
enum SortOrder {
  ascending,
  descending,
}

/// Get transaction by ID use case
class GetTransactionByIdUseCase implements UseCase<TransactionEntity, String> {
  final TransactionRepository repository;

  GetTransactionByIdUseCase({required this.repository});

  @override
  Future<Either<Failure, TransactionEntity>> call(String transactionId) async {
    if (transactionId.isEmpty) {
      return const Left(
          ValidationFailure(message: 'Transaction ID is required'));
    }

    return await repository.getTransactionById(transactionId);
  }
}

/// Get today's transactions use case
class GetTodayTransactionsUseCase
    implements UseCase<List<TransactionEntity>, void> {
  final TransactionRepository repository;

  GetTodayTransactionsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<TransactionEntity>>> call(void params) async {
    return await repository.getTodayTransactions();
  }
}

/// Get recent transactions use case
class GetRecentTransactionsUseCase
    implements UseCase<List<TransactionEntity>, int> {
  final TransactionRepository repository;

  GetRecentTransactionsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<TransactionEntity>>> call(int limit) async {
    return await repository.getRecentTransactions(limit: limit);
  }
}

/// Get transactions by type use case
class GetTransactionsByTypeUseCase
    implements UseCase<List<TransactionEntity>, TransactionType> {
  final TransactionRepository repository;

  GetTransactionsByTypeUseCase({required this.repository});

  @override
  Future<Either<Failure, List<TransactionEntity>>> call(
      TransactionType type) async {
    return await repository.getTransactionsByType(type);
  }
}

/// Get transactions by customer use case
class GetTransactionsByCustomerUseCase
    implements UseCase<List<TransactionEntity>, String> {
  final TransactionRepository repository;

  GetTransactionsByCustomerUseCase({required this.repository});

  @override
  Future<Either<Failure, List<TransactionEntity>>> call(
      String customerId) async {
    if (customerId.isEmpty) {
      return const Left(ValidationFailure(message: 'Customer ID is required'));
    }
    return await repository.getTransactionsByCustomer(customerId);
  }
}

/// Parameters for getting transactions summary
class GetTransactionsSummaryParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;

  const GetTransactionsSummaryParams({
    required this.startDate,
    required this.endDate,
  });

  /// Today's summary
  factory GetTransactionsSummaryParams.today() {
    final now = DateTime.now();
    return GetTransactionsSummaryParams(
      startDate: DateTime(now.year, now.month, now.day),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  /// This week's summary
  factory GetTransactionsSummaryParams.thisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return GetTransactionsSummaryParams(
      startDate: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  /// This month's summary
  factory GetTransactionsSummaryParams.thisMonth() {
    final now = DateTime.now();
    return GetTransactionsSummaryParams(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Transactions summary entity
class TransactionsSummary extends Equatable {
  final int totalBuyTransactions;
  final int totalSellTransactions;
  final double totalBuyAmount;
  final double totalSellAmount;
  final double totalBuyPaid;
  final double totalSellReceived;
  final double buyOutstanding;
  final double sellOutstanding;
  final double profit;
  final Map<String, double> dailyBuyAmounts;
  final Map<String, double> dailySellAmounts;

  const TransactionsSummary({
    required this.totalBuyTransactions,
    required this.totalSellTransactions,
    required this.totalBuyAmount,
    required this.totalSellAmount,
    required this.totalBuyPaid,
    required this.totalSellReceived,
    required this.buyOutstanding,
    required this.sellOutstanding,
    required this.profit,
    this.dailyBuyAmounts = const {},
    this.dailySellAmounts = const {},
  });

  int get totalTransactions => totalBuyTransactions + totalSellTransactions;
  double get totalAmount => totalBuyAmount + totalSellAmount;
  double get totalOutstanding => buyOutstanding + sellOutstanding;

  @override
  List<Object?> get props => [
        totalBuyTransactions,
        totalSellTransactions,
        totalBuyAmount,
        totalSellAmount,
        totalBuyPaid,
        totalSellReceived,
        buyOutstanding,
        sellOutstanding,
        profit,
        dailyBuyAmounts,
        dailySellAmounts,
      ];
}

/// Search transactions use case
class SearchTransactionsUseCase
    implements UseCase<List<TransactionEntity>, String> {
  final TransactionRepository repository;

  SearchTransactionsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<TransactionEntity>>> call(String query) async {
    if (query.isEmpty) {
      return const Left(ValidationFailure(message: 'Search query is required'));
    }
    return await repository.searchTransactions(query);
  }
}

/// Get pending transactions use case
class GetPendingTransactionsUseCase
    implements UseCase<List<TransactionEntity>, void> {
  final TransactionRepository repository;

  GetPendingTransactionsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<TransactionEntity>>> call(void params) async {
    return await repository.getPendingTransactions();
  }
}

/// Add payment to transaction use case
class AddTransactionPaymentUseCase
    implements UseCase<TransactionEntity, AddPaymentParams> {
  final TransactionRepository repository;

  AddTransactionPaymentUseCase({required this.repository});

  @override
  Future<Either<Failure, TransactionEntity>> call(
      AddPaymentParams params) async {
    if (params.transactionId.isEmpty) {
      return const Left(
          ValidationFailure(message: 'Transaction ID is required'));
    }

    if (params.amount <= 0) {
      return const Left(
          ValidationFailure(message: 'Amount must be greater than 0'));
    }

    return await repository.addPayment(
      transactionId: params.transactionId,
      amount: params.amount,
      method: params.paymentMethod,
      notes: params.notes,
    );
  }
}

/// Parameters for adding payment to transaction
class AddPaymentParams extends Equatable {
  final String transactionId;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? notes;

  const AddPaymentParams({
    required this.transactionId,
    required this.amount,
    this.paymentMethod = PaymentMethod.cash,
    this.notes,
  });

  @override
  List<Object?> get props => [transactionId, amount, paymentMethod, notes];
}

