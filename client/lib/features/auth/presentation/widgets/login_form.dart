// lib/features/auth/presentation/widgets/login_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../core/shared_widgets/custom_button.dart';
import '../../../../core/shared_widgets/custom_text_field.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController identifierController; // Can be email or phone
  final TextEditingController passwordController;
  final FocusNode identifierFocusNode;
  final FocusNode passwordFocusNode;
  final bool isPhoneLogin;
  final bool isPasswordVisible;
  final bool rememberMe;
  final Map<String, String>? fieldErrors;
  final VoidCallback onToggleLoginType;
  final VoidCallback onTogglePasswordVisibility;
  final ValueChanged<bool> onToggleRememberMe;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.identifierController,
    required this.passwordController,
    required this.identifierFocusNode,
    required this.passwordFocusNode,
    required this.isPhoneLogin,
    required this.isPasswordVisible,
    required this.rememberMe,
    this.fieldErrors,
    required this.onToggleLoginType,
    required this.onTogglePasswordVisibility,
    required this.onToggleRememberMe,
    required this.onLogin,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Identifier Field (Email or Phone) - Auto-detect
          _buildIdentifierField(),
          const SizedBox(height: 20),

          // Password Field
          _buildPasswordField(),
          const SizedBox(height: 16),

          // Remember Me & Forgot Password Row
          _buildOptionsRow(),
          const SizedBox(height: 32),

          // Login Button
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildIdentifierField() {
    return CustomTextField(
      controller: identifierController,
      focusNode: identifierFocusNode,
      label: 'Phone or Email',
      hint: 'ඔබගේ දුරකථන අංකය හෝ Email එක ඇතුළත් කරන්න',
      prefixIcon: Icons.person,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      errorText: fieldErrors?['identifier'],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'දුරකථන අංකය හෝ Email එක අවශ්‍යයි';
        }

        final isEmail = value.contains('@');
        final isPhone = value.replaceAll(RegExp(r'[^\d]'), '').length >= 9;

        if (!isEmail && !isPhone) {
          return 'නිවැරදි දුරකථන අංකයක් හෝ Email එකක් ඇතුළත් කරන්න';
        }
        return null;
      },
      onSubmitted: (_) {
        FocusScope.of(identifierFocusNode.context!)
            .requestFocus(passwordFocusNode);
      },
    );
  }

  Widget _buildPasswordField() {
    return CustomTextField(
      controller: passwordController,
      focusNode: passwordFocusNode,
      label: SiStrings.password,
      hint: 'ඔබගේ මුරපදය ඇතුළත් කරන්න',
      prefixIcon: Icons.lock_outline,
      obscureText: !isPasswordVisible,
      textInputAction: TextInputAction.done,
      errorText: fieldErrors?['password'],
      suffix: IconButton(
        icon: Icon(
          isPasswordVisible ? Icons.visibility_off : Icons.visibility,
          color: AppColors.textSecondary,
        ),
        onPressed: onTogglePasswordVisibility,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'මුරපදය අවශ්‍යයි';
        }
        if (value.length < 6) {
          return 'මුරපදය අවම වශයෙන් අක්ෂර 6ක් විය යුතුය';
        }
        return null;
      },
      onSubmitted: (_) => onLogin(),
    );
  }

  Widget _buildOptionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember Me Checkbox
        Flexible(
          child: InkWell(
            onTap: () => onToggleRememberMe(!rememberMe),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: rememberMe,
                      onChanged: (value) => onToggleRememberMe(value ?? false),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      SiStrings.rememberMe,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Forgot Password
        Flexible(
          child: TextButton(
            onPressed: onForgotPassword,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            ),
            child: Text(
              SiStrings.forgotPassword,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return CustomButton(
      label: SiStrings.login,
      onPressed: onLogin,
      icon: Icons.login,
      height: 56,
    );
  }
}

/// Phone number formatter for display (e.g., 071 234 5678)
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 3 || i == 6) {
        buffer.write(' ');
      }
      buffer.write(digitsOnly[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
