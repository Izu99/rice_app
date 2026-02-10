// lib/domain/repositories/auth_repository.dart

import 'package:dartz/dartz.dart';
import '../../core/constants/enums.dart';
import '../../core/errors/failures.dart';
import '../../data/models/company_model.dart';
import '../entities/user_entity.dart';

/// Abstract repository interface for authentication operations
/// This defines the contract that any auth repository implementation must follow
abstract class AuthRepository {
  /// Login with phone number and password
  ///
  /// Returns [UserEntity] on success or [Failure] on error
  ///
  /// Parameters:
  /// - [phone]: User's phone number
  /// - [password]: User's password
  /// - [rememberMe]: Whether to save credentials for auto-login
  Future<Either<Failure, UserEntity>> login({
    required String phone,
    required String password,
    bool rememberMe = false,
  });

  /// Register a new user
  ///
  /// Returns [UserEntity] on success or [Failure] on error
  ///
  /// Parameters:
  /// - [name]: User's full name
  /// - [phone]: User's phone number
  /// - [password]: User's password
  /// - [companyId]: Company ID to associate the user with
  /// - [role]: User's role (defaults to operator)
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String phone,
    required String password,
    required String companyId,
    UserRole role = UserRole.operator,
  });

  /// Logout the current user
  ///
  /// Clears all local user data and tokens
  Future<Either<Failure, void>> logout();

  /// Check if user is currently logged in
  ///
  /// Returns true if user has valid session
  Future<Either<Failure, bool>> isLoggedIn();

  /// Get the currently logged in user
  ///
  /// Returns [UserEntity] if logged in, or [Failure] if not
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Update user profile
  ///
  /// Returns updated [UserEntity] on success
  Future<Either<Failure, UserEntity>> updateProfile({
    String? name,
    String? email,
    String? avatar,
  });

  /// Change user password
  ///
  /// Parameters:
  /// - [currentPassword]: Current password for verification
  /// - [newPassword]: New password to set
  Future<Either<Failure, bool>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Request password reset OTP
  ///
  /// Sends OTP to the given phone number
  Future<Either<Failure, bool>> requestPasswordReset(String phone);

  /// Verify OTP code
  ///
  /// Parameters:
  /// - [phone]: Phone number that received the OTP
  /// - [otp]: OTP code to verify
  Future<Either<Failure, bool>> verifyOtp({
    required String phone,
    required String otp,
  });

  /// Reset password with OTP
  ///
  /// Parameters:
  /// - [phone]: Phone number
  /// - [otp]: Verified OTP code
  /// - [newPassword]: New password to set
  Future<Either<Failure, bool>> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  });

  /// Resend OTP code
  ///
  /// Sends a new OTP to the given phone number
  Future<Either<Failure, bool>> resendOtp(String phone);

  /// Get saved authentication token
  ///
  /// Returns the JWT token if available
  Future<Either<Failure, String?>> getToken();

  /// Refresh authentication token
  ///
  /// Returns updated [UserEntity] with new tokens
  Future<Either<Failure, UserEntity>> refreshToken();

  /// Get saved login credentials (if remember me was enabled)
  ///
  /// Returns map with 'phone', 'password', and 'rememberMe' keys
  Future<Either<Failure, Map<String, dynamic>?>> getSavedCredentials();

  /// Get current user's company
  ///
  /// Returns [CompanyModel] if available
  Future<Either<Failure, CompanyModel?>> getCompany();

  /// Update FCM token for push notifications
  ///
  /// Parameters:
  /// - [fcmToken]: Firebase Cloud Messaging token
  Future<Either<Failure, bool>> updateFcmToken(String fcmToken);

  /// Check if phone number is already registered
  ///
  /// Returns true if phone exists in the system
  Future<Either<Failure, bool>> isPhoneRegistered(String phone);

  /// Get last sync time
  ///
  /// Returns the last time data was synced with server
  Future<Either<Failure, DateTime?>> getLastSyncTime();

  /// Save last sync time
  ///
  /// Records the current sync time
  Future<Either<Failure, void>> saveLastSyncTime(DateTime dateTime);

  /// Update company details
  ///
  /// Returns updated [CompanyModel] on success
  Future<Either<Failure, CompanyModel>> updateCompany({
    required CompanyModel company,
  });
}
