// lib/data/datasources/remote/transaction_remote_ds.dart

import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import '../../../core/network/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/enums.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  /// Get all transactions from server
  Future<List<TransactionModel>> getAllTransactions({
    int page = 1,
    int limit = 50,
    TransactionType? type,
  });

  /// Get transaction by ID from server
  Future<TransactionModel> getTransactionById(String id);

  /// Get transactions by customer
  Future<List<TransactionModel>> getTransactionsByCustomer(String customerId);

  /// Get transactions by date range
  Future<List<TransactionModel>> getTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    TransactionType? type,
  });

  /// Get today's transactions
  Future<List<TransactionModel>> getTodayTransactions({TransactionType? type});

  /// Create new transaction (Buy/Sell)
  Future<TransactionModel> createTransaction(TransactionModel transaction);

  /// Update transaction
  Future<TransactionModel> updateTransaction(TransactionModel transaction);

  /// Cancel transaction
  Future<bool> cancelTransaction(String id, String reason);

  /// Delete transaction
  Future<bool> deleteTransaction(String id);

  /// Sync transactions
  Future<List<TransactionModel>> syncTransactions(
      List<TransactionModel> transactions);

  /// Get transactions updated after a specific date
  Future<List<TransactionModel>> getTransactionsUpdatedAfter(DateTime dateTime);

  /// Get daily summary
  Future<Map<String, dynamic>> getDailySummary(DateTime date);

  /// Get monthly summary
  Future<Map<String, dynamic>> getMonthlySummary(int year, int month);

  /// Get dashboard summary
  Future<Map<String, dynamic>> getDashboardSummary();

  /// Get transaction statistics
  Future<Map<String, dynamic>> getTransactionStatistics({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Search transactions
  Future<List<TransactionModel>> searchTransactions(String query);

  /// Generate invoice PDF
  Future<String> generateInvoicePdf(String transactionId);

  /// Get pending transactions (not completed)
  Future<List<TransactionModel>> getPendingTransactions();

  /// Complete transaction
  Future<TransactionModel> completeTransaction(String id);

  /// Add payment to transaction
  Future<TransactionModel> addPayment({
    required String transactionId,
    required double amount,
    required PaymentMethod method,
    String? notes,
  });
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final ApiService apiService;

  TransactionRemoteDataSourceImpl({required this.apiService});

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

  @override
  Future<List<TransactionModel>> getAllTransactions({
    int page = 1,
    int limit = 50,
    TransactionType? type,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (type != null) {
        queryParams['type'] = type.name;
      }

      final either = await apiService.get(
        ApiEndpoints.transactions,
        queryParameters: queryParams,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> transactionsJson =
                response.data['transactions'] ?? response.data;
            return transactionsJson
                .map((json) =>
                    TransactionModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          throw ServerException(
            message: response.message ?? 'Failed to fetch transactions',
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
          message: 'Failed to fetch transactions: ${e.toString()}');
    }
  }

  @override
  Future<TransactionModel> getTransactionById(String id) async {
    try {
      final either = await apiService.get(
        '${ApiEndpoints.transactions}/$id',
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            // Server returns: { transaction: {...}, customer: {...}, paymentHistory: [...] }
            // Extract the transaction object
            final transactionData = response.data['transaction'] ?? response.data;
            return TransactionModel.fromJson(transactionData);
          }

          if (response.statusCode == 404) {
            throw NotFoundException(message: 'Transaction not found');
          }

          throw ServerException(
            message: response.message ?? 'Failed to fetch transaction',
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
          message: 'Failed to fetch transaction: ${e.toString()}');
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsByCustomer(
      String customerId) async {
    try {
      final either = await apiService.get(
        ApiEndpoints.transactionsByCustomer(customerId),
        queryParameters: {'customer_id': customerId},
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> transactionsJson =
                response.data['transactions'] ?? response.data;
            return transactionsJson
                .map((json) =>
                    TransactionModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          throw ServerException(
            message:
                response.message ?? 'Failed to fetch customer transactions',
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
          message: 'Failed to fetch customer transactions: ${e.toString()}');
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    TransactionType? type,
  }) async {
    try {
      final queryParams = <String, String>{
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      };

      if (type != null) {
        queryParams['type'] = type.name;
      }

      final either = await apiService.get(
        ApiEndpoints.transactions,
        queryParameters: queryParams,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> transactionsJson =
                response.data['transactions'] ?? response.data;
            return transactionsJson
                .map((json) =>
                    TransactionModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          throw ServerException(
            message: response.message ??
                'Failed to fetch transactions by date range',
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
          message:
              'Failed to fetch transactions by date range: ${e.toString()}');
    }
  }

  @override
  Future<List<TransactionModel>> getTodayTransactions(
      {TransactionType? type}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return getTransactionsByDateRange(
      startDate: startOfDay,
      endDate: endOfDay,
      type: type,
    );
  }

  @override
  Future<TransactionModel> createTransaction(
      TransactionModel transaction) async {
    try {
      final endpoint = transaction.type == TransactionType.buy
          ? ApiEndpoints.buyTransactions
          : ApiEndpoints.sellTransactions;

      debugPrint(
          '🚀 Sending POST to $endpoint with data: ${jsonEncode(transaction.toJsonForApi())}');
      final either = await apiService.post(
        endpoint,
        data: transaction.toJsonForApi(),
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          debugPrint('📥 Received response: ${jsonEncode(response.data)}');
          if (response.success && response.data != null) {
            final data = response.data;
            if (data is Map<String, dynamic> &&
                data.containsKey('transaction')) {
              return TransactionModel.fromJson(data['transaction']);
            }
            return TransactionModel.fromJson(data);
          }

          if (response.statusCode == 400) {
            throw ValidationException(
              message: response.message ?? 'Invalid transaction data',
              errors: {
                'transaction': ['Invalid data']
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
            message: response.message ?? 'Failed to create transaction',
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
          message: 'Failed to create transaction: ${e.toString()}');
    }
  }

  @override
  Future<TransactionModel> updateTransaction(
      TransactionModel transaction) async {
    try {
      final serverId = transaction.serverId ?? transaction.id;

      final either = await apiService.put(
        '${ApiEndpoints.transactions}/$serverId',
        data: transaction.toJsonForApi(),
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return TransactionModel.fromJson(response.data);
          }

          if (response.statusCode == 404) {
            throw NotFoundException(message: 'Transaction not found');
          }

          if (response.statusCode == 400) {
            throw ValidationException(
              message: response.message ??
                  'Cannot update completed or cancelled transaction',
              errors: {
                'status': ['Invalid status for update']
              },
            );
          }

          throw ServerException(
            message: response.message ?? 'Failed to update transaction',
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
      throw ServerException(
          message: 'Failed to update transaction: ${e.toString()}');
    }
  }

  @override
  Future<bool> cancelTransaction(String id, String reason) async {
    try {
      final either = await apiService.post(
        '${ApiEndpoints.transactions}/$id/cancel',
        data: {'reason': reason},
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success) {
            return true;
          }

          if (response.statusCode == 404) {
            throw NotFoundException(message: 'Transaction not found');
          }

          if (response.statusCode == 400) {
            throw ValidationException(
              message: response.message ?? 'Cannot cancel this transaction',
              errors: {
                'status': ['Invalid status for cancellation']
              },
            );
          }

          throw ServerException(
            message: response.message ?? 'Failed to cancel transaction',
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
      throw ServerException(
          message: 'Failed to cancel transaction: ${e.toString()}');
    }
  }

  @override
  Future<bool> deleteTransaction(String id) async {
    try {
      final either = await apiService.delete(
        '${ApiEndpoints.transactions}/$id',
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success) {
            return true;
          }

          if (response.statusCode == 404) {
            throw NotFoundException(message: 'Transaction not found');
          }

          throw ServerException(
            message: response.message ?? 'Failed to delete transaction',
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
          message: 'Failed to delete transaction: ${e.toString()}');
    }
  }

  @override
  Future<List<TransactionModel>> syncTransactions(
      List<TransactionModel> transactions) async {
    try {
      final either = await apiService.post(
        ApiEndpoints.transactionSync,
        data: {
          'transactions': transactions.map((t) => t.toJsonForSync()).toList(),
        },
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> syncedJson = response.data['synced'] ?? [];
            return syncedJson
                .map((json) =>
                    TransactionModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          throw SyncException(
            message: response.message ?? 'Failed to sync transactions',
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on SyncException {
      rethrow;
    } catch (e) {
      throw SyncException(
          message: 'Failed to sync transactions: ${e.toString()}');
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsUpdatedAfter(
      DateTime dateTime) async {
    try {
      final either = await apiService.get(
        ApiEndpoints.transactionUpdates,
        queryParameters: {
          'updated_after': dateTime.toIso8601String(),
        },
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> transactionsJson =
                response.data['transactions'] ?? response.data;
            return transactionsJson
                .map((json) =>
                    TransactionModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          throw ServerException(
            message: response.message ?? 'Failed to fetch transaction updates',
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
          message: 'Failed to fetch transaction updates: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    try {
      final either = await apiService.get(
        ApiEndpoints.reportsDailySummary,
        queryParameters: {
          'date': date.toIso8601String().split('T')[0],
        },
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return response.data as Map<String, dynamic>;
          }

          throw ServerException(
            message: response.message ?? 'Failed to fetch daily summary',
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
          message: 'Failed to fetch daily summary: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getMonthlySummary(int year, int month) async {
    try {
      final either = await apiService.get(
        ApiEndpoints.reportsMonthlySummary,
        queryParameters: {
          'year': year.toString(),
          'month': month.toString(),
        },
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return response.data as Map<String, dynamic>;
          }

          throw ServerException(
            message: response.message ?? 'Failed to fetch monthly summary',
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
          message: 'Failed to fetch monthly summary: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final either = await apiService.get(
        ApiEndpoints.reportsDashboard,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return response.data as Map<String, dynamic>;
          }

          throw ServerException(
            message: response.message ?? 'Failed to fetch dashboard summary',
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
          message: 'Failed to fetch dashboard summary: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getTransactionStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final either = await apiService.get(
        ApiEndpoints.reportsStatistics,
        queryParameters: queryParams,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return response.data as Map<String, dynamic>;
          }

          throw ServerException(
            message:
                response.message ?? 'Failed to fetch transaction statistics',
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
          message: 'Failed to fetch transaction statistics: ${e.toString()}');
    }
  }

  @override
  Future<List<TransactionModel>> searchTransactions(String query) async {
    try {
      final either = await apiService.get(
        ApiEndpoints.transactionSearch,
        queryParameters: {'q': query},
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> transactionsJson =
                response.data['transactions'] ?? response.data;
            return transactionsJson
                .map((json) =>
                    TransactionModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          throw ServerException(
            message: response.message ?? 'Failed to search transactions',
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
          message: 'Failed to search transactions: ${e.toString()}');
    }
  }

  @override
  Future<String> generateInvoicePdf(String transactionId) async {
    try {
      final either = await apiService.get(
        '${ApiEndpoints.transactions}/$transactionId/invoice',
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return response.data['pdf_url'] ?? response.data['url'];
          }

          if (response.statusCode == 404) {
            throw NotFoundException(message: 'Transaction not found');
          }

          throw ServerException(
            message: response.message ?? 'Failed to generate invoice PDF',
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
          message: 'Failed to generate invoice PDF: ${e.toString()}');
    }
  }

  @override
  Future<List<TransactionModel>> getPendingTransactions() async {
    try {
      final either = await apiService.get(
        ApiEndpoints.transactionsPending,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> transactionsJson =
                response.data['transactions'] ?? response.data;
            return transactionsJson
                .map((json) =>
                    TransactionModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          throw ServerException(
            message: response.message ?? 'Failed to fetch pending transactions',
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
          message: 'Failed to fetch pending transactions: ${e.toString()}');
    }
  }

  @override
  Future<TransactionModel> completeTransaction(String id) async {
    try {
      final either = await apiService.post(
        '${ApiEndpoints.transactions}/$id/complete',
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return TransactionModel.fromJson(response.data);
          }

          if (response.statusCode == 404) {
            throw NotFoundException(message: 'Transaction not found');
          }

          if (response.statusCode == 400) {
            throw ValidationException(
              message: response.message ?? 'Cannot complete this transaction',
              errors: {
                'status': ['Invalid status for completion']
              },
            );
          }

          throw ServerException(
            message: response.message ?? 'Failed to complete transaction',
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
      throw ServerException(
          message: 'Failed to complete transaction: ${e.toString()}');
    }
  }

  @override
  Future<TransactionModel> addPayment({
    required String transactionId,
    required double amount,
    required PaymentMethod method,
    String? notes,
  }) async {
    try {
      final either = await apiService.post(
        '${ApiEndpoints.transactions}/$transactionId/payments',
        data: {
          'amount': amount,
          'payment_method': method.name,
          'notes': notes,
          'paid_at': DateTime.now().toIso8601String(),
        },
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return TransactionModel.fromJson(response.data);
          }

          if (response.statusCode == 404) {
            throw NotFoundException(message: 'Transaction not found');
          }

          if (response.statusCode == 400) {
            throw ValidationException(
              message: response.message ?? 'Invalid payment amount',
              errors: {
                'amount': ['Invalid payment amount']
              },
            );
          }

          throw ServerException(
            message: response.message ?? 'Failed to add payment',
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
      throw ServerException(message: 'Failed to add payment: ${e.toString()}');
    }
  }
}
