// lib/features/auth/presentation/cubit/auth_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Auth Cubit - Manages authentication business logic
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(AuthState.initial()) {
    checkAuthStatus();
  }

  /// Check if user is already logged in
  Future<void> checkAuthStatus() async {
    // Try to load from cache first for immediate UI update
    final cachedUserResult = await _authRepository.getCurrentUser();
    final cachedUser = cachedUserResult.fold((l) => null, (r) => r);

    if (cachedUser != null) {
      final cachedCompanyResult = await _authRepository.getCompany();
      final cachedCompany = cachedCompanyResult.fold((l) => null, (r) => r);

      emit(state.copyWith(
        authStatus: AuthStatus.authenticated,
        user: cachedUser,
        company: cachedCompany,
      ));
    } else {
      emit(state.copyWith(authStatus: AuthStatus.loading));
    }

    final isLoggedInResult = await _authRepository.isLoggedIn();

    await isLoggedInResult.fold(
      (failure) async {
        emit(state.copyWith(
          authStatus: AuthStatus.unauthenticated,
          clearUser: true,
          clearError: true,
        ));
      },
      (isLoggedIn) async {
        if (isLoggedIn) {
          // Verify with server in background
          final userResult = await _authRepository.getCurrentUser();
          await userResult.fold(
            (failure) async {
              // If background check fails but we have cache, keep it
              // unless it's an AuthFailure (invalid token)
              if (state.user == null) {
                emit(state.copyWith(
                  authStatus: AuthStatus.unauthenticated,
                  errorMessage: failure.message,
                ));
              }
            },
            (user) async {
              final companyResult = await _authRepository.getCompany();
              final company = companyResult.fold((l) => null, (r) => r);

              emit(state.copyWith(
                authStatus: AuthStatus.authenticated,
                user: user,
                company: company,
                clearError: true,
              ));
            },
          );
        } else {
          // Not logged in
          await _loadSavedCredentials();
          emit(state.copyWith(
            authStatus: AuthStatus.unauthenticated,
            clearUser: true,
            clearError: true,
          ));
        }
      },
    );
  }

  /// Load saved credentials for auto-fill
  Future<void> _loadSavedCredentials() async {
    final credentialsResult = await _authRepository.getSavedCredentials();

    credentialsResult.fold(
      (failure) {
        // No saved credentials, ignore
      },
      (credentials) {
        if (credentials != null) {
          emit(state.copyWith(
            savedPhone: credentials['phone'],
            savedPassword: credentials['password'],
            rememberMe: credentials['rememberMe'] ?? false,
          ));
        }
      },
    );
  }

  /// Login with identifier (email or phone) and password
  Future<void> login({
    required String identifier, // Can be email or phone
    required String password,
    bool rememberMe = false,
  }) async {
    // Validate input
    final fieldErrors = _validateLoginInput(identifier, password);
    if (fieldErrors.isNotEmpty) {
      emit(state.copyWith(
        loginStatus: LoginStatus.failure,
        fieldErrors: fieldErrors,
      ));
      return;
    }

    emit(state.copyWith(
      loginStatus: LoginStatus.loading,
      clearError: true,
    ));

    // Determine if identifier is email or phone
    final loginData = _isEmail(identifier)
        ? {'email': identifier, 'password': password}
        : {'phone': identifier, 'password': password};

    final result = await _authRepository.login(
      phone:
          identifier, // Keep for backward compatibility, but send proper data
      password: password,
      rememberMe: rememberMe,
    );

    await result.fold(
      (failure) async {
        emit(state.copyWith(
          loginStatus: LoginStatus.failure,
          errorMessage: failure.message,
          authStatus: AuthStatus.unauthenticated,
        ));
      },
      (user) async {
        // Get company
        print(
            '🔐 [AuthCubit] User authenticated: ${user.name}, CompanyID: ${user.companyId}');
        final companyResult = await _authRepository.getCompany();
        final company = companyResult.fold((l) => null, (r) => r);

        emit(state.copyWith(
          loginStatus: LoginStatus.success,
          authStatus: AuthStatus.authenticated,
          user: user,
          company: company,
          rememberMe: rememberMe,
          savedIdentifier: identifier, // Save the identifier used for login
          clearError: true,
        ));
      },
    );
  }

  /// Check if string is an email
  bool _isEmail(String value) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(value);
  }

  /// Validate login input
  Map<String, String> _validateLoginInput(String identifier, String password) {
    final errors = <String, String>{};

    // Validate identifier (email or phone)
    if (identifier.isEmpty) {
      errors['identifier'] = 'Email or phone number is required';
    } else {
      // Check if it's an email
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      final isEmail = emailRegex.hasMatch(identifier);

      if (isEmail) {
        // Email validation - already done by regex
      } else {
        // Phone validation
        final cleanPhone = identifier.replaceAll(RegExp(r'[^\d]'), '');
        if (cleanPhone.length < 9 || cleanPhone.length > 12) {
          errors['identifier'] = 'Invalid phone number format';
        }
      }
    }

    // Validate password
    if (password.isEmpty) {
      errors['password'] = 'Password is required';
    } else if (password.length < 6) {
      errors['password'] = 'Password must be at least 6 characters';
    }

    return errors;
  }

  /// Logout user
  Future<void> logout() async {
    emit(state.copyWith(authStatus: AuthStatus.loading));

    final result = await _authRepository.logout();

    result.fold(
      (failure) {
        // Even on failure, clear local state
        emit(state.copyWith(
          authStatus: AuthStatus.unauthenticated,
          clearUser: true,
          clearError: true,
        ));
      },
      (_) {
        emit(state.copyWith(
          authStatus: AuthStatus.unauthenticated,
          loginStatus: LoginStatus.initial,
          clearUser: true,
          clearError: true,
        ));
      },
    );
  }

  /// Request password reset OTP
  Future<void> requestPasswordReset(String phone) async {
    // Validate phone
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.isEmpty || cleanPhone.length < 9) {
      emit(state.copyWith(
        passwordResetStatus: PasswordResetStatus.failure,
        errorMessage: 'Please enter a valid phone number',
      ));
      return;
    }

    emit(state.copyWith(
      passwordResetStatus: PasswordResetStatus.sendingOtp,
      clearError: true,
    ));

    final result = await _authRepository.requestPasswordReset(phone);

    result.fold(
      (failure) {
        emit(state.copyWith(
          passwordResetStatus: PasswordResetStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (_) {
        emit(state.copyWith(
          passwordResetStatus: PasswordResetStatus.otpSent,
          successMessage: 'OTP sent to your phone',
        ));
      },
    );
  }

  /// Verify OTP
  Future<void> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    if (otp.isEmpty || otp.length < 4) {
      emit(state.copyWith(
        passwordResetStatus: PasswordResetStatus.failure,
        errorMessage: 'Please enter a valid OTP',
      ));
      return;
    }

    emit(state.copyWith(
      passwordResetStatus: PasswordResetStatus.verifyingOtp,
      clearError: true,
    ));

    final result = await _authRepository.verifyOtp(phone: phone, otp: otp);

    result.fold(
      (failure) {
        emit(state.copyWith(
          passwordResetStatus: PasswordResetStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (_) {
        emit(state.copyWith(
          passwordResetStatus: PasswordResetStatus.otpVerified,
          successMessage: 'OTP verified successfully',
        ));
      },
    );
  }

  /// Reset password
  Future<void> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // Validate passwords
    if (newPassword.isEmpty || newPassword.length < 6) {
      emit(state.copyWith(
        passwordResetStatus: PasswordResetStatus.failure,
        errorMessage: 'Password must be at least 6 characters',
      ));
      return;
    }

    if (newPassword != confirmPassword) {
      emit(state.copyWith(
        passwordResetStatus: PasswordResetStatus.failure,
        errorMessage: 'Passwords do not match',
      ));
      return;
    }

    emit(state.copyWith(
      passwordResetStatus: PasswordResetStatus.resettingPassword,
      clearError: true,
    ));

    final result = await _authRepository.resetPassword(
      phone: phone,
      otp: otp,
      newPassword: newPassword,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          passwordResetStatus: PasswordResetStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (_) {
        emit(state.copyWith(
          passwordResetStatus: PasswordResetStatus.success,
          successMessage: 'Password reset successfully. Please login.',
        ));
      },
    );
  }

  /// Resend OTP
  Future<void> resendOtp(String phone) async {
    emit(state.copyWith(
      passwordResetStatus: PasswordResetStatus.sendingOtp,
      clearError: true,
    ));

    final result = await _authRepository.resendOtp(phone);

    result.fold(
      (failure) {
        emit(state.copyWith(
          passwordResetStatus:
              PasswordResetStatus.otpSent, // Keep in OTP sent state
          errorMessage: failure.message,
        ));
      },
      (_) {
        emit(state.copyWith(
          passwordResetStatus: PasswordResetStatus.otpSent,
          successMessage: 'OTP resent successfully',
        ));
      },
    );
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  /// Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    emit(state.copyWith(
      isConfirmPasswordVisible: !state.isConfirmPasswordVisible,
    ));
  }

  /// Toggle remember me
  void toggleRememberMe(bool value) {
    emit(state.copyWith(rememberMe: value));
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  /// Reset password reset status
  void resetPasswordResetStatus() {
    emit(state.copyWith(
      passwordResetStatus: PasswordResetStatus.initial,
      clearError: true,
    ));
  }

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    String? email,
    String? avatar,
  }) async {
    emit(state.copyWith(authStatus: AuthStatus.loading));

    final result = await _authRepository.updateProfile(
      name: name,
      email: email,
      avatar: avatar,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          authStatus: AuthStatus.authenticated,
          errorMessage: failure.message,
        ));
      },
      (user) {
        emit(state.copyWith(
          authStatus: AuthStatus.authenticated,
          user: user,
          successMessage: 'Profile updated successfully',
          clearError: true,
        ));
      },
    );
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // Validate
    if (newPassword.length < 6) {
      emit(state.copyWith(
        errorMessage: 'Password must be at least 6 characters',
      ));
      return;
    }

    if (newPassword != confirmPassword) {
      emit(state.copyWith(
        errorMessage: 'Passwords do not match',
      ));
      return;
    }

    emit(state.copyWith(authStatus: AuthStatus.loading, clearError: true));

    final result = await _authRepository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          authStatus: AuthStatus.authenticated,
          errorMessage: failure.message,
        ));
      },
      (_) {
        emit(state.copyWith(
          authStatus: AuthStatus.authenticated,
          successMessage: 'Password changed successfully',
          clearError: true,
        ));
      },
    );
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    final userResult = await _authRepository.getCurrentUser();

    userResult.fold(
      (failure) {
        // Ignore refresh failures
      },
      (user) {
        emit(state.copyWith(user: user));
      },
    );
  }
}
