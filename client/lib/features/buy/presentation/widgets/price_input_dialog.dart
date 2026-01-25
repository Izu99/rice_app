// lib/features/buy/presentation/widgets/price_input_dialog.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/shared_widgets/custom_keyboard/custom_keyboard.dart';
import '../../../../core/shared_widgets/custom_keyboard/keyboard_controller.dart';

/// Price input dialog for entering price per KG
class PriceInputDialog extends StatefulWidget {
  final ItemType itemType;
  final String variety;
  final double totalWeight;
  final int bags;
  final double? initialPrice;
  final double? lastPrice;
  final double? averagePrice;

  const PriceInputDialog({
    super.key,
    required this.itemType,
    required this.variety,
    required this.totalWeight,
    required this.bags,
    this.initialPrice,
    this.lastPrice,
    this.averagePrice,
  });

  @override
  State<PriceInputDialog> createState() => _PriceInputDialogState();

  /// Show price input dialog and return the price
  static Future<double?> show({
    required BuildContext context,
    required ItemType itemType,
    required String variety,
    required double totalWeight,
    required int bags,
    double? initialPrice,
    double? lastPrice,
    double? averagePrice,
  }) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PriceInputDialog(
        itemType: itemType,
        variety: variety,
        totalWeight: totalWeight,
        bags: bags,
        initialPrice: initialPrice,
        lastPrice: lastPrice,
        averagePrice: averagePrice,
      ),
    );
  }
}

class _PriceInputDialogState extends State<PriceInputDialog> {
  late KeyboardController _priceController;
  double _totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _priceController = KeyboardController(
      initialValue: widget.initialPrice != null && widget.initialPrice! > 0
          ? widget.initialPrice!.toStringAsFixed(2)
          : '',
      allowDecimal: true,
      decimalPlaces: 2,
    );
    _priceController.addListener(_calculateTotal);
    _calculateTotal();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final price = _priceController.doubleValue;
    setState(() {
      _totalAmount = price * widget.totalWeight;
    });
  }

  void _onQuickPrice(double price) {
    _priceController.setDouble(price);
  }

  void _onConfirm() {
    final price = _priceController.doubleValue;
    if (price > 0) {
      Navigator.of(context).pop(price);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPaddy = widget.itemType == ItemType.paddy;
    final accentColor = isPaddy ? AppColors.warning : AppColors.primary;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isPaddy ? Icons.grass : Icons.rice_bowl,
                        color: accentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter Price',
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.variety,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Item summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _InfoItem(
                        icon: Icons.shopping_bag,
                        value: '${widget.bags}',
                        label: 'Bags',
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppColors.divider,
                      ),
                      _InfoItem(
                        icon: Icons.scale,
                        value: widget.totalWeight.toStringAsFixed(2),
                        label: 'kg',
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppColors.divider,
                      ),
                      _InfoItem(
                        icon: Icons.speed,
                        value: (widget.totalWeight / widget.bags)
                            .toStringAsFixed(1),
                        label: 'kg/bag',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Price Input Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Price display
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accentColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Price per KG',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rs.',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _priceController.isEmpty
                                ? '0.00'
                                : _priceController.value,
                            style: AppTextStyles.displayMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Total amount
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Rs. ${_totalAmount.toStringAsFixed(2)}',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick price buttons
                if (widget.lastPrice != null || widget.averagePrice != null)
                  _buildQuickPriceButtons(),
              ],
            ),
          ),

          // Custom Keyboard
          CustomKeyboard(
            controller: _priceController,
            showDecimal: true,
            onDone: _onConfirm,
            doneLabel: 'Confirm Price',
            showDisplay: false,
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildQuickPriceButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Select',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (widget.lastPrice != null)
              _QuickPriceButton(
                label: 'Last: Rs.${widget.lastPrice!.toStringAsFixed(0)}',
                onTap: () => _onQuickPrice(widget.lastPrice!),
              ),
            if (widget.averagePrice != null)
              _QuickPriceButton(
                label: 'Avg: Rs.${widget.averagePrice!.toStringAsFixed(0)}',
                onTap: () => _onQuickPrice(widget.averagePrice!),
              ),
            // Common price suggestions
            ..._getCommonPriceSuggestions().map((price) => _QuickPriceButton(
                  label: 'Rs.$price',
                  onTap: () => _onQuickPrice(price.toDouble()),
                )),
          ],
        ),
      ],
    );
  }

  List<int> _getCommonPriceSuggestions() {
    if (widget.itemType == ItemType.paddy) {
      return [50, 55, 60, 65, 70, 75, 80];
    } else {
      return [100, 110, 120, 130, 140, 150, 160];
    }
  }
}

/// Info item widget
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _InfoItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Quick price button
class _QuickPriceButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickPriceButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

