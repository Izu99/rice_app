import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubit/stock_state.dart';

class StockFilter extends StatelessWidget {
  final StockFilterType selectedFilter;
  final String searchQuery;
  final Function(StockFilterType) onFilterChanged;
  final Function(String) onSearchChanged;

  const StockFilter({
    super.key,
    required this.selectedFilter,
    required this.searchQuery,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        children: [
          // Search Field
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search stock items...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => onSearchChanged(''),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: const BorderSide(color: AppColors.grey300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: const BorderSide(color: AppColors.grey300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
                vertical: AppDimensions.paddingS,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),

          // Filter Chips
          Row(
            children: [
              _buildFilterChip(
                label: 'All',
                filterType: StockFilterType.all,
                icon: Icons.inventory,
              ),
              const SizedBox(width: AppDimensions.paddingS),
              _buildFilterChip(
                label: 'Paddy',
                filterType: StockFilterType.paddy,
                icon: Icons.grass,
                color: AppColors.paddyColor,
              ),
              const SizedBox(width: AppDimensions.paddingS),
              _buildFilterChip(
                label: 'Rice',
                filterType: StockFilterType.rice,
                icon: Icons.rice_bowl,
                color: AppColors.riceColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required StockFilterType filterType,
    required IconData icon,
    Color? color,
  }) {
    final isSelected = selectedFilter == filterType;
    final chipColor = color ?? AppColors.primary;

    return Expanded(
      child: InkWell(
        onTap: () => onFilterChanged(filterType),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingS,
            horizontal: AppDimensions.paddingM,
          ),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: isSelected ? chipColor : AppColors.grey300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: chipColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : chipColor,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
