import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/enums.dart';
import '../domain/repositories/auth_repository.dart';
import 'route_names.dart';

/// Route guard to check authentication status
class AuthGuard {
  final AuthRepository _authRepository;

  AuthGuard({required AuthRepository authRepository})
      : _authRepository = authRepository;

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final result = await _authRepository.isLoggedIn();
      return result.fold((l) => false, (r) => r);
    } catch (e) {
      return false;
    }
  }

  /// Check if user is global admin
  Future<bool> isAdmin() async {
    try {
      final result = await _authRepository.getCurrentUser();
      return result.fold((l) => false, (r) => r.role == UserRole.admin);
    } catch (e) {
      return false;
    }
  }

  /// Check if user is company user
  Future<bool> isCompany() async {
    try {
      final result = await _authRepository.getCurrentUser();
      return result.fold((l) => false,
          (r) => r.role == UserRole.company || r.role == UserRole.admin);
    } catch (e) {
      return false;
    }
  }

  /// Get user role
  Future<UserRole?> getUserRole() async {
    try {
      final result = await _authRepository.getCurrentUser();
      return result.fold((l) => null, (r) => r.role);
    } catch (e) {
      return null;
    }
  }
}

/// GoRouter redirect function for authentication
FutureOr<String?> authRedirect(
  BuildContext context,
  GoRouterState state,
  AuthGuard authGuard,
) async {
  final isLoggedIn = await authGuard.isAuthenticated();
  final isLoggingIn = state.matchedLocation == RouteNames.login;
  final isSplash = state.matchedLocation == RouteNames.splash;

  // Public routes that don't require authentication
  final publicRoutes = [
    RouteNames.splash,
    RouteNames.login,
    RouteNames.forgotPassword,
    RouteNames.resetPassword,
  ];

  final isPublicRoute = publicRoutes.contains(state.matchedLocation);

  // If not logged in and trying to access protected route
  if (!isLoggedIn && !isPublicRoute) {
    return '${RouteNames.login}?${RouteQueryParams.redirect}=${state.matchedLocation}';
  }

  // If logged in and trying to access login page
  if (isLoggedIn && isLoggingIn) {
    final role = await authGuard.getUserRole();
    if (role == UserRole.admin) {
      return RouteNames.adminDashboard;
    }
    return RouteNames.home;
  }

  // If on splash and logged in, redirect to appropriate dashboard
  if (isSplash && isLoggedIn) {
    final role = await authGuard.getUserRole();
    if (role == UserRole.admin) {
      return RouteNames.adminDashboard;
    }
    return RouteNames.home;
  }

  return null;
}

/// GoRouter redirect function for admin routes
FutureOr<String?> adminRedirect(
  BuildContext context,
  GoRouterState state,
  AuthGuard authGuard,
) async {
  final isAdmin = await authGuard.isAdmin();

  // Check if trying to access admin routes
  if (state.matchedLocation.startsWith('/admin')) {
    if (!isAdmin) {
      return RouteNames.home;
    }
  }

  return null;
}

/// Route observer for analytics and logging
class AppRouteObserver extends RouteObserver<ModalRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logNavigation('PUSH', route.settings.name, previousRoute?.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logNavigation('POP', previousRoute?.settings.name, route.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _logNavigation('REPLACE', newRoute?.settings.name, oldRoute?.settings.name);
  }

  void _logNavigation(String action, String? to, String? from) {
    debugPrint('🧭 Navigation: $action | From: $from | To: $to');
  }
}

/// Custom page transitions
class AppPageTransitions {
  AppPageTransitions._();

  /// Fade transition
  static CustomTransitionPage<void> fadeTransition({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// Slide transition from right
  static CustomTransitionPage<void> slideTransition({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  /// Slide up transition (for bottom sheets / modals)
  static CustomTransitionPage<void> slideUpTransition({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  /// Scale transition
  static CustomTransitionPage<void> scaleTransition({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  /// No transition
  static CustomTransitionPage<void> noTransition({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }
}
