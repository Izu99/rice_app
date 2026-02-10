import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/constants/enums.dart';
import '../../entities/customer_entity.dart';
import '../../repositories/customer_repository.dart';
import '../usecase.dart';

// lib/domain/usecases/customer/search_customer_usecase.dart

/// Search customer use case
/// Searches customers by name, phone, or other criteria
class SearchCustomerUseCase
    implements UseCase<List<CustomerEntity>, SearchCustomerParams> {
  final CustomerRepository repository;

  SearchCustomerUseCase({required this.repository});

  @override
  Future<Either<Failure, List<CustomerEntity>>> call(
      SearchCustomerParams params) async {
    if (params.query.trim().isEmpty) {
      // Return all customers if no search query
      return await repository.getAllCustomers();
    }

    return await repository.searchCustomers(params.query.trim());
  }
}

/// Parameters for searching customers
class SearchCustomerParams extends Equatable {
  final String query;
  final CustomerType? filterType;
  final int limit;
  final int offset;

  const SearchCustomerParams({
    this.query = '',
    this.filterType,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [query, filterType, limit, offset];
}

/// Check customer exists by phone use case
class CheckCustomerExistsUseCase implements UseCase<CustomerEntity?, String> {
  final CustomerRepository repository;

  CheckCustomerExistsUseCase({required this.repository});

  @override
  Future<Either<Failure, CustomerEntity?>> call(String phone) async {
    if (phone.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Phone number is required'));
    }

    return await repository.getCustomerByPhone(phone.trim());
  }
}

/// Get customer by ID use case
class GetCustomerByIdUseCase implements UseCase<CustomerEntity, String> {
  final CustomerRepository repository;

  GetCustomerByIdUseCase({required this.repository});

  @override
  Future<Either<Failure, CustomerEntity>> call(String id) async {
    if (id.isEmpty) {
      return const Left(ValidationFailure(message: 'Customer ID is required'));
    }

    return await repository.getCustomerById(id);
  }
}
