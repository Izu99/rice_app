// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/shared_widgets/sync_status_indicator.dart';
import '../../../../core/shared_widgets/confirmation_dialog.dart';
import '../../../../core/sync/sync_status.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../buy/presentation/cubit/buy_cubit.dart';
import '../../../sell/presentation/cubit/sell_cubit.dart';
import '../../../../data/models/customer_model.dart';
import '../../../../routes/route_names.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../widgets/action_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/recent_transactions.dart';
import '../widgets/weekly_activity_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation =
        _animationController.drive(CurveTween(curve: Curves.easeInOut));
    // Start animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
        context.read<DashboardCubit>().loadDashboard();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            onRefresh: () => context.read<DashboardCubit>().refreshDashboard(),
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // App Bar
                _buildAppBar(state),

                // Content
                SliverPadding(
                  padding: EdgeInsets.all(
                    ResponsiveUtils.getResponsivePadding(
                      context,
                      mobile: AppDimensions.paddingMedium,
                      tablet: AppDimensions.paddingL,
                      desktop: AppDimensions.paddingXL,
                    ),
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Sync Status

                      // Quick Actions - Buy & Sell
                      _buildQuickActions(),
                      const SizedBox(height: 20),

                      // Today's Summary
                      _buildSectionTitle('Today\'s Summary', 'අද දින සාරාංශය'),
                      const SizedBox(height: 12),
                      _buildTodaySummary(state),
                      const SizedBox(height: 20),

                      // Weekly Activity
                      _buildSectionTitle('Weekly Activity', 'සතිපතා විශ්ලේෂණය'),
                      const SizedBox(height: 12),
                      WeeklyActivityChart(
                        data: state.weeklyActivity,
                        isLoading: state.isLoading,
                      ),
                      const SizedBox(height: 20),

                      // Stock Overview
                      _buildSectionTitle('Stock Overview', 'තොග දළ විශ්ලේෂණය'),
                      const SizedBox(height: 12),
                      _buildStockOverview(state),
                      const SizedBox(height: 20),

                      // Monthly Summary
                      _buildSectionTitle('This Month', 'මෙම මාසය'),
                      const SizedBox(height: 12),
                      _buildMonthlySummary(state),
                      const SizedBox(height: 20),

                      // Recent Transactions
                      _buildSectionTitle(
                        'Recent Transactions',
                        'මෑත ගනුදෙනු',
                        onViewAll: () => context.pushNamed('reports'),
                      ),
                      const SizedBox(height: 12),
                      RecentTransactions(
                        transactions: state.recentTransactions,
                        isLoading: state.isLoading && state.recentTransactions.isEmpty,
                      ),

                      // Bottom padding
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(DashboardState state) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      return Row(
                        children: [
                          // Avatar with Ring
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  authState.user?.initials ?? 'U',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Greeting & Profile
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.greeting,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  authState.user?.name ?? 'User',
                                  style: AppTextStyles.titleLarge.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Sync indicator
                          SyncStatusIndicator(
                            status: SyncStatusModel.idle(
                              pendingCount: state.pendingSyncCount,
                              lastSyncTime: state.lastSyncTime,
                            ),
                            onTap: () {
                              context.read<DashboardCubit>().syncData();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: AppColors.white),
          onPressed: () => _handleLogout(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _handleLogout(BuildContext context) async {
    final confirmed = await ConfirmationDialog.showLogout(context);
    if (confirmed && context.mounted) {
      context.read<AuthCubit>().logout();
    }
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Quick Actions', 'කඩිනම් ක්‍රියාකාරකම්'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ActionCard(
                title: 'Buy Paddy',
                subtitle: 'වී මිලදී ගැනීම',
                icon: Icons.shopping_bag_rounded,
                color: AppColors.success,
                onTap: () async {
                  final selectedCustomer =
                      await context.push<CustomerModel>('/buy');
                  if (selectedCustomer != null && mounted) {
                    context.read<BuyCubit>().selectCustomer(selectedCustomer);
                    context.pushNamed('buyProcess');
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ActionCard(
                title: 'Sell Rice',
                subtitle: 'සහල් විකිණීම',
                icon: Icons.sell_rounded,
                color: AppColors.info,
                onTap: () async {
                  final selectedCustomer =
                      await context.push<CustomerModel>(RouteNames.sell);
                  if (selectedCustomer != null && mounted) {
                    context.read<SellCubit>().selectCustomer(selectedCustomer);
                    context.pushNamed('sellProcess');
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ActionCard(
                title: 'Stock',
                subtitle: 'තොග කළමනාකරණය',
                icon: Icons.inventory_2_rounded,
                color: AppColors.warning,
                onTap: () => context.push('/stock'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ActionCard(
                title: 'Analytics',
                subtitle: 'විස්තරාත්මක විශ්ලේෂණය',
                icon: Icons.analytics_rounded,
                color: AppColors.primary,
                onTap: () => context.pushNamed('detailedDashboard'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    String title,
    String subtitle, {
    VoidCallback? onViewAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, size: 12),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTodaySummary(DashboardState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Purchases',
                value: state.formattedTodayPurchases,
                subtitle: '${state.todayBuyCount} orders',
                icon: Icons.arrow_downward_rounded,
                iconColor: AppColors.error,
                isLoading: state.isLoading,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SummaryCard(
                title: 'Sales',
                value: state.formattedTodaySales,
                subtitle: '${state.todaySellCount} orders',
                icon: Icons.arrow_upward_rounded,
                iconColor: AppColors.success,
                isLoading: state.isLoading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SummaryCard(
          title: 'Today\'s Profit',
          value: state.formattedTodayProfit,
          subtitle: 'Net from today\'s transactions',
          icon: Icons.monetization_on_rounded,
          iconColor: AppColors.primary,
          isLoading: state.isLoading,
          trend: state.todayProfit >= 0 ? 'Positive' : 'Loss',
          trendIsPositive: state.todayProfit >= 0,
        ),
      ],
    );
  }

  Widget _buildStockOverview(DashboardState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStockItem(
                  'Paddy Stock',
                  'වී තොගය',
                  state.formattedPaddyStock,
                  Icons.grass_rounded,
                  AppColors.warning,
                  state.isLoading,
                ),
              ),
              Container(
                width: 1,
                height: 80,
                color: AppColors.divider.withOpacity(0.5),
              ),
              Expanded(
                child: _buildStockItem(
                  'Rice Stock',
                  'සහල් තොගය',
                  state.formattedRiceStock,
                  Icons.rice_bowl_rounded,
                  AppColors.primary,
                  state.isLoading,
                ),
              ),
            ],
          ),
          if (state.hasLowStock) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () => context.push('/stock'),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${state.lowStockCount} items are running low',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStockItem(
    String title,
    String subtitle,
    String value,
    IconData icon,
    Color color,
    bool isLoading,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        if (isLoading)
          Container(
            width: 60,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.divider.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          )
        else
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMonthlySummary(DashboardState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildMonthlyItem(
                  'Purchases',
                  state.formattedMonthlyPurchases,
                  Icons.shopping_cart_checkout_rounded,
                  state.isLoading,
                ),
              ),
              Expanded(
                child: _buildMonthlyItem(
                  'Sales',
                  state.formattedMonthlySales,
                  Icons.payments_rounded,
                  state.isLoading,
                ),
              ),
              Expanded(
                child: _buildMonthlyItem(
                  'Profit',
                  state.formattedMonthlyProfit,
                  Icons.analytics_rounded,
                  state.isLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildStatItem('${state.monthlyBuyCount}', 'Purchases')),
                Expanded(child: _buildStatItem('${state.monthlySellCount}', 'Sales')),
                Expanded(child: _buildStatItem('${state.totalCustomers}', 'Customers')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyItem(
    String label,
    String value,
    IconData icon,
    bool isLoading,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.white, size: 20),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        if (isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          )
        else
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.white.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

