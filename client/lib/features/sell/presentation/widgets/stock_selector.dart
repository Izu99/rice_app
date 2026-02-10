// lib/features/sell/presentation/widgets/stock_selector.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../data/models/stock_item_model.dart';

class StockSelector extends StatefulWidget {
  final List<StockItemModel> availableStock;
  final StockItemModel? selectedItem;
  final Function(StockItemModel) onItemSelected;

  const StockSelector({
    super.key,
    required this.availableStock,
    this.selectedItem,
    required this.onItemSelected,
  });

  @override
  State<StockSelector> createState() => _StockSelectorState();
}

class _StockSelectorState extends State<StockSelector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<StockItemModel> get _filteredStock {
    var filtered = widget.availableStock;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.variety.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply tab filter
    switch (_tabController.index) {
      case 1:
        filtered =
            filtered.where((item) => item.type == ItemType.paddy).toList();
        break;
      case 2:
        filtered =
            filtered.where((item) => item.type == ItemType.rice).toList();
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingS),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: SiStrings.searchStock,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Sort dropdown
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                onSelected: (value) {
                  setState(() {
                    _selectedFilter = value;
                  });
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'name',
                    child: Text(SiStrings.sortByName),
                  ),
                  PopupMenuItem(
                    value: 'quantity',
                    child: Text(SiStrings.sortByQuantity),
                  ),
                  PopupMenuItem(
                    value: 'recent',
                    child: Text(SiStrings.recentlyAdded),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Tab bar
        Container(
          color: Colors.grey[100],
          child: TabBar(
            controller: _tabController,
            onTap: (_) => setState(() {}),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(SiStrings.all),
                    const SizedBox(width: 4),
                    _buildBadge(widget.availableStock.length),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.grass, size: 16),
                    const SizedBox(width: 4),
                    Text(SiStrings.paddy),
                    const SizedBox(width: 4),
                    _buildBadge(
                      widget.availableStock
                          .where((i) => i.type == ItemType.paddy)
                          .length,
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.rice_bowl, size: 16),
                    const SizedBox(width: 4),
                    Text(SiStrings.rice),
                    const SizedBox(width: 4),
                    _buildBadge(
                      widget.availableStock
                          .where((i) => i.type == ItemType.rice)
                          .length,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Stock grid
        Expanded(
          child: _filteredStock.isEmpty
              ? _buildEmptyState()
              : LayoutBuilder(builder: (context, constraints) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(AppDimensions.paddingS),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: constraints.maxWidth < 450 ? 1 : 2,
                      childAspectRatio: constraints.maxWidth < 450 ? 2.5 : 1.1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _filteredStock.length,
                    itemBuilder: (context, index) {
                      final item = _filteredStock[index];
                      final isSelected = widget.selectedItem?.id == item.id;

                      return _StockItemCard(
                        item: item,
                        isSelected: isSelected,
                        onTap: () => widget.onItemSelected(item),
                      );
                    },
                  );
                }),
        ),
      ],
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'තොග කිසිවක් හමු නොවීය',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'විකිණීම ආරම්භ කිරීමට තොග එක් කරන්න',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockItemCard extends StatelessWidget {
  final StockItemModel item;
  final bool isSelected;
  final VoidCallback onTap;

  const _StockItemCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRice = item.type == ItemType.rice;
    final typeColor = isRice ? AppColors.riceColor : AppColors.paddyColor;
    final lowStock = item.currentQuantity < 100; // Less than 100kg

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? typeColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: isSelected ? typeColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: typeColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.type.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Low stock warning
                  if (lowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            size: 12,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            SiStrings.low,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Name
              Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Variety
              Text(
                item.variety,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Available quantity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${SiStrings.available}:',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '${item.currentQuantity.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color:
                          lowStock ? AppColors.warning : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),

              // Last price indicator
              if (item.sellingPricePerKg != null &&
                  item.sellingPricePerKg! > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${SiStrings.sellingPrice}:',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'Rs.${item.sellingPricePerKg!.toStringAsFixed(2)}/kg',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
