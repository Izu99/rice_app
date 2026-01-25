import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../data/models/customer_model.dart';
import '../../entities/customer_entity.dart';
import '../../repositories/customer_repository.dart';
import '../usecase.dart';

// lib/domain/usecases/customer/add_customer_usecase.dart

/// Add customer use case
/// Creates a new customer (buyer/seller)
class AddCustomerUseCase implements UseCase<CustomerEntity, AddCustomerParams> {
  final CustomerRepository repository;

  AddCustomerUseCase({required this.repository});

  @override
  Future<Either<Failure, CustomerEntity>> call(AddCustomerParams params) async {
    // Validate inputs
    if (params.name.trim().isEmpty) {
      return const Left(
          ValidationFailure(message: 'Customer name is required'));
    }

    if (params.phone.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Phone number is required'));
    }

    if (params.phone.length < 10) {
      return const Left(ValidationFailure(message: 'Invalid phone number'));
    }

    // Check if customer with same phone already exists
    final existingResult = await repository.getCustomerByPhone(params.phone);

    return existingResult.fold(
      (failure) async {
        // Customer doesn't exist (failure usually means not found in some repo implementations)
        final customer = CustomerModel.create(
          name: params.name.trim(),
          phone: params.phone.trim(),
          email: params.email?.trim(),
          address: params.address?.trim(),
          nicNumber: params.nic?.trim(),
          companyId: 'current_company_id',
          notes: params.notes?.trim(),
        );
        return await repository.addCustomer(customer);
      },
      (existingCustomer) async {
        if (existingCustomer != null) {
          return Left(DatabaseFailure.duplicateEntry());
        }

        final customer = CustomerModel.create(
          name: params.name.trim(),
          phone: params.phone.trim(),
          email: params.email?.trim(),
          address: params.address?.trim(),
          nicNumber: params.nic?.trim(),
          companyId: 'current_company_id',
          notes: params.notes?.trim(),
        );
        return await repository.addCustomer(customer);
      },
    );
  }
}

/// Parameters for adding a new customer
class AddCustomerParams extends Equatable {
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? nic;
  final String? notes;

  const AddCustomerParams({
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.nic,
    this.notes,
  });

  @override
  List<Object?> get props => [
        name,
        phone,
        email,
        address,
        nic,
        notes,
      ];
}

/// Update customer use case
class UpdateCustomerUseCase
    implements UseCase<CustomerEntity, UpdateCustomerParams> {
  final CustomerRepository repository;

  UpdateCustomerUseCase({required this.repository});

  @override
  Future<Either<Failure, CustomerEntity>> call(
      UpdateCustomerParams params) async {
    if (params.id.isEmpty) {
      return const Left(ValidationFailure(message: 'Customer ID is required'));
    }

    // Get existing customer entity
    final existingResult = await repository.getCustomerById(params.id);
    return existingResult.fold(
      (failure) async => Left(failure),
      (existingCustomer) async {
        final existingModel =
            CustomerModel.fromEntity(existingCustomer, 'current_company_id');

        final updatedCustomer = existingModel.copyWith(
          name: params.name,
          phone: params.phone,
          email: params.email,
          address: params.address,
          nicNumber: params.nic,
          notes: params.notes,
          updatedAt: DateTime.now(),
          isSynced: false,
        );

        return await repository.updateCustomer(updatedCustomer);
      },
    );
  }
}

/// Parameters for updating a customer
class UpdateCustomerParams extends Equatable {
  final String id;
  final String? name;
  final String? phone;
  final String? email;
  final String? address;
  final String? nic;
  final String? notes;

  const UpdateCustomerParams({
    required this.id,
    this.name,
    this.phone,
    this.email,
    this.address,
    this.nic,
    this.notes,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        email,
        address,
        nic,
        notes,
      ];
}

