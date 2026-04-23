import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../core/shared_widgets/sync_status_indicator.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../core/shared_widgets/app_page_scaffold.dart';
import '../../../../core/sync/sync_status.dart';
import '../../../../core/constants/enums.dart';
import '../cubit/stock_cubit.dart';
import '../cubit/stock_state.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<StockCubit>().loadStock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Refresh stock data when app comes to foreground
      context.read<StockCubit>().refreshStock();
    }
  }

  @override
  Widget build(BuildContext context) {
    context.select((ProfileCubit c) => c.state.language);
    return BlocConsumer<StockCubit, StockState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
          context.read<StockCubit>().clearError();
        }
      },
      builder: (context, state) {
        return LoadingOverlay(
          isLoading: state.status == StockStatus.loading,
          child: AppPageScaffold(
            title: SiStrings.liveStock,
            subtitle:
                SiStrings.isSinhala ? 'Stock Overview' : 'තොග දළ විශ්ලේෂණය',
            onRefresh: () => context.read<StockCubit>().refreshStock(),
            actions: [
              SyncStatusIndicator(
                status: state.isSynced
                    ? SyncStatusModel.success()
                    : SyncStatusModel.idle(),
              ),
              const SizedBox(width: 4),
            ],
            body: RefreshIndicator(
              onRefresh: () => context.read<StockCubit>().refreshStock(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildSummaryGrid(state),
                    const SizedBox(height: 32),
                    if (state.filterType == StockFilterType.all ||
                        state.filterType == StockFilterType.paddy)
                      _buildPaddyStockSection(state),
                    if (state.filterType == StockFilterType.all)
                      const SizedBox(height: 32),
                    if (state.filterType == StockFilterType.all ||
                        state.filterType == StockFilterType.rice)
                      _buildRiceStockSection(state),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF444466),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(StockState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionChip(SiStrings.stockOverview),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildModernSummaryCard(
                title: SiStrings.paddyStock,
                value: '${state.totalPaddyKg.toStringAsFixed(0)}',
                unit: 'KG',
                subtitle: 'මලු ${state.totalPaddyBags}',
                icon: Icons.grass_rounded,
                color: AppColors.paddy,
                isSelected: state.filterType == StockFilterType.paddy,
                onTap: () => context
                    .read<StockCubit>()
                    .filterByType(StockFilterType.paddy),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernSummaryCard(
                title: SiStrings.riceStock,
                value: '${state.totalRiceKg.toStringAsFixed(0)}',
                unit: 'KG',
                subtitle: 'මලු ${state.totalRiceBags}',
                icon: Icons.rice_bowl_rounded,
                color: AppColors.riceAccent,
                isSelected: state.filterType == StockFilterType.rice,
                onTap: () => context
                    .read<StockCubit>()
                    .filterByType(StockFilterType.rice),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernSummaryCard({
    required String title,
    required String value,
    required String unit,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: color, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      fontSize: 20,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textHint,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaddyStockSection(StockState state) {
    final paddyItems =
        state.allItems.where((item) => item.type == ItemType.paddy).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            SiStrings.paddyStockVarieties, Icons.inventory_2_rounded),
        const SizedBox(height: 16),
        _buildStockTable(paddyItems, AppColors.paddy),
      ],
    );
  }

  Widget _buildRiceStockSection(StockState state) {
    final riceItems =
        state.allItems.where((item) => item.type == ItemType.rice).toList();

    if (riceItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            SiStrings.riceStockVarieties, Icons.auto_awesome_rounded),
        const SizedBox(height: 16),
        _buildStockTable(riceItems, AppColors.riceAccent),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(icon, size: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1C1C2E),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        _buildSectionChip('${title.split(' ').first} Items'),
      ],
    );
  }

  Widget _buildStockTable(List<dynamic> items, Color accentColor) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 48, color: AppColors.grey300),
            const SizedBox(height: 16),
            Text(
              'No items in this category',
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
            ),
          ],
        ),
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: const Color(0xFFF8F9FB),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(SiStrings.variety, // VARIETY
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF8E8E93),
                        letterSpacing: 0.5,
                      )),
                ),
                Expanded(
                  flex: 2,
                  child: Text('BAGS', // BAGS
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF8E8E93),
                        letterSpacing: 0.5,
                      )),
                ),
                Expanded(
                  flex: 3,
                  child: Text('WEIGHT (KG)', // WEIGHT (KG)
                      textAlign: TextAlign.right,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF8E8E93),
                        letterSpacing: 0.5,
                      )),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F1F1)),
          // Table Body
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Color(0xFFF1F1F1)),
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.variety
                                    .replaceAll('Rice - ', '')
                                    .replaceAll('Paddy - ', ''),
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1C1C2E),
                                  fontSize: 16,
                                ),
                              ),
                              if (item.isLowStock)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'LOW STOCK',
                                    style: TextStyle(
                                        color: AppColors.error,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${item.currentBags}',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1C1C2E),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '${item.currentQuantity.toStringAsFixed(1)}',
                            textAlign: TextAlign.right,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w900,
                              color: accentColor,
                              fontSize: 18,
                            ),
                          ),
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
