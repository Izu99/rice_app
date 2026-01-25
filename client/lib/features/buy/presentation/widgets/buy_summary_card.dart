// lib/features/buy/presentation/widgets/buy_summary_card.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/transaction_item_model.dart';
import '../../../../data/models/customer_model.dart';

/// Buy summary card showing transaction totals
class BuySummaryCard extends StatelessWidget {
  final CustomerModel? customer;
  final List<TransactionItemModel> items;
  final double discount;
  final double paidAmount;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final VoidCallback? onEditDiscount;
  final VoidCallback? onEditPayment;

  const BuySummaryCard({
    super.key,
    this.customer,
    required this.items,
    this.discount = 0,
    this.paidAmount = 0,
    this.isExpanded = false,
    this.onToggleExpand,
    this.onEditDiscount,
    this.onEditPayment,
  });

  // Calculations
  int get totalBags => items.fold(0, (sum, item) => sum + item.bags);
  double get totalWeight =>
      items.fold(0.0, (sum, item) => sum + item.totalWeight);
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get totalAmount => subtotal - discount;
  double get dueAmount => totalAmount - paidAmount;
  bool get isFullyPaid => dueAmount <= 0;

  // Item type breakdown
  Map<ItemType, double> get weightByType {
    final result = <ItemType, double>{};
    for (final item in items) {
      result[item.itemType] = (result[item.itemType] ?? 0) + item.totalWeight;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Summary (always visible)
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: AppColors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transaction Summary',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'ගනුදෙනු සාරාංශය',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onToggleExpand != null)
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: AppColors.white,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick Stats
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          icon: Icons.list_alt,
                          value: '${items.length}',
                          label: 'Items',
                        ),
                        _VerticalDivider(),
                        _StatItem(
                          icon: Icons.shopping_bag,
                          value: '$totalBags',
                          label: 'Bags',
                        ),
                        _VerticalDivider(),
                        _StatItem(
                          icon: Icons.scale,
                          value: totalWeight.toStringAsFixed(1),
                          label: 'kg',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Total Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.white.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        'Rs. ${totalAmount.toStringAsFixed(2)}',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // Due Amount (if not fully paid)
                  if (paidAmount > 0 && !isFullyPaid) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Due Amount',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                        Text(
                          'Rs. ${dueAmount.toStringAsFixed(2)}',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Expanded Details
          if (isExpanded) _buildExpandedDetails(),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),

          // Customer info (if available)
          if (customer != null) ...[
            _DetailRow(
              label: 'Customer',
              value: customer!.name,
              icon: Icons.person,
            ),
            const SizedBox(height: 8),
          ],

          // Weight breakdown by type
          ...weightByType.entries.map((entry) {
            final isPaddy = entry.key == ItemType.paddy;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DetailRow(
                label: isPaddy ? 'Paddy (වී)' : 'Rice (සහල්)',
                value: '${entry.value.toStringAsFixed(2)} kg',
                icon: isPaddy ? Icons.grass : Icons.rice_bowl,
                iconColor: isPaddy ? AppColors.warning : AppColors.info,
              ),
            );
          }),

          // Subtotal
          _DetailRow(
            label: 'Subtotal',
            value: 'Rs. ${subtotal.toStringAsFixed(2)}',
          ),

          // Discount
          if (discount > 0 || onEditDiscount != null)
            InkWell(
              onTap: onEditDiscount,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _DetailRow(
                  label: 'Discount',
                  value: '- Rs. ${discount.toStringAsFixed(2)}',
                  valueColor: AppColors.warning,
                  trailing: onEditDiscount != null
                      ? const Icon(
                          Icons.edit,
                          color: Colors.white54,
                          size: 16,
                        )
                      : null,
                ),
              ),
            ),

          const Divider(color: Colors.white24, height: 20),

          // Total
          _DetailRow(
            label: 'Total',
            value: 'Rs. ${totalAmount.toStringAsFixed(2)}',
            isTotal: true,
          ),
          const SizedBox(height: 8),

          // Payment
          InkWell(
            onTap: onEditPayment,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _DetailRow(
                label: 'Paid Amount',
                value: 'Rs. ${paidAmount.toStringAsFixed(2)}',
                valueColor: AppColors.success,
                trailing: onEditPayment != null
                    ? const Icon(
                        Icons.edit,
                        color: Colors.white54,
                        size: 16,
                      )
                    : null,
              ),
            ),
          ),

          // Due
          if (!isFullyPaid)
            _DetailRow(
              label: 'Balance Due',
              value: 'Rs. ${dueAmount.toStringAsFixed(2)}',
              valueColor: AppColors.warning,
            ),

          // Payment status badge
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isFullyPaid
                  ? AppColors.success.withOpacity(0.2)
                  : AppColors.warning.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFullyPaid ? Icons.check_circle : Icons.access_time,
                  color: isFullyPaid ? AppColors.success : AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isFullyPaid ? 'Fully Paid' : 'Pending Payment',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isFullyPaid ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat item widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Vertical divider
class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white24,
    );
  }
}

/// Detail row widget
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? valueColor;
  final bool isTotal;
  final Widget? trailing;

  const _DetailRow({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.valueColor,
    this.isTotal = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: iconColor ?? Colors.white70,
            size: 16,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style:
                (isTotal ? AppTextStyles.titleSmall : AppTextStyles.bodyMedium)
                    .copyWith(
              color: isTotal ? AppColors.white : Colors.white70,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style:
              (isTotal ? AppTextStyles.titleMedium : AppTextStyles.bodyMedium)
                  .copyWith(
            color: valueColor ?? AppColors.white,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

/// Compact summary for inline display
class CompactBuySummary extends StatelessWidget {
  final int itemCount;
  final int totalBags;
  final double totalWeight;
  final double totalAmount;

  const CompactBuySummary({
    super.key,
    required this.itemCount,
    required this.totalBags,
    required this.totalWeight,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _CompactStat(value: '$itemCount', label: 'items'),
              const SizedBox(width: 16),
              _CompactStat(value: '$totalBags', label: 'bags'),
              const SizedBox(width: 16),
              _CompactStat(value: totalWeight.toStringAsFixed(1), label: 'kg'),
            ],
          ),
          Text(
            'Rs. ${totalAmount.toStringAsFixed(0)}',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String value;
  final String label;

  const _CompactStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

