import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/constants/enums.dart';
import '../../entities/customer_entity.dart';
import '../../repositories/customer_repository.dart';
import '../usecase.dart';

// lib/domain/usecases/customer/get_customers_usecase.dart

/// Get all customers use case
/// Returns list of all customers with optional filtering
class GetCustomersUseCase
    implements UseCase<List<CustomerEntity>, GetCustomersParams> {
  final CustomerRepository repository;

  GetCustomersUseCase({required this.repository});

  @override
  Future<Either<Failure, List<CustomerEntity>>> call(
      GetCustomersParams params) async {
    // For now, just get all customers - filtering can be added later
    return await repository.getAllCustomers();
  }
}

/// Parameters for getting customers
class GetCustomersParams extends Equatable {
  final CustomerType? customerType;
  final CustomerSortBy sortBy;
  final SortOrder sortOrder;
  final int limit;
  final int offset;

  const GetCustomersParams({
    this.customerType,
    this.sortBy = CustomerSortBy.name,
    this.sortOrder = SortOrder.ascending,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [customerType, sortBy, sortOrder, limit, offset];
}

/// Customer sort options
enum CustomerSortBy {
  name,
  phone,
  createdAt,
  totalTransactions,
  lastTransaction,
}

/// Sort order
enum SortOrder {
  ascending,
  descending,
}

/// Get customer transaction history use case
class GetCustomerTransactionsUseCase
    implements
        UseCase<List<Map<String, dynamic>>, GetCustomerTransactionsParams> {
  final CustomerRepository repository;

  GetCustomerTransactionsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(
      GetCustomerTransactionsParams params) async {
    if (params.customerId.isEmpty) {
      return const Left(ValidationFailure(message: 'Customer ID is required'));
    }

    return await repository.getCustomerTransactionHistory(
      customerId: params.customerId,
      limit: 50, // Default limit
    );
  }
}

/// Parameters for getting customer transactions
class GetCustomerTransactionsParams extends Equatable {
  final String customerId;
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionType? transactionType;

  const GetCustomerTransactionsParams({
    required this.customerId,
    this.startDate,
    this.endDate,
    this.transactionType,
  });

  @override
  List<Object?> get props => [customerId, startDate, endDate, transactionType];
}

/// Customer transaction history entity
class CustomerTransactionHistory extends Equatable {
  final CustomerEntity customer;
  final List<dynamic> transactions;
  final double totalBuyAmount;
  final double totalSellAmount;
  final double balance;

  const CustomerTransactionHistory({
    required this.customer,
    required this.transactions,
    required this.totalBuyAmount,
    required this.totalSellAmount,
    required this.balance,
  });

  @override
  List<Object?> get props => [
        customer,
        transactions,
        totalBuyAmount,
        totalSellAmount,
        balance,
      ];
}

/// Delete customer use case
class DeleteCustomerUseCase implements UseCase<bool, String> {
  final CustomerRepository repository;

  DeleteCustomerUseCase({required this.repository});

  @override
  Future<Either<Failure, bool>> call(String customerId) async {
    if (customerId.isEmpty) {
      return const Left(ValidationFailure(message: 'Customer ID is required'));
    }

    // For now, just attempt to delete - validation can be added later
    return await repository.deleteCustomer(customerId);
  }
}

