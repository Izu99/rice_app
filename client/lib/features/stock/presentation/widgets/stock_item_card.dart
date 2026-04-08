import 'package:flutter/material.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/stock_item_model.dart';

class StockItemCard extends StatelessWidget {
  final StockItemModel item;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const StockItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isPaddy = item.itemType == ItemType.paddy;
    final typeColor = isPaddy ? AppColors.paddy : AppColors.riceAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Type Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isPaddy ? Icons.grass_rounded : Icons.rice_bowl_rounded,
                        color: typeColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Name & Type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              color: Color(0xFF1C1C2E),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPaddy ? 'Paddy' : 'Rice',
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Sync Status
                    if (!item.isSynced)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_off_rounded,
                          color: AppColors.warning,
                          size: 14,
                        ),
                      ),

                    // Edit Button
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: onEdit,
                        color: AppColors.textSecondary,
                        iconSize: 20,
                      ),
                  ],
                ),

                const Divider(height: AppDimensions.paddingL),

                // Stock Details Row
                Row(
                  children: [
                    // Weight
                    Expanded(
                      child: _buildDetailColumn(
                        icon: Icons.scale,
                        label: 'Weight',
                        value: '${item.totalWeightKg.toStringAsFixed(1)} kg',
                        color: typeColor,
                      ),
                    ),

                    // Vertical Divider
                    Container(
                      height: 40,
                      width: 1,
                      color: AppColors.grey200,
                    ),

                    // Bags
                    Expanded(
                      child: _buildDetailColumn(
                        icon: Icons.inventory_2,
                        label: 'Bags',
                        value: '${item.totalBags}',
                        color: typeColor,
                      ),
                    ),

                    // Vertical Divider
                    Container(
                      height: 40,
                      width: 1,
                      color: AppColors.grey200,
                    ),

                    // Price
                    Expanded(
                      child: _buildDetailColumn(
                        icon: Icons.attach_money,
                        label: 'Price/kg',
                        value: 'Rs.${item.pricePerKg.toStringAsFixed(0)}',
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                // Total Value
                const SizedBox(height: AppDimensions.paddingM),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.paddingS),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Value',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Rs. ${(item.totalWeightKg * item.pricePerKg).toStringAsFixed(2)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Last Updated
                ...[
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(
                    'Updated: ${_formatDate(item.updatedAt)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailColumn({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color.withOpacity(0.7)),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
