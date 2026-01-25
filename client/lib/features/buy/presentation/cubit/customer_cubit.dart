// lib/features/buy/presentation/cubit/customer_cubit.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/customer_repository.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../../data/models/customer_model.dart';
import 'customer_state.dart';

/// Customer Cubit - Manages customer search and creation
class CustomerCubit extends Cubit<CustomerState> {
  final CustomerRepository _customerRepository;
  final AuthRepository _authRepository;

  Timer? _debounceTimer;

  CustomerCubit({
    required CustomerRepository customerRepository,
    required AuthRepository authRepository,
  })  : _customerRepository = customerRepository,
        _authRepository = authRepository,
        super(CustomerState.initial());

  /// Load all customers
  Future<void> loadCustomers() async {
    emit(state.copyWith(isLoadingCustomers: true));

    final result = await _customerRepository.getAllCustomers();

    result.fold(
      (failure) {
        emit(state.copyWith(
          isLoadingCustomers: false,
          errorMessage: failure.message,
        ));
      },
      (customers) {
        emit(state.copyWith(
          isLoadingCustomers: false,
          allCustomers: customers
              .map((e) => CustomerModel(
                    id: e.id,
                    name: e.name,
                    phone: e.phone,
                    address: e.address,
                    balance: e.balance,
                    isActive: e.isActive,
                    companyId: '',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ))
              .toList(),
        ));
      },
    );
  }

  /// Search customers
  void searchCustomers(String query) {
    emit(state.copyWith(
      searchQuery: query,
      status: CustomerStatus.searching,
    ));

    // Debounce search
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (query.isEmpty) {
        emit(state.copyWith(
          searchResults: [],
          status: CustomerStatus.initial,
        ));
        return;
      }

      final result = await _customerRepository.searchCustomers(query);

      result.fold(
        (failure) {
          emit(state.copyWith(
            status: CustomerStatus.searched,
            searchResults: [],
          ));
        },
        (customers) {
          emit(state.copyWith(
            status: CustomerStatus.searched,
            searchResults: customers
                .map((e) => CustomerModel(
                      id: e.id,
                      name: e.name,
                      phone: e.phone,
                      address: e.address,
                      balance: e.balance,
                      isActive: e.isActive,
                      companyId: '',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ))
                .toList(),
          ));
        },
      );
    });
  }

  /// Check phone number
  Future<CustomerModel?> checkPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanPhone.length < 9) {
      emit(state.copyWith(clearFoundByPhone: true));
      return null;
    }

    emit(state.copyWith(isPhoneSearching: true));

    final result = await _customerRepository.getCustomerByPhone(cleanPhone);

    return result.fold(
      (failure) {
        emit(state.copyWith(
          isPhoneSearching: false,
          clearFoundByPhone: true,
        ));
        return null;
      },
      (customer) {
        if (customer != null) {
          final customerModel = CustomerModel(
            id: customer.id,
            name: customer.name,
            phone: customer.phone,
            address: customer.address,
            balance: customer.balance,
            isActive: customer.isActive,
            companyId: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          emit(state.copyWith(
            isPhoneSearching: false,
            foundByPhone: customerModel,
          ));
          return customerModel;
        } else {
          emit(state.copyWith(
            isPhoneSearching: false,
            clearFoundByPhone: true,
          ));
          return null;
        }
      },
    );
  }

  /// Select customer
  void selectCustomer(CustomerModel customer) {
    emit(state.copyWith(
      selectedCustomer: customer,
      status: CustomerStatus.searched,
    ));
  }

  /// Clear selection
  void clearSelection() {
    emit(state.copyWith(clearSelectedCustomer: true));
  }

  /// Update name
  void updateName(String name) {
    emit(state.copyWith(name: name, clearError: true));
  }

  /// Update phone
  void updatePhone(String phone) {
    emit(state.copyWith(phone: phone, clearError: true));
    checkPhone(phone);
  }

  /// Update secondary phone
  void updateSecondaryPhone(String phone) {
    emit(state.copyWith(secondaryPhone: phone));
  }

  /// Update address
  void updateAddress(String address) {
    emit(state.copyWith(address: address));
  }

  /// Update city
  void updateCity(String city) {
    emit(state.copyWith(city: city));
  }

  /// Update NIC
  void updateNic(String nic) {
    emit(state.copyWith(nic: nic));
  }

  /// Update notes
  void updateNotes(String notes) {
    emit(state.copyWith(notes: notes));
  }

  /// Validate form
  Map<String, String> _validateForm() {
    final errors = <String, String>{};

    if (state.name.trim().isEmpty) {
      errors['name'] = 'Name is required';
    } else if (state.name.trim().length < 2) {
      errors['name'] = 'Name must be at least 2 characters';
    }

    final cleanPhone = state.phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.isEmpty) {
      errors['phone'] = 'Phone number is required';
    } else if (cleanPhone.length < 9 || cleanPhone.length > 12) {
      errors['phone'] = 'Invalid phone number';
    }

    return errors;
  }

  /// Add new customer
  Future<CustomerModel?> addCustomer() async {
    // Validate
    final errors = _validateForm();
    if (errors.isNotEmpty) {
      emit(state.copyWith(fieldErrors: errors));
      return null;
    }

    // Check if phone exists
    if (state.foundByPhone != null) {
      emit(state.copyWith(
        errorMessage: 'Customer with this phone already exists',
        fieldErrors: {'phone': 'Phone number already in use'},
      ));
      return null;
    }

    emit(state.copyWith(status: CustomerStatus.adding, clearError: true));

    try {
      // Get company ID
      String companyId = '';
      final userResult = await _authRepository.getCurrentUser();
      userResult.fold((l) {}, (user) {
        companyId = user.companyId;
      });

      // Combine address and city
      String fullAddress = '';
      if (state.address?.isNotEmpty == true && state.city?.isNotEmpty == true) {
        fullAddress = '${state.address}, ${state.city}';
      } else if (state.address?.isNotEmpty == true) {
        fullAddress = state.address!;
      } else if (state.city?.isNotEmpty == true) {
        fullAddress = state.city!;
      }

      final customer = CustomerModel.create(
        name: state.name.trim(),
        phone: state.phone.replaceAll(RegExp(r'[^\d]'), ''),
        companyId: companyId,
        secondaryPhone: state.secondaryPhone,
        address: fullAddress,
        nicNumber: state.nic,
        notes: state.notes,
      );

      final result = await _customerRepository.addCustomer(customer);

      return result.fold(
        (failure) {
          emit(state.copyWith(
            status: CustomerStatus.error,
            errorMessage: failure.message,
          ));
          return null;
        },
        (entity) {
          final addedCustomer = CustomerModel(
            id: entity.id,
            name: entity.name,
            phone: entity.phone,
            address: entity.address,
            balance: entity.balance,
            isActive: entity.isActive,
            companyId: companyId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          emit(state.copyWith(
            status: CustomerStatus.added,
            selectedCustomer: addedCustomer,
            allCustomers: [addedCustomer, ...state.allCustomers],
            successMessage: 'Customer added successfully',
            clearForm: true,
          ));

          return addedCustomer;
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: CustomerStatus.error,
        errorMessage: 'Failed to add customer: ${e.toString()}',
      ));
      return null;
    }
  }

  /// Reset form
  void resetForm() {
    emit(state.copyWith(
      clearForm: true,
      clearFoundByPhone: true,
      clearError: true,
      status: CustomerStatus.initial,
    ));
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}

