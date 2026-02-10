// lib/features/auth/presentation/cubit/auth_state.dart

import 'package:equatable/equatable.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../../data/models/company_model.dart';

/// Auth status enum
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Login status enum
enum LoginStatus {
  initial,
  loading,
  success,
  failure,
}

/// Password reset status
enum PasswordResetStatus {
  initial,
  sendingOtp,
  otpSent,
  verifyingOtp,
  otpVerified,
  resettingPassword,
  success,
  failure,
}

/// Auth State - Manages authentication state
class AuthState extends Equatable {
  final AuthStatus authStatus;
  final LoginStatus loginStatus;
  final PasswordResetStatus passwordResetStatus;
  final UserEntity? user;
  final CompanyModel? company;
  final String? token;
  final String? errorMessage;
  final String? successMessage;
  final Map<String, String>? fieldErrors;
  final bool rememberMe;
  final String? savedIdentifier; // Can be email or phone
  final String? savedPhone; // Keep for backward compatibility
  final String? savedPassword;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;

  const AuthState({
    this.authStatus = AuthStatus.initial,
    this.loginStatus = LoginStatus.initial,
    this.passwordResetStatus = PasswordResetStatus.initial,
    this.user,
    this.company,
    this.token,
    this.errorMessage,
    this.successMessage,
    this.fieldErrors,
    this.rememberMe = false,
    this.savedIdentifier,
    this.savedPhone,
    this.savedPassword,
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
  });

  /// Initial state
  factory AuthState.initial() {
    return const AuthState();
  }

  /// Check if authenticated
  bool get isAuthenticated => authStatus == AuthStatus.authenticated;

  /// Check if loading
  bool get isLoading =>
      authStatus == AuthStatus.loading || loginStatus == LoginStatus.loading;

  /// Check if login failed
  bool get hasLoginError => loginStatus == LoginStatus.failure;

  /// Check if has any error
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  /// Check if has field errors
  bool get hasFieldErrors => fieldErrors != null && fieldErrors!.isNotEmpty;

  /// Get field error
  String? getFieldError(String field) => fieldErrors?[field];

  /// Check if user is admin (global controller)
  bool get isAdmin => user?.isAdmin ?? false;

  /// Copy with method
  AuthState copyWith({
    AuthStatus? authStatus,
    LoginStatus? loginStatus,
    PasswordResetStatus? passwordResetStatus,
    UserEntity? user,
    CompanyModel? company,
    String? token,
    String? errorMessage,
    String? successMessage,
    Map<String, String>? fieldErrors,
    bool? rememberMe,
    String? savedIdentifier,
    String? savedPhone,
    String? savedPassword,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      authStatus: authStatus ?? this.authStatus,
      loginStatus: loginStatus ?? this.loginStatus,
      passwordResetStatus: passwordResetStatus ?? this.passwordResetStatus,
      user: clearUser ? null : (user ?? this.user),
      company: clearUser ? null : (company ?? this.company),
      token: clearUser ? null : (token ?? this.token),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: successMessage,
      fieldErrors: clearError ? null : (fieldErrors ?? this.fieldErrors),
      rememberMe: rememberMe ?? this.rememberMe,
      savedIdentifier: savedIdentifier ?? this.savedIdentifier,
      savedPhone: savedPhone ?? this.savedPhone,
      savedPassword: savedPassword ?? this.savedPassword,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isConfirmPasswordVisible:
          isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
    );
  }

  @override
  List<Object?> get props => [
        authStatus,
        loginStatus,
        passwordResetStatus,
        user,
        company,
        token,
        errorMessage,
        successMessage,
        fieldErrors,
        rememberMe,
        savedIdentifier,
        savedPhone,
        savedPassword,
        isPasswordVisible,
        isConfirmPasswordVisible,
      ];

  @override
  String toString() {
    return 'AuthState(authStatus: $authStatus, loginStatus: $loginStatus, user: ${user?.name})';
  }
}
