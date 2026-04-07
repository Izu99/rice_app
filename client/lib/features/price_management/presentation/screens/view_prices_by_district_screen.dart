// lib/features/price_management/presentation/screens/view_prices_by_district_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../core/shared_widgets/h_app_bar.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../data/models/paddy_rice_price_model.dart';
import '../cubit/price_management_cubit.dart';
import '../cubit/price_management_state.dart';

class ViewPricesByDistrictScreen extends StatefulWidget {
  const ViewPricesByDistrictScreen({super.key});

  @override
  State<ViewPricesByDistrictScreen> createState() =>
      _ViewPricesByDistrictScreenState();
}

class _ViewPricesByDistrictScreenState
    extends State<ViewPricesByDistrictScreen> {
  String _searchDistrict = '';

  @override
  void initState() {
    super.initState();
    context.read<PriceManagementCubit>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PriceManagementCubit, PriceManagementState>(
      builder: (context, state) {
        // Filter districts based on search
        final filteredDistricts = _searchDistrict.isEmpty
            ? state.districts
            : state.districts
                .where((d) => d.district
                    .toLowerCase()
                    .contains(_searchDistrict.toLowerCase()))
                .toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const HAppBar(
            title: 'Paddy Prices',
            subtitle: 'දිස්ත්‍රික්ක අනුව',
            showBack: false,
          ),
          body: LoadingOverlay(
            isLoading: state.status == PriceManagementStatus.loadingDistricts,
            message: 'Loading prices...',
            child: Column(
              children: [
                // Search Box
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: SearchAnchor(
                    builder: (BuildContext context,
                        SearchController searchController) {
                      return SearchBar(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchDistrict = value;
                          });
                        },
                        leading: const Icon(Icons.search),
                        hintText: 'Search by district...',
                      );
                    },
                    suggestionsBuilder: (BuildContext context,
                        SearchController searchController) {
                      final suggestions = state.districts
                          .where((d) => d.district
                              .toLowerCase()
                              .contains(
                                  searchController.text.toLowerCase()))
                          .map((d) => d.district)
                          .toList();
                      return suggestions.map((district) {
                        return ListTile(
                          title: Text(district),
                          onTap: () {
                            searchController.closeView(district);
                            setState(() {
                              _searchDistrict = district;
                            });
                          },
                        );
                      }).toList();
                    },
                  ),
                ),
                // Prices List
                Expanded(
                  child: filteredDistricts.isEmpty
                      ? _buildEmptyState()
                      : _buildPricesList(context, state, filteredDistricts),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: AppColors.grey500,
          ),
          const SizedBox(height: 16),
          Text(
            'No prices found',
            style: AppTextStyles.titleMedium
                .copyWith(color: AppColors.grey700),
          ),
          const SizedBox(height: 8),
          Text(
            _searchDistrict.isEmpty
                ? 'No companies have added prices yet'
                : 'No prices available in "$_searchDistrict"',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
          ),
        ],
      ),
    );
  }

  Widget _buildPricesList(BuildContext context, PriceManagementState state,
      List<DistrictWithPricesResponse> filteredDistricts) {
    return RefreshIndicator(
      onRefresh: () =>
          context.read<PriceManagementCubit>().loadDistricts(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        itemCount: filteredDistricts.length,
        itemBuilder: (context, index) {
          final district = filteredDistricts[index];
          return _buildDistrictCard(context, district);
        },
      ),
    );
  }

  Widget _buildDistrictCard(
      BuildContext context, DistrictWithPricesResponse district) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context
              .read<PriceManagementCubit>()
              .loadPricesByDistrict(district.district);
          _showPricesBottomSheet(context, district.district);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                district.district,
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${district.priceCount} price${district.priceCount == 1 ? '' : 's'} listed',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.grey600),
                        ),
                        if (district.lastUpdated != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Updated: ${_formatDate(district.lastUpdated!)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.grey500,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${district.priceCount}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (district.lastUpdated != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last updated: ${district.lastUpdated!.toLocal().toString().split('.')[0]}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey500),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPricesBottomSheet(BuildContext context, String district) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return BlocBuilder<PriceManagementCubit, PriceManagementState>(
          builder: (context, state) {
            final prices = state.prices;

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.grey300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.paddingMedium),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Prices in $district',
                                      style: AppTextStyles.titleMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${prices.length} price${prices.length == 1 ? '' : 's'} available',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.grey600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Prices List
                    if (state.status == PriceManagementStatus.loadingPrices)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (prices.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            'No prices found in $district',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding:
                              const EdgeInsets.all(AppDimensions.paddingMedium),
                          itemCount: prices.length,
                          itemBuilder: (context, index) {
                            final price = prices[index];
                            return _buildPriceCard(price);
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPriceCard(dynamic price) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company and District
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        price.companyName ?? 'Unknown Company',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            price.district ?? 'N/A',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    price.priceDisplay,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            // Quality Grade and Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    price.qualityGrade ?? 'standard',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: AppColors.primary,
                ),
                Text(
                  'Added: ${_formatDate(price.createdAt)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
            if (price.notes != null && price.notes!.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.paddingM),
              Text(
                'Notes: ${price.notes}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey600,
                ),
              ),
            ],
          ],
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
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
