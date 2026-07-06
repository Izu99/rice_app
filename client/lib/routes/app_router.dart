import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Core
import '../core/theme/app_colors.dart';
import '../core/shared_widgets/app_page_scaffold.dart';
import '../core/shared_widgets/h_app_bar.dart';

// Features - Auth
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';

// Features - Home
import '../features/home/presentation/screens/home_screen.dart';
import '../features/home/presentation/screens/detailed_dashboard_screen.dart';
import '../features/home/presentation/screens/main_wrapper_screen.dart';

// Features - Buy
import '../features/buy/presentation/screens/buy_screen.dart';
import '../features/buy/presentation/screens/buy_customer_selection_screen.dart';

// Features - Sell
import '../features/sell/presentation/screens/sell_screen.dart';
import '../features/sell/presentation/screens/sell_customer_selection_screen.dart';

// Features - Stock
import '../core/constants/enums.dart';
import '../features/stock/presentation/screens/stock_screen.dart';
import '../features/stock/presentation/screens/milling_screen.dart';

// Features - Customers
import '../features/customers/presentation/screens/customers_list_screen.dart';
import '../features/customers/presentation/screens/customer_detail_screen.dart';
import '../features/customers/presentation/screens/customer_add_edit_screen.dart';

// Features - Reports
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/reports/presentation/screens/daily_report_screen.dart';
import '../features/reports/presentation/screens/stock_report_screen.dart';
import '../features/reports/presentation/screens/customer_report_screen.dart';

// Features - Expenses
import '../features/expenses/presentation/screens/expenses_list_screen.dart';
import '../features/expenses/presentation/screens/expense_add_edit_screen.dart';

// Features - Profile
import '../features/profile/presentation/screens/profile_screen.dart';

// Features - Legal
import '../features/legal/presentation/screens/terms_screen.dart';
import '../features/legal/presentation/screens/privacy_screen.dart';
import '../features/legal/presentation/screens/about_screen.dart';
import '../features/legal/presentation/screens/data_deletion_screen.dart';

// Features - Price Management
import '../features/price_management/presentation/screens/add_price_screen.dart';
import '../features/price_management/presentation/screens/view_prices_by_district_screen.dart';
import '../features/price_management/presentation/screens/prices_in_district_screen.dart';

// Features - Super Admin
import '../features/super_admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/super_admin/presentation/screens/companies_screen.dart';
import '../features/super_admin/presentation/screens/add_company_screen.dart';
import '../features/super_admin/presentation/screens/admin_price_list_screen.dart';
import '../features/super_admin/presentation/screens/admin_reports_screen.dart';
import '../features/super_admin/presentation/screens/admin_settings_screen.dart';

// Routes
import 'route_names.dart';
import 'route_guards.dart';

// Injection

/// Global navigator key
final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// App Router configuration
class AppRouter {
  final AuthGuard _authGuard;

  final AppRouteObserver routeObserver = AppRouteObserver();

  AppRouter({required AuthGuard authGuard}) : _authGuard = authGuard;

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    observers: [routeObserver],

    // Global redirect for authentication
    redirect: (context, state) => authRedirect(context, state, _authGuard),

    // Error page
    errorBuilder: (context, state) => ErrorScreen(error: state.error),

    routes: [
      // ==================== Auth Routes ====================
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      /*
      GoRoute(
        path: RouteNames.landing,
        name: 'landing',
        builder: (context, state) => const LandingScreen(),
      ),
      */

      // ==================== Main App Shell ====================
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return MainWrapperScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch: Home/Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'detailed-dashboard',
                    name: 'detailedDashboard',
                    builder: (context, state) =>
                        const DetailedDashboardScreen(),
                  ),
                ],
              ),
              // ==================== Price Management Routes ====================
              GoRoute(
                path: '/prices',
                name: 'prices',
                builder: (context, state) => const ViewPricesByDistrictScreen(),
              ),
              GoRoute(
                path: '/prices/add',
                name: 'addPrice',
                builder: (context, state) => const AddPriceScreen(),
              ),
              GoRoute(
                path: '/prices/district/:district',
                name: 'pricesInDistrict',
                builder: (context, state) {
                  final district = state.pathParameters['district'] ?? '';
                  return PricesInDistrictScreen(district: district);
                },
              ),

              // ==================== Customers Routes ====================
              GoRoute(
                path: RouteNames.customers,
                name: 'customers',
                builder: (context, state) => const CustomersListScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    name: 'customerAdd',
                    builder: (context, state) => const CustomerAddEditScreen(),
                  ),
                  GoRoute(
                    path: 'detail/:id',
                    name: 'customerDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return CustomerDetailScreen(customerId: id);
                    },
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    name: 'customerEdit',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return CustomerAddEditScreen(customerId: id);
                    },
                  ),
                ],
              ),

              // ==================== Settings Route ====================
              GoRoute(
                path: RouteNames.settings,
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),

              // ==================== Buy Routes ====================
              GoRoute(
                path: RouteNames.buy,
                name: 'buy',
                builder: (context, state) => const BuyCustomerSelectionScreen(),
                routes: [
                  GoRoute(
                    path: 'process',
                    name: 'buyProcess',
                    builder: (context, state) => const BuyScreen(),
                  ),
                  GoRoute(
                    path: 'add-customer',
                    name: 'buyAddCustomer',
                    builder: (context, state) => const CustomerAddEditScreen(
                        initialType: CustomerType.seller),
                  ),
                ],
              ),

              // ==================== Sell Routes ====================
              GoRoute(
                path: RouteNames.sell,
                name: 'sell',
                builder: (context, state) => const SellCustomerSelectionScreen(),
                routes: [
                  GoRoute(
                    path: 'process',
                    name: 'sellProcess',
                    builder: (context, state) => const SellScreen(),
                  ),
                  GoRoute(
                    path: 'add-customer',
                    name: 'sellAddCustomer',
                    builder: (context, state) => const CustomerAddEditScreen(
                        initialType: CustomerType.buyer),
                  ),
                ],
              ),
            ],
          ),

          // Branch: Stock
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.stock,
                name: 'stock',
                builder: (context, state) => const StockScreen(),
                routes: [
                  GoRoute(
                    path: 'detail/:id',
                    name: 'stockDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return StockDetailScreen(stockId: id);
                    },
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    name: 'stockEdit',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return StockEditScreen(stockId: id);
                    },
                  ),
                  GoRoute(
                    path: 'milling',
                    name: 'milling',
                    builder: (context, state) => const MillingScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Branch: Reports
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.reports,
                name: 'reports',
                builder: (context, state) => const ReportsScreen(),
                routes: [
                  GoRoute(
                    path: 'daily',
                    name: 'dailyReport',
                    builder: (context, state) => const DailyReportScreen(),
                  ),
                  GoRoute(
                    path: 'stock',
                    name: 'stockReport',
                    builder: (context, state) => const StockReportScreen(),
                  ),
                  GoRoute(
                    path: 'customer',
                    name: 'customerReport',
                    builder: (context, state) => const CustomerReportScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Branch: Expenses
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.expenses,
                name: 'expenses',
                builder: (context, state) => const ExpensesListScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    name: 'expenseAdd',
                    builder: (context, state) => const ExpenseAddEditScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Branch: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Sell Receipt (Full Screen)
      GoRoute(
        path: '${RouteNames.sellReceipt}/:id',
        name: 'sellReceipt',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SellReceiptScreen(transactionId: id);
        },
      ),

      // ==================== Admin Routes ====================
      GoRoute(
        path: RouteNames.adminDashboard,
        name: 'adminDashboard',
        redirect: (context, state) => adminRedirect(context, state, _authGuard),
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.adminCompanies,
        name: 'adminCompanies',
        redirect: (context, state) => adminRedirect(context, state, _authGuard),
        builder: (context, state) => const CompaniesScreen(),
        routes: [
          GoRoute(
            path: 'add',
            name: 'adminCompanyAdd',
            builder: (context, state) => const AddCompanyScreen(),
          ),
          GoRoute(
            path: ':id',
            name: 'adminCompanyDetail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CompanyDetailScreen(companyId: id);
            },
          ),
          GoRoute(
            path: 'edit/:id',
            name: 'adminCompanyEdit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AddCompanyScreen(companyId: id);
            },
          ),
        ],
      ),

      // ==================== Admin Reports Route ====================
      GoRoute(
        path: RouteNames.adminReports,
        name: 'adminReports',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => adminRedirect(context, state, _authGuard),
        builder: (context, state) => const AdminReportsScreen(),
      ),

      // ==================== Admin Settings Route ====================
      GoRoute(
        path: RouteNames.adminSettings,
        name: 'adminSettings',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => adminRedirect(context, state, _authGuard),
        builder: (context, state) => const AdminSettingsScreen(),
      ),

      // ==================== Admin Price List Route ====================
      GoRoute(
        path: '/admin/prices',
        name: 'adminPriceList',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => adminRedirect(context, state, _authGuard),
        builder: (context, state) => const AdminPriceListScreen(),
      ),

      // ==================== Legal Routes ====================
      GoRoute(
        path: RouteNames.termsConditions,
        name: 'terms',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: RouteNames.privacyPolicy,
        name: 'privacy',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: RouteNames.about,
        name: 'about',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: RouteNames.dataDeletion,
        name: 'dataDeletion',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DataDeletionScreen(),
      ),
    ],
  );
}

// ==================== Error & Placeholder Screens ====================

class ErrorScreen extends StatelessWidget {
  final Exception? error;
  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Error'), backgroundColor: AppColors.error),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text('Oops! Something went wrong',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(error?.toString() ?? 'Page not found',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: () => context.go(RouteNames.home),
                  child: const Text('Go to Home')),
            ],
          ),
        ),
      ),
    );
  }
}

class StockDetailScreen extends StatelessWidget {
  final String stockId;
  const StockDetailScreen({super.key, required this.stockId});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text('Stock Detail: $stockId')));
}

class StockEditScreen extends StatelessWidget {
  final String stockId;
  const StockEditScreen({super.key, required this.stockId});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text('Edit Stock: $stockId')));
}

class BuyReceiptScreen extends StatelessWidget {
  final String transactionId;
  const BuyReceiptScreen({super.key, required this.transactionId});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Buy Receipt')));
}

class SellReceiptScreen extends StatelessWidget {
  final String transactionId;
  const SellReceiptScreen({super.key, required this.transactionId});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Sell Receipt')));
}

class CompanyDetailScreen extends StatelessWidget {
  final String companyId;
  const CompanyDetailScreen({super.key, required this.companyId});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Company Detail')));
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Maintenance Settings',
      subtitle: 'Fix data issues or check backend connectivity',
      actions: [
        IconButton(
          onPressed: () => _showBackendAction(context),
          icon: const Icon(Icons.cloud_outlined),
          tooltip: 'Backend',
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HSectionChip('Database Management'),
          const SizedBox(height: 16),
          const Text(
            'Use these tools if you are experiencing data errors or sync issues.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          HCard(
            onTap: () => _showResetConfirmation(context),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete_forever, color: AppColors.error),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Reset Local Database',
                        style: TextStyle(
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Delete local customers and transactions. Unsynced data will be lost.',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0B7C3)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          HCard(
            onTap: () {},
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.settings_backup_restore_outlined,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Backend Sync',
                        style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Trigger a backend connection check and sync health status.',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0B7C3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBackendAction(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backend action opened'),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Are you absolutely sure?'),
        content: const Text(
          'This action will wipe your local data and restart the app. Only use this to fix corrupt data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'All local data related to SharedPreferences cleared. Please close and restart the app if issues persist.',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
                context.go(RouteNames.splash);
              }
            },
            child: const Text('RESET NOW'),
          ),
        ],
      ),
    );
  }
}
