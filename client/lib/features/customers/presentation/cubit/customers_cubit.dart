// lib/features/customers/presentation/cubit/customers_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/enums.dart';
import '../../../../data/models/customer_model.dart';
import '../../../../domain/entities/customer_entity.dart';
import '../../../../domain/repositories/customer_repository.dart';
import '../../../../core/utils/logger_utils.dart';
import 'customers_state.dart';

/// Customers Cubit - Manages customers business logic
class CustomersCubit extends Cubit<CustomersState> {
  final CustomerRepository _customerRepository;

  CustomersCubit({
    required CustomerRepository customerRepository,
  })  : _customerRepository = customerRepository,
        super(CustomersState.initial());

  /// Load all customers
  Future<void> loadCustomers() async {
    emit(state.copyWith(status: CustomersStatus.loading, clearError: true));

    final result = await _customerRepository.getAllCustomers();

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: CustomersStatus.error,
          errorMessage: failure.message,
        ));
      },
      (customers) {
        final sortedCustomers = _sortCustomers(customers);
        emit(state.copyWith(
          status: CustomersStatus.loaded,
          customers: sortedCustomers,
          filteredCustomers: sortedCustomers,
          totalCustomers: customers.length,
        ));
      },
    );
  }

  /// Refresh customers
  Future<void> refreshCustomers() async {
    final result = await _customerRepository.getAllCustomers();

    result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
      },
      (customers) {
        final sortedCustomers = _sortCustomers(customers);
        final filtered = _applyFilters(sortedCustomers);
        emit(state.copyWith(
          customers: sortedCustomers,
          filteredCustomers: filtered,
          totalCustomers: customers.length,
        ));
      },
    );
  }

  /// Search customers
  void searchCustomers(String query) {
    emit(state.copyWith(searchQuery: query));
    _applyFiltersAndSort();
  }

  /// Filter by balance type
  void filterByBalance(BalanceType? type) {
    if (type == state.balanceFilter) {
      emit(state.copyWith(clearBalanceFilter: true));
    } else {
      emit(state.copyWith(balanceFilter: type));
    }
    _applyFiltersAndSort();
  }

  /// Filter by customer type
  void filterByType(CustomerType? type) {
    if (type == state.customerTypeFilter) {
      emit(state.copyWith(clearCustomerTypeFilter: true));
    } else {
      emit(state.copyWith(customerTypeFilter: type));
    }
    _applyFiltersAndSort();
  }

  /// Toggle show only with balance
  void toggleShowOnlyWithBalance() {
    emit(state.copyWith(showOnlyWithBalance: !state.showOnlyWithBalance));
    _applyFiltersAndSort();
  }

  /// Sort customers
  void sortCustomers(CustomerSortBy sortBy) {
    if (state.sortBy == sortBy) {
      emit(state.copyWith(sortAscending: !state.sortAscending));
    } else {
      emit(state.copyWith(sortBy: sortBy, sortAscending: true));
    }
    _applyFiltersAndSort();
  }

  /// Clear all filters
  void clearFilters() {
    emit(state.copyWith(
      searchQuery: '',
      clearBalanceFilter: true,
      clearCustomerTypeFilter: true,
      showOnlyWithBalance: false,
      filteredCustomers: state.customers,
    ));
  }

  /// Apply filters and sort
  void _applyFiltersAndSort() {
    var filtered = _applyFilters(state.customers);
    filtered = _sortCustomers(filtered);
    emit(state.copyWith(filteredCustomers: filtered));
  }

  /// Apply filters to customers list
  List<CustomerEntity> _applyFilters(List<CustomerEntity> customers) {
    var filtered = customers;

    // Search filter
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((customer) {
        return customer.name.toLowerCase().contains(query) ||
            customer.phone.contains(query) ||
            (customer.address?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Balance filter
    if (state.showOnlyWithBalance) {
      filtered = filtered.where((c) => c.balance != 0).toList();
    }

    if (state.balanceFilter != null) {
      switch (state.balanceFilter!) {
        case BalanceType.receivable:
          filtered = filtered.where((c) => c.balance > 0).toList();
          break;
        case BalanceType.payable:
          filtered = filtered.where((c) => c.balance < 0).toList();
          break;
      }
    }

    // Customer type filter
    if (state.customerTypeFilter != null) {
      filtered = filtered.where((c) {
        return c.customerType == state.customerTypeFilter;
      }).toList();
    }

    return filtered;
  }

  /// Sort customers list
  List<CustomerEntity> _sortCustomers(List<CustomerEntity> customers) {
    final sorted = List<CustomerEntity>.from(customers);

    sorted.sort((a, b) {
      int comparison;
      switch (state.sortBy) {
        case CustomerSortBy.name:
          comparison = a.name.compareTo(b.name);
          break;
        case CustomerSortBy.phone:
          comparison = a.phone.compareTo(b.phone);
          break;
        case CustomerSortBy.balance:
          comparison = a.balance.compareTo(b.balance);
          break;
        case CustomerSortBy.createdAt:
          // For entity, we don't have createdAt, so sort by name
          comparison = a.name.compareTo(b.name); // Placeholder
          break;
        case CustomerSortBy.totalPurchases:
          comparison = a.name.compareTo(b.name); // Placeholder
          break;
        case CustomerSortBy.totalSales:
          comparison = a.name.compareTo(b.name); // Placeholder
          break;
      }

      return state.sortAscending ? comparison : -comparison;
    });

    return sorted;
  }

  /// Load customer detail
  Future<void> loadCustomerDetail(String customerId) async {
    emit(state.copyWith(
      detailStatus: CustomerDetailStatus.loading,
      clearSelectedCustomer: true,
    ));

    final result = await _customerRepository.getCustomerById(customerId);

    await result.fold(
      (failure) async {
        emit(state.copyWith(
          detailStatus: CustomerDetailStatus.error,
          errorMessage: failure.message,
        ));
      },
      (customer) async {
        // Load customer transactions
        final transactionsResult =
            await _customerRepository.getCustomerTransactionHistory(
          customerId: customerId,
          limit: 20,
        );

        final transactions = transactionsResult.fold(
          (l) => <Map<String, dynamic>>[],
          (r) => r,
        );

        emit(state.copyWith(
          detailStatus: CustomerDetailStatus.loaded,
          selectedCustomer: customer,
          customerTransactions: transactions,
        ));
      },
    );
  }

  /// Add new customer
  Future<void> addCustomer({
    required String name,
    required String phone,
    String? secondaryPhone,
    String? email,
    String? address,
    String? city,
    String? nic,
    String? notes,
    required String companyId,
    CustomerType customerType = CustomerType.seller,
  }) async {
    // Validate
    final errors = _validateCustomerInput(
      name: name,
      phone: phone,
      email: email,
    );

    if (errors.isNotEmpty) {
      emit(state.copyWith(
        formStatus: CustomerFormStatus.failure,
        fieldErrors: errors,
      ));
      return;
    }

    emit(state.copyWith(
      formStatus: CustomerFormStatus.submitting,
      clearFormError: true,
    ));

    // Check if phone exists
    final phoneExistsResult = await _customerRepository.isPhoneExists(phone);
    final phoneExists = phoneExistsResult.fold((l) => false, (r) => r);

    if (phoneExists) {
      emit(state.copyWith(
        formStatus: CustomerFormStatus.failure,
        fieldErrors: {'phone': 'Phone number already exists'},
      ));
      return;
    }

    // Create customer model
    final customer = CustomerModel.create(
      name: name,
      phone: phone,
      companyId: companyId,
      secondaryPhone: secondaryPhone,
      email: email,
      address: address,
      city: city,
      nicNumber: nic,
      notes: notes,
      customerType: customerType,
    );

    final result = await _customerRepository.addCustomer(customer);

    result.fold(
      (failure) {
        Log.e('Failed to add customer $name',
            error: failure.message, tag: 'CUSTOMER');
        emit(state.copyWith(
          formStatus: CustomerFormStatus.failure,
          formErrorMessage: failure.message,
        ));
      },
      (newCustomer) {
        Log.s('Customer ${newCustomer.name} added successfully',
            tag: 'CUSTOMER');
        // Add to list
        final updatedCustomers = [newCustomer, ...state.customers];
        final filtered = _applyFilters(updatedCustomers);

        emit(state.copyWith(
          formStatus: CustomerFormStatus.success,
          formSuccessMessage: 'Customer added successfully',
          customers: updatedCustomers,
          filteredCustomers: filtered,
          totalCustomers: updatedCustomers.length,
        ));
      },
    );
  }

  /// Update customer
  Future<void> updateCustomer({
    required String id,
    required String name,
    required String phone,
    String? secondaryPhone,
    String? email,
    String? address,
    String? city,
    String? nic,
    String? notes,
    required String companyId,
    CustomerType? customerType,
  }) async {
    // Validate
    final errors = _validateCustomerInput(
      name: name,
      phone: phone,
      email: email,
    );

    if (errors.isNotEmpty) {
      emit(state.copyWith(
        formStatus: CustomerFormStatus.failure,
        fieldErrors: errors,
      ));
      return;
    }

    emit(state.copyWith(
      formStatus: CustomerFormStatus.submitting,
      clearFormError: true,
    ));

    // Check if phone exists for another customer
    final phoneExistsResult = await _customerRepository.isPhoneExists(
      phone,
      excludeId: id,
    );
    final phoneExists = phoneExistsResult.fold((l) => false, (r) => r);

    if (phoneExists) {
      emit(state.copyWith(
        formStatus: CustomerFormStatus.failure,
        fieldErrors: {'phone': 'Phone number already in use'},
      ));
      return;
    }

    // Get existing customer to preserve some fields
    final existingResult = await _customerRepository.getCustomerById(id);
    final existing = existingResult.fold((l) => null, (r) => r);

    if (existing == null) {
      emit(state.copyWith(
        formStatus: CustomerFormStatus.failure,
        formErrorMessage: 'Customer not found',
      ));
      return;
    }

    // Create updated customer model
    final customer = CustomerModel(
      id: id,
      serverId: existing.serverId,
      name: name,
      phone: phone,
      secondaryPhone: secondaryPhone,
      email: email,
      address: address,
      city: city,
      nicNumber: nic,
      notes: notes,
      companyId: companyId,
      balance: existing.balance,
      customerType: customerType ?? existing.customerType,
      isActive: existing.isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: false,
      syncStatus: SyncStatus.pending,
    );

    final result = await _customerRepository.updateCustomer(customer);

    result.fold(
      (failure) {
        emit(state.copyWith(
          formStatus: CustomerFormStatus.failure,
          formErrorMessage: failure.message,
        ));
      },
      (updatedCustomer) {
        // Update in list
        final updatedCustomers = state.customers.map((c) {
          return c.id == id ? updatedCustomer : c;
        }).toList();
        final filtered = _applyFilters(updatedCustomers);

        emit(state.copyWith(
          formStatus: CustomerFormStatus.success,
          formSuccessMessage: 'Customer updated successfully',
          customers: updatedCustomers,
          filteredCustomers: filtered,
          selectedCustomer: updatedCustomer,
        ));
      },
    );
  }

  /// Delete customer
  Future<void> deleteCustomer(String id) async {
    emit(state.copyWith(formStatus: CustomerFormStatus.submitting));

    final result = await _customerRepository.deleteCustomer(id);

    result.fold(
      (failure) {
        Log.e('Failed to delete customer $id',
            error: failure.message, tag: 'CUSTOMER');
        emit(state.copyWith(
          formStatus: CustomerFormStatus.failure,
          formErrorMessage: failure.message,
        ));
      },
      (_) {
        Log.s('Customer $id deleted successfully', tag: 'CUSTOMER');
        // Remove from list
        final updatedCustomers =
            state.customers.where((c) => c.id != id).toList();
        final filtered = _applyFilters(updatedCustomers);

        emit(state.copyWith(
          formStatus: CustomerFormStatus.success,
          formSuccessMessage: 'Customer deleted successfully',
          customers: updatedCustomers,
          filteredCustomers: filtered,
          totalCustomers: updatedCustomers.length,
          clearSelectedCustomer: true,
        ));
      },
    );
  }

  /// Validate customer input
  Map<String, String> _validateCustomerInput({
    required String name,
    required String phone,
    String? email,
  }) {
    final errors = <String, String>{};

    // Name validation
    if (name.trim().isEmpty) {
      errors['name'] = 'Name is required';
    } else if (name.trim().length < 2) {
      errors['name'] = 'Name must be at least 2 characters';
    }

    // Phone validation
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.isEmpty) {
      errors['phone'] = 'Phone number is required';
    } else if (cleanPhone.length < 9 || cleanPhone.length > 12) {
      errors['phone'] = 'Invalid phone number';
    }

    // Email validation (optional)
    if (email != null && email.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        errors['email'] = 'Invalid email address';
      }
    }

    return errors;
  }

  /// Check if phone exists
  Future<bool> checkPhoneExists(String phone, {String? excludeId}) async {
    final result = await _customerRepository.isPhoneExists(
      phone,
      excludeId: excludeId,
    );
    return result.fold((l) => false, (r) => r);
  }

  /// Get customer by phone
  Future<CustomerEntity?> getCustomerByPhone(String phone) async {
    final result = await _customerRepository.getCustomerByPhone(phone);
    return result.fold((l) => null, (r) => r);
  }

  /// Reset form status
  void resetFormStatus() {
    emit(state.copyWith(
      formStatus: CustomerFormStatus.initial,
      clearFormError: true,
    ));
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  /// Clear selected customer
  void clearSelectedCustomer() {
    emit(state.copyWith(clearSelectedCustomer: true));
  }
}
