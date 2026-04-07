// lib/features/super_admin/presentation/screens/admin_price_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../features/price_management/presentation/cubit/price_management_cubit.dart';
import '../../../../features/price_management/presentation/cubit/price_management_state.dart';
import '../../../../features/price_management/presentation/widgets/price_list_item.dart';
import '../../../../core/constants/districts.dart';

class AdminPriceListScreen extends StatefulWidget {
  const AdminPriceListScreen({super.key});

  @override
  State<AdminPriceListScreen> createState() => _AdminPriceListScreenState();
}

class _AdminPriceListScreenState extends State<AdminPriceListScreen> {
  final _searchController = TextEditingController();
  String? _selectedDistrict;
  String? _selectedPriceType; // null = all, 'paddy', 'rice'

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  void _loadPrices({int page = 1}) {
    context.read<PriceManagementCubit>().loadAllPricesAdmin(
          page: page,
          district: _selectedDistrict,
          priceType: _selectedPriceType,
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: BlocBuilder<PriceManagementCubit, PriceManagementState>(
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: state.status == PriceManagementStatus.loadingPrices,
            child: RefreshIndicator(
              onRefresh: () async => _loadPrices(),
              color: AppColors.adminPrimary,
              child: CustomScrollView(
                slivers: [
                  _buildStickyHeader(context),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildFiltersSection(),
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                            'Available Prices',
                            subtitle: '${state.prices.length} items',
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  if (state.status == PriceManagementStatus.error)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildErrorState(state),
                    )
                  else if (state.prices.isEmpty &&
                      state.status != PriceManagementStatus.loadingPrices)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(state),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == state.prices.length) {
                              return _buildPaginationRow(state);
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: PriceListItem(price: state.prices[index]),
                            );
                          },
                          childCount: state.prices.length +
                              (state.totalPages > 1 ? 1 : 0),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStickyHeader(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black12,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Price List',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
          onPressed: () => _loadPrices(),
          tooltip: 'Refresh',
        ),
      ],
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

  Widget _buildSectionHeader(String label, {String? subtitle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionChip(label),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Column(
      children: [
        // District Dropdown styled as a card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: _selectedDistrict,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_on_outlined,
                    size: 20, color: Color(0xFF444466)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                hintText: 'All Districts',
                labelText: 'District',
                labelStyle: TextStyle(
                    color: Color(0xFF444466),
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Districts'),
                ),
                ...SriLankanDistricts.sortedDistricts.map(
                  (d) => DropdownMenuItem<String>(
                    value: d,
                    child: Text(d),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedDistrict = value);
                _loadPrices();
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Type filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'All Types',
                icon: Icons.all_inclusive_rounded,
                selected: _selectedPriceType == null,
                onTap: () {
                  setState(() => _selectedPriceType = null);
                  _loadPrices();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Paddy',
                icon: Icons.grass_rounded,
                color: const Color(0xFF8BC34A),
                selected: _selectedPriceType == 'paddy',
                onTap: () {
                  setState(() => _selectedPriceType = 'paddy');
                  _loadPrices();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Rice',
                icon: Icons.rice_bowl_rounded,
                color: AppColors.primary,
                selected: _selectedPriceType == 'rice',
                onTap: () {
                  setState(() => _selectedPriceType = 'rice');
                  _loadPrices();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(PriceManagementState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ?? 'Failed to load prices',
              style: const TextStyle(
                color: Color(0xFF1C1C2E),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPrices,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(PriceManagementState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8EE),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.price_change_outlined,
                  size: 48, color: Color(0xFF444466)),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Prices Found',
              style: TextStyle(
                color: Color(0xFF1C1C2E),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedDistrict != null
                  ? 'No prices in $_selectedDistrict matching the criteria.'
                  : 'No companies have added prices yet.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationRow(PriceManagementState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: state.currentPage > 1
                ? () => _loadPrices(page: state.currentPage - 1)
                : null,
          ),
          Text(
            'Page ${state.currentPage} of ${state.totalPages}',
            style: AppTextStyles.bodySmall,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: state.currentPage < state.totalPages
                ? () => _loadPrices(page: state.currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.adminPrimary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? chipColor : const Color(0xFFE8E8EE),
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: chipColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? Colors.white : chipColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : const Color(0xFF444466),
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
