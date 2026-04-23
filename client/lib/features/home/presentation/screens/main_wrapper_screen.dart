// lib/features/home/presentation/screens/main_wrapper_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/shared_widgets/app_bottom_nav_bar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/cubit/profile_state.dart';
import '../cubit/dashboard_cubit.dart';

/// Main wrapper with bottom navigation
class MainWrapperScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainWrapperScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data when wrapper is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardCubit>().loadDashboard();
    });
  }

  void _onDestinationSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: true,
    );

    if (index == 0) {
      context.read<DashboardCubit>().loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.authStatus != current.authStatus,
      listener: (context, state) {
        if (state.authStatus == AuthStatus.unauthenticated) {
          context.go('/login');
        }
      },
      child: BlocBuilder<ProfileCubit, ProfileState>(
        buildWhen: (previous, current) => previous.language != current.language,
        builder: (context, profileState) {
          return BlocBuilder<AuthCubit, AuthState>(
            buildWhen: (previous, current) => previous.user != current.user,
            builder: (context, authState) {
              final isAdmin = authState.user?.isAdmin ?? false;

              return Scaffold(
                body: widget.navigationShell,
                bottomNavigationBar: !isAdmin
                    ? AppBottomNavigationBar(
                        currentIndex: widget.navigationShell.currentIndex,
                        onTap: _onDestinationSelected,
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
