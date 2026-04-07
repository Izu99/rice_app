// lib/features/auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../routes/route_names.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/login_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController =
      TextEditingController(); // Can be email or phone
  final _passwordController = TextEditingController();
  final _identifierFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isPhoneLogin = true; // Default to phone login

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() {
    final state = context.read<AuthCubit>().state;
    if (state.savedIdentifier != null) {
      _identifierController.text = state.savedIdentifier!;
      // Auto-detect if it's email or phone
      _isPhoneLogin = !state.savedIdentifier!.contains('@');
    }
    if (state.savedPassword != null && state.rememberMe) {
      _passwordController.text = state.savedPassword!;
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      final identifier = _identifierController.text.trim();

      // Use the existing login method - backend will handle email/phone detection
      context.read<AuthCubit>().login(
            identifier:
                identifier, // Backend accepts either email or phone here
            password: _passwordController.text,
            rememberMe: context.read<AuthCubit>().state.rememberMe,
          );
    }
  }

  void _onForgotPassword() {
    _showForgotPasswordDialog();
  }

  void _showForgotPasswordDialog() {
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(SiStrings.resetPassword),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              SiStrings.enterPhoneForOtp,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: SiStrings.phoneNumber,
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(SiStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().requestPasswordReset(
                    phoneController.text.trim(),
                  );
            },
            child: Text(SiStrings.sendOtp),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.loginStatus != current.loginStatus ||
          previous.authStatus != current.authStatus ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        // Handle successful login
        if (state.authStatus == AuthStatus.authenticated) {
          if (state.user?.role == UserRole.admin) {
            context.go(RouteNames.adminDashboard);
          } else {
            context.go(RouteNames.home);
          }
        }

        // Handle login error
        if (state.loginStatus == LoginStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage!,
                maxLines: 5,
                overflow: TextOverflow.visible,
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }

        // Handle password reset
        if (state.passwordResetStatus == PasswordResetStatus.otpSent) {
          _showOtpDialog();
        }

        if (state.passwordResetStatus == PasswordResetStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('මුරපදය සාර්ථකව යාවත්කාලීන කරන ලදී.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<AuthCubit>().resetPasswordResetStatus();
        }
      },
      builder: (context, state) {
        return LoadingOverlay(
          isLoading: state.isLoading,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Language Toggle
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          await SiStrings.toggleLanguage();
                          setState(() {});
                        },
                        icon: const Icon(Icons.language, size: 20, color: AppColors.primary),
                        label: Text(
                          SiStrings.isSinhala ? 'English' : 'සිංහල',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Logo and Title
                    _buildHeader(),
                    const SizedBox(height: 48),

                    // Google Login Button
                    OutlinedButton.icon(
                      onPressed: () {
                        context.read<AuthCubit>().googleLogin();
                      },
                      icon: Image.asset(
                        'assets/icons/google_logo.png',
                        height: 24,
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.account_circle_outlined, color: AppColors.textHint, size: 24),
                      ),
                      label: Text(SiStrings.signInWithGoogle),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            SiStrings.or,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Login Form
                    LoginForm(
                      formKey: _formKey,
                      identifierController: _identifierController,
                      passwordController: _passwordController,
                      identifierFocusNode: _identifierFocusNode,
                      passwordFocusNode: _passwordFocusNode,
                      isPhoneLogin: _isPhoneLogin,
                      isPasswordVisible: state.isPasswordVisible,
                      rememberMe: state.rememberMe,
                      fieldErrors: state.fieldErrors,
                      onToggleLoginType: () {
                        setState(() {
                          _isPhoneLogin = !_isPhoneLogin;
                        });
                      },
                      onTogglePasswordVisibility: () {
                        context.read<AuthCubit>().togglePasswordVisibility();
                      },
                      onToggleRememberMe: (value) {
                        context.read<AuthCubit>().toggleRememberMe(value);
                      },
                      onLogin: _onLogin,
                      onForgotPassword: _onForgotPassword,
                    ),

                    const SizedBox(height: 32),

                    // Footer
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          SiStrings.welcomeBack,
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          SiStrings.signInToContinue,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // Register link
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              SiStrings.registerPrompt,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            TextButton(
              onPressed: () => context.go(RouteNames.register),
              child: Text(
                SiStrings.registerNow,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Version info
        Text(
          '${SiStrings.version} 1.0.0',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textHint,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Copyright
        Text(
          '© ${DateTime.now().year} ricemill',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textHint,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showOtpDialog() {
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final identifier = _identifierController.text.trim();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<AuthCubit>(),
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isOtpVerified =
                state.passwordResetStatus == PasswordResetStatus.otpVerified;

            return AlertDialog(
              title: Text(isOtpVerified ? SiStrings.newPassword : SiStrings.enterOtp),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isOtpVerified) ...[
                      Text(
                        'ඔබගේ $identifier අංකයට ලැබුණු OTP කේතය ඇතුළත් කරන්න',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          letterSpacing: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          hintText: '------',
                          counterText: '',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          context.read<AuthCubit>().resendOtp(identifier);
                        },
                        child: const Text('OTP නැවත යවන්න'),
                      ),
                    ] else ...[
                      TextField(
                        controller: newPasswordController,
                        obscureText: !state.isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: SiStrings.newPassword,
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              state.isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              context
                                  .read<AuthCubit>()
                                  .togglePasswordVisibility();
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: !state.isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: SiStrings.confirmPassword,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              state.isConfirmPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              context
                                  .read<AuthCubit>()
                                  .toggleConfirmPasswordVisibility();
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        state.errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    context.read<AuthCubit>().resetPasswordResetStatus();
                  },
                  child: Text(SiStrings.cancel),
                ),
                ElevatedButton(
                  onPressed: state.passwordResetStatus ==
                              PasswordResetStatus.verifyingOtp ||
                          state.passwordResetStatus ==
                              PasswordResetStatus.resettingPassword
                      ? null
                      : () {
                          if (!isOtpVerified) {
                            context.read<AuthCubit>().verifyOtp(
                                  phone: identifier,
                                  otp: otpController.text.trim(),
                                );
                          } else {
                            context.read<AuthCubit>().resetPassword(
                                  phone: identifier,
                                  otp: otpController.text.trim(),
                                  newPassword: newPasswordController.text,
                                  confirmPassword:
                                      confirmPasswordController.text,
                                );
                            if (state.passwordResetStatus ==
                                PasswordResetStatus.success) {
                              Navigator.pop(dialogContext);
                            }
                          }
                        },
                  child: state.passwordResetStatus ==
                              PasswordResetStatus.verifyingOtp ||
                          state.passwordResetStatus ==
                              PasswordResetStatus.resettingPassword
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isOtpVerified ? SiStrings.resetPassword : SiStrings.verify),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

