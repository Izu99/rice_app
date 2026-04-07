// lib/features/auth/presentation/cubit/auth_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../injection_container.dart' as di;
import '../../../home/presentation/cubit/dashboard_cubit.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../buy/presentation/cubit/buy_cubit.dart';
import '../../../buy/presentation/cubit/customer_cubit.dart';
import '../../../sell/presentation/cubit/sell_cubit.dart';
import '../../../stock/presentation/cubit/stock_cubit.dart';
import '../../../stock/presentation/cubit/milling_cubit.dart';
import '../../../reports/presentation/cubit/reports_cubit.dart';
import '../../../super_admin/presentation/cubit/admin_cubit.dart';
import '../../../customers/presentation/cubit/customers_cubit.dart';
import '../../../expenses/presentation/cubit/expenses_cubit.dart';
import '../../../price_management/presentation/cubit/price_management_cubit.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/utils/logger_utils.dart';
import 'auth_state.dart';

/// Auth Cubit - Manages authentication business logic
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  GoogleSignInAccount? _currentGoogleUser;

  AuthCubit({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(AuthState.initial()) {
    _initializeGoogleSignIn();
    checkAuthStatus();
  }

  /// Initialize Google Sign-In with required configuration
  Future<void> _initializeGoogleSignIn() async {
    // Note: Use the 'Web Client ID' from Google Cloud Console here as serverClientId.
    // This is required to obtain an idToken for backend verification.
    await _googleSignIn.initialize(
      serverClientId: '816656670559-ucfdqo2gn4h9gst50rtfi9sjlm8428ja.apps.googleusercontent.com',
    );
    
    // Listen to authentication events for reactive UI/State updates
    _googleSignIn.authenticationEvents.listen(
      _handleGoogleAuthEvent,
      onError: (error) => _handleGoogleAuthError(error),
    );

    // Try to recover a previous silent sign-in if any
    _googleSignIn.attemptLightweightAuthentication();
  }

  void _handleGoogleAuthEvent(GoogleSignInAuthenticationEvent? event) async {
    Log.auth('Google Auth Event: $event');
    if (event is GoogleSignInAuthenticationEventSignIn) {
      _currentGoogleUser = event.user;
      final user = event.user;
      // If we are not currently in a loading state for login,
      // this might be a background sign-in or lightweight auth
      if (state.loginStatus != LoginStatus.loading && state.authStatus != AuthStatus.authenticated) {
        final auth = await user.authentication;
        if (auth.idToken != null) {
          final result = await _authRepository.googleLogin(idToken: auth.idToken!);
          result.fold(
            (failure) => Log.e('Google Auto-Login failed: ${failure.message}', tag: 'AUTH'),
            (userEntity) {
              emit(state.copyWith(
                authStatus: AuthStatus.authenticated,
                user: userEntity,
                clearError: true,
              ));
              refreshUser();
            },
          );
        }
      }
    } else if (event is GoogleSignInAuthenticationEventSignOut) {
      _currentGoogleUser = null;
    }
  }

  void _handleGoogleAuthError(Object error) {
    Log.e('Google Auth Error: $error', tag: 'AUTH');
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
        Log.auth('User authenticated: ${user.name}, CompanyID: ${user.companyId}');
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

  /// Login with Google
  Future<void> googleLogin() async {
    try {
      emit(state.copyWith(
        loginStatus: LoginStatus.loading,
        clearError: true,
      ));

      // Use attemptLightweightAuthentication for "silent" sign-in check
      // This is the new way in 7.0+ instead of signInSilently()
      _googleSignIn.attemptLightweightAuthentication();
      
      // For explicit sign-in, use supportsAuthenticate check
      if (!_googleSignIn.supportsAuthenticate()) {
        emit(state.copyWith(
          loginStatus: LoginStatus.failure,
          errorMessage: 'Google Sign-In is not supported on this platform/configuration.',
        ));
        return;
      }

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );
      
      _currentGoogleUser = googleUser;
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        emit(state.copyWith(
          loginStatus: LoginStatus.failure,
          errorMessage: 'Failed to get ID token from Google',
        ));
        return;
      }

      final result = await _authRepository.googleLogin(idToken: idToken);

      await result.fold(
        (failure) async {
          // Check if message is related to account not found to show localized message
          String errorMsg = failure.message;
          if (errorMsg.contains('Account not found') || errorMsg.contains('administrator to register')) {
            errorMsg = SiStrings.accountNotFound;
          }
          
          emit(state.copyWith(
            loginStatus: LoginStatus.failure,
            errorMessage: errorMsg,
          ));
        },
        (user) async {
          final companyResult = await _authRepository.getCompany();
          final company = companyResult.fold((l) => null, (r) => r);

          emit(state.copyWith(
            loginStatus: LoginStatus.success,
            authStatus: AuthStatus.authenticated,
            user: user,
            company: company,
            clearError: true,
          ));
        },
      );
    } catch (e) {
      if (e is GoogleSignInException && e.code == GoogleSignInExceptionCode.canceled) {
        emit(state.copyWith(loginStatus: LoginStatus.initial));
        return;
      }
      emit(state.copyWith(
        loginStatus: LoginStatus.failure,
        errorMessage: 'Google Sign-In failed: ${e.toString()}',
      ));
    }
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

    // Sign out from Google if signed in
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      Log.w('Google Sign-Out error: $e', tag: 'AUTH');
    }

    final result = await _authRepository.logout();

    // Reset all session-based Cubits to clear stale data
    _resetAllCubits();

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

  /// Reset all Cubits that might contain user-specific data
  void _resetAllCubits() {
    try {
      // Clear API cache first to prevent stale role/user data on next login
      if (di.sl.isRegistered<ApiService>()) di.sl<ApiService>().clearCache();

      if (di.sl.isRegistered<DashboardCubit>()) di.sl<DashboardCubit>().reset();
      if (di.sl.isRegistered<ProfileCubit>()) di.sl<ProfileCubit>().reset();
      if (di.sl.isRegistered<BuyCubit>()) di.sl<BuyCubit>().reset();
      if (di.sl.isRegistered<CustomerCubit>()) di.sl<CustomerCubit>().reset();
      if (di.sl.isRegistered<CustomersCubit>()) di.sl<CustomersCubit>().reset();
      if (di.sl.isRegistered<SellCubit>()) di.sl<SellCubit>().reset();
      if (di.sl.isRegistered<StockCubit>()) di.sl<StockCubit>().reset();
      if (di.sl.isRegistered<MillingCubit>()) di.sl<MillingCubit>().reset();
      if (di.sl.isRegistered<ReportsCubit>()) di.sl<ReportsCubit>().reset();
      if (di.sl.isRegistered<AdminCubit>()) di.sl<AdminCubit>().reset();
      if (di.sl.isRegistered<ExpensesCubit>()) di.sl<ExpensesCubit>().reset();
      if (di.sl.isRegistered<PriceManagementCubit>()) di.sl<PriceManagementCubit>().reset();
    } catch (e) {
      Log.w('Error resetting cubits: $e', tag: 'AUTH');
    }
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

  /// Register a new company (Public)
  Future<void> registerCompany({
    required String name,
    required String address,
    required String phone,
    required String ownerName,
    required String ownerPhone,
    required String ownerPassword,
    String? email,
    String? registrationNumber,
    String? district,
  }) async {
    emit(state.copyWith(
      registerStatus: RegisterStatus.loading,
      clearError: true,
    ));

    final result = await _authRepository.publicRegisterCompany(
      name: name,
      address: address,
      phone: phone,
      ownerName: ownerName,
      ownerPhone: ownerPhone,
      ownerPassword: ownerPassword,
      email: email,
      registrationNumber: registrationNumber,
      district: district,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          registerStatus: RegisterStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (company) {
        emit(state.copyWith(
          registerStatus: RegisterStatus.success,
          successMessage:
              'Company "${company.name}" registered successfully! Your account is pending admin approval.',
          clearError: true,
        ));
      },
    );
  }
}
