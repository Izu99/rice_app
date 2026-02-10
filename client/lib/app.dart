import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
import 'features/profile/presentation/cubit/profile_state.dart';
import 'features/super_admin/presentation/cubit/admin_cubit.dart';

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
      ],
      child: BlocBuilder<ProfileCubit, ProfileState>(
        buildWhen: (previous, current) => previous.language != current.language,
        builder: (context, state) {
          return MaterialApp.router(
            key: ValueKey(state.language),
            title: 'Rice Mill ERP',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            routerConfig: sl<AppRouter>().router,
            locale: Locale(state.language),
          );
        },
      ),
    );
  }
}
