import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

    if (phone.isEmpty || (_isEditing && phone == _originalPhone)) {
      setState(() {
        _isPhoneAvailable = true;
        _phoneStatusMessage = null;
        _isPhoneChecking = false;
      });
      _checkAnimController.stop();
      return;
    }

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
      _phoneStatusMessage = 'පරීක්ෂා කරමින් පවතී...';
    });
    _checkAnimController.repeat();

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final cubit = context.read<CustomersCubit>();

      final existingLocally = cubit.state.customers
          .where((c) => c.phone == phone && c.id != _currentEditingId)
          .firstOrNull;

      if (existingLocally != null) {
        _handlePhoneExists(existingLocally);
        return;
      }

      final phoneCustomer = await cubit.getCustomerByPhone(phone);

      if (mounted) {
        _checkAnimController.stop();
        if (phoneCustomer != null && phoneCustomer.id != _currentEditingId) {
          _handlePhoneExists(phoneCustomer);
        } else {
          setState(() {
            _isPhoneAvailable = true;
            _phoneStatusMessage = 'නව ගනුදෙනුකරුවෙක්';
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
        _phoneStatusMessage = 'දැනටමත් ලියාපදිංචි වී ඇත';
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
            Text('දැනට සිටින ගනුදෙනුකරුවෙක්'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('මෙම දුරකථන අංකය දැනටමත් ලියාපදිංචි කර ඇත:'),
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
                'ඔබට මෙම තොරතුරු යාවත්කාලීන කිරීමට හෝ වෙනත් අංකයක් භාවිතා කිරීමට අවශ්‍යද?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _phoneController.clear();
              _phoneFocusNode.requestFocus();
            },
            child: const Text('වෙනත් අංකයක්'),
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
            child: const Text('යාවත්කාලීන කරන්න'),
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
                'කරුණාකර වෙනත් දුරකථන අංකයක් භාවිතා කරන්න හෝ පවතින වාර්තාව යාවත්කාලීන කරන්න.')));
        return;
      }

      final authState = context.read<AuthCubit>().state;
      final companyId = authState.user?.companyId ?? '';

      if (companyId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'දෝෂයකි: ආයතනයේ තොරතුරු හමු නොවීය. කරුණාකර නැවත ඇතුළු වන්න.')));
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
            const SnackBar(
              content: Text('සාර්ථකව සුරැකිණි'),
              backgroundColor: AppColors.success,
            ),
          );
          if (context.canPop()) {
            context.pop(true);
          } else {
            context.go('/customers');
          }
          context.read<CustomersCubit>().resetFormStatus();
        } else if (state.formStatus == CustomerFormStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.formErrorMessage ?? 'ගනුදෙනුකරු සුරැකීමේදී දෝෂයක් සිදු විය'),
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
              title: Text(_isEditing ? 'ගනුදෙනුකරු යාවත්කාලීන කිරීම' : 'නව ගනුදෙනුකරු'),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
            ),
            body: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: AppColors.primary,
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person_add_alt_1,
                            size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isEditing ? 'තොරතුරු යාවත්කාලීන කිරීම' : 'නව ගිණුමක් සාදන්න',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
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
                            _buildSectionTitle('මූලික තොරතුරු'),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              decoration: InputDecoration(
                                labelText: 'දුරකථන අංකය (අනිවාර්යයි)',
                                hintText: '07XXXXXXXX',
                                prefixIcon: Icon(Icons.phone_outlined,
                                    color: AppColors.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                suffixIcon: _isPhoneChecking
                                    ? RotationTransition(
                                        turns: _checkAnimController,
                                        child: Icon(Icons.sync,
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
                                  return 'කරුණාකර  දුරකථන අංකයක් ඇතුළත් කරන්න';
                                }
                                if (value.length < 9) {
                                  return 'දුරකථන අංකය කෙටි වැඩියි';
                                }
                                if (!_isPhoneAvailable) {
                                  return 'මෙම දුරකථන අංකය දැනටමත් භාවිතා කර ඇත';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            _buildSectionTitle('ගනුදෙනුකරුගේ විස්තර'),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.7,
                                child: DropdownButtonFormField<CustomerType>(
                                  value: _selectedType,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'භූමිකාව (අනිවාර්යයි)',
                                    prefixIcon: Icon(
                                        Icons.category_outlined,
                                        color: AppColors.primary),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 16),
                                  ),
                                  icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.primary),
                                  borderRadius: BorderRadius.circular(16),
                                  items: [
                                    CustomerType.seller,
                                    CustomerType.buyer,
                                    CustomerType.both,
                                  ].map((type) {
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(
                                        type.sinhalaName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedType = value);
                                    }
                                  },
                                  validator: (value) => value == null
                                      ? 'කරුණාකර වර්ගයක් තෝරන්න'
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: _inputDecoration(
                                  'සම්පූර්ණ නම (අනිවාර්යයි)', Icons.person_outline),
                              textCapitalization: TextCapitalization.words,
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? 'කරුණාකර නම ඇතුළත් කරන්න'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _secondaryPhoneController,
                              decoration: _inputDecoration(
                                  'අමතර දුරකථන අංකය',
                                  Icons.phone_android_outlined),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              decoration: _inputDecoration(
                                  'ලිපිනය (අනිවාර්යයි)',
                                  Icons.location_on_outlined),
                              maxLines: 2,
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? 'කරුණාකර ලිපිනය ඇතුළත් කරන්න'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _cityController,
                              decoration: _inputDecoration(
                                  'නගරය (අනිවාර්යයි)', Icons.location_city_outlined),
                              textCapitalization: TextCapitalization.words,
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? 'කරුණාකර නගරය ඇතුළත් කරන්න'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nicController,
                              decoration: _inputDecoration(
                                  'හැඳුනුම්පත් අංකය', Icons.badge_outlined),
                              textCapitalization: TextCapitalization.characters,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _notesController,
                              decoration: _inputDecoration(
                                  'සටහන්',
                                  Icons.note_alt_outlined),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 40),
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
                                      ? 'යාවත්කාලීන කරන්න'
                                      : 'ලියාපදිංචි කරන්න',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: Colors.white,
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
      prefixIcon: Icon(icon, size: 22, color: AppColors.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
