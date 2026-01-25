import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../domain/entities/customer_entity.dart';
import '../../../../core/constants/enums.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/customers_cubit.dart';
import '../cubit/customers_state.dart';

class CustomerAddEditScreen extends StatefulWidget {
  final String? customerId;
  final CustomerType? initialType;

  const CustomerAddEditScreen({
    super.key,
    this.customerId,
    this.initialType,
  });

  @override
  State<CustomerAddEditScreen> createState() => _CustomerAddEditScreenState();
}

class _CustomerAddEditScreenState extends State<CustomerAddEditScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _nicController = TextEditingController();
  final _notesController = TextEditingController();

  // Focus Nodes
  final _phoneFocusNode = FocusNode();

  // Animation for phone check
  late AnimationController _checkAnimController;

  // State
  Timer? _debounce;
  bool _isPhoneChecking = false;
  bool _isPhoneAvailable = true;
  String? _phoneStatusMessage;
  bool _isEditing = false;
  String? _currentEditingId;
  String? _originalPhone;
  CustomerType _selectedType = CustomerType.both;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.customerId != null;
    _currentEditingId = widget.customerId;
    _selectedType = widget.initialType ?? CustomerType.both;

    _checkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (_isEditing) {
      _loadCustomerData();
    }

    _phoneController.addListener(_onPhoneChanged);
  }

  void _loadCustomerData() {
    final cubit = context.read<CustomersCubit>();
    final customer = cubit.state.customers.firstWhere(
      (c) => c.id == _currentEditingId,
      orElse: () => CustomerEntity.empty(),
    );

    if (customer.isNotEmpty) {
      _nameController.text = customer.name;
      _phoneController.text = customer.phone;
      _originalPhone = customer.phone;
      _secondaryPhoneController.text = customer.secondaryPhone ?? '';
      _addressController.text = customer.address ?? '';
      _cityController.text = customer.city ?? '';
      _nicController.text = customer.nic ?? '';
      _notesController.text = customer.notes ?? '';
      _selectedType = customer.customerType;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _checkAnimController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _secondaryPhoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _nicController.dispose();
    _notesController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final phone = _phoneController.text.trim();

    // Reset state if empty or same as original (when editing)
    if (phone.isEmpty || (_isEditing && phone == _originalPhone)) {
      setState(() {
        _isPhoneAvailable = true;
        _phoneStatusMessage = null;
        _isPhoneChecking = false;
      });
      _checkAnimController.stop();
      return;
    }

    // Don't check if too short
    if (phone.length < 9) {
      setState(() {
        _isPhoneAvailable = true;
        _phoneStatusMessage = null;
        _isPhoneChecking = false;
      });
      _checkAnimController.stop();
      return;
    }

    setState(() {
      _isPhoneChecking = true;
      _phoneStatusMessage = 'Checking number...';
    });
    _checkAnimController.repeat();

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final cubit = context.read<CustomersCubit>();

      // First check local/memory list
      final existingLocally = cubit.state.customers
          .where((c) => c.phone == phone && c.id != _currentEditingId)
          .firstOrNull;

      if (existingLocally != null) {
        _handlePhoneExists(existingLocally);
        return;
      }

      // Then check via repository (remote/local DB)
      final phoneCustomer = await cubit.getCustomerByPhone(phone);

      if (mounted) {
        _checkAnimController.stop();
        if (phoneCustomer != null && phoneCustomer.id != _currentEditingId) {
          _handlePhoneExists(phoneCustomer);
        } else {
          setState(() {
            _isPhoneAvailable = true;
            _phoneStatusMessage = 'New customer detected';
            _isPhoneChecking = false;
          });
        }
      }
    });
  }

  void _handlePhoneExists(CustomerEntity customer) {
    if (mounted) {
      _checkAnimController.stop();
      setState(() {
        _isPhoneAvailable = false;
        _phoneStatusMessage = 'Already registered';
        _isPhoneChecking = false;
      });
      _showExistingCustomerDialog(customer);
    }
  }

  void _showExistingCustomerDialog(CustomerEntity customer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Existing Customer'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This phone number is already registered to:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(customer.initials,
                        style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.name,
                            style: AppTextStyles.titleSmall
                                .copyWith(fontWeight: FontWeight.bold)),
                        if (customer.address != null &&
                            customer.address!.isNotEmpty)
                          Text(customer.address!,
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
                'Do you want to update this customer\'s details or use a different phone number?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _phoneController.clear();
              _phoneFocusNode.requestFocus();
            },
            child: const Text('Different Number'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _switchToEditExisting(customer);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Update This Record'),
          ),
        ],
      ),
    );
  }

  void _switchToEditExisting(CustomerEntity customer) {
    setState(() {
      _isEditing = true;
      _currentEditingId = customer.id;
      _originalPhone = customer.phone;
      _isPhoneAvailable = true;
      _phoneStatusMessage = null;

      _nameController.text = customer.name;
      _phoneController.text = customer.phone;
      _secondaryPhoneController.text = customer.secondaryPhone ?? '';
      _addressController.text = customer.address ?? '';
      _cityController.text = customer.city ?? '';
      _nicController.text = customer.nic ?? '';
      _notesController.text = customer.notes ?? '';
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_isPhoneAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Please use a unique phone number or update the existing record.')));
        return;
      }

      final authState = context.read<AuthCubit>().state;
      final companyId = authState.user?.companyId ?? '';
      
      if (companyId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Error: Company information not found. Please log in again.')));
        return;
      }

      final cubit = context.read<CustomersCubit>();

      if (_isEditing) {
        cubit.updateCustomer(
          id: _currentEditingId!,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          secondaryPhone: _secondaryPhoneController.text.trim(),
          email: null,
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          nic: _nicController.text.trim(),
          notes: _notesController.text.trim(),
          companyId: companyId,
          customerType: _selectedType,
        );
      } else {
        cubit.addCustomer(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          secondaryPhone: _secondaryPhoneController.text.trim(),
          email: null,
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          nic: _nicController.text.trim(),
          notes: _notesController.text.trim(),
          companyId: companyId,
          customerType: _selectedType,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomersCubit, CustomersState>(
      listenWhen: (previous, current) =>
          previous.formStatus != current.formStatus,
      listener: (context, state) {
        if (state.formStatus == CustomerFormStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.formSuccessMessage ?? 'Saved successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/customers');
          }
          context.read<CustomersCubit>().resetFormStatus();
        } else if (state.formStatus == CustomerFormStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.formErrorMessage ?? 'Error saving customer'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return LoadingOverlay(
          isLoading: state.formStatus == CustomerFormStatus.submitting,
          child: Scaffold(
            appBar: AppBar(
              title: Text(_isEditing ? 'Edit Customer' : 'Add Customer'),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
            ),
            body: Column(
              children: [
                // Header with icon
                Container(
                  width: double.infinity,
                  color: AppColors.primary,
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person_add_alt_1,
                            size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isEditing ? 'Updating Record' : 'Create New Profile',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Primary Identification'),
                            const SizedBox(height: 16),

                            // Phone
                            TextFormField(
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              decoration: InputDecoration(
                                labelText: 'Phone Number *',
                                hintText: '07XXXXXXXX',
                                prefixIcon: const Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.primary, width: 2),
                                ),
                                suffixIcon: _isPhoneChecking
                                    ? RotationTransition(
                                        turns: _checkAnimController,
                                        child: const Icon(Icons.sync,
                                            color: AppColors.primary),
                                      )
                                    : _phoneStatusMessage != null
                                        ? Icon(
                                            _isPhoneAvailable
                                                ? Icons.check_circle
                                                : Icons.error,
                                            color: _isPhoneAvailable
                                                ? AppColors.success
                                                : AppColors.error)
                                        : null,
                                helperText: _phoneStatusMessage,
                                helperStyle: TextStyle(
                                    color: _isPhoneAvailable
                                        ? AppColors.success
                                        : AppColors.error,
                                    fontWeight: FontWeight.bold),
                              ),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (value.length < 9) {
                                  return 'Too short';
                                }
                                if (!_isPhoneAvailable) {
                                  return 'Use a unique number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            _buildSectionTitle('Customer Details'),
                            const SizedBox(height: 16),

                            // Customer Type
                            DropdownButtonFormField<CustomerType>(
                              initialValue: _selectedType,
                              decoration: _inputDecoration(
                                  'Customer Role / Type',
                                  Icons.category_outlined),
                              items: CustomerType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                      '${type.displayName} (${type.sinhalaName})'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedType = value);
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            // Name
                            TextFormField(
                              controller: _nameController,
                              decoration: _inputDecoration(
                                  'Full Name *', Icons.person_outline),
                              textCapitalization: TextCapitalization.words,
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                            ),
                            const SizedBox(height: 16),

                            // Secondary Phone
                            TextFormField(
                              controller: _secondaryPhoneController,
                              decoration: _inputDecoration(
                                  'Secondary Phone (Optional)',
                                  Icons.phone_android_outlined),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Address
                            TextFormField(
                              controller: _addressController,
                              decoration: _inputDecoration(
                                  'Street Address', Icons.location_on_outlined),
                              maxLines: 2,
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _cityController,
                                    decoration: _inputDecoration(
                                        'City', Icons.location_city_outlined),
                                    textCapitalization:
                                        TextCapitalization.words,
                                    validator: (value) =>
                                        (value == null || value.trim().isEmpty)
                                            ? 'Required'
                                            : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _nicController,
                                    decoration: _inputDecoration(
                                        'NIC (Optional)', Icons.badge_outlined),
                                    textCapitalization:
                                        TextCapitalization.characters,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Notes
                            TextFormField(
                              controller: _notesController,
                              decoration: _inputDecoration(
                                  'Internal Notes', Icons.note_alt_outlined),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 40),

                            // Submit Button
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  _isEditing
                                      ? 'UPDATE CUSTOMER'
                                      : 'REGISTER CUSTOMER',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 22),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

