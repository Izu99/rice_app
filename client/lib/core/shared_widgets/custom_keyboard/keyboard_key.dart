import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

/// Type of keyboard key
enum KeyType {
  /// Numeric digit (0-9)
  digit,

  /// Decimal point
  decimal,

  /// Backspace/delete
  backspace,

  /// Clear all
  clear,

  /// Done/confirm action
  done,

  /// Custom action
  action,

  /// Empty/spacer
  empty,
}

/// Individual keyboard key widget
class KeyboardKey extends StatefulWidget {
  /// Label text for the key
  final String label;

  /// Type of key
  final KeyType type;

  /// Callback when key is tapped
  final VoidCallback? onTap;

  /// Callback for long press
  final VoidCallback? onLongPress;

  /// Icon to display instead of label
  final IconData? icon;

  /// Background color
  final Color? backgroundColor;

  /// Text/Icon color
  final Color? foregroundColor;

  /// Key width (null for flexible)
  final double? width;

  /// Key height
  final double? height;

  /// Whether key is enabled
  final bool enabled;

  /// Border radius
  final double? borderRadius;

  /// Show ripple effect
  final bool showRipple;

  /// Haptic feedback type
  final HapticFeedbackType hapticType;

  const KeyboardKey({
    super.key,
    required this.label,
    required this.type,
    this.onTap,
    this.onLongPress,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.enabled = true,
    this.borderRadius,
    this.showRipple = true,
    this.hapticType = HapticFeedbackType.light,
  });

  /// Create a digit key
  factory KeyboardKey.digit(
    String digit, {
    required VoidCallback onTap,
    double? width,
    double? height,
  }) {
    return KeyboardKey(
      label: digit,
      type: KeyType.digit,
      onTap: onTap,
      width: width,
      height: height,
    );
  }

  /// Create a decimal key
  factory KeyboardKey.decimal({
    required VoidCallback onTap,
    double? width,
    double? height,
  }) {
    return KeyboardKey(
      label: '.',
      type: KeyType.decimal,
      onTap: onTap,
      width: width,
      height: height,
    );
  }

  /// Create a backspace key
  factory KeyboardKey.backspace({
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    double? width,
    double? height,
  }) {
    return KeyboardKey(
      label: '',
      type: KeyType.backspace,
      onTap: onTap,
      onLongPress: onLongPress,
      icon: Icons.backspace_outlined,
      width: width,
      height: height,
    );
  }

  /// Create a clear key
  factory KeyboardKey.clear({
    required VoidCallback onTap,
    double? width,
    double? height,
  }) {
    return KeyboardKey(
      label: 'C',
      type: KeyType.clear,
      onTap: onTap,
      width: width,
      height: height,
    );
  }

  /// Create a done key
  factory KeyboardKey.done({
    required VoidCallback onTap,
    String label = 'Done',
    double? width,
    double? height,
  }) {
    return KeyboardKey(
      label: label,
      type: KeyType.done,
      onTap: onTap,
      width: width,
      height: height,
    );
  }

  /// Create an empty spacer key
  factory KeyboardKey.empty({
    double? width,
    double? height,
  }) {
    return KeyboardKey(
      label: '',
      type: KeyType.empty,
      width: width,
      height: height,
    );
  }

  @override
  State<KeyboardKey> createState() => _KeyboardKeyState();
}

class _KeyboardKeyState extends State<KeyboardKey>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.type == KeyType.empty) return;
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.enabled || widget.type == KeyType.empty) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    if (!widget.enabled || widget.type == KeyType.empty) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTap() {
    if (!widget.enabled || widget.type == KeyType.empty) return;
    _triggerHaptic();
    widget.onTap?.call();
  }

  void _onLongPress() {
    if (!widget.enabled || widget.type == KeyType.empty) return;
    _triggerHaptic();
    widget.onLongPress?.call();
  }

  void _triggerHaptic() {
    switch (widget.hapticType) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticFeedbackType.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == KeyType.empty) {
      return SizedBox(
        width: widget.width ?? AppDimensions.keyboardKeySize,
        height: widget.height ?? AppDimensions.keyboardKeySize,
      );
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: SizedBox(
        width: widget.width ?? AppDimensions.keyboardKeySize,
        height: widget.height ?? AppDimensions.keyboardKeySize,
        child: Material(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? AppDimensions.radiusM,
          ),
          elevation: _isPressed ? 0 : 1,
          shadowColor: Colors.black26,
          child: InkWell(
            onTap: widget.enabled ? _onTap : null,
            onLongPress: widget.onLongPress != null && widget.enabled
                ? _onLongPress
                : null,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            borderRadius: BorderRadius.circular(
              widget.borderRadius ?? AppDimensions.radiusM,
            ),
            splashColor: widget.showRipple
                ? _getForegroundColor().withOpacity(0.2)
                : Colors.transparent,
            highlightColor: widget.showRipple
                ? _getForegroundColor().withOpacity(0.1)
                : Colors.transparent,
            child: Center(
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.icon != null) {
      return Icon(
        widget.icon,
        size: AppDimensions.iconL,
        color: widget.enabled
            ? _getForegroundColor()
            : _getForegroundColor().withOpacity(0.5),
      );
    }

    return Text(
      widget.label,
      style: _getTextStyle().copyWith(
        color: widget.enabled
            ? _getForegroundColor()
            : _getForegroundColor().withOpacity(0.5),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (widget.backgroundColor != null) return widget.backgroundColor!;

    switch (widget.type) {
      case KeyType.digit:
      case KeyType.decimal:
        return AppColors.grey100;
      case KeyType.backspace:
        return AppColors.grey200;
      case KeyType.clear:
        return AppColors.errorLight;
      case KeyType.done:
      case KeyType.action:
        return AppColors.primary;
      case KeyType.empty:
        return Colors.transparent;
    }
  }

  Color _getForegroundColor() {
    if (widget.foregroundColor != null) return widget.foregroundColor!;

    switch (widget.type) {
      case KeyType.digit:
      case KeyType.decimal:
      case KeyType.backspace:
        return AppColors.textPrimary;
      case KeyType.clear:
        return AppColors.error;
      case KeyType.done:
      case KeyType.action:
        return AppColors.white;
      case KeyType.empty:
        return Colors.transparent;
    }
  }

  TextStyle _getTextStyle() {
    switch (widget.type) {
      case KeyType.digit:
      case KeyType.decimal:
        return AppTextStyles.numberLarge;
      case KeyType.clear:
        return AppTextStyles.h5;
      case KeyType.done:
      case KeyType.action:
        return AppTextStyles.button;
      default:
        return AppTextStyles.bodyLarge;
    }
  }
}

/// Haptic feedback type
enum HapticFeedbackType {
  none,
  light,
  medium,
  heavy,
  selection,
}
