// lib/data/datasources/remote/auth_remote_ds.dart

import 'dart:io';
import '../../../core/network/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/enums.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../models/user_model.dart';
import '../../models/company_model.dart';

abstract class AuthRemoteDataSource {
  /// Login with identifier (email or phone) and password
  Future<AuthResponse> login({
    required String identifier, // Can be email or phone
    required String password,
  });

  /// Register new user
  Future<AuthResponse> register({
    required String name,
    required String phone,
    required String password,
    required String companyId,
    UserRole role = UserRole.operator,
  });

  /// Logout user
  Future<bool> logout();

  /// Refresh access token
  Future<AuthResponse> refreshToken(String refreshToken);

  /// Get current user profile
  Future<UserModel> getCurrentUser();

  /// Update user profile
  Future<UserModel> updateProfile({
    String? name,
    String? email,
    String? avatar,
  });

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Request password reset OTP
  Future<bool> requestPasswordReset(String phone);

  /// Verify OTP
  Future<bool> verifyOtp({
    required String phone,
    required String otp,
  });

  /// Reset password with OTP
  Future<bool> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  });

  /// Verify phone number
  Future<bool> verifyPhone({
    required String phone,
    required String otp,
  });

  /// Resend OTP
  Future<bool> resendOtp(String phone);

  /// Update FCM token
  Future<bool> updateFcmToken(String fcmToken);

  /// Get company details
  Future<CompanyModel> getCompanyDetails(String companyId);

  /// Register new company (Super Admin)
  Future<CompanyModel> registerCompany({
    required String name,
    required String address,
    required String phone,
    required String adminName,
    required String adminPhone,
    required String adminPassword,
  });

  /// Get all companies (Super Admin)
  Future<List<CompanyModel>> getAllCompanies();

  /// Update company status (Super Admin)
  Future<CompanyModel> updateCompanyStatus({
    required String companyId,
    required bool isActive,
  });

  /// Get company users
  Future<List<UserModel>> getCompanyUsers(String companyId);

  /// Add user to company
  Future<UserModel> addUserToCompany({
    required String companyId,
    required String name,
    required String phone,
    required String password,
    required UserRole role,
  });

  /// Remove user from company
  Future<bool> removeUserFromCompany(String userId);

  /// Update user role
  Future<UserModel> updateUserRole({
    required String userId,
    required UserRole role,
  });

  /// Check if phone is registered
  Future<bool> isPhoneRegistered(String phone);

  /// Deactivate user account
  Future<bool> deactivateAccount();

  /// Delete user account
  Future<bool> deleteAccount(String password);

  /// Update company details
  Future<CompanyModel> updateCompany(CompanyModel company);
}

/// Auth response containing user, tokens, and company
class AuthResponse {
  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final CompanyModel? company;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.company,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user']),
      accessToken: json['access_token'] ?? json['token'],
      refreshToken: json['refresh_token'] ?? '',
      company: json['company'] != null
          ? CompanyModel.fromJson(json['company'])
          : null,
    );
  }
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiService apiService;

  AuthRemoteDataSourceImpl({required this.apiService});

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
  Future<AuthResponse> login({
    required String identifier,
    required String password,
  }) async {
    try {
      // Determine if identifier is email or phone
      final isEmail =
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(identifier);
      final cleanIdentifier = identifier.replaceAll(RegExp(r'[^\d+]'), '');

      final either = await apiService.post(
        ApiEndpoints.login,
        data: isEmail
            ? {'email': identifier, 'password': password}
            : {'phone': cleanIdentifier, 'password': password},
        requiresAuth: false,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return AuthResponse.fromJson(response.data);
          }

          if (response.statusCode == 401) {
            throw AuthException(
              message: 'Invalid phone or password',
              statusCode: 401,
            );
          }

          if (response.statusCode == 403) {
            throw AuthException(
              message: response.message ?? 'Account is deactivated',
              statusCode: 403,
            );
          }

          throw ServerException(
            message: response.message ?? 'Login failed',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Login failed: ${e.toString()}');
    }
  }

  @override
  Future<AuthResponse> register({
    required String name,
    required String phone,
    required String password,
    required String companyId,
    UserRole role = UserRole.operator,
  }) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

      final either = await apiService.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'phone': cleanPhone,
          'password': password,
          'company_id': companyId,
          'role': role.name,
        },
        requiresAuth: false,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return AuthResponse.fromJson(response.data);
          }

          if (response.statusCode == 409) {
            throw ValidationException(
              message: 'Phone number already registered',
            );
          }

          if (response.statusCode == 422) {
            throw ValidationException(
              message: response.message ?? 'Validation failed',
            );
          }

          throw ServerException(
            message: response.message ?? 'Registration failed',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on AuthException {
      rethrow;
    } on ValidationException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<bool> logout() async {
    try {
      final either = await apiService.post(
        ApiEndpoints.logout,
        requiresAuth: true, // Logout requires auth token
      );

      return either.fold(
        (failure) => false,
        (response) => response.success,
      );
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      // Even if logout fails on server, we should clear local data
      return true;
    }
  }

  @override
  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final either = await apiService.post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
        requiresAuth: false,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return AuthResponse.fromJson(response.data);
          }

          if (response.statusCode == 401) {
            throw AuthException(
              message: 'Session expired. Please login again.',
              statusCode: 401,
            );
          }

          throw ServerException(
            message: response.message ?? 'Token refresh failed',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Token refresh failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final either = await apiService.get(
        ApiEndpoints.profile,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return UserModel.fromJson(response.data['user']);
          }

          if (response.statusCode == 401) {
            throw AuthException(
              message: 'Session expired',
              statusCode: 401,
            );
          }

          throw ServerException(
            message: response.message ?? 'Failed to get user profile',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to get user profile: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? name,
    String? email,
    String? avatar,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (avatar != null) data['avatar'] = avatar;

      final either = await apiService.put(
        ApiEndpoints.profile,
        data: data,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return UserModel.fromJson(response.data);
          }

          throw ServerException(
            message: response.message ?? 'Failed to update profile',
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
          message: 'Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final either = await apiService.post(
        ApiEndpoints.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success) {
            return true;
          }

          if (response.statusCode == 400) {
            throw AuthException(
              message: 'Current password is incorrect',
              code: 'WRONG_PASSWORD',
            );
          }

          throw ServerException(
            message: response.message ?? 'Failed to change password',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to change password: ${e.toString()}');
    }
  }

  @override
  Future<bool> requestPasswordReset(String phone) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

      final either = await apiService.post(
        ApiEndpoints.forgotPassword,
        data: {'phone': cleanPhone},
        requiresAuth: false,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success) {
            return true;
          }

          if (response.statusCode == 404) {
            throw AuthException(
              message: 'Phone number not registered',
              code: 'PHONE_NOT_FOUND',
            );
          }

          throw ServerException(
            message: response.message ?? 'Failed to request password reset',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to request password reset: ${e.toString()}');
    }
  }

  @override
  Future<bool> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

      final either = await apiService.post(
        ApiEndpoints.verifyOtp,
        data: {
          'phone': cleanPhone,
          'otp': otp,
        },
        requiresAuth: false,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success) {
            return true;
          }

          if (response.statusCode == 400) {
            throw AuthException(
              message: 'Invalid or expired OTP',
              code: 'INVALID_OTP',
            );
          }

          throw ServerException(
            message: response.message ?? 'OTP verification failed',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'OTP verification failed: ${e.toString()}');
    }
  }

  @override
  Future<bool> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

      final either = await apiService.post(
        ApiEndpoints.resetPassword,
        data: {
          'phone': cleanPhone,
          'otp': otp,
          'new_password': newPassword,
        },
        requiresAuth: false,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success) {
            return true;
          }

          if (response.statusCode == 400) {
            throw AuthException(
              message: 'Invalid or expired OTP',
              code: 'INVALID_OTP',
            );
          }

          throw ServerException(
            message: response.message ?? 'Password reset failed',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Password reset failed: ${e.toString()}');
    }
  }

  @override
  Future<bool> verifyPhone({
    required String phone,
    required String otp,
  }) async {
    return verifyOtp(phone: phone, otp: otp);
  }

  @override
  Future<bool> resendOtp(String phone) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

      final either = await apiService.post(
        ApiEndpoints.resendOtp,
        data: {'phone': cleanPhone},
        requiresAuth: false,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success) {
            return true;
          }

          if (response.statusCode == 429) {
            throw AuthException(
              message: 'Too many requests. Please try again later.',
              code: 'RATE_LIMITED',
            );
          }

          throw ServerException(
            message: response.message ?? 'Failed to resend OTP',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to resend OTP: ${e.toString()}');
    }
  }

  @override
  Future<bool> updateFcmToken(String fcmToken) async {
    try {
      final either = await apiService.post(
        ApiEndpoints.registerFcmToken,
        data: {'fcm_token': fcmToken},
      );

      return either.fold(
        (failure) => false,
        (response) => response.success,
      );
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      // FCM token update failure is not critical
      return false;
    }
  }

  @override
  Future<CompanyModel> getCompanyDetails(String companyId) async {
    try {
      final either = await apiService.get(
        '${ApiEndpoints.companies}/$companyId',
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return CompanyModel.fromJson(response.data);
          }

          if (response.statusCode == 404) {
            throw NotFoundException(message: 'Company not found');
          }

          throw ServerException(
            message: response.message ?? 'Failed to get company details',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on NotFoundException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to get company details: ${e.toString()}');
    }
  }

  @override
  Future<CompanyModel> registerCompany({
    required String name,
    required String address,
    required String phone,
    required String adminName,
    required String adminPhone,
    required String adminPassword,
  }) async {
    try {
      final either = await apiService.post(
        ApiEndpoints.companies,
        data: {
          'name': name,
          'address': address,
          'phone': phone,
          'admin_name': adminName,
          'admin_phone': adminPhone,
          'admin_password': adminPassword,
        },
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return CompanyModel.fromJson(response.data);
          }

          if (response.statusCode == 409) {
            throw ValidationException(
              message: 'Company or admin phone already exists',
            );
          }

          throw ServerException(
            message: response.message ?? 'Failed to register company',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on ValidationException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to register company: ${e.toString()}');
    }
  }

  @override
  Future<List<CompanyModel>> getAllCompanies() async {
    try {
      final either = await apiService.get(
        ApiEndpoints.companies,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> companiesJson =
                response.data['companies'] ?? response.data;
            return companiesJson
                .map((json) =>
                    CompanyModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          throw ServerException(
            message: response.message ?? 'Failed to fetch companies',
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
          message: 'Failed to fetch companies: ${e.toString()}');
    }
  }

  @override
  Future<CompanyModel> updateCompanyStatus({
    required String companyId,
    required bool isActive,
  }) async {
    try {
      final either = await apiService.patch(
        '${ApiEndpoints.companies}/$companyId/status',
        data: {'is_active': isActive},
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return CompanyModel.fromJson(response.data);
          }

          if (response.statusCode == 404) {
            throw NotFoundException(message: 'Company not found');
          }

          throw ServerException(
            message: response.message ?? 'Failed to update company status',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on NotFoundException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to update company status: ${e.toString()}');
    }
  }

  @override
  Future<List<UserModel>> getCompanyUsers(String companyId) async {
    try {
      final either = await apiService.get(
        '${ApiEndpoints.companies}/$companyId/users',
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            final List<dynamic> usersJson =
                response.data['users'] ?? response.data;
            return usersJson
                .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          throw ServerException(
            message: response.message ?? 'Failed to fetch company users',
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
          message: 'Failed to fetch company users: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> addUserToCompany({
    required String companyId,
    required String name,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

      final either = await apiService.post(
        '${ApiEndpoints.companies}/$companyId/users',
        data: {
          'name': name,
          'phone': cleanPhone,
          'password': password,
          'role': role.name,
        },
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return UserModel.fromJson(response.data);
          }

          if (response.statusCode == 409) {
            throw ValidationException(
              message: 'Phone number already registered',
            );
          }

          throw ServerException(
            message: response.message ?? 'Failed to add user',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on ValidationException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to add user: ${e.toString()}');
    }
  }

  @override
  Future<bool> removeUserFromCompany(String userId) async {
    try {
      final either = await apiService.delete(
        '${ApiEndpoints.users}/$userId',
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success) {
            return true;
          }

          if (response.statusCode == 404) {
            throw NotFoundException(message: 'User not found');
          }

          throw ServerException(
            message: response.message ?? 'Failed to remove user',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on NotFoundException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to remove user: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateUserRole({
    required String userId,
    required UserRole role,
  }) async {
    try {
      final either = await apiService.patch(
        '${ApiEndpoints.users}/$userId/role',
        data: {'role': role.name},
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return UserModel.fromJson(response.data);
          }

          if (response.statusCode == 404) {
            throw NotFoundException(message: 'User not found');
          }

          throw ServerException(
            message: response.message ?? 'Failed to update user role',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on NotFoundException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to update user role: ${e.toString()}');
    }
  }

  @override
  Future<bool> isPhoneRegistered(String phone) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

      final either = await apiService.get(
        ApiEndpoints.checkPhone,
        queryParameters: {'phone': cleanPhone},
        requiresAuth: false,
      );

      return either.fold(
        (failure) => false,
        (response) {
          if (response.success && response.data != null) {
            return response.data['registered'] ?? false;
          }
          return false;
        },
      );
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      throw ServerException(message: 'Failed to check phone: ${e.toString()}');
    }
  }

  @override
  Future<bool> deactivateAccount() async {
    try {
      final either = await apiService.post(
        ApiEndpoints.deactivateAccount,
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success) {
            return true;
          }

          throw ServerException(
            message: response.message ?? 'Failed to deactivate account',
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
          message: 'Failed to deactivate account: ${e.toString()}');
    }
  }

  @override
  Future<bool> deleteAccount(String password) async {
    try {
      final either = await apiService.post(
        ApiEndpoints.deleteAccount,
        data: {'password': password},
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success) {
            return true;
          }

          if (response.statusCode == 400) {
            throw AuthException(
              message: 'Incorrect password',
              code: 'WRONG_PASSWORD',
            );
          }

          throw ServerException(
            message: response.message ?? 'Failed to delete account',
            statusCode: response.statusCode,
          );
        },
      );
    } on SocketException {
      throw NetworkException();
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Failed to delete account: ${e.toString()}');
    }
  }

  @override
  Future<CompanyModel> updateCompany(CompanyModel company) async {
    try {
      final either = await apiService.put(
        '/companies/profile', // Updating own company profile
        data: company.toJson(),
      );

      return either.fold(
        (failure) => throw _mapFailureToException(failure),
        (response) {
          if (response.success && response.data != null) {
            return CompanyModel.fromJson(response.data);
          }

          throw ServerException(
            message: response.message ?? 'Failed to update company',
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
          message: 'Failed to update company: ${e.toString()}');
    }
  }
}

