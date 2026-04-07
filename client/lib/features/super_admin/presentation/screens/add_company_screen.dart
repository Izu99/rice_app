import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/shared_widgets/custom_text_field.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../core/constants/districts.dart';
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

  String? _selectedDistrict;
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
      _selectedDistrict = company.district;
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
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Company' : 'Add New Company'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    _buildHeaderCard(),
                    const SizedBox(height: 24),

                    // Company Information Section
                    _buildSectionHeader('Company Information'),
                    const SizedBox(height: 12),
                    _buildCompanyInfoSection(),
                    const SizedBox(height: 24),

                    // Owner Information Section
                    _buildSectionHeader('Owner Information'),
                    const SizedBox(height: 12),
                    _buildOwnerInfoSection(),
                    const SizedBox(height: 24),

                    // Login Credentials Section (only for new company)
                    if (!_isEditMode) ...[
                      _buildSectionHeader('Login Credentials'),
                      const SizedBox(height: 12),
                      _buildCredentialsSection(),
                      const SizedBox(height: 24),
                    ],

                    // Additional Information Section
                    _buildSectionHeader('Additional Information'),
                    const SizedBox(height: 12),
                    _buildAdditionalInfoSection(),
                    const SizedBox(height: 32),

                    // Submit Button
                    _buildSubmitButton(),
                    const SizedBox(height: 40),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.adminPrimary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.adminPrimary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              _isEditMode ? Icons.edit_document : Icons.add_business_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditMode ? 'Update Company' : 'Register New Company',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEditMode
                      ? 'Modify existing company records'
                      : 'Create a new rice mill profile',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF444466),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return _buildSectionChip(label);
  }

  Widget _buildCompanyInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomTextField(
            controller: _nameController,
            label: 'Company Name',
            hint: 'Enter company name',
            prefixIcon: Icons.business_rounded,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Company name is required' : null,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _registrationNumberController,
            label: 'Registration Number',
            hint: 'Enter registration number (optional)',
            prefixIcon: Icons.badge_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomTextField(
            controller: _ownerNameController,
            label: 'Owner Full Name',
            hint: 'Enter owner name',
            prefixIcon: Icons.person_outline_rounded,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Owner name is required' : null,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'Enter email (optional)',
            prefixIcon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: 'Enter contact number',
            prefixIcon: Icons.phone_outlined,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_rounded, size: 20, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Company admin will use these to login.',
                    style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _passwordController,
            label: 'New Password',
            hint: 'Min. 6 characters',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) => (value?.length ?? 0) < 6
                ? 'Password must be at least 6 characters'
                : null,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter password',
            prefixIcon: Icons.lock_clock_outlined,
            obscureText: _obscureConfirmPassword,
            suffix: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
              ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // District Dropdown styled
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8E8EE)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: _selectedDistrict,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'District',
                  labelStyle: TextStyle(
                      color: Color(0xFF444466),
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                  border: InputBorder.none,
                ),
                items: SriLankanDistricts.sortedDistricts.map((district) {
                  return DropdownMenuItem(
                    value: district,
                    child: Text(district, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedDistrict = value),
                validator: (value) => value == null || value.isEmpty
                    ? 'District is required'
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _addressController,
            label: 'Full Address',
            hint: 'Enter company location address',
            prefixIcon: Icons.map_outlined,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.adminPrimary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.adminPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isEditMode ? Icons.check_circle_rounded : Icons.rocket_launch,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              _isEditMode ? 'Save Changes' : 'Register Company',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
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
          district: _selectedDistrict,
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
      district: _selectedDistrict,
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
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, size: 32, color: AppColors.success),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Company Created Successfully',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please share these login credentials with the company admin:',
                    style: TextStyle(color: Color(0xFF444466), fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Credentials Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8E8EE)),
                    ),
                    child: Column(
                      children: [
                        _buildCredentialRow('Name', credentials.name),
                        const Divider(height: 16, color: Color(0xFFE8E8EE)),
                        _buildCredentialRow('Email', credentials.email),
                        const Divider(height: 16, color: Color(0xFFE8E8EE)),
                        _buildCredentialRow('Phone', credentials.phone),
                        const Divider(height: 16, color: Color(0xFFE8E8EE)),
                        _buildCredentialRow('Password', credentials.password),
                        const Divider(height: 16, color: Color(0xFFE8E8EE)),
                        _buildCredentialRow('Role', credentials.role),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 20, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Please save these credentials securely. They will not be shown again.',
                            style: TextStyle(color: Colors.orange.shade800, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6FA),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.read<AdminCubit>().clearMessages();
                        context.pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF444466),
                        side: const BorderSide(color: Color(0xFFE8E8EE)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
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
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.adminPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
