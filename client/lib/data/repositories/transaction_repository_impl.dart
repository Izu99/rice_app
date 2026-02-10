// lib/data/repositories/transaction_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../core/constants/enums.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/remote/transaction_remote_ds.dart';
import '../models/transaction_model.dart';
import '../models/transaction_item_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TransactionRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  String get tableName =>
      'transactions'; // Deprecated but keeping for interface

  @override
  Future<Either<Failure, List<TransactionEntity>>> getAllTransactions() async {
    try {
      final transactions = await remoteDataSource.getAllTransactions();
      return Right(transactions.map((t) => t.toEntity()).toList());
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> getTransactionById(
      String id) async {
    try {
      final transaction = await remoteDataSource.getTransactionById(id);
      return Right(transaction.toEntity());
    } catch (e) {
      if (e is NotFoundException) {
        return const Left(NotFoundFailure(message: 'Transaction not found'));
      }
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionModel>> getFullTransactionById(
      String id) async {
    try {
      final transaction = await remoteDataSource.getTransactionById(id);
      return Right(transaction);
    } catch (e) {
      if (e is NotFoundException) {
        return const Left(NotFoundFailure(message: 'Transaction not found'));
      }
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactionsByType(
    TransactionType type,
  ) async {
    try {
      final transactions =
          await remoteDataSource.getAllTransactions(type: type);
      return Right(transactions.map((t) => t.toEntity()).toList());
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactionsByCustomer(
    String customerId,
  ) async {
    try {
      final transactions =
          await remoteDataSource.getTransactionsByCustomer(customerId);
      return Right(transactions.map((t) => t.toEntity()).toList());
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    TransactionType? type,
  }) async {
    try {
      final transactions = await remoteDataSource.getTransactionsByDateRange(
        startDate: startDate,
        endDate: endDate,
        type: type,
      );
      return Right(transactions.map((t) => t.toEntity()).toList());
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTodayTransactions({
    TransactionType? type,
  }) async {
    try {
      final transactions =
          await remoteDataSource.getTodayTransactions(type: type);
      return Right(transactions.map((t) => t.toEntity()).toList());
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> createBuyTransaction({
    required String customerId,
    required String companyId,
    required String createdById,
    required List<TransactionItemModel> items,
    double discount = 0,
    double paidAmount = 0,
    PaymentMethod? paymentMethod,
    String? notes,
    String? vehicleNumber,
    String? transactionNumber,
  }) async {
    try {
      // Use provided transactionNumber or let server generate it (empty string)
      final transaction = TransactionModel.createBuy(
        transactionNumber: transactionNumber ?? "",
        customerId: customerId,
        customerLocalId: null,
        customerName: "", // Server usually populates names from ID
        companyId: companyId,
        createdBy: createdById,
        items: items,
        discount: discount,
        notes: notes,
      );

      final created = await remoteDataSource.createTransaction(transaction);

      // We assume server handles stock updates and balance updates transactionally.

      return Right(created.toEntity());
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
  Future<Either<Failure, TransactionEntity>> createSellTransaction({
    required String customerId,
    required String companyId,
    required String createdById,
    required List<TransactionItemModel> items,
    double discount = 0,
    double paidAmount = 0,
    PaymentMethod? paymentMethod,
    String? notes,
    String? vehicleNumber,
  }) async {
    try {
      final transaction = TransactionModel.createSell(
        transactionNumber: "",
        customerId: customerId,
        customerLocalId: null,
        customerName: "",
        companyId: companyId,
        createdBy: createdById,
        items: items,
        discount: discount,
        notes: notes,
      );

      final created = await remoteDataSource.createTransaction(transaction);
      return Right(created.toEntity());
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
  Future<Either<Failure, TransactionEntity>> updateTransaction(
    TransactionModel transaction,
  ) async {
    try {
      final updated = await remoteDataSource.updateTransaction(transaction);
      return Right(updated.toEntity());
    } catch (e) {
      if (e is ValidationException) {
        return Left(ValidationFailure(message: e.message));
      } else if (e is NotFoundException) {
        return const Left(NotFoundFailure(message: 'Transaction not found'));
      } else if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> cancelTransaction(
      String id, String reason) async {
    try {
      final result = await remoteDataSource.cancelTransaction(id, reason);
      return Right(result);
    } catch (e) {
      if (e is ValidationException) {
        return Left(ValidationFailure(message: e.message));
      } else if (e is NotFoundException) {
        return const Left(NotFoundFailure(message: 'Transaction not found'));
      } else if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteTransaction(String id) async {
    try {
      final result = await remoteDataSource.deleteTransaction(id);
      return Right(result);
    } catch (e) {
      if (e is NotFoundException) {
        return const Left(NotFoundFailure(message: 'Transaction not found'));
      } else if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> addPayment({
    required String transactionId,
    required double amount,
    required PaymentMethod method,
    String? notes,
  }) async {
    try {
      final result = await remoteDataSource.addPayment(
        transactionId: transactionId,
        amount: amount,
        method: method,
        notes: notes,
      );
      return Right(result.toEntity());
    } catch (e) {
      if (e is ValidationException) {
        return Left(ValidationFailure(message: e.message));
      } else if (e is NotFoundException) {
        return const Left(NotFoundFailure(message: 'Transaction not found'));
      } else if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDailySummary(
      DateTime date) async {
    try {
      final result = await remoteDataSource.getDailySummary(date);
      return Right(result);
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getMonthlySummary(
      int year, int month) async {
    try {
      final result = await remoteDataSource.getMonthlySummary(year, month);
      return Right(result);
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, double>>> getTotalsByTypeForDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Requires specific endpoint or client side calc
    try {
      // Fallback to client side calc if no endpoint
      final transactions = await remoteDataSource.getTransactionsByDateRange(
          startDate: startDate, endDate: endDate);
      final Map<String, double> totals = {};
      for (var t in transactions) {
        totals[t.type.name] = (totals[t.type.name] ?? 0) + t.totalAmount;
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
  Future<Either<Failure, List<TransactionEntity>>> searchTransactions(
      String query) async {
    try {
      final result = await remoteDataSource.searchTransactions(query);
      return Right(result.map((t) => t.toEntity()).toList());
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getTransactionsCount(
      {TransactionType? type}) async {
    return const Right(0); // Placeholder
  }

  @override
  Future<Either<Failure, String>> generateTransactionNumber(
      TransactionType type) async {
    // Return placeholder
    return const Right("AUTO-GEN");
  }

  @override
  Future<Either<Failure, void>> syncTransactions() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<TransactionModel>>>
      getUnsyncedTransactions() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>>
      getPendingTransactions() async {
    try {
      final result = await remoteDataSource.getPendingTransactions();
      return Right(result.map((t) => t.toEntity()).toList());
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>>
      getTransactionsWithDue() async {
    try {
      // Filter locally for now
      final all = await remoteDataSource.getAllTransactions();
      final withDue = all.where((t) => t.dueAmount > 0).toList();
      return Right(withDue.map((t) => t.toEntity()).toList());
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> completeTransaction(
      String id) async {
    try {
      final result = await remoteDataSource.completeTransaction(id);
      return Right(result.toEntity());
    } catch (e) {
      if (e is ValidationException) {
        return Left(ValidationFailure(message: e.message));
      } else if (e is NotFoundException) {
        return const Left(NotFoundFailure(message: 'Transaction not found'));
      } else if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getRecentTransactions({
    int limit = 10,
    TransactionType? type,
  }) async {
    try {
      final transactions =
          await remoteDataSource.getAllTransactions(limit: limit, type: type);
      return Right(transactions.map((t) => t.toEntity()).toList());
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TransactionItemModel>>> getTransactionItems(
      String transactionId) async {
    try {
      final transaction =
          await remoteDataSource.getTransactionById(transactionId);
      return Right(transaction.items);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> duplicateTransaction(
      String transactionId) async {
    try {
      final transaction =
          await remoteDataSource.getTransactionById(transactionId);
      // Create new model with cleared ID and dates
      final newTransaction = transaction.copyWith(
        id: '',
        transactionDate: DateTime.now(),
        transactionNumber: '', // Should regenerate
        status: TransactionStatus.pending,
      );
      // In real scenario, we might want to return this "draft" without saving,
      // or save it as draft. Interface implies returning an Entity.
      // Let's assume we return the draft entity without saving to remote yet,
      // or we save it. For "duplicate", saving is safer.
      final created = await remoteDataSource.createTransaction(newTransaction);
      return Right(created.toEntity());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> savePendingBuyItems(
      String customerId, List<Map<String, dynamic>> items) async {
    // Local storage stub
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPendingBuyItems(
      String customerId) async {
    // Local storage stub
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> clearPendingBuyItems(String customerId) async {
    // Local storage stub
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveSessionBatches(
      String customerId, List<Map<String, dynamic>> transactions) async {
    // Local storage stub
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getSessionBatches(
      String customerId) async {
    // Local storage stub
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> clearSessionBatches(String customerId) async {
    // Local storage stub
    return const Right(null);
  }
}
