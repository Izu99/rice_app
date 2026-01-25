// lib/features/buy/presentation/widgets/temp_items_table.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubit/buy_state.dart';

/// Temporary items table for Buy flow batches
class TempItemsTable extends StatelessWidget {
  final List<TempBuyItem> items;
  final Function(String) onRemove;

  const TempItemsTable({
    super.key,
    required this.items,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text('Variety',
                        style: AppTextStyles.labelMedium
                            .copyWith(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 1,
                    child: Text('Bags',
                        style: AppTextStyles.labelMedium
                            .copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center)),
                Expanded(
                    flex: 3,
                    child: Text('Weight',
                        style: AppTextStyles.labelMedium
                            .copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right)),
                const SizedBox(width: 40),
              ],
            ),
          ),
          const Divider(height: 1),

          // Batch List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.variety,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text('Batch #${index + 1}',
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text('${item.bagsCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text('${item.totalWeight.toStringAsFixed(2)} kg',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: AppColors.error, size: 20),
                      onPressed: () => onRemove(item.id),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

