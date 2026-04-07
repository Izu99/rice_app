// lib/features/price_management/presentation/widgets/price_list_item.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/paddy_rice_price_entity.dart';

class PriceListItem extends StatelessWidget {
  final PaddyRicePriceEntity price;
  final VoidCallback? onTap;

  const PriceListItem({
    super.key,
    required this.price,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPaddy = price.priceType == 'paddy';
    final typeColor = isPaddy ? const Color(0xFF8BC34A) : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          price.companyName,
                          style: AppTextStyles.titleMedium
                              .copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Price type badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPaddy
                                        ? Icons.grass_rounded
                                        : Icons.rice_bowl_rounded,
                                    size: 12,
                                    color: typeColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isPaddy ? 'PADDY' : 'RICE',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: typeColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (price.qualityGrade != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getQualityColor(price.qualityGrade!)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  price.qualityGrade!.toUpperCase(),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color:
                                        _getQualityColor(price.qualityGrade!),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Price display
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Rs.',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.grey600)),
                        const SizedBox(height: 2),
                        Text(
                          price.priceDisplay,
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: typeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: AppColors.grey300),
              const SizedBox(height: 10),

              // Footer row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Added: ${_formatDate(price.createdAt)}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (price.notes != null && price.notes!.isNotEmpty)
                    Tooltip(
                      message: price.notes!,
                      child: Icon(Icons.info_outline,
                          color: AppColors.grey600, size: 18),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly == today) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getQualityColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'premium':
        return Colors.amber.shade700;
      case 'standard':
        return AppColors.success;
      case 'basic':
        return AppColors.warning;
      default:
        return AppColors.grey600;
    }
  }
}
