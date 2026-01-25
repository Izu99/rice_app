import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

class MillingCalculator extends StatelessWidget {
  final double inputPaddyKg;
  final double millingPercentage;
  final double expectedRiceKg;
  final double expectedBrokenRiceKg;
  final double expectedHuskKg;
  final double expectedWastageKg;
  final Function(double) onMillingPercentageChanged;
  final Function(double)? onActualOutputChanged;

  const MillingCalculator({
    super.key,
    required this.inputPaddyKg,
    required this.millingPercentage,
    required this.expectedRiceKg,
    required this.expectedBrokenRiceKg,
    required this.expectedHuskKg,
    required this.expectedWastageKg,
    required this.onMillingPercentageChanged,
    this.onActualOutputChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
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
          // Milling Percentage Slider
          _buildPercentageSlider(),
          const SizedBox(height: AppDimensions.paddingL),

          // Visual Breakdown
          _buildVisualBreakdown(),
          const SizedBox(height: AppDimensions.paddingL),

          // Output Details
          _buildOutputDetails(),
        ],
      ),
    );
  }

  Widget _buildPercentageSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Milling Percentage',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${millingPercentage.toStringAsFixed(1)}%',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingS),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.grey200,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.2),
            valueIndicatorColor: AppColors.primary,
            valueIndicatorTextStyle: const TextStyle(color: Colors.white),
          ),
          child: Slider(
            value: millingPercentage,
            min: 50,
            max: 75,
            divisions: 50,
            label: '${millingPercentage.toStringAsFixed(1)}%',
            onChanged: onMillingPercentageChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '50%',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'Standard: 65%',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '75%',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVisualBreakdown() {
    if (inputPaddyKg <= 0) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Center(
          child: Text(
            'Enter paddy weight to see breakdown',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final total = inputPaddyKg;
    final ricePercent = (expectedRiceKg / total) * 100;
    final brokenPercent = (expectedBrokenRiceKg / total) * 100;
    final huskPercent = (expectedHuskKg / total) * 100;
    final wastagePercent = (expectedWastageKg / total) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Output Breakdown',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),

        // Stacked Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              _buildBarSegment(ricePercent, AppColors.riceColor),
              _buildBarSegment(brokenPercent, Colors.orange),
              _buildBarSegment(huskPercent, Colors.brown),
              _buildBarSegment(wastagePercent, AppColors.grey400),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),

        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildLegendItem('Rice', AppColors.riceColor),
            _buildLegendItem('Broken Rice', Colors.orange),
            _buildLegendItem('Husk', Colors.brown),
            _buildLegendItem('Wastage', AppColors.grey400),
          ],
        ),
      ],
    );
  }

  Widget _buildBarSegment(double percent, Color color) {
    return Expanded(
      flex: percent.round(),
      child: Container(
        height: 24,
        color: color,
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  Widget _buildOutputDetails() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        children: [
          _buildOutputRow(
            'Input Paddy',
            '${inputPaddyKg.toStringAsFixed(1)} kg',
            Icons.grass,
            AppColors.paddyColor,
            isInput: true,
          ),
          const Divider(),
          _buildOutputRow(
            'Expected Rice',
            '${expectedRiceKg.toStringAsFixed(1)} kg',
            Icons.rice_bowl,
            AppColors.riceColor,
          ),
          _buildOutputRow(
            'Broken Rice',
            '${expectedBrokenRiceKg.toStringAsFixed(1)} kg',
            Icons.grain,
            Colors.orange,
          ),
          _buildOutputRow(
            'Husk',
            '${expectedHuskKg.toStringAsFixed(1)} kg',
            Icons.eco,
            Colors.brown,
          ),
          _buildOutputRow(
            'Wastage',
            '${expectedWastageKg.toStringAsFixed(1)} kg',
            Icons.delete_outline,
            AppColors.grey500,
          ),
        ],
      ),
    );
  }

  Widget _buildOutputRow(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isInput = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isInput ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

