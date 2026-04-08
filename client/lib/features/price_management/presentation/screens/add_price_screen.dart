// lib/features/price_management/presentation/screens/add_price_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/shared_widgets/custom_text_field.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../core/shared_widgets/h_app_bar.dart';
import '../../../../core/shared_widgets/app_page_scaffold.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/cubit/profile_state.dart';
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
        const SnackBar(content: Text('Please enter a valid minimum price')),
      );
      return;
    }

    context.read<PriceManagementCubit>().addPrice(
          price: price,
          priceRangeEnd: priceRangeEnd,
          qualityGrade: _selectedQualityGrade,
          priceType: _selectedPriceType,
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
              content:
                  Text('Price added: ${state.lastAddedPrice!.formattedPrice}'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        } else if (state.status == PriceManagementStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Failed to add price'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: AppPageScaffold(
        title: 'Add Price',
        subtitle: 'මිල ඇතුළත් කරන්න',
        onBack: () => context.pop(),
        bottomBar: AppSubBottomBar(
          centerLabel: 'Save Price',
          centerIcon: Icons.save_rounded,
          onCenter: _handleAddPrice,
        ),
        body: BlocBuilder<PriceManagementCubit, PriceManagementState>(
          builder: (context, state) {
            return LoadingOverlay(
              isLoading: state.status == PriceManagementStatus.addingPrice,
              message: 'Adding price...',
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // District display (read-only)
                      BlocBuilder<ProfileCubit, ProfileState>(
                        builder: (context, profileState) {
                          final district =
                              profileState.company?.district ?? 'Not Set';
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              border: Border.all(
                                  color: AppColors.primary, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.location_on,
                                    color: AppColors.primary, size: 22),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Your District',
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
                      Text('Commodity Type',
                          style: AppTextStyles.labelMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _TypeButton(
                              label: 'Paddy',
                              icon: Icons.grass_rounded,
                              selected: _selectedPriceType == 'paddy',
                              color: const Color(0xFF8BC34A),
                              onTap: () =>
                                  setState(() => _selectedPriceType = 'paddy'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TypeButton(
                              label: 'Rice',
                              icon: Icons.rice_bowl_rounded,
                              selected: _selectedPriceType == 'rice',
                              color: AppColors.primary,
                              onTap: () =>
                                  setState(() => _selectedPriceType = 'rice'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Min Price
                      CustomTextField(
                        controller: _minPriceController,
                        label: 'Minimum Price (Rs.)',
                        hint: 'e.g., 115',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        prefixIcon: Icons.currency_rupee,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Price is required';
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Max Price (optional)
                      CustomTextField(
                        controller: _maxPriceController,
                        label: 'Maximum Price (Rs.) — Optional',
                        hint: 'e.g., 118 (leave blank for single price)',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        prefixIcon: Icons.currency_rupee,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null; // Optional
                          }
                          final max = double.tryParse(value.trim());
                          if (max == null) return 'Enter a valid number';
                          final min =
                              double.tryParse(_minPriceController.text.trim());
                          if (min != null && max <= min) {
                            return 'Max must be greater than min price';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Quality Grade
                      Text('Quality Grade',
                          style: AppTextStyles.labelMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedQualityGrade,
                        items: const [
                          DropdownMenuItem(
                              value: 'premium', child: Text('Premium')),
                          DropdownMenuItem(
                              value: 'standard', child: Text('Standard')),
                          DropdownMenuItem(
                              value: 'basic', child: Text('Basic')),
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
                        label: 'Notes (Optional)',
                        hint: 'Any additional details about this price',
                        maxLines: 3,
                        maxLength: 200,
                        showCounter: true,
                      ),
                      const SizedBox(height: 28),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _handleAddPrice,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'Add Price',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
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
          color: selected ? color.withOpacity(0.12) : Colors.white,
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
