// lib/features/price_management/presentation/screens/view_prices_by_district_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/entities/paddy_rice_price_entity.dart';
import '../../../../data/models/paddy_rice_price_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../core/shared_widgets/h_app_bar.dart';
import '../../../../core/shared_widgets/app_page_scaffold.dart';

import '../widgets/price_list_item.dart';
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

        return AppPageScaffold(
          title: 'Market Prices',
          subtitle: 'Real-time Trends',
          onBack: () => context.pop(),
          bottomBar: AppSubBottomBar(
            showBack: false,
            centerLabel: 'Add Price',
            centerIcon: Icons.add_circle_rounded,
            onCenter: () => context.pushNamed('addPrice'),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.pushNamed('addPrice'),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Price',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          body: LoadingOverlay(
            isLoading: state.status == PriceManagementStatus.loadingDistricts,
            message: 'Loading market data...',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern Header & Search
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'District Overview',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select a district to view detailed prices',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Search Box
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchDistrict = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search district...',
                          hintStyle:
                              TextStyle(color: Colors.grey[400], fontSize: 15),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppColors.primary),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Prices List
                Expanded(
                  child: filteredDistricts.isEmpty &&
                          state.status != PriceManagementStatus.loadingDistricts
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No districts found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _searchDistrict.isEmpty
                  ? 'There are no market prices available at the moment. Please check back later.'
                  : 'We couldn\'t find any districts matching "$_searchDistrict". Try a different name.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricesList(BuildContext context, PriceManagementState state,
      List<DistrictWithPricesResponse> filteredDistricts) {
    return RefreshIndicator(
      onRefresh: () => context.read<PriceManagementCubit>().loadDistricts(),
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.pushNamed(
              'pricesInDistrict',
              pathParameters: {'district': district.district},
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        district.district,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${district.priceCount} Listings',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (district.lastUpdated != null)
                            Expanded(
                              child: Text(
                                'Updated ${_formatRelativeTime(district.lastUpdated!)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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
                      padding:
                          const EdgeInsets.all(AppDimensions.paddingMedium),
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
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: prices.length,
                          itemBuilder: (context, index) {
                            final price = prices[index];
                            return PriceListItem(price: price);
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
}
