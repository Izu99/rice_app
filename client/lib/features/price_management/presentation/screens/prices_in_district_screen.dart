// lib/features/price_management/presentation/screens/prices_in_district_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/shared_widgets/h_app_bar.dart';
import '../../../../core/shared_widgets/app_page_scaffold.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
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
  State<PricesInDistrictScreen> createState() => _PricesInDistrictScreenState();
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
              content:
                  Text(state.errorMessage ?? SiStrings.failedToLoadPrices),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: BlocBuilder<PriceManagementCubit, PriceManagementState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFFF4F6FA),
            body: CustomScrollView(
              slivers: [
                HSliverAppBar(
                  title: widget.district,
                  subtitle: SiStrings.marketPrices,
                  onRefresh: () => context
                      .read<PriceManagementCubit>()
                      .loadPricesByDistrict(widget.district),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      if (state.isRefreshing ||
                          (state.status ==
                                  PriceManagementStatus.loadingPrices &&
                              state.prices.isNotEmpty))
                        const LinearProgressIndicator(minHeight: 3),
                      // Info Summary Strip
                      if (state.prices.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          color: AppColors.primary.withValues(alpha: 0.05),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 16,
                                  color: AppColors.primary.withValues(alpha: 0.7)),
                              const SizedBox(width: 8),
                              Text(
                                SiStrings.displayingPricesIn(
                                    state.prices.length, widget.district),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (state.status == PriceManagementStatus.loadingPrices &&
                    state.prices.isEmpty)
                  const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()))
                else if (state.prices.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final price = state.prices[index];
                          return BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, authState) {
                              final companyId = authState.user?.companyId;
                              final isOwn =
                                  companyId != null && price.companyId == companyId;

                              if (isOwn) {
                                return Dismissible(
                                  key: Key(price.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade400,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 24),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.delete_rounded,
                                            color: Colors.white, size: 28),
                                        const SizedBox(height: 4),
                                        Text(SiStrings.remove,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  confirmDismiss: (_) => _confirmRemove(context),
                                  onDismissed: (_) => context
                                      .read<PriceManagementCubit>()
                                      .deletePrice(price.id),
                                  child: PriceListItem(price: price),
                                );
                              }

                              return PriceListItem(price: price);
                            },
                          );
                        },
                        childCount: state.prices.length,
                      ),
                    ),
                  ),
              ],
            ),
            bottomNavigationBar: _buildBottomStatusBar(state.prices.length),
          );
        },
      ),
    );
  }

  Widget _buildBottomStatusBar(int count) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '${SiStrings.totalVarieties}: $count',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const Text(
            'LKR/KG',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: AppColors.primary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
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
              Icons.no_meals_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            SiStrings.noPricesListed,
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
              SiStrings.noPricesInDistrictYet(widget.district),
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

  Widget _buildPricesList(BuildContext context, PriceManagementState state) {
    final companyId = context.read<AuthCubit>().state.company?.id;

    return RefreshIndicator(
      onRefresh: () => context
          .read<PriceManagementCubit>()
          .loadPricesByDistrict(widget.district),
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        itemCount: state.prices.length,
        itemBuilder: (context, index) {
          final price = state.prices[index];
          final isOwn =
              companyId != null && price.companyId == companyId;

          if (isOwn) {
            return Dismissible(
              key: Key(price.id),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                    SizedBox(height: 4),
                    Text('Remove',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              confirmDismiss: (_) => _confirmRemove(context),
              onDismissed: (_) =>
                  context.read<PriceManagementCubit>().deletePrice(price.id),
              child: PriceListItem(price: price),
            );
          }

          return PriceListItem(price: price);
        },
      ),
    );
  }

  Future<bool?> _confirmRemove(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(SiStrings.removePriceTitle),
          content: Text(SiStrings.removePriceContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(SiStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(SiStrings.remove),
            ),
          ],
        ),
      );
}
