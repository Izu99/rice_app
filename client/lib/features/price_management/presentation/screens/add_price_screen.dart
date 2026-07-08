// lib/features/price_management/presentation/screens/add_price_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/shared_widgets/custom_text_field.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../core/shared_widgets/h_app_bar.dart';
import '../../../../core/shared_widgets/app_page_scaffold.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/price_management_cubit.dart';
import '../cubit/price_management_state.dart';

class AddPriceScreen extends StatefulWidget {
  const AddPriceScreen({super.key});

  @override
  State<AddPriceScreen> createState() => _AddPriceScreenState();
}

class _AddPriceScreenState extends State<AddPriceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedPriceType = 'paddy';
  String _selectedQualityGrade = 'standard';
  String? _selectedVariety;

  static const List<String> _paddyVarieties = [
    'සම්බා',
    'කකුළු',
    'නාඩු',
    'කීරි සම්බා',
    'සුවඳැල්',
    'පච්චපෙරුමාල්',
    'රතු හීනටි',
    'මඩතවාලු',
  ];

  static const List<String> _riceVarieties = [
    'සම්බා සහල්',
    'නාඩු සහල්',
    'කීරි සම්බා සහල්',
    'රතු සහල්',
    'සුදු සහල්',
    'බාස්මතී',
  ];

  List<String> get _varieties =>
      _selectedPriceType == 'paddy' ? _paddyVarieties : _riceVarieties;

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleAddPrice() {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_minPriceController.text.trim());
    final priceRangeEnd = _maxPriceController.text.trim().isNotEmpty
        ? double.tryParse(_maxPriceController.text.trim())
        : null;

    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SiStrings.validMinPriceRequired)),
      );
      return;
    }

    context.read<PriceManagementCubit>().addPrice(
          price: price,
          priceRangeEnd: priceRangeEnd,
          qualityGrade: _selectedQualityGrade,
          priceType: _selectedPriceType,
          variety: _selectedVariety,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PriceManagementCubit, PriceManagementState>(
      listener: (context, state) {
        if (state.status == PriceManagementStatus.success &&
            state.lastAddedPrice != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(SiStrings.priceAddedMessage(
                  state.lastAddedPrice!.formattedPrice)),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        } else if (state.status == PriceManagementStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? SiStrings.failedToAddPrice),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        appBar: HAppBar(
          title: SiStrings.addPrice,
          subtitle: SiStrings.enterPriceDetails,
          onBack: () => context.pop(),
        ),
        body: BlocBuilder<PriceManagementCubit, PriceManagementState>(
          builder: (context, state) {
            return LoadingOverlay(
              isLoading: state.status == PriceManagementStatus.addingPrice,
              message: SiStrings.addingPrice,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // District display (top, read-only from company)
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, authState) {
                          final district =
                              authState.company?.district ?? SiStrings.notSet;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              border: Border.all(
                                  color: AppColors.primary, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: AppColors.primary, size: 22),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(SiStrings.yourDistrict,
                                        style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textSecondary)),
                                    Text(district,
                                        style: AppTextStyles.titleMedium
                                            .copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Paddy / Rice toggle
                      Text(SiStrings.commodityType,
                          style: AppTextStyles.labelMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _TypeButton(
                              label: SiStrings.paddyLabel,
                              icon: Icons.grass_rounded,
                              selected: _selectedPriceType == 'paddy',
                              color: const Color(0xFF8BC34A),
                              onTap: () => setState(() {
                                _selectedPriceType = 'paddy';
                                _selectedVariety = null;
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TypeButton(
                              label: SiStrings.riceLabel,
                              icon: Icons.rice_bowl_rounded,
                              selected: _selectedPriceType == 'rice',
                              color: AppColors.primary,
                              onTap: () => setState(() {
                                _selectedPriceType = 'rice';
                                _selectedVariety = null;
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Variety dropdown
                      Text(SiStrings.variety,
                          style: AppTextStyles.labelMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedVariety,
                        hint: Text(SiStrings.selectVariety),
                        items: _varieties
                            .map((v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(v),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedVariety = value);
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Min Price
                      CustomTextField(
                        controller: _minPriceController,
                        label: SiStrings.minimumPriceRs,
                        hint: 'e.g., 115',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        prefixIcon: Icons.currency_rupee,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return SiStrings.priceRequired;
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return SiStrings.enterValidNumber;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Max Price (optional)
                      CustomTextField(
                        controller: _maxPriceController,
                        label: SiStrings.maximumPriceOptionalRs,
                        hint: SiStrings.maxPriceHint,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        prefixIcon: Icons.currency_rupee,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final max = double.tryParse(value.trim());
                          if (max == null) return SiStrings.enterValidNumber;
                          final min =
                              double.tryParse(_minPriceController.text.trim());
                          if (min != null && max <= min) {
                            return SiStrings.maxGreaterThanMin;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Quality Grade
                      Text(SiStrings.qualityGrade,
                          style: AppTextStyles.labelMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedQualityGrade,
                        items: [
                          DropdownMenuItem(
                              value: 'premium', child: Text(SiStrings.premium)),
                          DropdownMenuItem(
                              value: 'standard',
                              child: Text(SiStrings.standard)),
                          DropdownMenuItem(
                              value: 'basic', child: Text(SiStrings.basic)),
                        ],
                        onChanged: (value) {
                          setState(() =>
                              _selectedQualityGrade = value ?? 'standard');
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Notes
                      CustomTextField(
                        controller: _notesController,
                        label: SiStrings.notesOptional,
                        hint: SiStrings.notesHint,
                        maxLines: 3,
                        maxLength: 200,
                        showCounter: true,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _handleAddPrice,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            SiStrings.save,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.white,
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.grey.shade600,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
