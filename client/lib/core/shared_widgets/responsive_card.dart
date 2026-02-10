import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../utils/responsive_utils.dart';

/// Reusable responsive card widget with consistent styling
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final List<BoxShadow>? boxShadow;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final Border? border;
  final double? elevation;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.boxShadow,
    this.borderRadius,
    this.gradient,
    this.onTap,
    this.border,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ??
        EdgeInsets.all(
          ResponsiveUtils.getResponsivePadding(
            context,
            mobile: AppDimensions.paddingM,
            tablet: AppDimensions.paddingL,
          ),
        );

    final widget = Container(
      padding: responsivePadding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.white) : null,
        gradient: gradient,
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: boxShadow ??
            (elevation != null
                ? [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: elevation! * 2,
                      offset: Offset(0, elevation! / 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]),
        border: border,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppDimensions.radiusL),
        child: widget,
      );
    }

    return widget;
  }
}

/// Responsive stat card for displaying statistics
class ResponsiveStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const ResponsiveStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      onTap: onTap,
      elevation: 2,
      border: Border.all(color: color.withOpacity(0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (onTap != null)
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.grey400),
            ],
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isLoading)
                  const CircularProgressIndicator(strokeWidth: 2)
                else
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: ResponsiveUtils.scaleTextStyle(
                        context,
                        TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        mobileFactor: 0.9,
                        tabletFactor: 1.0,
                        desktopFactor: 1.1,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Responsive action button card
class ResponsiveActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ResponsiveActionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      onTap: onTap,
      elevation: 2,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: ResponsiveUtils.scaleTextStyle(
                context,
                const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                mobileFactor: 0.9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
