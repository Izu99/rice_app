// lib/features/buy/presentation/cubit/customer_state.dart

import 'package:equatable/equatable.dart';
import '../../../../core/constants/enums.dart';
import '../../../../data/models/customer_model.dart';

/// Customer search/add status
enum CustomerStatus {
  initial,
  searching,
  searched,
  adding,
  added,
  error,
  loading,
}

/// Customer State for customer selection and creation
class CustomerState extends Equatable {
  final CustomerStatus status;
  final String? errorMessage;
  final String? successMessage;

  // Search
  final String searchQuery;
  final List<CustomerModel> searchResults;
  final CustomerModel? foundByPhone;
  final bool isPhoneSearching;

  // Selected customer
  final CustomerModel? selectedCustomer;

  // Add customer form
  final String name;
  final String phone;
  final String? secondaryPhone;
  final String? address;
  final String? city;
  final String? nic;
  final CustomerType customerType;
  final String? notes;

  // Validation errors
  final Map<String, String>? fieldErrors;

  // All customers
  final List<CustomerModel> allCustomers;
  final bool isLoadingCustomers;

  const CustomerState({
    this.status = CustomerStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.searchQuery = '',
    this.searchResults = const [],
    this.foundByPhone,
    this.isPhoneSearching = false,
    this.selectedCustomer,
    this.name = '',
    this.phone = '',
    this.secondaryPhone,
    this.address,
    this.city,
    this.nic,
    this.customerType = CustomerType.seller,
    this.notes,
    this.fieldErrors,
    this.allCustomers = const [],
    this.isLoadingCustomers = false,
  });

  /// Initial state
  factory CustomerState.initial() {
    return const CustomerState();
  }

  /// Check if searching
  bool get isSearching =>
      status == CustomerStatus.searching || isPhoneSearching;

  /// Check if adding
  bool get isAdding => status == CustomerStatus.adding;

  /// Check if has error
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  /// Check if has field errors
  bool get hasFieldErrors => fieldErrors != null && fieldErrors!.isNotEmpty;

  /// Get field error
  String? getFieldError(String field) => fieldErrors?[field];

  /// Check if has search results
  bool get hasSearchResults => searchResults.isNotEmpty;

  /// Check if phone exists
  bool get phoneExists => foundByPhone != null;

  /// Validate form
  bool get isFormValid {
    if (name.trim().isEmpty) return false;
    if (phone.trim().isEmpty) return false;
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length < 9) return false;
    return true;
  }

  /// Get formatted phone
  String get formattedPhone {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length == 10) {
      return '${cleanPhone.substring(0, 3)} ${cleanPhone.substring(3, 6)} ${cleanPhone.substring(6)}';
    }
    return phone;
  }

  /// Getters used by widgets
  List<CustomerModel> get filteredCustomers => searchResults;
  List<CustomerModel> get customers => allCustomers;

  /// Copy with method
  CustomerState copyWith({
    CustomerStatus? status,
    String? errorMessage,
    String? successMessage,
    String? searchQuery,
    List<CustomerModel>? searchResults,
    CustomerModel? foundByPhone,
    bool? isPhoneSearching,
    CustomerModel? selectedCustomer,
    String? name,
    String? phone,
    String? secondaryPhone,
    String? address,
    String? city,
    String? nic,
    CustomerType? customerType,
    String? notes,
    Map<String, String>? fieldErrors,
    List<CustomerModel>? allCustomers,
    bool? isLoadingCustomers,
    bool clearError = false,
    bool clearFoundByPhone = false,
    bool clearSelectedCustomer = false,
    bool clearForm = false,
  }) {
    return CustomerState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: successMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      foundByPhone:
          clearFoundByPhone ? null : (foundByPhone ?? this.foundByPhone),
      isPhoneSearching: isPhoneSearching ?? this.isPhoneSearching,
      selectedCustomer: clearSelectedCustomer
          ? null
          : (selectedCustomer ?? this.selectedCustomer),
      name: clearForm ? '' : (name ?? this.name),
      phone: clearForm ? '' : (phone ?? this.phone),
      secondaryPhone:
          clearForm ? null : (secondaryPhone ?? this.secondaryPhone),
      address: clearForm ? null : (address ?? this.address),
      city: clearForm ? null : (city ?? this.city),
      nic: clearForm ? null : (nic ?? this.nic),
      customerType:
          clearForm ? CustomerType.seller : (customerType ?? this.customerType),
      notes: clearForm ? null : (notes ?? this.notes),
      fieldErrors: clearError ? null : (fieldErrors ?? this.fieldErrors),
      allCustomers: allCustomers ?? this.allCustomers,
      isLoadingCustomers: isLoadingCustomers ?? this.isLoadingCustomers,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        successMessage,
        searchQuery,
        searchResults,
        foundByPhone,
        isPhoneSearching,
        selectedCustomer,
        name,
        phone,
        secondaryPhone,
        address,
        city,
        nic,
        customerType,
        notes,
        fieldErrors,
        allCustomers,
        isLoadingCustomers,
      ];
}
