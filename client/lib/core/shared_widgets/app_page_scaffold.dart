// lib/core/shared_widgets/app_page_scaffold.dart
// Consistent page wrapper for all non-home screens

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'h_app_bar.dart';

// ─── AppPageScaffold ──────────────────────────────────────────────────────────

/// Drop-in Scaffold replacement for all sub-pages.
/// Provides:
///   • Gradient HAppBar with animated back button
///   • Fade + slide-up entrance animation on body
///   • Consistent background color
///   • Optional floating pill bottom bar via [bottomBar]
class AppPageScaffold extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final Widget? bottomBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? appBarBottom;
  final double appBarBottomHeight;
  final bool resizeToAvoidBottomInset;

  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.onBack,
    this.bottomBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.appBarBottom,
    this.appBarBottomHeight = 0,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  State<AppPageScaffold> createState() => _AppPageScaffoldState();
}

class _AppPageScaffoldState extends State<AppPageScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      appBar: HAppBar(
        title: widget.title,
        subtitle: widget.subtitle,
        actions: widget.actions,
        onBack: widget.onBack,
        bottom: widget.appBarBottom,
        bottomHeight: widget.appBarBottomHeight,
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: widget.body,
        ),
      ),
      bottomNavigationBar: widget.bottomBar,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
    );
  }
}

// ─── AppSubBottomBar ──────────────────────────────────────────────────────────

/// Floating pill bottom bar for sub-pages.
/// Matches the main nav pill style with gradient background.
///
/// Usage:
/// ```dart
/// bottomBar: AppSubBottomBar(
///   centerLabel: SiStrings.save,
///   onCenter: _save,
///   trailingIcon: Icons.delete_outline,
///   onTrailing: _delete,
///   trailingColor: AppColors.error,
/// )
/// ```
class AppSubBottomBar extends StatelessWidget {
  /// Left side: back button (always shown unless showBack is false)
  final bool showBack;
  final VoidCallback? onBack;

  /// Optional center label + action
  final String? centerLabel;
  final VoidCallback? onCenter;
  final Color? centerColor;
  final IconData? centerIcon;

  /// Optional trailing icon + action
  final IconData? trailingIcon;
  final VoidCallback? onTrailing;
  final Color? trailingColor;
  final String? trailingTooltip;

  const AppSubBottomBar({
    super.key,
    this.showBack = true,
    this.onBack,
    this.centerLabel,
    this.onCenter,
    this.centerColor,
    this.centerIcon,
    this.trailingIcon,
    this.onTrailing,
    this.trailingColor,
    this.trailingTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        height: 60,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Back button (left)
            if (showBack)
              _PillButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack ?? () => Navigator.of(context).pop(),
                tooltip: 'Back',
              )
            else
              const SizedBox(width: 16),

            // Center action
            if (centerLabel != null || centerIcon != null)
              Expanded(
                child: _PillCenterButton(
                  label: centerLabel,
                  icon: centerIcon,
                  color: centerColor,
                  onTap: onCenter ?? () {},
                ),
              )
            else
              const Spacer(),

            // Trailing action
            if (trailingIcon != null)
              _PillButton(
                icon: trailingIcon!,
                color: trailingColor,
                onTap: onTrailing ?? () {},
                tooltip: trailingTooltip,
              )
            else
              const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Internal pill button ────────────────────────────────────────────────────

class _PillButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final String? tooltip;

  const _PillButton({
    required this.icon,
    required this.onTap,
    this.color,
    this.tooltip,
  });

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.80).animate(
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
    Widget btn = GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 52,
          height: 52,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            color: widget.color ?? Colors.white,
            size: 20,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: btn);
    }
    return btn;
  }
}

// ─── Internal pill center button ─────────────────────────────────────────────

class _PillCenterButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final Color? color;
  final VoidCallback onTap;

  const _PillCenterButton({
    this.label,
    this.icon,
    this.color,
    required this.onTap,
  });

  @override
  State<_PillCenterButton> createState() => _PillCenterButtonState();
}

class _PillCenterButtonState extends State<_PillCenterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
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
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: widget.color ?? Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                const SizedBox(width: 12),
                Icon(widget.icon!, color: Colors.white, size: 18),
                const SizedBox(width: 6),
              ] else
                const SizedBox(width: 16),
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}
