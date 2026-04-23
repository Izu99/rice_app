import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable extended FAB used on any "add item" page.
/// Matches the app's green gradient theme consistently.
///
/// Usage:
/// ```dart
/// floatingActionButton: AppFab(
///   label: 'Add Price',
///   onPressed: () => context.pushNamed('addPrice'),
/// ),
/// ```
class AppFab extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  final Color? color;

  const AppFab({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: color ?? AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
