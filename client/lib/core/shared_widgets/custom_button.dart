import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

/// Button variant enum
enum ButtonVariant {
  primary,
  secondary,
  outline,
  text,
  danger,
  success,
  warning,
}

/// Button size enum
enum ButtonSize {
  small,
  medium,
  large,
}

/// Custom button widget
class CustomButton extends StatelessWidget {
  /// Button label text
  final String label;

  /// Callback when pressed
  final VoidCallback? onPressed;

  /// Button variant
  final ButtonVariant variant;

  /// Button size
  final ButtonSize size;

  /// Leading icon
  final IconData? icon;

  /// Trailing icon
  final IconData? trailingIcon;

  /// Whether button is loading
  final bool isLoading;

  /// Whether button should expand to full width
  final bool isExpanded;

  /// Custom width
  final double? width;

  /// Custom height
  final double? height;

  /// Border radius
  final double? borderRadius;

  /// Whether button is disabled
  final bool disabled;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = true,
    this.width,
    this.height,
    this.borderRadius,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isExpanded ? double.infinity : width,
      height: height ?? _getHeight(),
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    final isDisabled = disabled || isLoading || onPressed == null;

    switch (variant) {
      case ButtonVariant.primary:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: _getPrimaryStyle(),
          child: _buildContent(AppColors.white),
        );

      case ButtonVariant.secondary:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: _getSecondaryStyle(),
          child: _buildContent(AppColors.white),
        );

      case ButtonVariant.outline:
        return OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: _getOutlineStyle(),
          child: _buildContent(AppColors.primary),
        );

      case ButtonVariant.text:
        return TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: _getTextStyle(),
          child: _buildContent(AppColors.primary),
        );

      case ButtonVariant.danger:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: _getDangerStyle(),
          child: _buildContent(AppColors.white),
        );

      case ButtonVariant.success:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: _getSuccessStyle(),
          child: _buildContent(AppColors.white),
        );

      case ButtonVariant.warning:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: _getWarningStyle(),
          child: _buildContent(AppColors.black),
        );
    }
  }

  Widget _buildContent(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    final textStyle = _getTextStyle2().copyWith(color: color);
    final iconSize = _getIconSize();

    if (icon != null && trailingIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: color),
          SizedBox(width: _getIconSpacing()),
          Text(label, style: textStyle),
          SizedBox(width: _getIconSpacing()),
          Icon(trailingIcon, size: iconSize, color: color),
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: color),
          SizedBox(width: _getIconSpacing()),
          Text(label, style: textStyle),
        ],
      );
    }

    if (trailingIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: textStyle),
          SizedBox(width: _getIconSpacing()),
          Icon(trailingIcon, size: iconSize, color: color),
        ],
      );
    }

    return Text(label, style: textStyle);
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return AppDimensions.buttonHeightS;
      case ButtonSize.medium:
        return AppDimensions.buttonHeightM;
      case ButtonSize.large:
        return AppDimensions.buttonHeightL;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  double _getIconSpacing() {
    switch (size) {
      case ButtonSize.small:
        return 4;
      case ButtonSize.medium:
        return 8;
      case ButtonSize.large:
        return 10;
    }
  }

  TextStyle _getTextStyle2() {
    switch (size) {
      case ButtonSize.small:
        return AppTextStyles.labelMedium;
      case ButtonSize.medium:
        return AppTextStyles.button;
      case ButtonSize.large:
        return AppTextStyles.button.copyWith(fontSize: 16);
    }
  }

  ButtonStyle _getPrimaryStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDimensions.radiusM,
        ),
      ),
    );
  }

  ButtonStyle _getSecondaryStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.secondary,
      foregroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDimensions.radiusM,
        ),
      ),
    );
  }

  ButtonStyle _getOutlineStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDimensions.radiusM,
        ),
      ),
    );
  }

  ButtonStyle _getTextStyle() {
    return TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDimensions.radiusM,
        ),
      ),
    );
  }

  ButtonStyle _getDangerStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.error,
      foregroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDimensions.radiusM,
        ),
      ),
    );
  }

  ButtonStyle _getSuccessStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.success,
      foregroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDimensions.radiusM,
        ),
      ),
    );
  }

  ButtonStyle _getWarningStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.warning,
      foregroundColor: AppColors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDimensions.radiusM,
        ),
      ),
    );
  }
}

/// Icon button with label
class IconTextButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final double iconSize;
  final bool vertical;

  const IconTextButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
    this.iconSize = 24,
    this.vertical = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    if (vertical) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingS),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize, color: effectiveColor),
              const SizedBox(height: AppDimensions.paddingXS),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: effectiveColor),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingS),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: effectiveColor),
            const SizedBox(width: AppDimensions.paddingS),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: effectiveColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// Large action card button (for Dashboard)
class ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double? height;

  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Container(
          height: height ?? AppDimensions.actionCardHeight,
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Icon(
                  icon,
                  size: AppDimensions.iconL,
                  color: AppColors.white,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.h4.copyWith(color: AppColors.white),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
