// lib/domain/repositories/transaction_repository.dart

import 'package:dartz/dartz.dart';
import '../../core/constants/enums.dart';
import '../../core/errors/failures.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/transaction_item_model.dart';
import '../entities/transaction_entity.dart';

/// Abstract repository interface for transaction operations
/// Handles all buy/sell transaction operations with offline-first support
abstract class TransactionRepository {
  /// Get all transactions
  ///
  /// Returns list of [TransactionEntity] from local database
  /// Triggers background sync if online
  Future<Either<Failure, List<TransactionEntity>>> getAllTransactions();

  /// Get transaction by ID
  ///
  /// Parameters:
  /// - [id]: Transaction's unique identifier
  ///
  /// Returns [TransactionEntity] if found
  Future<Either<Failure, TransactionEntity>> getTransactionById(String id);

  /// Get full transaction details including items and metadata
  Future<Either<Failure, TransactionModel>> getFullTransactionById(String id);

  /// Get transactions by type
  ///
  /// Parameters:
  /// - [type]: Transaction type (buy or sell)
  ///
  /// Returns list of transactions of the specified type
  Future<Either<Failure, List<TransactionEntity>>> getTransactionsByType(
    TransactionType type,
  );

  /// Get transactions by customer
  ///
  /// Parameters:
  /// - [customerId]: Customer's unique identifier
  ///
  /// Returns list of transactions for the specified customer
  Future<Either<Failure, List<TransactionEntity>>> getTransactionsByCustomer(
    String customerId,
  );

  /// Get transactions by date range
  ///
  /// Parameters:
  /// - [startDate]: Start of date range
  /// - [endDate]: End of date range
  /// - [type]: Optional filter by transaction type
  ///
  /// Returns list of transactions within the date range
  Future<Either<Failure, List<TransactionEntity>>> getTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    TransactionType? type,
  });

  /// Get today's transactions
  ///
  /// Parameters:
  /// - [type]: Optional filter by transaction type
  ///
  /// Returns list of today's transactions
  Future<Either<Failure, List<TransactionEntity>>> getTodayTransactions({
    TransactionType? type,
  });

  /// Create a buy transaction (purchasing from farmer/supplier)
  ///
  /// Parameters:
  /// - [customerId]: Seller/farmer's ID
  /// - [companyId]: Company ID
  /// - [createdById]: User creating the transaction
  /// - [items]: List of items being purchased
  /// - [discount]: Discount amount
  /// - [paidAmount]: Amount paid
  /// - [paymentMethod]: Method of payment
  /// - [notes]: Optional notes
  /// - [vehicleNumber]: Optional vehicle number
  /// - [transactionNumber]: Optional custom transaction number (to prevent server-side ID collisions)
  ///
  /// Returns the created [TransactionEntity]
  /// Also updates stock (adds stock)
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
  });

  /// Create a sell transaction (selling to buyer)
  ///
  /// Parameters:
  /// - [customerId]: Buyer's ID
  /// - [companyId]: Company ID
  /// - [createdById]: User creating the transaction
  /// - [items]: List of items being sold
  /// - [discount]: Discount amount
  /// - [paidAmount]: Amount paid
  /// - [paymentMethod]: Method of payment
  /// - [notes]: Optional notes
  /// - [vehicleNumber]: Optional vehicle number
  ///
  /// Returns the created [TransactionEntity]
  /// Also updates stock (deducts stock)
  /// Fails if insufficient stock
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
  });

  /// Update an existing transaction
  ///
  /// Parameters:
  /// - [transaction]: Transaction model with updated data
  ///
  /// Returns the updated [TransactionEntity]
  /// Only pending transactions can be updated
  Future<Either<Failure, TransactionEntity>> updateTransaction(
    TransactionModel transaction,
  );

  /// Cancel a transaction
  ///
  /// Parameters:
  /// - [id]: Transaction's unique identifier
  /// - [reason]: Reason for cancellation
  ///
  /// Returns true if successful
  /// Also reverses stock changes
  Future<Either<Failure, bool>> cancelTransaction(String id, String reason);

  /// Delete a transaction (soft delete)
  ///
  /// Parameters:
  /// - [id]: Transaction's unique identifier
  ///
  /// Returns true if successful
  Future<Either<Failure, bool>> deleteTransaction(String id);

  /// Add payment to a transaction
  ///
  /// Parameters:
  /// - [transactionId]: Transaction's unique identifier
  /// - [amount]: Payment amount
  /// - [method]: Payment method
  /// - [notes]: Optional payment notes
  ///
  /// Returns the updated [TransactionEntity]
  Future<Either<Failure, TransactionEntity>> addPayment({
    required String transactionId,
    required double amount,
    required PaymentMethod method,
    String? notes,
  });

  /// Get daily summary
  ///
  /// Parameters:
  /// - [date]: Date to get summary for
  ///
  /// Returns summary with totals, counts, and profit
  Future<Either<Failure, Map<String, dynamic>>> getDailySummary(DateTime date);

  /// Get monthly summary
  ///
  /// Parameters:
  /// - [year]: Year
  /// - [month]: Month (1-12)
  ///
  /// Returns summary with totals, counts, profit, and daily breakdown
  Future<Either<Failure, Map<String, dynamic>>> getMonthlySummary(
    int year,
    int month,
  );

  /// Get totals by type for date range
  ///
  /// Parameters:
  /// - [startDate]: Start of date range
  /// - [endDate]: End of date range
  ///
  /// Returns map with 'buy' and 'sell' totals
  Future<Either<Failure, Map<String, double>>> getTotalsByTypeForDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Search transactions
  ///
  /// Parameters:
  /// - [query]: Search query (transaction number, notes)
  ///
  /// Returns list of matching transactions
  Future<Either<Failure, List<TransactionEntity>>> searchTransactions(
    String query,
  );

  /// Get transactions count
  ///
  /// Parameters:
  /// - [type]: Optional filter by transaction type
  ///
  /// Returns count of transactions
  Future<Either<Failure, int>> getTransactionsCount({TransactionType? type});

  /// Generate transaction number
  ///
  /// Parameters:
  /// - [type]: Transaction type
  ///
  /// Returns unique transaction number
  Future<Either<Failure, String>> generateTransactionNumber(
    TransactionType type,
  );

  /// Sync transactions with server
  ///
  /// Uploads unsynced transactions and downloads updates from server
  Future<Either<Failure, void>> syncTransactions();

  /// Get unsynced transactions
  ///
  /// Returns list of transactions that haven't been synced to server
  Future<Either<Failure, List<TransactionModel>>> getUnsyncedTransactions();

  /// Get pending transactions
  ///
  /// Returns list of transactions with pending status
  Future<Either<Failure, List<TransactionEntity>>> getPendingTransactions();

  /// Get transactions with outstanding payments
  ///
  /// Returns list of transactions with due amount > 0
  Future<Either<Failure, List<TransactionEntity>>> getTransactionsWithDue();

  /// Complete a transaction
  ///
  /// Parameters:
  /// - [id]: Transaction's unique identifier
  ///
  /// Returns the updated [TransactionEntity]
  Future<Either<Failure, TransactionEntity>> completeTransaction(String id);

  /// Get recent transactions
  ///
  /// Parameters:
  /// - [limit]: Maximum number of transactions to return
  /// - [type]: Optional filter by transaction type
  ///
  /// Returns list of recent transactions
  Future<Either<Failure, List<TransactionEntity>>> getRecentTransactions({
    int limit = 10,
    TransactionType? type,
  });

  /// Get transaction items
  ///
  /// Parameters:
  /// - [transactionId]: Transaction's unique identifier
  ///
  /// Returns list of transaction items
  Future<Either<Failure, List<TransactionItemModel>>> getTransactionItems(
    String transactionId,
  );

  /// Duplicate transaction
  ///
  /// Creates a new transaction based on an existing one
  ///
  /// Parameters:
  /// - [transactionId]: Source transaction ID
  ///
  /// Returns the new [TransactionEntity]
  Future<Either<Failure, TransactionEntity>> duplicateTransaction(
    String transactionId,
  );

  /// Save pending buy items
  Future<Either<Failure, void>> savePendingBuyItems(
    String customerId,
    List<Map<String, dynamic>> items,
  );

  /// Get pending buy items
  Future<Either<Failure, List<Map<String, dynamic>>>> getPendingBuyItems(
    String customerId,
  );

  /// Clear pending buy items
  Future<Either<Failure, void>> clearPendingBuyItems(String customerId);

  /// Save session batches (Table 2)
  Future<Either<Failure, void>> saveSessionBatches(
    String customerId,
    List<Map<String, dynamic>> transactions,
  );

  /// Get session batches (Table 2)
  Future<Either<Failure, List<Map<String, dynamic>>>> getSessionBatches(
    String customerId,
  );

  /// Clear session batches (Table 2)
  Future<Either<Failure, void>> clearSessionBatches(String customerId);
}
