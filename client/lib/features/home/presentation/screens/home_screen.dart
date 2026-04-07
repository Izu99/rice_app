// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes/app_router.dart';
import '../../../../injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/confirmation_dialog.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
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
    _fadeAnimation = _animationController.drive(CurveTween(curve: Curves.easeInOut));
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

  // ─── Navigation items for drawer ────────────────────────────────────────
  static const _drawerItems = [
    _DrawerItem(Icons.dashboard_rounded,      'Dashboard',      '/home'),
    _DrawerItem(Icons.shopping_bag_rounded,   'Buy Paddy',      '/buy'),
    _DrawerItem(Icons.sell_rounded,           'Sell Rice',      '/sell'),
    _DrawerItem(Icons.inventory_2_rounded,    'Stock',          '/stock'),
    _DrawerItem(Icons.people_rounded,         'Customers',      '/customers'),
    _DrawerItem(Icons.receipt_long_rounded,   'Expenses',       '/expenses'),
    _DrawerItem(Icons.bar_chart_rounded,      'Reports',        '/reports'),
    _DrawerItem(Icons.local_offer_rounded,    'Prices',         'prices'),
    _DrawerItem(Icons.person_rounded,         'Profile',        '/profile'),
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
                    onRefresh: () => context.read<DashboardCubit>().refreshDashboard(),
                    color: AppColors.primary,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        _buildStickyHeader(context, state, profileState),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                // Welcome + Today stats banner
                                _buildWelcomeBanner(context, state),
                                const SizedBox(height: 24),
                                // Section: Quick Actions
                                _buildSectionChip('Quick Actions'),
                                const SizedBox(height: 14),
                                _buildIconGrid(context, _quickActions(context)),
                                const SizedBox(height: 24),
                                // Section: Records
                                _buildSectionChip('Records'),
                                const SizedBox(height: 14),
                                _buildIconGrid(context, _recordActions(context)),
                                const SizedBox(height: 24),
                                // Section: Reports & Tools
                                _buildSectionChip('Reports & Tools'),
                                const SizedBox(height: 14),
                                _buildIconGrid(context, _reportActions(context)),
                                const SizedBox(height: 24),
                                // Today Summary strip
                                _buildSectionChip('Today\'s Summary'),
                                const SizedBox(height: 14),
                                _buildTodayStrip(state),
                                const SizedBox(height: 24),
                                // Stock overview
                                _buildSectionChip('Stock Overview'),
                                const SizedBox(height: 14),
                                _buildStockCard(state),
                                const SizedBox(height: 24),
                                // Recent transactions
                                _buildSectionHeader(
                                  'Recent Transactions',
                                  onViewAll: () => context.pushNamed('reports'),
                                ),
                                const SizedBox(height: 12),
                                RecentTransactions(
                                  transactions: state.recentTransactions,
                                  isLoading: state.isLoading && state.recentTransactions.isEmpty,
                                ),
                                const SizedBox(height: 20),
                                // Recent expenses
                                _buildSectionHeader(
                                  'Recent Expenses',
                                  onViewAll: () => context.push('/expenses'),
                                ),
                                const SizedBox(height: 12),
                                RecentExpenses(
                                  expenses: state.recentExpenses,
                                  isLoading: state.isLoading && state.recentExpenses.isEmpty,
                                ),
                                const SizedBox(height: 100),
                              ],
                            ),
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

  // ─── Sticky App Bar ──────────────────────────────────────────────────────
  Widget _buildStickyHeader(
      BuildContext context, DashboardState state, ProfileState profileState) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black12,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 26),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      titleSpacing: 0,
      title: null,
      actions: [
        // Language toggle
        BlocBuilder<ProfileCubit, ProfileState>(
          builder: (ctx, ps) {
            final isSi = ps.language == 'si';
            return GestureDetector(
              onTap: () =>
                  context.read<ProfileCubit>().changeLanguage(isSi ? 'en' : 'si'),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isSi ? 'EN' : 'සිං',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 22),
          onPressed: () {},
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        // Profile avatar
        BlocBuilder<AuthCubit, AuthState>(
          builder: (ctx, authState) {
            return GestureDetector(
              onTap: () => context.push('/profile'),
              child: Container(
                margin: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryLight, width: 2),
                ),
                child: Center(
                  child: Text(
                    authState.user?.initials ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
      bottom: _showSearch
          ? PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search features...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF4F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            )
          : null,
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
                  ..._drawerItems.map((item) => _buildDrawerTile(context, item)),
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
                    title: const Text('Logout',
                        style: TextStyle(fontWeight: FontWeight.w600)),
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
                'Rice Mill ERP v1.0',
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
              ? AppColors.primary.withOpacity(0.1)
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
        if (item.route.startsWith('/')) {
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
                color: AppColors.primary.withOpacity(0.25),
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
                      'Hello, ${(authState.user?.name ?? 'User').split(' ').first}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Today\'s profit',
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
              // Sync status
              GestureDetector(
                onTap: () => context.read<DashboardCubit>().syncData(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_sync_outlined,
                          color: Colors.white, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        state.pendingSyncCount > 0
                            ? '${state.pendingSyncCount} pending'
                            : 'Synced',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 9),
                      ),
                    ],
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

  // Section header with "View All"
  Widget _buildSectionHeader(String label, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionChip(label),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Text(
              'View All →',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ─── Icon Grid (Helakuru-style) ──────────────────────────────────────────
  Widget _buildIconGrid(BuildContext context, List<_GridItem> items) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 6,
      mainAxisSpacing: 8,
      childAspectRatio: 0.63,
      children: items.map((item) => _buildGridItem(item)).toList(),
    );
  }

  Widget _buildGridItem(_GridItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: item.color.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(item.icon, color: item.color, size: 24),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C3E),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Grid item definitions ────────────────────────────────────────────────
  List<_GridItem> _quickActions(BuildContext context) => [
        _GridItem(
          icon: Icons.shopping_bag_rounded,
          label: 'Buy\nPaddy',
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
          label: 'Sell\nRice',
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
          label: 'Stock',
          color: const Color(0xFFFF9800),
          onTap: () async {
            await context.push('/stock');
            if (mounted) context.read<DashboardCubit>().loadDashboard();
          },
        ),
        _GridItem(
          icon: Icons.receipt_long_rounded,
          label: 'Add\nExpense',
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
          label: 'Customers',
          color: const Color(0xFF9C27B0),
          onTap: () => context.push('/customers'),
        ),
        _GridItem(
          icon: Icons.compare_arrows_rounded,
          label: 'Transactions',
          color: const Color(0xFF00BCD4),
          onTap: () => context.pushNamed('reports'),
        ),
        _GridItem(
          icon: Icons.settings_suggest_rounded,
          label: 'Milling',
          color: const Color(0xFF795548),
          onTap: () => context.push('/stock'),
        ),
        _GridItem(
          icon: Icons.local_offer_rounded,
          label: 'Prices',
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
          label: 'Analytics',
          color: const Color(0xFF3F51B5),
          onTap: () async {
            await context.pushNamed('detailedDashboard');
            if (mounted) context.read<DashboardCubit>().loadDashboard();
          },
        ),
        _GridItem(
          icon: Icons.summarize_rounded,
          label: 'Daily\nReport',
          color: const Color(0xFF009688),
          onTap: () => context.pushNamed('reports'),
        ),
        _GridItem(
          icon: Icons.add_box_rounded,
          label: 'Add Price',
          color: const Color(0xFFFFC107),
          onTap: () async {
            await context.pushNamed('addPrice');
            if (mounted) context.read<DashboardCubit>().loadDashboard();
          },
        ),
        _GridItem(
          icon: Icons.person_rounded,
          label: 'Profile',
          color: const Color(0xFF607D8B),
          onTap: () => context.push('/profile'),
        ),
      ];

  // ─── Today's Summary grid layout ─────────────────────────────────────────
  Widget _buildTodayStrip(DashboardState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Buy',
                state.formattedTodayPurchases,
                AppColors.error,
                Icons.call_received_rounded,
                state.isLoading,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Sell',
                state.formattedTodaySales,
                AppColors.success,
                Icons.call_made_rounded,
                state.isLoading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Expenses',
                state.formattedTodayExpenses,
                AppColors.warning,
                Icons.receipt_rounded,
                state.isLoading,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Profit',
                state.formattedTodayProfit,
                state.todayProfit >= 0 ? AppColors.primary : AppColors.error,
                Icons.monetization_on_rounded,
                state.isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon,
      bool isLoading) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF666688),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
        ],
      ),
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
            color: Colors.black.withOpacity(0.04),
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
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => context.push('/stock'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${state.lowStockCount} items low on stock — Tap to view',
                        style: const TextStyle(
                          color: AppColors.warningDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.warning, size: 18),
                  ],
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
            color: color.withOpacity(0.1),
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

// ─── Helper models ──────────────────────────────────────────────────────────
class _GridItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _GridItem(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
}

class _StatItem {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatItem(this.label, this.value, this.color, this.icon);
}

class _DrawerItem {
  final IconData icon;
  final String label;
  final String route;
  const _DrawerItem(this.icon, this.label, this.route);
}
