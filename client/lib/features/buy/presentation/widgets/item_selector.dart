// lib/features/buy/presentation/widgets/item_selector.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/stock_item_model.dart';

/// Item type and variety selector for Buy/Sell
class ItemSelector extends StatefulWidget {
  final ItemType? selectedType;
  final String? selectedVariety;
  final StockItemModel? selectedItem;
  final ValueChanged<ItemType> onTypeChanged;
  final ValueChanged<String> onVarietyChanged;
  final ValueChanged<StockItemModel>? onItemSelected;
  final List<StockItemModel>? availableItems;
  final bool showStock;
  final bool allowCustomVariety;
  final bool isEnabled;

  const ItemSelector({
    super.key,
    this.selectedType,
    this.selectedVariety,
    this.selectedItem,
    required this.onTypeChanged,
    required this.onVarietyChanged,
    this.onItemSelected,
    this.availableItems,
    this.showStock = false,
    this.allowCustomVariety = true,
    this.isEnabled = true,
  });

  @override
  State<ItemSelector> createState() => _ItemSelectorState();
}

class _ItemSelectorState extends State<ItemSelector> {
  bool _showVarietyList = false;
  bool _isCustomVariety = false;
  final _customVarietyController = TextEditingController();

  // Predefined varieties
  static const List<String> _paddyVarieties = [
    'සම්බා', // Samba
    'නාඩු', // Nadu
    'කීරි සම්බා', // Keeri Samba
    'සුවඳැල්', // Suwandel
    'පච්චපෙරුමාල්', // Pachchaperumal
    'රතු හීනටි', // Rathu Heenati
    'මඩතවාලු', // Madathawalu
  ];

  static const List<String> _riceVarieties = [
    'සම්බා සහල්', // Samba Rice
    'නාඩු සහල්', // Nadu Rice
    'කීරි සම්බා සහල්', // Keeri Samba Rice
    'රතු සහල්', // Red Rice
    'සුදු සහල්', // White Rice
    'බාස්මතී', // Basmati
  ];

  List<String> get _currentVarieties =>
      widget.selectedType == ItemType.paddy ? _paddyVarieties : _riceVarieties;

  @override
  void dispose() {
    _customVarietyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Text(
          'අයිතමය තෝරන්න',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Type Selection
        _buildTypeSelection(),
        const SizedBox(height: 16),

        // Variety Selection
        if (widget.selectedType != null) _buildVarietySection(),
      ],
    );
  }

  Widget _buildTypeSelection() {
    return Row(
      children: [
        Expanded(
          child: _TypeCard(
            title: 'වී',
            subtitle: 'Paddy',
            icon: Icons.grass,
            color: AppColors.warning,
            isSelected: widget.selectedType == ItemType.paddy,
            isEnabled: widget.isEnabled,
            onTap: () {
              widget.onTypeChanged(ItemType.paddy);
              setState(() {
                _showVarietyList = false;
                _isCustomVariety = false;
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TypeCard(
            title: 'සහල්',
            subtitle: 'Rice',
            icon: Icons.rice_bowl,
            color: AppColors.primary,
            isSelected: widget.selectedType == ItemType.rice,
            isEnabled: widget.isEnabled,
            onTap: () {
              widget.onTypeChanged(ItemType.rice);
              setState(() {
                _showVarietyList = false;
                _isCustomVariety = false;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVarietySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ප්‍රභේදය (Variety)',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.allowCustomVariety)
              TextButton.icon(
                onPressed: widget.isEnabled
                    ? () {
                        setState(() {
                          _isCustomVariety = !_isCustomVariety;
                          _showVarietyList = false;
                        });
                      }
                    : null,
                icon: Icon(
                  _isCustomVariety ? Icons.list : Icons.edit,
                  size: 16,
                ),
                label: Text(
                  _isCustomVariety ? 'ලැයිස්තුව' : 'වෙනත්',
                  style: AppTextStyles.labelMedium,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isCustomVariety)
          _buildCustomVarietyInput()
        else
          _buildVarietySelector(),
      ],
    );
  }

  Widget _buildVarietySelector() {
    // If showing items from stock
    if (widget.availableItems != null && widget.availableItems!.isNotEmpty) {
      return _buildStockItemsList();
    }

    // Show predefined varieties
    return _buildPredefinedVarietiesList();
  }

  Widget _buildStockItemsList() {
    final items = widget.availableItems!
        .where((item) => item.type == widget.selectedType)
        .toList();

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 40,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 8),
              Text(
                'තොගයේ ${widget.selectedType == ItemType.paddy ? 'වී' : 'සහල්'} නැත',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = widget.selectedItem?.id == item.id;

          return _StockItemTile(
            item: item,
            isSelected: isSelected,
            showStock: widget.showStock,
            onTap: widget.isEnabled && widget.onItemSelected != null
                ? () => widget.onItemSelected!(item)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildPredefinedVarietiesList() {
    return InkWell(
      onTap: widget.isEnabled
          ? () => setState(() => _showVarietyList = !_showVarietyList)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _showVarietyList ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (widget.selectedType == ItemType.paddy
                            ? AppColors.warning
                            : AppColors.primary)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.eco,
                    color: widget.selectedType == ItemType.paddy
                        ? AppColors.warning
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.selectedVariety ?? 'ප්‍රභේදය තෝරන්න',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: widget.selectedVariety != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ),
                Icon(
                  _showVarietyList
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),

            // Expanded variety list
            if (_showVarietyList) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _currentVarieties.map((variety) {
                  final isSelected = widget.selectedVariety == variety;
                  return _VarietyChip(
                    label: variety,
                    isSelected: isSelected,
                    onTap: () {
                      widget.onVarietyChanged(variety);
                      setState(() => _showVarietyList = false);
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomVarietyInput() {
    return TextField(
      controller: _customVarietyController,
      enabled: widget.isEnabled,
      decoration: InputDecoration(
        hintText: 'ප්‍රභේදයේ නම ඇතුළත් කරන්න',
        prefixIcon: const Icon(Icons.eco),
        suffixIcon: IconButton(
          icon: const Icon(Icons.check),
          onPressed: () {
            final variety = _customVarietyController.text.trim();
            if (variety.isNotEmpty) {
              widget.onVarietyChanged(variety);
            }
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textCapitalization: TextCapitalization.words,
      onSubmitted: (value) {
        if (value.trim().isNotEmpty) {
          widget.onVarietyChanged(value.trim());
        }
      },
    );
  }
}

/// Type selection card
class _TypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _TypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Variety chip widget
class _VarietyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _VarietyChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? AppColors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Stock item tile
class _StockItemTile extends StatelessWidget {
  final StockItemModel item;
  final bool isSelected;
  final bool showStock;
  final VoidCallback? onTap;

  const _StockItemTile({
    required this.item,
    required this.isSelected,
    required this.showStock,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: isSelected ? AppColors.primaryLight : Colors.transparent,
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (item.type == ItemType.paddy
                            ? AppColors.warning
                            : AppColors.primary)
                        .withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.type == ItemType.paddy ? Icons.grass : Icons.rice_bowl,
                color: isSelected
                    ? AppColors.white
                    : (item.type == ItemType.paddy
                        ? AppColors.warning
                        : AppColors.primary),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Item info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.variety,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (showStock) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Stock: ${item.formattedQuantity}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: item.isLowStock
                            ? AppColors.warning
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Stock badge
            if (showStock)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: item.isOutOfStock
                      ? AppColors.error.withOpacity(0.1)
                      : item.isLowStock
                          ? AppColors.warning.withOpacity(0.1)
                          : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.stockStatus,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: item.isOutOfStock
                        ? AppColors.error
                        : item.isLowStock
                            ? AppColors.warning
                            : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // Selection indicator
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
