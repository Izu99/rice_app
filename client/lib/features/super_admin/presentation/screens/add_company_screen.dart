import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/shared_widgets/custom_text_field.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../data/models/company_model.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';

class AddCompanyScreen extends StatefulWidget {
  final String? companyId; // If provided, edit mode

  const AddCompanyScreen({super.key, this.companyId});

  @override
  State<AddCompanyScreen> createState() => _AddCompanyScreenState();
}

class _AddCompanyScreenState extends State<AddCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _registrationNumberController = TextEditingController();

  bool _isEditMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  CompanyModel? _editingCompany;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.companyId != null;

    if (_isEditMode) {
      _loadCompanyData();
    }
  }

  void _loadCompanyData() {
    final company =
        context.read<AdminCubit>().getCompanyById(widget.companyId!);
    if (company != null) {
      _editingCompany = company;
      _nameController.text = company.name;
      _ownerNameController.text = company.ownerName ?? '';
      _emailController.text = company.email ?? '';
      _phoneController.text = company.phone;
      _addressController.text = company.address;
      _registrationNumberController.text = company.registrationNumber ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _registrationNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Company' : 'Add New Company'),
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state.status == AdminStatus.success &&
              state.successMessage != null) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.success,
              ),
            );

            // Show admin credentials dialog if available
            if (state.lastCreatedAdminCredentials != null) {
              _showAdminCredentialsDialog(
                  context, state.lastCreatedAdminCredentials!);
            } else {
              context.read<AdminCubit>().clearMessages();
              context.pop();
            }
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
            context.read<AdminCubit>().clearError();
          }
        },
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: state.status == AdminStatus.creating ||
                state.status == AdminStatus.updating,
            message:
                _isEditMode ? 'Updating company...' : 'Creating company...',
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    _buildHeaderCard(),
                    const SizedBox(height: AppDimensions.paddingL),

                    // Company Information Section
                    _buildSectionTitle('Company Information'),
                    const SizedBox(height: AppDimensions.paddingM),
                    _buildCompanyInfoSection(),
                    const SizedBox(height: AppDimensions.paddingL),

                    // Owner Information Section
                    _buildSectionTitle('Owner Information'),
                    const SizedBox(height: AppDimensions.paddingM),
                    _buildOwnerInfoSection(),
                    const SizedBox(height: AppDimensions.paddingL),

                    // Login Credentials Section (only for new company)
                    if (!_isEditMode) ...[
                      _buildSectionTitle('Login Credentials'),
                      const SizedBox(height: AppDimensions.paddingM),
                      _buildCredentialsSection(),
                      const SizedBox(height: AppDimensions.paddingL),
                    ],

                    // Additional Information Section
                    _buildSectionTitle('Additional Information'),
                    const SizedBox(height: AppDimensions.paddingM),
                    _buildAdditionalInfoSection(),
                    const SizedBox(height: AppDimensions.paddingXL),

                    // Submit Button
                    _buildSubmitButton(),
                    const SizedBox(height: AppDimensions.paddingXL),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.adminPrimary,
            AppColors.adminPrimary.withAlpha(204),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Icon(
              _isEditMode ? Icons.edit_note : Icons.add_business,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditMode ? 'Edit Company Details' : 'Register New Company',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEditMode
                      ? 'Update company information below'
                      : 'Fill in the details to create a new rice mill company',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withAlpha(229),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCompanyInfoSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomTextField(
            controller: _nameController,
            label: 'Company Name',
            hint: 'Enter rice mill company name',
            prefixIcon: Icons.business,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Company name is required' : null,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          CustomTextField(
            controller: _registrationNumberController,
            label: 'Registration Number',
            hint: 'Business registration number (optional)',
            prefixIcon: Icons.numbers,
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerInfoSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomTextField(
            controller: _ownerNameController,
            label: 'Owner Name',
            hint: 'Enter owner full name',
            prefixIcon: Icons.person,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Owner name is required' : null,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          CustomTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'Enter email address',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: null,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          CustomTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: 'Enter phone number',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
            validator: (value) =>
                value?.isEmpty ?? true ? 'Phone number is required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Banner
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(26),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(color: Colors.blue.withAlpha(77)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'These credentials will be used by the company admin to login',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          CustomTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter password',
            prefixIcon: Icons.lock,
            obscureText: _obscurePassword,
            suffix: IconButton(
              icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) => (value?.length ?? 0) < 6
                ? 'Password must be at least 6 characters'
                : null,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            suffix: IconButton(
              icon: Icon(_obscureConfirmPassword
                  ? Icons.visibility
                  : Icons.visibility_off),
              onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomTextField(
            controller: _addressController,
            label: 'Address',
            hint: 'Enter company address (optional)',
            prefixIcon: Icons.location_on,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.adminPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isEditMode ? Icons.save : Icons.add_business,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              _isEditMode ? 'Update Company' : 'Create Company',
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_isEditMode && _editingCompany != null) {
        _updateCompany();
      } else {
        _createCompany();
      }
    }
  }

  void _createCompany() {
    context.read<AdminCubit>().createCompany(
          name: _nameController.text.trim(),
          ownerName: _ownerNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          address: _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
          registrationNumber:
              _registrationNumberController.text.trim().isNotEmpty
                  ? _registrationNumberController.text.trim()
                  : null,
        );
  }

  void _updateCompany() {
    final updatedCompany = _editingCompany!.copyWith(
      name: _nameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      registrationNumber: _registrationNumberController.text.trim().isNotEmpty
          ? _registrationNumberController.text.trim()
          : null,
    );

    context.read<AdminCubit>().updateCompany(updatedCompany);
  }

  void _showAdminCredentialsDialog(
      BuildContext context, AdminCredentials credentials) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Company Created Successfully',
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please share these login credentials with the company admin:',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppDimensions.paddingM),

              // Credentials Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildCredentialRow('Name', credentials.name),
                    const Divider(height: 16),
                    _buildCredentialRow('Email', credentials.email),
                    const Divider(height: 16),
                    _buildCredentialRow('Phone', credentials.phone),
                    const Divider(height: 16),
                    _buildCredentialRow('Password', credentials.password),
                    const Divider(height: 16),
                    _buildCredentialRow('Role', credentials.role),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.paddingM),
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingS),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(26),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  border: Border.all(color: Colors.orange.withAlpha(77)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        size: 20, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please save these credentials securely. They will not be shown again.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AdminCubit>().clearMessages();
              context.pop();
            },
            child: const Text('Done'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Copy all credentials to clipboard
              final credentialsText = '''
Company Admin Credentials:

Name: ${credentials.name}
Email: ${credentials.email}
Phone: ${credentials.phone}
Password: ${credentials.password}
Role: ${credentials.role}

Please share these credentials with the company admin securely.
''';
              Clipboard.setData(ClipboardData(text: credentialsText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Credentials copied to clipboard'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

