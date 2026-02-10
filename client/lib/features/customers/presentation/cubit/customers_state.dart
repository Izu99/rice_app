// lib/features/customers/presentation/cubit/customers_state.dart

// Need to import Icons
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../../domain/entities/customer_entity.dart';
import '../../../../core/constants/enums.dart';

/// Customers list status
enum CustomersStatus {
  initial,
  loading,
  loaded,
  error,
}

/// Customer detail status
enum CustomerDetailStatus {
  initial,
  loading,
  loaded,
  error,
}

/// Customer form status
enum CustomerFormStatus {
  initial,
  submitting,
  success,
  failure,
}

/// Customers State - Manages customers list and detail state
class CustomersState extends Equatable {
  // List state
  final CustomersStatus status;
  final List<CustomerEntity> customers;
  final List<CustomerEntity> filteredCustomers;
  final String? errorMessage;

  // Search & Filter
  final String searchQuery;
  final CustomerSortBy sortBy;
  final bool sortAscending;

  // Detail state
  final CustomerDetailStatus detailStatus;
  final CustomerEntity? selectedCustomer;
  final List<Map<String, dynamic>> customerTransactions;

  // Form state
  final CustomerFormStatus formStatus;
  final Map<String, String>? fieldErrors;
  final String? formErrorMessage;
  final String? formSuccessMessage;

  // Pagination
  final int currentPage;
  final int totalPages;
  final int totalCustomers;
  final bool hasMore;
  final bool isLoadingMore;

  // Balance filters
  final bool showOnlyWithBalance;
  final BalanceType? balanceFilter;
  final CustomerType? customerTypeFilter;

  const CustomersState({
    this.status = CustomersStatus.initial,
    this.customers = const [],
    this.filteredCustomers = const [],
    this.errorMessage,
    this.searchQuery = '',
    this.sortBy = CustomerSortBy.name,
    this.sortAscending = true,
    this.detailStatus = CustomerDetailStatus.initial,
    this.selectedCustomer,
    this.customerTransactions = const [],
    this.formStatus = CustomerFormStatus.initial,
    this.fieldErrors,
    this.formErrorMessage,
    this.formSuccessMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCustomers = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.showOnlyWithBalance = false,
    this.balanceFilter,
    this.customerTypeFilter,
  });

  /// Initial state
  factory CustomersState.initial() {
    return const CustomersState();
  }

  /// Check if loading
  bool get isLoading => status == CustomersStatus.loading;

  /// Check if loaded
  bool get isLoaded => status == CustomersStatus.loaded;

  /// Check if has error
  bool get hasError => status == CustomersStatus.error;

  /// Check if form is submitting
  bool get isSubmitting => formStatus == CustomerFormStatus.submitting;

  /// Check if has customers
  bool get hasCustomers => customers.isNotEmpty;

  /// Check if has filtered results
  bool get hasFilteredResults => filteredCustomers.isNotEmpty;

  /// Check if search is active
  bool get isSearchActive => searchQuery.isNotEmpty;

  /// Check if any filter is active
  bool get hasActiveFilters =>
      showOnlyWithBalance ||
      balanceFilter != null ||
      customerTypeFilter != null;

  /// Get total receivables
  double get totalReceivables {
    return customers
        .where((c) => c.balance > 0)
        .fold(0.0, (sum, c) => sum + c.balance);
  }

  /// Get total payables
  double get totalPayables {
    return customers
        .where((c) => c.balance < 0)
        .fold(0.0, (sum, c) => sum + c.balance.abs());
  }

  /// Get customers with receivables
  List<CustomerEntity> get customersWithReceivables {
    return customers.where((c) => c.balance > 0).toList();
  }

  /// Get customers with payables
  List<CustomerEntity> get customersWithPayables {
    return customers.where((c) => c.balance < 0).toList();
  }

  /// Copy with method
  CustomersState copyWith({
    CustomersStatus? status,
    List<CustomerEntity>? customers,
    List<CustomerEntity>? filteredCustomers,
    String? errorMessage,
    String? searchQuery,
    CustomerSortBy? sortBy,
    bool? sortAscending,
    CustomerDetailStatus? detailStatus,
    CustomerEntity? selectedCustomer,
    List<Map<String, dynamic>>? customerTransactions,
    CustomerFormStatus? formStatus,
    Map<String, String>? fieldErrors,
    String? formErrorMessage,
    String? formSuccessMessage,
    int? currentPage,
    int? totalPages,
    int? totalCustomers,
    bool? hasMore,
    bool? isLoadingMore,
    bool? showOnlyWithBalance,
    BalanceType? balanceFilter,
    CustomerType? customerTypeFilter,
    bool clearError = false,
    bool clearFormError = false,
    bool clearBalanceFilter = false,
    bool clearCustomerTypeFilter = false,
    bool clearSelectedCustomer = false,
  }) {
    return CustomersState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      detailStatus: detailStatus ?? this.detailStatus,
      selectedCustomer: clearSelectedCustomer
          ? null
          : (selectedCustomer ?? this.selectedCustomer),
      customerTransactions: customerTransactions ?? this.customerTransactions,
      formStatus: formStatus ?? this.formStatus,
      fieldErrors: clearFormError ? null : (fieldErrors ?? this.fieldErrors),
      formErrorMessage:
          clearFormError ? null : (formErrorMessage ?? this.formErrorMessage),
      formSuccessMessage: formSuccessMessage,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      showOnlyWithBalance: showOnlyWithBalance ?? this.showOnlyWithBalance,
      balanceFilter:
          clearBalanceFilter ? null : (balanceFilter ?? this.balanceFilter),
      customerTypeFilter: clearCustomerTypeFilter
          ? null
          : (customerTypeFilter ?? this.customerTypeFilter),
    );
  }

  @override
  List<Object?> get props => [
        status,
        customers,
        filteredCustomers,
        errorMessage,
        searchQuery,
        sortBy,
        sortAscending,
        detailStatus,
        selectedCustomer,
        customerTransactions,
        formStatus,
        fieldErrors,
        formErrorMessage,
        formSuccessMessage,
        currentPage,
        totalPages,
        totalCustomers,
        hasMore,
        isLoadingMore,
        showOnlyWithBalance,
        balanceFilter,
        customerTypeFilter,
      ];

  @override
  String toString() {
    return 'CustomersState(status: $status, customersCount: ${customers.length}, searchQuery: $searchQuery)';
  }
}

/// Customer sort options
enum CustomerSortBy {
  name,
  phone,
  balance,
  createdAt,
  totalPurchases,
  totalSales,
}

/// Balance type filter
enum BalanceType {
  receivable, // They owe us
  payable, // We owe them
}

/// Extension for CustomerSortBy
extension CustomerSortByExtension on CustomerSortBy {
  String get displayName {
    switch (this) {
      case CustomerSortBy.name:
        return 'Name';
      case CustomerSortBy.phone:
        return 'Phone';
      case CustomerSortBy.balance:
        return 'Balance';
      case CustomerSortBy.createdAt:
        return 'Date Added';
      case CustomerSortBy.totalPurchases:
        return 'Total Purchases';
      case CustomerSortBy.totalSales:
        return 'Total Sales';
    }
  }

  IconData get icon {
    switch (this) {
      case CustomerSortBy.name:
        return Icons.sort_by_alpha;
      case CustomerSortBy.phone:
        return Icons.phone;
      case CustomerSortBy.balance:
        return Icons.account_balance_wallet;
      case CustomerSortBy.createdAt:
        return Icons.calendar_today;
      case CustomerSortBy.totalPurchases:
        return Icons.shopping_cart;
      case CustomerSortBy.totalSales:
        return Icons.sell;
    }
  }
}
