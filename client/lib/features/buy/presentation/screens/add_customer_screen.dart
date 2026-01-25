// lib/features/buy/presentation/screens/add_customer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/shared_widgets/custom_button.dart';
import '../../../../core/shared_widgets/custom_text_field.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../data/models/customer_model.dart';
import '../cubit/buy_cubit.dart';
import '../cubit/customer_cubit.dart';
import '../cubit/customer_state.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _nicController = TextEditingController();
  final _notesController = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _secondaryPhoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _nicController.dispose();
    _notesController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerCubit, CustomerState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.foundByPhone != current.foundByPhone,
      listener: (context, state) {
        // Show phone exists dialog
        if (state.foundByPhone != null) {
          _showPhoneExistsDialog(context, state.foundByPhone!);
        }

        // Handle success
        if (state.status == CustomerStatus.added &&
            state.selectedCustomer != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer added successfully!'),
              backgroundColor: AppColors.success,
            ),
          );

          // Select customer in buy screen and navigate back
          context.read<BuyCubit>().selectCustomer(state.selectedCustomer!);
          context.go('/buy');
        }

        // Handle error
        if (state.status == CustomerStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return LoadingOverlay(
          isLoading: state.isAdding,
          message: 'Adding customer...',
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Customer',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'පාරිභෝගිකයෙකු එක් කරන්න',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.white),
                onPressed: () {
                  context.read<CustomerCubit>().resetForm();
                  context.go('/buy');
                },
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Basic Info Card
                    _buildBasicInfoCard(state),
                    const SizedBox(height: 16),

                    // Contact Info Card
                    _buildContactInfoCard(state),
                    const SizedBox(height: 16),

                    // Additional Info Card
                    _buildAdditionalInfoCard(state),
                    const SizedBox(height: 24),

                    // Submit Button
                    CustomButton(
                      label: 'Add Customer',
                      icon: Icons.person_add,
                      onPressed: _onSubmit,
                      height: 56,
                    ),

                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBasicInfoCard(CustomerState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Basic Information',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name
          CustomTextField(
            controller: _nameController,
            focusNode: _nameFocus,
            label: 'Full Name *',
            hint: 'Enter customer name',
            prefixIcon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            errorText: state.getFieldError('name'),
            onChanged: (value) {
              context.read<CustomerCubit>().updateName(value);
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard(CustomerState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Contact Information',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Primary Phone
          CustomTextField(
            controller: _phoneController,
            focusNode: _phoneFocus,
            label: 'Phone Number *',
            hint: '07X XXX XXXX',
            prefixIcon: Icons.phone_android,
            keyboardType: TextInputType.phone,
            errorText: state.getFieldError('phone'),
            suffix: state.isPhoneSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : state.foundByPhone != null
                    ? const Icon(Icons.warning, color: AppColors.warning)
                    : null,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (value) {
              context.read<CustomerCubit>().updatePhone(value);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number is required';
              }
              if (value.length < 9) {
                return 'Invalid phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Secondary Phone
          CustomTextField(
            controller: _secondaryPhoneController,
            label: 'Secondary Phone (Optional)',
            hint: '07X XXX XXXX',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (value) {
              context.read<CustomerCubit>().updateSecondaryPhone(value);
            },
          ),
          const SizedBox(height: 16),

          // Address
          CustomTextField(
            controller: _addressController,
            label: 'Address (Optional)',
            hint: 'Enter address',
            prefixIcon: Icons.location_on_outlined,
            maxLines: 2,
            onChanged: (value) {
              context.read<CustomerCubit>().updateAddress(value);
            },
          ),
          const SizedBox(height: 16),

          // City
          CustomTextField(
            controller: _cityController,
            label: 'City (Optional)',
            hint: 'Enter city',
            prefixIcon: Icons.location_city,
            textCapitalization: TextCapitalization.words,
            onChanged: (value) {
              context.read<CustomerCubit>().updateCity(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard(CustomerState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Additional Information',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // NIC
          CustomTextField(
            controller: _nicController,
            label: 'NIC Number (Optional)',
            hint: 'Enter NIC',
            prefixIcon: Icons.badge_outlined,
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) {
              context.read<CustomerCubit>().updateNic(value);
            },
          ),
          const SizedBox(height: 16),

          // Notes
          CustomTextField(
            controller: _notesController,
            label: 'Notes (Optional)',
            hint: 'Additional notes about this customer...',
            prefixIcon: Icons.note_outlined,
            maxLines: 3,
            onChanged: (value) {
              context.read<CustomerCubit>().updateNotes(value);
            },
          ),
        ],
      ),
    );
  }

  void _onSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      await context.read<CustomerCubit>().addCustomer();
    }
  }

  void _showPhoneExistsDialog(BuildContext context, CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Phone Exists'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('A customer with this phone number already exists:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      customer.initials,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          customer.formattedPhone,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CustomerCubit>().clearError();
            },
            child: const Text('Use Different Phone'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<BuyCubit>().selectCustomer(customer);
              context.go('/buy');
            },
            child: const Text('Select This Customer'),
          ),
        ],
      ),
    );
  }
}

