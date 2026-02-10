// lib/domain/repositories/customer_repository.dart

import 'package:dartz/dartz.dart';
import '../../core/constants/enums.dart';
import '../../core/errors/failures.dart';
import '../../data/models/customer_model.dart';
import '../entities/customer_entity.dart';

/// Abstract repository interface for customer operations
/// Handles all customer-related data operations with offline-first support
abstract class CustomerRepository {
  /// Get all customers
  ///
  /// Returns list of [CustomerEntity] from local database
  /// Triggers background sync if online
  Future<Either<Failure, List<CustomerEntity>>> getAllCustomers();

  /// Get customer by ID
  ///
  /// Parameters:
  /// - [id]: Customer's unique identifier
  ///
  /// Returns [CustomerEntity] if found
  Future<Either<Failure, CustomerEntity>> getCustomerById(String id);

  /// Get customer by phone number
  ///
  /// Parameters:
  /// - [phone]: Customer's phone number
  ///
  /// Returns [CustomerEntity] if found, null if not exists
  Future<Either<Failure, CustomerEntity?>> getCustomerByPhone(String phone);

  /// Search customers by name, phone, or address
  ///
  /// Parameters:
  /// - [query]: Search query string
  ///
  /// Returns list of matching [CustomerEntity]
  Future<Either<Failure, List<CustomerEntity>>> searchCustomers(String query);

  /// Add a new customer
  ///
  /// Parameters:
  /// - [customer]: Customer model to add
  ///
  /// Returns the created [CustomerEntity]
  /// Syncs to server if online
  Future<Either<Failure, CustomerEntity>> addCustomer(CustomerModel customer);

  /// Update an existing customer
  ///
  /// Parameters:
  /// - [customer]: Customer model with updated data
  ///
  /// Returns the updated [CustomerEntity]
  Future<Either<Failure, CustomerEntity>> updateCustomer(
      CustomerModel customer);

  /// Delete a customer (soft delete)
  ///
  /// Parameters:
  /// - [id]: Customer's unique identifier
  ///
  /// Returns true if successful
  Future<Either<Failure, bool>> deleteCustomer(String id);

  /// Check if phone number already exists
  ///
  /// Parameters:
  /// - [phone]: Phone number to check
  /// - [excludeId]: Optional customer ID to exclude (for updates)
  ///
  /// Returns true if phone exists
  Future<Either<Failure, bool>> isPhoneExists(String phone,
      {String? excludeId});

  /// Get total customer count
  ///
  /// Returns the number of active customers
  Future<Either<Failure, int>> getCustomersCount();

  /// Update customer balance
  ///
  /// Parameters:
  /// - [customerId]: Customer's unique identifier
  /// - [amount]: Amount to add/subtract
  /// - [isCredit]: true to add, false to subtract
  ///
  /// Returns updated [CustomerEntity]
  Future<Either<Failure, CustomerEntity>> updateCustomerBalance({
    required String customerId,
    required double amount,
    required bool isCredit,
  });

  /// Get customers with outstanding balance
  ///
  /// Parameters:
  /// - [type]: 'receivable' for customers who owe us, 'payable' for those we owe
  ///
  /// Returns list of customers with outstanding balance
  Future<Either<Failure, List<CustomerEntity>>> getCustomersWithBalance({
    String? type,
  });

  /// Get customer transaction history
  ///
  /// Parameters:
  /// - [customerId]: Customer's unique identifier
  /// - [limit]: Maximum number of transactions to return
  ///
  /// Returns list of transaction summaries
  Future<Either<Failure, List<Map<String, dynamic>>>>
      getCustomerTransactionHistory({
    required String customerId,
    int limit = 50,
  });

  /// Get top customers by transaction volume
  ///
  /// Parameters:
  /// - [type]: 'buy' or 'sell' to filter by transaction type
  /// - [limit]: Maximum number of customers to return
  ///
  /// Returns list of top customers
  Future<Either<Failure, List<CustomerEntity>>> getTopCustomers({
    String? type,
    int limit = 10,
  });

  /// Get customers by type
  ///
  /// Parameters:
  /// - [type]: Customer type (farmer, trader, retailer, wholesaler)
  ///
  /// Returns list of customers of the specified type
  Future<Either<Failure, List<CustomerEntity>>> getCustomersByType(
    CustomerType type,
  );
}
