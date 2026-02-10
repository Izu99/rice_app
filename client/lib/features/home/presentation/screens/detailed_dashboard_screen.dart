// lib/features/home/presentation/screens/detailed_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/si_strings.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';

import '../../../../routes/app_router.dart';
import '../../../../injection_container.dart';

class DetailedDashboardScreen extends StatefulWidget {
  const DetailedDashboardScreen({super.key});

  @override
  State<DetailedDashboardScreen> createState() =>
      _DetailedDashboardScreenState();
}

class _DetailedDashboardScreenState extends State<DetailedDashboardScreen>
    with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route observer
    try {
      final route = ModalRoute.of(context);
      if (route != null) {
        sl<AppRouter>().routeObserver.subscribe(this, route);
      }
    } catch (e) {
      debugPrint('Error subscribing to route observer: $e');
    }
  }

  @override
  void dispose() {
    try {
      sl<AppRouter>().routeObserver.unsubscribe(this);
    } catch (e) {
      debugPrint('Error unsubscribing from route observer: $e');
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when the top route has been popped off, and the current route shows up.
    if (mounted) {
      context.read<DashboardCubit>().refreshDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth > 600;
        final isDesktop = screenWidth > 1024;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: LoadingOverlay(
            isLoading: state.status == DashboardStatus.loading ||
                state.status == DashboardStatus.refreshing,
            message: SiStrings.loading,
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, isDesktop),
                SliverPadding(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildFinancialCards(state, isTablet, isDesktop),
                      SizedBox(height: isDesktop ? 32 : 24),
                      _buildChartSection(state, isTablet, isDesktop),
                      SizedBox(height: isDesktop ? 32 : 24),
                      _buildStockAndPerformance(state, isTablet, isDesktop),
                      SizedBox(height: isDesktop ? 32 : 24),
                      _buildInventorySection(state, isTablet, isDesktop),
                      const SizedBox(height: 40),
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

  Widget _buildSliverAppBar(BuildContext context, bool isDesktop) {
    return SliverAppBar(
      expandedHeight: isDesktop ? 120 : 100,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          SiStrings.analytics,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
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
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list_rounded),
          onPressed: () {},
          tooltip: SiStrings.filter,
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => context.read<DashboardCubit>().refreshDashboard(),
          tooltip: SiStrings.refresh,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFinancialCards(
      DashboardState state, bool isTablet, bool isDesktop) {
    final cards = [
      _StatCardData(SiStrings.totalRevenue, state.formattedMonthlySales,
          Icons.account_balance_wallet_rounded, AppColors.success, '+12.5%'),
      _StatCardData(SiStrings.paddyPurchases, state.formattedMonthlyPurchases,
          Icons.shopping_basket_rounded, AppColors.error, '+8.2%'),
      _StatCardData(SiStrings.expenses, state.formattedMonthlyExpenses,
          Icons.receipt_long_rounded, AppColors.warning, '+3.1%'),
      _StatCardData(SiStrings.netProfit, state.formattedMonthlyProfit,
          Icons.trending_up_rounded, AppColors.primary, '+4.3%'),
      _StatCardData(SiStrings.customerBase, '${state.totalCustomers}',
          Icons.people_rounded, AppColors.info, '+5.7%'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (isDesktop) {
          crossAxisCount = 4;
        } else if (isTablet) {
          crossAxisCount = 2;
        } else if (MediaQuery.of(context).size.width < 400) {
          crossAxisCount = 1;
        }

        return MasonryGridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            return _buildModernStatCard(cards[index]);
          },
        );
      },
    );
  }

  Widget _buildModernStatCard(_StatCardData data) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.white,
              AppColors.white.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: data.color.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [data.color, data.color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                data.trend,
                style: TextStyle(
                  color: data.color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              data.label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              child: Text(
                data.value,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(
      DashboardState state, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 28 : 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop || isTablet)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SiStrings.salesVsPurchases,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isDesktop ? 20 : 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      SiStrings.last7Days,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                _buildChartLegend(),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SiStrings.salesVsPurchases,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  SiStrings.last7Days,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildChartLegend(),
              ],
            ),
          SizedBox(height: isDesktop ? 32 : 24),
          SizedBox(
            height: isDesktop ? 350 : 280,
            child: _buildModernLineChart(state),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    return Row(
      children: [
        _buildLegendItem(SiStrings.sell, AppColors.success),
        const SizedBox(width: 16),
        _buildLegendItem(SiStrings.buy, AppColors.error),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildModernLineChart(DashboardState state) {
    // Generate spots from weeklyTrend data
    // weeklyTrend is expected to have 7 days of data from backend
    // Format: [{_id: 'YYYY-MM-DD', buy: 100, sell: 200}, ...]

    final List<FlSpot> salesSpots = [];
    final List<FlSpot> purchaseSpots = [];

    // Defensive check for hot-reload state mismatch
    final trendData = state.weeklyTrend;

    if (trendData.isNotEmpty) {
      for (int i = 0; i < trendData.length; i++) {
        final dayData = trendData[i];
        final buy = (dayData['buy'] as num?)?.toDouble() ?? 0.0;
        final sell = (dayData['sell'] as num?)?.toDouble() ?? 0.0;

        // Use i as x-axis (0 to 6)
        // Scale down large numbers to 'k' for readability on y-axis
        purchaseSpots.add(FlSpot(i.toDouble(), buy / 1000));
        salesSpots.add(FlSpot(i.toDouble(), sell / 1000));
      }
    } else {
      // Fallback empty spots if no data
      for (int i = 0; i < 7; i++) {
        salesSpots.add(FlSpot(i.toDouble(), 0));
        purchaseSpots.add(FlSpot(i.toDouble(), 0));
      }
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppColors.white.withOpacity(0.9),
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(12),
            tooltipBorder: BorderSide(
              color: AppColors.primary.withOpacity(0.1),
            ),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final isSales = touchedSpot.barIndex == 0;
                return LineTooltipItem(
                  '${isSales ? SiStrings.sell : SiStrings.buy}: ${touchedSpot.y.toStringAsFixed(1)}k\n',
                  TextStyle(
                    color: isSales ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [
                    const TextSpan(
                      text: 'වැඩි විස්තර සඳහා ඔබන්න',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1, // Auto-calculate or set reasonable default
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.divider.withOpacity(0.2),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: AppColors.divider.withOpacity(0.2),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              // interval: 1, // Let chart calculate interval based on data range
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${value.toInt()}k',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                // Dynamic labels based on actual dates would be better,
                // but for now we map 0-6 to Mon-Sun or relative days
                // If we have actual dates in weeklyTrend, we could parse them

                String label = '';
                if (state.weeklyTrend.isNotEmpty &&
                    value.toInt() < state.weeklyTrend.length) {
                  final dateStr =
                      state.weeklyTrend[value.toInt()]['_id'] as String? ?? '';
                  if (dateStr.isNotEmpty) {
                    try {
                      final date = DateTime.parse(dateStr);
                      // E.g., "Mon", "Tue"
                      // Need simple date formatter
                      const days = [
                        'සඳුදා',
                        'අඟහ',
                        'බදාදා',
                        'බ්‍රහස්',
                        'සිකු',
                        'සෙන',
                        'ඉරිදා'
                      ];
                      label = days[date.weekday - 1];
                    } catch (_) {}
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.divider.withOpacity(0.3)),
        ),
        lineBarsData: [
          // Sales Line (Green)
          LineChartBarData(
            spots: salesSpots,
            isCurved: true,
            curveSmoothness: 0.5,
            color: AppColors.success,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withOpacity(0.5),
                  AppColors.success.withOpacity(0.1),
                  AppColors.success.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Purchases Line (Red)
          LineChartBarData(
            spots: purchaseSpots,
            isCurved: true,
            curveSmoothness: 0.5,
            color: AppColors.error,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.error.withOpacity(0.5),
                  AppColors.error.withOpacity(0.1),
                  AppColors.error.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockAndPerformance(
      DashboardState state, bool isTablet, bool isDesktop) {
    if (isDesktop || (isTablet && MediaQuery.of(context).size.width > 800)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _buildStockDistribution(state, isDesktop),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: _buildPerformanceTable(state, isDesktop),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildStockDistribution(state, isDesktop),
          const SizedBox(height: 24),
          _buildPerformanceTable(state, isDesktop),
        ],
      );
    }
  }

  Widget _buildStockDistribution(DashboardState state, bool isDesktop) {
    final hasStock = state.totalPaddyStock > 0 || state.totalRiceStock > 0;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 28 : 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SiStrings.stockDistribution,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isDesktop ? 18 : 16,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: hasStock
                    ? [
                        PieChartSectionData(
                          color: AppColors.warning,
                          value: state.totalPaddyStock,
                          title:
                              '${state.totalPaddyStock.toStringAsFixed(0)}kg',
                          radius: 50,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          badgeWidget:
                              _buildPieBadge('වී', AppColors.warning),
                          badgePositionPercentageOffset: 1.4,
                        ),
                        PieChartSectionData(
                          color: AppColors.primary,
                          value: state.totalRiceStock,
                          title: '${state.totalRiceStock.toStringAsFixed(0)}kg',
                          radius: 50,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          badgeWidget:
                              _buildPieBadge('සහල්', AppColors.primary),
                          badgePositionPercentageOffset: 1.4,
                        ),
                      ]
                    : [
                        PieChartSectionData(
                          color: AppColors.grey300,
                          value: 1,
                          title: 'තොග නොමැත',
                          radius: 50,
                          titleStyle: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildPerformanceTable(DashboardState state, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 28 : 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SiStrings.performanceMetrics,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isDesktop ? 18 : 16,
            ),
          ),
          const SizedBox(height: 20),
          _buildMetricRow(
              'මිලදී ගත් වී',
              '${state.totalPaddyBoughtKg.toStringAsFixed(0)} kg',
              'ප්‍රමාණය',
              AppColors.success),
          _buildMetricRow(
              'විකුණූ සහල්',
              '${state.totalRiceSoldKg.toStringAsFixed(0)} kg',
              'ප්‍රමාණය',
              AppColors.info),
          _buildMetricRow(
              SiStrings.millingOutput, '95%', 'ඉතා හොඳයි', AppColors.success),
          _buildMetricRow(SiStrings.wasteRatio, '2.5%', 'අඩු', AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
      String label, String value, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventorySection(
      DashboardState state, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  SiStrings.stockOverview,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isDesktop ? 20 : 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 28 : 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 700
                  ? 3
                  : (constraints.maxWidth > 400 ? 2 : 1);

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: crossAxisCount == 1 ? 4.0 : 2.2,
                children: [
                  _buildInventoryItem(
                    SiStrings.inventoryValue,
                    state.formattedStockValue,
                    Icons.monetization_on_rounded,
                  ),
                  _buildInventoryItem(
                    SiStrings.lowStockAlerts,
                    '${state.lowStockCount} අයිතම',
                    Icons.warning_amber_rounded,
                  ),
                  _buildInventoryItem(
                    SiStrings.totalItemsCount,
                    '${state.lowStockItems.length + 10}',
                    Icons.inventory_rounded,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  _StatCardData(this.label, this.value, this.icon, this.color, this.trend);
}
