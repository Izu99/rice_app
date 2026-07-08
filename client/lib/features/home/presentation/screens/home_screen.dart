// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes/app_router.dart';
import '../../../../injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/confirmation_dialog.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../core/shared_widgets/h_app_bar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../buy/presentation/cubit/buy_cubit.dart';
import '../../../sell/presentation/cubit/sell_cubit.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/cubit/profile_state.dart';
import '../../../../data/models/customer_model.dart';
import '../../../../routes/route_names.dart';
import '../../../../core/constants/si_strings.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../widgets/recent_transactions.dart';
import '../widgets/recent_expenses.dart';
import '../widgets/video_banner.dart';
import '../../../store/presentation/screens/store_home_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        _animationController.drive(CurveTween(curve: Curves.easeInOut));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
        context.read<DashboardCubit>().loadDashboard();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final route = ModalRoute.of(context);
      if (route != null) sl<AppRouter>().routeObserver.subscribe(this, route);
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      sl<AppRouter>().routeObserver.unsubscribe(this);
    } catch (_) {}
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    if (mounted) context.read<DashboardCubit>().refreshDashboard();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<DashboardCubit>().refreshDashboard();
    }
  }

  // ─── Navigation items for drawer (dynamic so labels update with language) ──
  List<_DrawerItem> get _drawerItems => [
        _DrawerItem(Icons.dashboard_rounded, SiStrings.dashboard, '/home'),
        _DrawerItem(Icons.shopping_bag_rounded, SiStrings.buyPaddy, '/buy'),
        _DrawerItem(Icons.sell_rounded, SiStrings.sellRice, '/sell'),
        _DrawerItem(Icons.inventory_2_rounded, SiStrings.stock, '/stock'),
        _DrawerItem(Icons.people_rounded, SiStrings.customers, '/customers'),
        _DrawerItem(
            Icons.receipt_long_rounded, SiStrings.expenses, '/expenses'),
        _DrawerItem(Icons.bar_chart_rounded, SiStrings.reports, '/reports'),
        _DrawerItem(Icons.local_offer_rounded, SiStrings.prices, 'prices'),
        _DrawerItem(Icons.person_rounded, SiStrings.profile, '/profile'),
        _DrawerItem(Icons.storefront_rounded, SiStrings.marketplace, 'store'),
      ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      buildWhen: (p, c) => p.language != c.language,
      builder: (context, profileState) {
        return BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            return Scaffold(
              backgroundColor: const Color(0xFFF4F6FA),
              drawer: _buildDrawer(context),
              body: LoadingOverlay(
                isLoading: state.status == DashboardStatus.loading,
                message: SiStrings.loading,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: () =>
                        context.read<DashboardCubit>().refreshDashboard(),
                    color: AppColors.primary,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        _buildStickyHeader(context, state, profileState),
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 16),
                                    // Promo video / banner - Large sized but inside padding
                                    const VideoBanner(
                                      assetPath:
                                          'assets/videos/promo_video.mp4',
                                      fullWidth: false,
                                    ),
                                    const SizedBox(height: 20),
                                    // Welcome + Today stats banner
                                    _buildWelcomeBanner(context, state),
                                    const SizedBox(height: 24),
                                    // Section: Quick Actions
                                    _buildSectionChip(SiStrings.quickActions),
                                    const SizedBox(height: 14),
                                    _buildIconGrid(
                                        context, _quickActions(context)),
                                    const SizedBox(height: 24),
                                    // Section: Records
                                    _buildSectionChip(SiStrings.records),
                                    const SizedBox(height: 14),
                                    _buildIconGrid(
                                        context, _recordActions(context)),
                                    const SizedBox(height: 24),
                                    // Section: Reports & Tools
                                    _buildSectionChip(
                                        SiStrings.reportsAndTools),
                                    const SizedBox(height: 14),
                                    _buildIconGrid(
                                        context, _reportActions(context)),
                                    const SizedBox(height: 24),
                                    // Marketplace Banner
                                    _buildMarketplaceBanner(context),
                                    const SizedBox(height: 24),
                                    // Today Summary grid layout
                                    _buildSectionChip(SiStrings.todaySummary),
                                    const SizedBox(height: 14),
                                    _buildTodayStrip(state),
                                    const SizedBox(height: 24),
                                    // Stock overview
                                    _buildSectionChip(SiStrings.stockOverview),
                                    const SizedBox(height: 14),
                                    _buildStockCard(state),
                                    const SizedBox(height: 24),
                                    // Recent transactions
                                    _buildSectionHeader(
                                      SiStrings.recentTransactions,
                                      onViewAll: () =>
                                          context.pushNamed('reports'),
                                    ),
                                    const SizedBox(height: 12),
                                    RecentTransactions(
                                      transactions: state.recentTransactions,
                                      isLoading: state.isLoading &&
                                          state.recentTransactions.isEmpty,
                                    ),
                                    const SizedBox(height: 20),
                                    // Recent expenses
                                    _buildSectionHeader(
                                      SiStrings.recentExpenses,
                                      onViewAll: () =>
                                          context.push('/expenses'),
                                    ),
                                    const SizedBox(height: 12),
                                    RecentExpenses(
                                      expenses: state.recentExpenses,
                                      isLoading: state.isLoading &&
                                          state.recentExpenses.isEmpty,
                                    ),
                                    const SizedBox(height: 100),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStickyHeader(
      BuildContext context, DashboardState state, ProfileState profileState) {
    return HSliverAppBar(
      pinned: true,
      title: SiStrings.dashboard,
      subtitle: 'Rice Mill Management',
      onRefresh: () => context.read<DashboardCubit>().refreshDashboard(),
      showBack: false,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      actions: [
        // Language toggle
        _buildLanguageToggle(context, profileState),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
        ),
        // Profile avatar
        _buildProfileAvatar(context),
      ],
      flexibleSpace: null, // Reset default gradient if needed
    );
  }

  Widget _buildLanguageToggle(BuildContext context, ProfileState ps) {
    final isSi = ps.language == 'si';
    return GestureDetector(
      onTap: () =>
          context.read<ProfileCubit>().changeLanguage(isSi ? 'en' : 'si'),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white70),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          isSi ? 'EN' : 'සිං',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (ctx, authState) {
        return GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30),
            ),
            child: Center(
              child: Text(
                authState.user?.initials ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Navigation Drawer ───────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer header
            BlocBuilder<AuthCubit, AuthState>(
              builder: (ctx, authState) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white30, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            authState.user?.initials ?? 'U',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authState.user?.name ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              authState.user?.roleDisplayName ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ..._drawerItems
                      .map((item) => _buildDrawerTile(context, item)),
                  const Divider(height: 24, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: AppColors.error, size: 20),
                    ),
                    title: Text(SiStrings.logout,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      _handleLogout(context);
                    },
                  ),
                ],
              ),
            ),

            // Version footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                SiStrings.erpVersion,
                style: TextStyle(color: AppColors.textHint, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(BuildContext context, _DrawerItem item) {
    // Highlight dashboard item when on home
    final isCurrent = item.route == '/home';
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.primary.withValues(alpha: 0.1)
              : const Color(0xFFF4F6FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(item.icon,
            color: isCurrent ? AppColors.primary : AppColors.textSecondary,
            size: 20),
      ),
      title: Text(
        item.label,
        style: TextStyle(
          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          color: isCurrent ? AppColors.primary : AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (item.route == 'store') {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const StoreHomePage()));
        } else if (item.route.startsWith('/')) {
          context.push(item.route);
        } else {
          context.pushNamed(item.route);
        }
      },
    );
  }

  void _handleLogout(BuildContext context) async {
    final confirmed = await ConfirmationDialog.showLogout(context);
    if (confirmed && context.mounted) context.read<AuthCubit>().logout();
  }

  // ─── Welcome Banner ──────────────────────────────────────────────────────
  Widget _buildWelcomeBanner(BuildContext context, DashboardState state) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (ctx, authState) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SiStrings.greetHello(
                          (authState.user?.name ?? 'User').split(' ').first),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      SiStrings.todayProfit,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    state.isLoading
                        ? const SizedBox(
                            width: 60,
                            height: 22,
                            child: LinearProgressIndicator(
                                color: Colors.white54,
                                backgroundColor: Colors.white24),
                          )
                        : Text(
                            state.formattedTodayProfit,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ],
                ),
              ),
              // Improved Sync status button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.read<DashboardCubit>().syncData(),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          state.status == DashboardStatus.loading
                              ? Icons.sync_rounded
                              : Icons.cloud_done_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.pendingSyncCount > 0
                              ? SiStrings.pendingCount(state.pendingSyncCount)
                              : 'Synced',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Section Chip (Helakuru-style label) ─────────────────────────────────
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

  // Section header with professional "View All" button
  Widget _buildSectionHeader(String label, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionChip(label),
        if (onViewAll != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      SiStrings.viewAll,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Marketplace Banner ──────────────────────────────────────────────────
  Widget _buildMarketplaceBanner(BuildContext context) {
    return _MarketplaceBanner(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StoreHomePage()),
      ),
    );
  }

  // ─── Icon Grid (Helakuru-style) ──────────────────────────────────────────
  Widget _buildIconGrid(BuildContext context, List<_GridItem> items) {
    final screenWidth = MediaQuery.of(context).size.width;
    // On narrow screens (phones) use 4 columns; wider gets more space per icon
    final iconSize = (screenWidth / 4 - 24).clamp(52.0, 72.0);
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 4,
      mainAxisSpacing: 12,
      childAspectRatio: iconSize / (iconSize + 36),
      children: items
          .map((item) => _AnimatedGridItem(item: item, iconSize: iconSize))
          .toList(),
    );
  }

  // ─── Grid item definitions ────────────────────────────────────────────────
  List<_GridItem> _quickActions(BuildContext context) => [
        _GridItem(
          icon: Icons.shopping_bag_rounded,
          assetImage: 'assets/icons/buy.png',
          label: SiStrings.buyPaddy,
          color: const Color(0xFF4CAF50),
          onTap: () async {
            final customer = await context.push<CustomerModel>('/buy');
            if (customer != null && mounted) {
              context.read<BuyCubit>().selectCustomer(customer);
              await context.pushNamed('buyProcess');
              if (mounted) context.read<DashboardCubit>().loadDashboard();
            }
          },
        ),
        _GridItem(
          icon: Icons.sell_rounded,
          assetImage: 'assets/icons/sell.png',
          label: SiStrings.sellRice,
          color: const Color(0xFF2196F3),
          onTap: () async {
            final customer = await context.push<CustomerModel>(RouteNames.sell);
            if (customer != null && mounted) {
              context.read<SellCubit>().selectCustomer(customer);
              await context.pushNamed('sellProcess');
              if (mounted) context.read<DashboardCubit>().loadDashboard();
            }
          },
        ),
        _GridItem(
          icon: Icons.inventory_2_rounded,
          assetImage: 'assets/icons/stock.png',
          label: SiStrings.stock,
          color: const Color(0xFFFF9800),
          onTap: () async {
            await context.push('/stock');
            if (mounted) context.read<DashboardCubit>().loadDashboard();
          },
        ),
        _GridItem(
          icon: Icons.receipt_long_rounded,
          assetImage: 'assets/icons/add-expenses.png',
          label: SiStrings.expenses,
          color: const Color(0xFFE53935),
          onTap: () async {
            await context.push('/expenses');
            if (mounted) context.read<DashboardCubit>().loadDashboard();
          },
        ),
      ];

  List<_GridItem> _recordActions(BuildContext context) => [
        _GridItem(
          icon: Icons.people_alt_rounded,
          assetImage: 'assets/icons/customers.png',
          label: SiStrings.customers,
          color: const Color(0xFF9C27B0),
          onTap: () => context.push('/customers'),
        ),
        _GridItem(
          icon: Icons.compare_arrows_rounded,
          assetImage: 'assets/icons/transactions.png',
          label: SiStrings.transactions,
          color: const Color(0xFF00BCD4),
          onTap: () => context.pushNamed('reports'),
        ),
        _GridItem(
          icon: Icons.settings_suggest_rounded,
          assetImage: 'assets/icons/milling.png',
          label: SiStrings.milling,
          color: const Color(0xFF795548),
          onTap: () => context.push(RouteNames.milling),
        ),
        _GridItem(
          icon: Icons.local_offer_rounded,
          assetImage: 'assets/icons/prices.png',
          label: SiStrings.prices,
          color: const Color(0xFFFF5722),
          onTap: () async {
            await context.pushNamed('prices');
            if (mounted) context.read<DashboardCubit>().loadDashboard();
          },
        ),
      ];

  List<_GridItem> _reportActions(BuildContext context) => [
        _GridItem(
          icon: Icons.analytics_rounded,
          assetImage: 'assets/icons/analitics.png',
          label: SiStrings.analytics,
          color: const Color(0xFF3F51B5),
          onTap: () async {
            await context.pushNamed('detailedDashboard');
            if (mounted) context.read<DashboardCubit>().loadDashboard();
          },
        ),
        _GridItem(
          icon: Icons.summarize_rounded,
          assetImage: 'assets/icons/daily-report.png',
          label: SiStrings.dailyReport,
          color: const Color(0xFF009688),
          onTap: () => context.pushNamed('reports'),
        ),
        _GridItem(
          icon: Icons.add_box_rounded,
          assetImage: 'assets/icons/add-price.png',
          label: SiStrings.addPrice,
          color: const Color(0xFFFFC107),
          onTap: () async {
            await context.pushNamed('addPrice');
            if (mounted) context.read<DashboardCubit>().loadDashboard();
          },
        ),
        _GridItem(
          icon: Icons.person_rounded,
          assetImage: 'assets/icons/profile.png',
          label: SiStrings.profile,
          color: const Color(0xFF607D8B),
          onTap: () => context.push('/profile'),
        ),
      ];

  // ─── Today's Summary grid layout ─────────────────────────────────────────
  Widget _buildTodayStrip(DashboardState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: [
          _buildStatCard(
            SiStrings.buyPaddy,
            state.formattedTodayPurchases,
            AppColors.error,
            Icons.call_received_rounded,
            state.isLoading,
          ),
          _buildStatCard(
            SiStrings.sellRice,
            state.formattedTodaySales,
            AppColors.success,
            Icons.call_made_rounded,
            state.isLoading,
          ),
          _buildStatCard(
            SiStrings.expenses,
            state.formattedTodayExpenses,
            AppColors.warning,
            Icons.receipt_rounded,
            state.isLoading,
          ),
          _buildStatCard(
            SiStrings.netProfit,
            state.formattedTodayProfit,
            state.todayProfit >= 0 ? AppColors.primary : AppColors.error,
            Icons.monetization_on_rounded,
            state.isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 12),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF666688),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        isLoading
            ? Container(
                height: 18,
                width: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FA),
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
      ],
    );
  }

  // ─── Stock Card ──────────────────────────────────────────────────────────
  Widget _buildStockCard(DashboardState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStockTile(
                  label: SiStrings.paddyStock,
                  value: state.formattedPaddyStock,
                  icon: Icons.grass_rounded,
                  color: AppColors.warning,
                  isLoading: state.isLoading,
                ),
              ),
              Container(width: 1, height: 60, color: AppColors.divider),
              Expanded(
                child: _buildStockTile(
                  label: SiStrings.riceStock,
                  value: state.formattedRiceStock,
                  icon: Icons.rice_bowl_rounded,
                  color: AppColors.primary,
                  isLoading: state.isLoading,
                ),
              ),
            ],
          ),
          if (state.hasLowStock) ...[
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/stock'),
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.warningDark, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${state.lowStockCount} items are low on stock',
                          style: const TextStyle(
                            color: AppColors.warningDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warningDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'FIX NOW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStockTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isLoading,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        isLoading
            ? Container(
                width: 50,
                height: 14,
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4)),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ],
    );
  }
}

// ─── Animated grid icon ──────────────────────────────────────────────────────
class _AnimatedGridItem extends StatefulWidget {
  final _GridItem item;
  final double iconSize;
  const _AnimatedGridItem({required this.item, required this.iconSize});

  @override
  State<_AnimatedGridItem> createState() => _AnimatedGridItemState();
}

class _AnimatedGridItemState extends State<_AnimatedGridItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.forward();
  void _onTapUp(_) => _ctrl.reverse();
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final sz = widget.iconSize;
    return GestureDetector(
      onTap: item.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: sz,
              height: sz,
              child: Center(
                child: item.assetImage != null
                    ? Image.asset(
                        item.assetImage!,
                        width: sz * 0.85,
                        height: sz * 0.85,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            Icon(item.icon, color: item.color, size: sz * 0.65),
                      )
                    : Icon(item.icon, color: item.color, size: sz * 0.65),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: (sz * 0.18).clamp(10.0, 13.0),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C2C3E),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper models ──────────────────────────────────────────────────────────
class _GridItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? assetImage; // optional PNG from assets/icons/
  const _GridItem(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap,
      this.assetImage});
}

class _DrawerItem {
  final IconData icon;
  final String label;
  final String route;
  const _DrawerItem(this.icon, this.label, this.route);
}

// ─── Animated Marketplace Banner ─────────────────────────────────────────────
class _MarketplaceBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _MarketplaceBanner({required this.onTap});

  @override
  State<_MarketplaceBanner> createState() => _MarketplaceBannerState();
}

class _MarketplaceBannerState extends State<_MarketplaceBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left icon circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.storefront_rounded,
                    color: Colors.white, size: 26),
              ),
            ),
            const SizedBox(width: 14),
            // Text section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'සහල් වෙළෙඳපොළ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Rice Marketplace',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      _tag('Paddy'),
                      _tag('Rice'),
                      _tag('+ More'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Animated Explore button — arrow only (no duplicate icon)
            ScaleTransition(
              scale: _pulse,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_forward_rounded,
                        color: Color(0xFF2E7D32), size: 20),
                    SizedBox(height: 4),
                    Text(
                      'Explore',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
      ),
    );
  }
}
