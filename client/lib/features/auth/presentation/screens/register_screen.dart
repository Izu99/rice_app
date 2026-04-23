import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/shared_widgets/custom_text_field.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../core/shared_widgets/h_app_bar.dart';
import '../../../../core/constants/districts.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../routes/route_names.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Company Details
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  String? _selectedDistrict;

  // Owner Details
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyPhoneController.dispose();
    _companyEmailController.dispose();
    _registrationNumberController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      context.read<AuthCubit>().registerCompany(
            name: _companyNameController.text.trim(),
            address: _companyAddressController.text.trim(),
            phone: _companyPhoneController.text.trim(),
            ownerName: _ownerNameController.text.trim(),
            ownerPhone: _ownerPhoneController.text.trim(),
            ownerPassword: _passwordController.text,
            email: _companyEmailController.text.trim().isEmpty
                ? null
                : _companyEmailController.text.trim(),
            registrationNumber:
                _registrationNumberController.text.trim().isEmpty
                    ? null
                    : _registrationNumberController.text.trim(),
            district: _selectedDistrict,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.registerStatus == RegisterStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage ?? 'Registration successful'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 5),
            ),
          );
          context.go(RouteNames.login);
        } else if (state.registerStatus == RegisterStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Registration failed'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return LoadingOverlay(
          isLoading: state.registerStatus == RegisterStatus.loading,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                              'Company Information', Icons.business_rounded),
                          const SizedBox(height: 12),
                          _buildCompanyDetailsCard(),
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                              'Owner Details', Icons.person_rounded),
                          const SizedBox(height: 12),
                          _buildOwnerDetailsCard(),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Security', Icons.lock_rounded),
                          const SizedBox(height: 12),
                          _buildSecurityCard(),
                          const SizedBox(height: 32),
                          _buildRegisterButton(),
                          const SizedBox(height: 16),
                          _buildLoginLink(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return HSliverAppBar(
      expandedHeight: 180.0,
      pinned: true,
      onBack: () => context.go(RouteNames.login),
      title: SiStrings.registerCompany,
      subtitle: 'Join our platform today',
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.business_center_rounded,
                  size: 150,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    Icon(
                      Icons.app_registration_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.h4.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C1C2E),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyDetailsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomTextField(
              controller: _companyNameController,
              label: 'Company Name',
              hint: 'Enter company name',
              prefixIcon: Icons.business_rounded,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _companyAddressController,
              label: 'Company Address',
              hint: 'Enter address',
              prefixIcon: Icons.location_on_rounded,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDistrict,
              decoration: InputDecoration(
                labelText: 'District',
                prefixIcon: const Icon(Icons.map_rounded),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE8E8EE)),
                ),
              ),
              items: SriLankanDistricts.allDistricts.map((district) {
                return DropdownMenuItem(
                  value: district,
                  child: Text(district),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedDistrict = value),
              validator: (value) => value == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _companyPhoneController,
              label: 'Company Phone',
              hint: '07x xxxxxxx',
              prefixIcon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _companyEmailController,
              label: 'Company Email (Optional)',
              hint: 'company@example.com',
              prefixIcon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _registrationNumberController,
              label: 'Registration Number (Optional)',
              hint: 'BR Number',
              prefixIcon: Icons.assignment_ind_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerDetailsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomTextField(
              controller: _ownerNameController,
              label: 'Owner Full Name',
              hint: 'Enter owner name',
              prefixIcon: Icons.person_rounded,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _ownerPhoneController,
              label: 'Owner Phone Number',
              hint: 'Login phone number',
              prefixIcon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Enter password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (value.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Re-enter password',
              prefixIcon: Icons.lock_rounded,
              obscureText: _obscureConfirmPassword,
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  size: 20,
                ),
                onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _onRegisterPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(
          SiStrings.registerNow,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            SiStrings.alreadyHaveCompany,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
          TextButton(
            onPressed: () => context.go(RouteNames.login),
            child: Text(
              SiStrings.login,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
