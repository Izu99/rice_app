import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/shared_widgets/custom_button.dart';
import '../../../../core/shared_widgets/confirmation_dialog.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../data/models/stock_item_model.dart';
import '../cubit/milling_cubit.dart';
import '../cubit/milling_state.dart';
import '../widgets/milling_calculator.dart';

class MillingScreen extends StatefulWidget {
  const MillingScreen({super.key});

  @override
  State<MillingScreen> createState() => _MillingScreenState();
}

class _MillingScreenState extends State<MillingScreen> {
  final _inputWeightController = TextEditingController();
  final _inputBagsController = TextEditingController();
  final _outputRiceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<MillingCubit>().loadAvailablePaddy();
  }

  @override
  void dispose() {
    _inputWeightController.dispose();
    _inputBagsController.dispose();
    _outputRiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paddy Milling'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/stock');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<MillingCubit>().resetMilling();
              _clearControllers();
            },
            tooltip: 'Reset',
          ),
        ],
      ),
      body: BlocConsumer<MillingCubit, MillingState>(
        listener: (context, state) {
          print('🖥️ [MillingScreen] State Listener: status=${state.status}');
          try {
            if (state.status == MillingStatus.success) {
              print('🖥️ [MillingScreen] Showing Success Dialog');
              _showSuccessDialog();
            } else if (state.errorMessage != null) {
              print('🖥️ [MillingScreen] Error detected: ${state.errorMessage}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.error,
                ),
              );
              context.read<MillingCubit>().clearError();
            }
          } catch (e) {
            print('❌ [MillingScreen] LISTENER ERROR: $e');
          }
        },
        builder: (context, state) {
          print('🖥️ [MillingScreen] State Builder: status=${state.status}');
          try {
            return LoadingOverlay(
              isLoading: state.status == MillingStatus.processing,
              message: 'Processing milling...',
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Batch Info Card
                    _buildBatchInfoCard(state),
                    const SizedBox(height: AppDimensions.paddingM),

                    // Select Paddy Section
                    _buildSectionTitle('1. Select Paddy'),
                    const SizedBox(height: AppDimensions.paddingS),
                    _buildPaddySelector(state),
                    const SizedBox(height: AppDimensions.paddingL),

                    // Input Section
                    if (state.selectedPaddy != null) ...[
                      _buildSectionTitle('2. Input Quantity'),
                      const SizedBox(height: AppDimensions.paddingS),
                      _buildInputSection(state),
                      const SizedBox(height: AppDimensions.paddingL),

                      // Milling Calculator
                      _buildSectionTitle('3. Milling Output'),
                      const SizedBox(height: AppDimensions.paddingS),
                      MillingCalculator(
                        inputPaddyKg: state.inputPaddyKg,
                        millingPercentage: state.millingPercentage,
                        expectedRiceKg: state.expectedRiceKg,
                        expectedBrokenRiceKg: state.expectedBrokenRiceKg,
                        expectedHuskKg: state.expectedHuskKg,
                        expectedWastageKg: state.expectedWastageKg,
                        onMillingPercentageChanged: (value) {
                          context
                              .read<MillingCubit>()
                              .updateMillingPercentage(value);
                        },
                        onActualOutputChanged: (riceKg) {
                          context
                              .read<MillingCubit>()
                              .updateActualOutput(riceKg: riceKg);
                        },
                      ),
                      const SizedBox(height: AppDimensions.paddingXL),

                      // Process Button
                      _buildProcessButton(state),
                    ],

                    const SizedBox(height: AppDimensions.paddingXL),
                  ],
                ),
              ),
            );
          } catch (e, stack) {
            print('❌ [MillingScreen] RENDER ERROR: $e');
            print('❌ [MillingScreen] STACK TRACE: $stack');
            return Scaffold(
              body: Center(
                child: Text('Rendering Error: $e'),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildBatchInfoCard(MillingState state) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment, color: AppColors.primary),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Batch Number',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  state.batchNumber ?? 'Generating...',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Date',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _formatDate(state.millingDate ?? DateTime.now()),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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

  Widget _buildPaddySelector(MillingState state) {
    if (state.status == MillingStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.availablePaddy.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.grey300),
        ),
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 48, color: AppColors.warning),
            const SizedBox(height: AppDimensions.paddingM),
            const Text(
              'No paddy available for milling',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            CustomButton(
              label: 'Buy Paddy',
              onPressed: () => context.go('/buy'),
              variant: ButtonVariant.outline,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        children: state.availablePaddy.map((paddy) {
          final isSelected = state.selectedPaddy?.id == paddy.id;
          return _buildPaddyTile(paddy, isSelected);
        }).toList(),
      ),
    );
  }

  Widget _buildPaddyTile(StockItemModel paddy, bool isSelected) {
    return InkWell(
      onTap: () => context.read<MillingCubit>().selectPaddy(paddy),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          border: const Border(
            bottom: BorderSide(color: AppColors.grey200),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.grey400,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paddy.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Available: ${paddy.totalWeightKg.toStringAsFixed(1)} kg (${paddy.totalBags} bags)',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.grass,
              color: AppColors.paddyColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(MillingState state) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Selected Paddy Info
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            decoration: BoxDecoration(
              color: AppColors.paddyColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 20, color: AppColors.paddyColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected: ${state.selectedPaddy!.name} - Available: ${state.selectedPaddy!.totalWeightKg.toStringAsFixed(1)} kg',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.paddyColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),

          // Weight Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputWeightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    suffixText: 'kg',
                  ),
                  onChanged: (value) {
                    final weight = double.tryParse(value) ?? 0;
                    context.read<MillingCubit>().updateInputWeight(weight);
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: TextField(
                  controller: _inputBagsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Bags',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    suffixText: 'bags',
                  ),
                  onChanged: (value) {
                    final bags = int.tryParse(value) ?? 0;
                    context.read<MillingCubit>().updateInputBags(bags);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),

          // Quick Select Buttons
          Wrap(
            spacing: 8,
            children: [25, 50, 100, 500].map((kg) {
              return ActionChip(
                label: Text('$kg kg'),
                onPressed: () {
                  _inputWeightController.text = kg.toString();
                  context.read<MillingCubit>().updateInputWeight(kg.toDouble());
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessButton(MillingState state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state.canProcess ? _confirmAndProcess : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings_suggest, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Process Milling',
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

  void _confirmAndProcess() {
    // Capture cubit before showing dialog to avoid context issues
    final cubit = context.read<MillingCubit>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => ConfirmationDialog(
        title: 'Confirm Milling',
        message: 'Are you sure you want to process this milling batch? '
            'This will deduct paddy and add rice to stock.',
        confirmLabel: 'Process',
        onConfirm: () {
          Navigator.pop(dialogContext);
          cubit.processMilling();
        },
      ),
    );
  }

  void _showSuccessDialog() {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 64,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingL),
              Text(
                'Milling Complete!',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                'Rice has been added to stock.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<MillingCubit>().resetMilling();
                _clearControllers();
              },
              child: const Text('New Batch'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                context.push('/stock'); // Use push to be safer
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child:
                  const Text('View Stock', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e, stack) {
      print('❌ [MillingScreen] DIALOG ERROR: $e');
      print('❌ [MillingScreen] STACK TRACE: $stack');
      // Fallback or inform user if dialog fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Operation successful, but failed to show confirmation.'),
            backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void _clearControllers() {
    _inputWeightController.clear();
    _inputBagsController.clear();
    _outputRiceController.clear();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

