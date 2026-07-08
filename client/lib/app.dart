import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/si_strings.dart';
import 'core/theme/app_theme.dart';
import 'injection_container.dart';
import 'routes/app_router.dart';

// Cubits
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/home/presentation/cubit/dashboard_cubit.dart';
import 'features/buy/presentation/cubit/buy_cubit.dart';
import 'features/buy/presentation/cubit/customer_cubit.dart';
import 'features/sell/presentation/cubit/sell_cubit.dart';
import 'features/stock/presentation/cubit/stock_cubit.dart';
import 'features/stock/presentation/cubit/milling_cubit.dart';
import 'features/customers/presentation/cubit/customers_cubit.dart';
import 'features/reports/presentation/cubit/reports_cubit.dart';
import 'features/expenses/presentation/cubit/expenses_cubit.dart';
import 'features/profile/presentation/cubit/profile_cubit.dart';
import 'features/super_admin/presentation/cubit/admin_cubit.dart';
import 'features/price_management/presentation/cubit/price_management_cubit.dart';

class RiceMillApp extends StatelessWidget {
  const RiceMillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Auth
        BlocProvider<AuthCubit>(
          create: (_) => sl<AuthCubit>(),
        ),

        // Dashboard
        BlocProvider<DashboardCubit>(
          create: (_) => sl<DashboardCubit>(),
        ),

        // Buy
        BlocProvider<BuyCubit>(
          create: (_) => sl<BuyCubit>(),
        ),
        BlocProvider<CustomerCubit>(
          create: (_) => sl<CustomerCubit>(),
        ),

        // Sell
        BlocProvider<SellCubit>(
          create: (_) => sl<SellCubit>(),
        ),

        // Stock
        BlocProvider<StockCubit>(
          create: (_) => sl<StockCubit>(),
        ),
        BlocProvider<MillingCubit>(
          create: (_) => sl<MillingCubit>(),
        ),

        // Customers
        BlocProvider<CustomersCubit>(
          create: (_) => sl<CustomersCubit>(),
        ),

        // Reports
        BlocProvider<ReportsCubit>(
          create: (_) => sl<ReportsCubit>(),
        ),

        // Expenses
        BlocProvider<ExpensesCubit>(
          create: (_) => sl<ExpensesCubit>(),
        ),

        // Profile
        BlocProvider<ProfileCubit>(
          create: (_) => sl<ProfileCubit>(),
        ),

        // Super Admin
        BlocProvider<AdminCubit>(
          create: (_) => sl<AdminCubit>(),
        ),

        // Price Management
        BlocProvider<PriceManagementCubit>(
          create: (_) => sl<PriceManagementCubit>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'ricemill',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: sl<AppRouter>().router,
        builder: (context, child) {
          // Layouts are tuned for scale 1.0; Sinhala strings are longer than
          // English, so devices with a large system font size overflow rows
          // and buttons. Clamp instead of ignoring the setting entirely.
          final scaled = MediaQuery.withClampedTextScaling(
            minScaleFactor: 0.85,
            maxScaleFactor: 1.15,
            child: child!,
          );

          // Bottom-nav tabs are kept alive by go_router's
          // StatefulNavigationShell, so they don't rebuild just because
          // SiStrings changed elsewhere. Re-keying on languageVersion forces
          // the whole routed tree (current route + kept-alive tabs) to
          // remount with the new language, without touching GoRouter's own
          // location state.
          return ValueListenableBuilder<int>(
            valueListenable: SiStrings.languageVersion,
            builder: (context, version, routedTree) {
              return KeyedSubtree(
                key: ValueKey(version),
                child: routedTree!,
              );
            },
            child: scaled,
          );
        },
      ),
    );
  }
}
