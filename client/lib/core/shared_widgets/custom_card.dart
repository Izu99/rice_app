import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

/// Custom card widget
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? elevation;
  final double? borderRadius;
  final Border? border;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Gradient? gradient;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.border,
    this.onTap,
    this.onLongPress,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.white) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDimensions.cardRadius,
        ),
        border: border,
        boxShadow: elevation != null && elevation! > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05 * elevation!),
                  blurRadius: elevation! * 4,
                  offset: Offset(0, elevation!),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppDimensions.cardRadius,
          ),
          child: cardContent,
        ),
      );
    }

    if (margin != null) {
      cardContent = Padding(padding: margin!, child: cardContent);
    }

    return cardContent;
  }
}

/// Summary card with title and value
class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.iconColor,
    this.backgroundColor,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      color: backgroundColor,
      onTap: onTap,
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
                size: AppDimensions.iconL,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption,
                ),
                Text(
                  value,
                  style: AppTextStyles.h5,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Stat card for dashboard
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? change;
  final bool isPositiveChange;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.change,
    this.isPositiveChange = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withOpacity(0.8),
          color,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingS),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusRound),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositiveChange
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        change!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.h4.copyWith(color: Colors.white),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// List item card
class ListItemCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailing;
  final Widget? leading;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Widget? trailingWidget;
  final bool showChevron;

  const ListItemCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.trailingWidget,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      color: backgroundColor,
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppDimensions.paddingM),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          if (trailingWidget != null) trailingWidget!,
          if (showChevron && onTap != null) ...[
            const SizedBox(width: AppDimensions.paddingS),
            const Icon(
              Icons.chevron_right,
              color: AppColors.grey400,
            ),
          ],
        ],
      ),
    );
  }
}

/// Info card with icon and message
class InfoCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;
  final VoidCallback? onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  const InfoCard({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color,
    this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  factory InfoCard.info({
    required String message,
    VoidCallback? onDismiss,
  }) {
    return InfoCard(
      message: message,
      icon: Icons.info_outline,
      color: AppColors.info,
      onDismiss: onDismiss,
    );
  }

  factory InfoCard.warning({
    required String message,
    VoidCallback? onDismiss,
  }) {
    return InfoCard(
      message: message,
      icon: Icons.warning_amber_outlined,
      color: AppColors.warning,
      onDismiss: onDismiss,
    );
  }

  factory InfoCard.error({
    required String message,
    VoidCallback? onDismiss,
  }) {
    return InfoCard(
      message: message,
      icon: Icons.error_outline,
      color: AppColors.error,
      onDismiss: onDismiss,
    );
  }

  factory InfoCard.success({
    required String message,
    VoidCallback? onDismiss,
  }) {
    return InfoCard(
      message: message,
      icon: Icons.check_circle_outline,
      color: AppColors.success,
      onDismiss: onDismiss,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.info;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: effectiveColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: effectiveColor, size: 24),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: effectiveColor),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, color: effectiveColor, size: 20),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

