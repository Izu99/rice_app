// lib/features/price_management/presentation/screens/prices_in_district_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../core/shared_widgets/h_app_bar.dart';
import '../cubit/price_management_cubit.dart';
import '../cubit/price_management_state.dart';
import '../widgets/price_list_item.dart';

class PricesInDistrictScreen extends StatefulWidget {
  final String district;

  const PricesInDistrictScreen({
    super.key,
    required this.district,
  });

  @override
  State<PricesInDistrictScreen> createState() =>
      _PricesInDistrictScreenState();
}

class _PricesInDistrictScreenState extends State<PricesInDistrictScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PriceManagementCubit>().loadPricesByDistrict(widget.district);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PriceManagementCubit, PriceManagementState>(
      listener: (context, state) {
        if (state.status == PriceManagementStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Failed to load prices'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: BlocBuilder<PriceManagementCubit, PriceManagementState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: HAppBar(
              title: widget.district,
              subtitle: 'Paddy Rice Prices',
              onBack: () => context.pop(),
            ),
            body: LoadingOverlay(
              isLoading: state.status == PriceManagementStatus.loadingPrices,
              message: 'Loading prices...',
              child: state.prices.isEmpty && state.status != PriceManagementStatus.loadingPrices
                  ? _buildEmptyState()
                  : _buildPricesList(context, state),
            ),
          );
        },
      ),
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
            'No prices available',
            style: AppTextStyles.titleMedium
                .copyWith(color: AppColors.grey700),
          ),
          const SizedBox(height: 8),
          Text(
            'No companies have added prices for ${widget.district} yet',
            textAlign: TextAlign.center,
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
          ),
        ],
      ),
    );
  }

  Widget _buildPricesList(
      BuildContext context, PriceManagementState state) {
    return RefreshIndicator(
      onRefresh: () =>
          context.read<PriceManagementCubit>().loadPricesByDistrict(widget.district),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        itemCount: state.prices.length,
        itemBuilder: (context, index) {
          final price = state.prices[index];
          return PriceListItem(price: price);
        },
      ),
    );
  }
}
