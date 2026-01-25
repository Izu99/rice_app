import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'keyboard_controller.dart';
import 'keyboard_key.dart';

/// Custom numeric keyboard widget
class CustomKeyboard extends StatelessWidget {
  /// Controller for keyboard input
  final KeyboardController controller;

  /// Callback when done is pressed
  final VoidCallback? onDone;

  /// Label for done button
  final String? doneLabel;

  /// Whether to show decimal key
  final bool showDecimal;

  /// Whether to show done button
  final bool showDone;

  /// Label for display
  final String? displayLabel;

  /// Suffix for display (e.g., 'kg')
  final String? displaySuffix;

  /// Prefix for display (e.g., 'Rs.')
  final String? displayPrefix;

  /// Whether to show display panel
  final bool showDisplay;

  /// Custom key builder
  final Widget Function(String key, VoidCallback onTap)? keyBuilder;

  /// Keyboard padding
  final EdgeInsets? padding;

  /// Gap between keys
  final double keyGap;

  /// Key size
  final double? keySize;

  const CustomKeyboard({
    super.key,
    required this.controller,
    this.onDone,
    this.doneLabel,
    this.showDecimal = true,
    this.showDone = true,
    this.displayLabel,
    this.displaySuffix,
    this.displayPrefix,
    this.showDisplay = true,
    this.keyBuilder,
    this.padding,
    this.keyGap = AppDimensions.paddingS,
    this.keySize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            _buildHandleBar(),

            // Display panel
            if (showDisplay) ...[
              const SizedBox(height: AppDimensions.paddingM),
              _buildDisplay(),
            ],

            const SizedBox(height: AppDimensions.paddingM),

            // Keyboard grid
            _buildKeyboard(),

            // Done button
            if (showDone) ...[
              const SizedBox(height: AppDimensions.paddingM),
              _buildDoneButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHandleBar() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.grey300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildDisplay() {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingL,
            vertical: AppDimensions.paddingM,
          ),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (displayLabel != null)
                Text(
                  displayLabel!,
                  style: AppTextStyles.caption,
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (displayPrefix != null)
                    Text(
                      displayPrefix!,
                      style: AppTextStyles.h5.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      controller.isEmpty ? '0' : controller.value,
                      style: AppTextStyles.numberLarge.copyWith(
                        fontSize: 42,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (displaySuffix != null) ...[
                    const SizedBox(width: AppDimensions.paddingS),
                    Text(
                      displaySuffix!,
                      style: AppTextStyles.h5.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKeyboard() {
    final size = keySize ?? 65.0;

    return Column(
      children: [
        // Row 1: 1, 2, 3
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDigitKey('1', size),
            _buildDigitKey('2', size),
            _buildDigitKey('3', size),
          ],
        ),
        SizedBox(height: keyGap),

        // Row 2: 4, 5, 6
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDigitKey('4', size),
            _buildDigitKey('5', size),
            _buildDigitKey('6', size),
          ],
        ),
        SizedBox(height: keyGap),

        // Row 3: 7, 8, 9
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDigitKey('7', size),
            _buildDigitKey('8', size),
            _buildDigitKey('9', size),
          ],
        ),
        SizedBox(height: keyGap),

        // Row 4: ., 0, backspace (or clear, 0, backspace)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (showDecimal)
              KeyboardKey.decimal(
                onTap: () => controller.appendDigit('.'),
                width: size,
                height: size,
              )
            else
              KeyboardKey.clear(
                onTap: () => controller.clear(),
                width: size,
                height: size,
              ),
            _buildDigitKey('0', size),
            KeyboardKey.backspace(
              onTap: () => controller.backspace(),
              onLongPress: () => controller.clear(),
              width: size,
              height: size,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDigitKey(String digit, double size) {
    if (keyBuilder != null) {
      return keyBuilder!(digit, () => controller.appendDigit(digit));
    }

    return KeyboardKey.digit(
      digit,
      onTap: () => controller.appendDigit(digit),
      width: size,
      height: size,
    );
  }

  Widget _buildDoneButton() {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeightL,
      child: ElevatedButton(
        onPressed: onDone,
        child: Text(doneLabel ?? 'Done'),
      ),
    );
  }
}

/// Weight input keyboard with bag counter
class WeightInputKeyboard extends StatelessWidget {
  final KeyboardController controller;
  final VoidCallback? onDone;
  final VoidCallback? onAddBag;
  final int bagCount;
  final String? itemName;

  const WeightInputKeyboard({
    super.key,
    required this.controller,
    this.onDone,
    this.onAddBag,
    this.bagCount = 0,
    this.itemName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Weight display
            _buildWeightDisplay(),

            const SizedBox(height: AppDimensions.paddingM),

            // Keyboard with action buttons
            _buildKeyboardWithActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightDisplay() {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              // Item name and bag count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (itemName != null)
                    Text(
                      itemName!,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    )
                  else
                    Text(
                      'බර (Weight)',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingM,
                      vertical: AppDimensions.paddingXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusRound),
                    ),
                    child: Text(
                      'බෑග් $bagCount',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingS),

              // Weight value
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      controller.isEmpty ? '0.000' : controller.value,
                      style: AppTextStyles.numberLarge.copyWith(
                        fontSize: 48,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingS),
                  Text(
                    'kg',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKeyboardWithActions() {
    const keySize = 60.0;
    const actionWidth = 75.0;
    const actionHeight = 110.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Number pad
        Expanded(
          child: Column(
            children: [
              // Row 1
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildKey('1', keySize),
                  _buildKey('2', keySize),
                  _buildKey('3', keySize),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingS),

              // Row 2
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildKey('4', keySize),
                  _buildKey('5', keySize),
                  _buildKey('6', keySize),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingS),

              // Row 3
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildKey('7', keySize),
                  _buildKey('8', keySize),
                  _buildKey('9', keySize),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingS),

              // Row 4
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  KeyboardKey.decimal(
                    onTap: () => controller.appendDigit('.'),
                    width: keySize,
                    height: keySize - 5,
                  ),
                  _buildKey('0', keySize),
                  KeyboardKey.backspace(
                    onTap: () => controller.backspace(),
                    onLongPress: () => controller.clear(),
                    width: keySize,
                    height: keySize - 5,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: AppDimensions.paddingM),

        // Action buttons column
        Column(
          children: [
            // Add Bag button
            _buildActionButton(
              icon: Icons.add_circle_outline,
              label: 'Add\nBag',
              color: AppColors.secondaryLight,
              onTap: onAddBag,
              width: actionWidth,
              height: actionHeight,
            ),
            const SizedBox(height: AppDimensions.paddingS),

            // Done button
            _buildActionButton(
              icon: Icons.check_circle_outline,
              label: 'Done',
              color: AppColors.primary,
              onTap: onDone,
              width: actionWidth,
              height: actionHeight,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String digit, double size) {
    return SizedBox(
      width: size,
      height: size - 5,
      child: Material(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: InkWell(
          onTap: () => controller.appendDigit(digit),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Center(
            child: Text(
              digit,
              style: AppTextStyles.numberMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    required double width,
    required double height,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppDimensions.iconL,
                color: AppColors.white,
              ),
              const SizedBox(height: AppDimensions.paddingXS),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Price input keyboard with quick select
class PriceInputKeyboard extends StatelessWidget {
  final KeyboardController controller;
  final VoidCallback? onDone;
  final double? totalWeight;
  final List<int> quickPrices;

  const PriceInputKeyboard({
    super.key,
    required this.controller,
    this.onDone,
    this.totalWeight,
    this.quickPrices = const [50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100, 110],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const Text('Enter Price per kg', style: AppTextStyles.h5),

            if (totalWeight != null) ...[
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                'Total weight: ${totalWeight!.toStringAsFixed(3)} kg',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],

            const SizedBox(height: AppDimensions.paddingL),

            // Price display with total
            _buildPriceDisplay(),

            const SizedBox(height: AppDimensions.paddingL),

            // Quick price selector
            _buildQuickPrices(),

            const SizedBox(height: AppDimensions.paddingL),

            // Keyboard
            CustomKeyboard(
              controller: controller,
              showDisplay: false,
              showDone: true,
              doneLabel: 'Confirm Price',
              onDone: onDone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDisplay() {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final price = controller.doubleValue;
        final total = totalWeight != null ? price * totalWeight! : 0.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rs. ',
                    style: AppTextStyles.h5.copyWith(color: AppColors.primary),
                  ),
                  Text(
                    controller.isEmpty ? '0' : controller.value,
                    style: AppTextStyles.numberLarge.copyWith(
                      fontSize: 42,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Text(
                'per kg',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (price > 0 && totalWeight != null) ...[
                const SizedBox(height: AppDimensions.paddingM),
                const Divider(),
                const SizedBox(height: AppDimensions.paddingM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:',
                        style: AppTextStyles.bodyMedium),
                    Text(
                      'Rs. ${total.toStringAsFixed(2)}',
                      style:
                          AppTextStyles.h5.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickPrices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Select',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingS),
        Wrap(
          spacing: AppDimensions.paddingS,
          runSpacing: AppDimensions.paddingS,
          children: quickPrices.map((price) {
            return InkWell(
              onTap: () => controller.setValue(price.toString()),
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                  vertical: AppDimensions.paddingS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusRound),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Text(
                  'Rs.$price',
                  style: AppTextStyles.labelMedium,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

