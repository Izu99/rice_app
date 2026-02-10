// lib/data/datasources/remote/customer_remote_ds.dart

import 'dart:io';
import '../../../core/network/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../models/customer_model.dart';

abstract class CustomerRemoteDataSource {
  /// Get all customers from server
  Future<List<CustomerModel>> getAllCustomers({
    int page = 1,
    int limit = 50,
  });

  /// Get customer by ID from server
  Future<CustomerModel> getCustomerById(String id);

  /// Get customer by phone from server
  Future<CustomerModel?> getCustomerByPhone(String phone);

  /// Search customers on server
  Future<List<CustomerModel>> searchCustomers(String query);

  /// Create new customer on server
  Future<CustomerModel> createCustomer(CustomerModel customer);

  /// Update customer on server
  Future<CustomerModel> updateCustomer(CustomerModel customer);

  /// Delete customer on server
  Future<bool> deleteCustomer(String id);

  /// Get total count of customers
  Future<int> getCustomersCount();

  /// Sync customers - upload local changes
  Future<List<CustomerModel>> syncCustomers(List<CustomerModel> customers);

  /// Get customers updated after a specific date
  Future<List<CustomerModel>> getCustomersUpdatedAfter(DateTime dateTime);

  /// Batch create customers
  Future<List<CustomerModel>> batchCreateCustomers(
      List<CustomerModel> customers);

  /// Validate phone number uniqueness
  Future<bool> isPhoneAvailable(String phone, {String? excludeId});
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final ApiService apiService;

  CustomerRemoteDataSourceImpl({required this.apiService});

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

  @override
  Future<List<CustomerModel>> getAllCustomers({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final either = await apiService.get(
        ApiEndpoints.customers,
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> customersJson =
                response.data['customers'] ?? response.data;
            return customersJson
                .map((json) =>
                    CustomerModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          throw ServerException(
            message: response.message ?? 'Failed to fetch customers',
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
          message: 'Failed to fetch customers: ${e.toString()}');
    }
  }

  @override
  Future<CustomerModel> getCustomerById(String id) async {
    try {
      final either = await apiService.get(
        '${ApiEndpoints.customers}/$id',
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            // Backend wraps in 'customer' key and includes other data
            final customerJson = response.data['customer'] ?? response.data;
            return CustomerModel.fromJson(customerJson as Map<String, dynamic>);
          }

          if (response.statusCode == 404) {
            throw NotFoundException(message: 'Customer not found');
          }

          throw ServerException(
            message: response.message ?? 'Failed to fetch customer',
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
          message: 'Failed to fetch customer: ${e.toString()}');
    }
  }

  @override
  Future<CustomerModel?> getCustomerByPhone(String phone) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

      final either = await apiService.get(
        ApiEndpoints.customerByPhone,
        queryParameters: {'phone': cleanPhone},
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            // Check for nested 'customer' key for consistency
            final customerJson = response.data['customer'] ?? response.data;
            return CustomerModel.fromJson(customerJson as Map<String, dynamic>);
          }

          if (response.statusCode == 404) {
            return null;
          }

          throw ServerException(
            message: response.message ?? 'Failed to fetch customer by phone',
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
          message: 'Failed to fetch customer by phone: ${e.toString()}');
    }
  }

  @override
  Future<List<CustomerModel>> searchCustomers(String query) async {
    try {
      final either = await apiService.get(
        ApiEndpoints.searchCustomers,
        queryParameters: {'q': query},
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> customersJson =
                response.data['customers'] ?? response.data;
            return customersJson
                .map((json) =>
                    CustomerModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          throw ServerException(
            message: response.message ?? 'Failed to search customers',
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
          message: 'Failed to search customers: ${e.toString()}');
    }
  }

  @override
  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    try {
      final either = await apiService.post(
        ApiEndpoints.customers,
        data: customer.toJsonForApi(),
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            // Backend might wrap in 'customer' key
            final customerJson = response.data['customer'] ?? response.data;
            return CustomerModel.fromJson(customerJson as Map<String, dynamic>);
          }

          if (response.statusCode == 409) {
            throw ValidationException(
              message: 'Customer with this phone already exists',
              errors: {
                'phone': ['Phone number already in use']
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
            message: response.message ?? 'Failed to create customer',
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
          message: 'Failed to create customer: ${e.toString()}');
    }
  }

  @override
  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    try {
      final serverId = customer.serverId ?? customer.id;

      final either = await apiService.put(
        '${ApiEndpoints.customers}/$serverId',
        data: customer.toJsonForApi(),
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            // Backend might wrap in 'customer' key
            final customerJson = response.data['customer'] ?? response.data;
            return CustomerModel.fromJson(customerJson as Map<String, dynamic>);
          }

          if (response.statusCode == 404) {
            throw NotFoundException(message: 'Customer not found');
          }

          if (response.statusCode == 409) {
            throw ValidationException(
              message: 'Phone number already in use by another customer',
              errors: {
                'phone': ['Phone number already in use']
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
            message: response.message ?? 'Failed to update customer',
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
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to update customer: ${e.toString()}');
    }
  }

  @override
  Future<bool> deleteCustomer(String id) async {
    try {
      final either = await apiService.delete(
        '${ApiEndpoints.customers}/$id',
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success) {
            return true;
          }

          if (response.statusCode == 404) {
            throw NotFoundException(message: 'Customer not found');
          }

          throw ServerException(
            message: response.message ?? 'Failed to delete customer',
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
          message: 'Failed to delete customer: ${e.toString()}');
    }
  }

  @override
  Future<int> getCustomersCount() async {
    try {
      final either = await apiService.get(
        ApiEndpoints.customers,
        queryParameters: {'limit': '1'},
      );

      return either.fold(
        (failure) => 0,
        (response) {
          if (response.success && response.data != null) {
            final pagination = response.data['pagination'];
            if (pagination != null) {
              return pagination['total'] as int? ?? 0;
            }
          }
          return 0;
        },
      );
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<List<CustomerModel>> syncCustomers(
      List<CustomerModel> customers) async {
    try {
      final either = await apiService.post(
        ApiEndpoints.customerSync,
        data: {
          'customers': customers.map((c) => c.toJsonForSync()).toList(),
        },
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> syncedJson = response.data['synced'] ?? [];
            return syncedJson
                .map((json) =>
                    CustomerModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          throw SyncException(
            message: response.message ?? 'Failed to sync customers',
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on SyncException {
      rethrow;
    } catch (e) {
      throw SyncException(message: 'Failed to sync customers: ${e.toString()}');
    }
  }

  @override
  Future<List<CustomerModel>> getCustomersUpdatedAfter(
      DateTime dateTime) async {
    try {
      final either = await apiService.get(
        ApiEndpoints.customerUpdates,
        queryParameters: {
          'updated_after': dateTime.toIso8601String(),
        },
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> customersJson =
                response.data['customers'] ?? response.data;
            return customersJson
                .map((json) =>
                    CustomerModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          throw ServerException(
            message: response.message ?? 'Failed to fetch customer updates',
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
          message: 'Failed to fetch customer updates: ${e.toString()}');
    }
  }

  @override
  Future<List<CustomerModel>> batchCreateCustomers(
      List<CustomerModel> customers) async {
    try {
      final either = await apiService.post(
        ApiEndpoints.customerBatch,
        data: {
          'customers': customers.map((c) => c.toJsonForApi()).toList(),
        },
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> createdJson = response.data['created'] ?? [];
            return createdJson
                .map((json) =>
                    CustomerModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          throw ServerException(
            message: response.message ?? 'Failed to batch create customers',
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
          message: 'Failed to batch create customers: ${e.toString()}');
    }
  }

  @override
  Future<bool> isPhoneAvailable(String phone, {String? excludeId}) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

      final queryParams = <String, String>{};
      if (excludeId != null) {
        queryParams['exclude_id'] = excludeId;
      }

      final either = await apiService.get(
        '${ApiEndpoints.customerCheckPhone}/$cleanPhone',
        queryParameters: queryParams,
      );

      return either.fold(
        (failure) => true, // If check fails, assume available or handle error
        (response) {
          if (response.success && response.data != null) {
            // Note: Server returns { exists: true/false }
            return !(response.data['exists'] ?? true);
          }
          return true;
        },
      );
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      // Don't throw for availability check, just log and return true
      return true;
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
}
