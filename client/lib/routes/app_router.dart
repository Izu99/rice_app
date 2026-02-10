import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Core
import '../core/theme/app_colors.dart';

// Features - Auth
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';

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
import '../features/reports/presentation/screens/monthly_report_screen.dart';

// Features - Transactions
import '../features/transactions/presentation/screens/transaction_detail_screen.dart';

// Features - Expenses
import '../features/expenses/presentation/screens/expenses_list_screen.dart';
import '../features/expenses/presentation/screens/expense_add_edit_screen.dart';

// Features - Profile
import '../features/profile/presentation/screens/profile_screen.dart';

// Features - Super Admin
import '../features/super_admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/super_admin/presentation/screens/companies_screen.dart';
import '../features/super_admin/presentation/screens/add_company_screen.dart';

// Routes
import 'route_names.dart';
import 'route_guards.dart';

// Injection

/// Global navigator key
final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');
final GlobalKey<NavigatorState> _buyShellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'buyShell');
final GlobalKey<NavigatorState> _sellShellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'sellShell');
final GlobalKey<NavigatorState> _adminShellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'adminShell');

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
                    path: 'monthly',
                    name: 'monthlyReport',
                    builder: (context, state) => const MonthlyReportScreen(),
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

      // ==================== Buy Routes (Outside Shell) ====================
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
            builder: (context, state) =>
                const CustomerAddEditScreen(initialType: CustomerType.seller),
          ),
        ],
      ),

      // Buy Receipt (Full Screen)
      GoRoute(
        path: '${RouteNames.buyReceipt}/:id',
        name: 'buyReceipt',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BuyReceiptScreen(transactionId: id);
        },
      ),

      // Transaction Detail (Full Screen)
      GoRoute(
        path: '/transactions/:id',
        name: 'transactionDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TransactionDetailScreen(transactionId: id);
        },
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
            builder: (context, state) =>
                const CustomerAddEditScreen(initialType: CustomerType.buyer),
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

      // ==================== Customers Routes ====================
      GoRoute(
        path: RouteNames.customers,
        name: 'customers',
        parentNavigatorKey: _rootNavigatorKey,
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

      // ==================== Settings Route ====================
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Database Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use these tools if you are experiencing data errors or sync issues.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Card(
            color: AppColors.error.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.error.withOpacity(0.2)),
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: AppColors.error),
              title: const Text('Reset Local Database',
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.bold)),
              subtitle: const Text(
                  'This will delete all local customers and transactions. Data NOT synced to the server will be lost.'),
              onTap: () => _showResetConfirmation(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Are you absolutely sure?'),
        content: const Text(
            'This action will wipe your local data and restart the app. Only use this to fix corrupt data.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogContext);

              // In a real app we might trigger a system restart, here we go home
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'All local data related to SharedPreferences cleared. Please close and restart the app if issues persist.'),
                      backgroundColor: AppColors.success),
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
