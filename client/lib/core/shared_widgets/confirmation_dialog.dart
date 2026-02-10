import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

/// Confirmation Dialog Types
enum DialogType {
  confirm,
  warning,
  danger,
  success,
  info,
}

/// Confirmation Dialog Widget
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? subtitle;
  final String confirmLabel;
  final String cancelLabel;
  final Color? confirmColor;
  final Color? cancelColor;
  final IconData? icon;
  final DialogType type;
  final bool isDangerous;
  final bool showCancel;
  final bool barrierDismissible;
  final Widget? customContent;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.subtitle,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.confirmColor,
    this.cancelColor,
    this.icon,
    this.type = DialogType.confirm,
    this.isDangerous = false,
    this.showCancel = true,
    this.barrierDismissible = true,
    this.customContent,
    this.onConfirm,
    this.onCancel,
  });

  /// Show confirmation dialog and return result
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String? subtitle,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color? confirmColor,
    Color? cancelColor,
    IconData? icon,
    DialogType type = DialogType.confirm,
    bool isDangerous = false,
    bool showCancel = true,
    bool barrierDismissible = true,
    Widget? customContent,
  }) async {
    HapticFeedback.mediumImpact();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        subtitle: subtitle,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
        cancelColor: cancelColor,
        icon: icon,
        type: type,
        isDangerous: isDangerous,
        showCancel: showCancel,
        barrierDismissible: barrierDismissible,
        customContent: customContent,
      ),
    );
    return result ?? false;
  }

  /// Show delete confirmation
  static Future<bool> showDelete(
    BuildContext context, {
    String title = 'Delete?',
    required String itemName,
    String? additionalMessage,
  }) {
    return show(
      context,
      title: title,
      message:
          'Are you sure you want to delete "$itemName"?${additionalMessage != null ? '\n\n$additionalMessage' : ''}',
      confirmLabel: 'Delete',
      type: DialogType.danger,
      isDangerous: true,
      icon: Icons.delete_forever_outlined,
    );
  }

  /// Show discard changes confirmation
  static Future<bool> showDiscardChanges(BuildContext context) {
    return show(
      context,
      title: 'Discard Changes?',
      message:
          'You have unsaved changes. Are you sure you want to discard them?',
      confirmLabel: 'Discard',
      type: DialogType.warning,
      isDangerous: true,
      icon: Icons.warning_amber_outlined,
    );
  }

  /// Show logout confirmation
  static Future<bool> showLogout(BuildContext context) {
    return show(
      context,
      title: 'Logout?',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
      type: DialogType.warning,
      icon: Icons.logout_outlined,
    );
  }

  /// Show save confirmation
  static Future<bool> showSave(
    BuildContext context, {
    String title = 'Save Changes?',
    String message = 'Do you want to save your changes?',
  }) {
    return show(
      context,
      title: title,
      message: message,
      confirmLabel: 'Save',
      type: DialogType.confirm,
      icon: Icons.save_outlined,
    );
  }

  /// Show cancel transaction confirmation
  static Future<bool> showCancelTransaction(
    BuildContext context, {
    required String transactionId,
  }) {
    return show(
      context,
      title: 'Cancel Transaction?',
      message:
          'Are you sure you want to cancel transaction $transactionId?\n\nThis action cannot be undone.',
      confirmLabel: 'Cancel Transaction',
      type: DialogType.danger,
      isDangerous: true,
      icon: Icons.cancel_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      contentPadding: EdgeInsets.zero,
      content: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon
            _buildHeader(),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingL,
              ),
              child: Column(
                children: [
                  // Title
                  Text(
                    title,
                    style: AppTextStyles.h5,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppDimensions.paddingS),

                  // Message
                  Text(
                    message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Subtitle
                  if (subtitle != null) ...[
                    const SizedBox(height: AppDimensions.paddingS),
                    Text(
                      subtitle!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHint,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  // Custom content
                  if (customContent != null) ...[
                    const SizedBox(height: AppDimensions.paddingM),
                    customContent!,
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.paddingL),

            // Actions
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final headerIcon = icon ?? _getDefaultIcon();
    final headerColor = _getTypeColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: headerColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: headerColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              headerIcon,
              size: AppDimensions.iconXL,
              color: headerColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: const BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: Row(
        children: [
          // Cancel button
          if (showCancel)
            Expanded(
              child: _DialogButton(
                label: cancelLabel,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onCancel?.call();
                  Navigator.pop(context, false);
                },
                isOutlined: true,
                color: cancelColor ?? AppColors.grey600,
              ),
            ),

          if (showCancel) const SizedBox(width: AppDimensions.paddingM),

          // Confirm button
          Expanded(
            child: _DialogButton(
              label: confirmLabel,
              onPressed: () {
                HapticFeedback.mediumImpact();
                onConfirm?.call();
                Navigator.pop(context, true);
              },
              color: confirmColor ?? _getConfirmColor(),
              isOutlined: false,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case DialogType.confirm:
        return Icons.help_outline;
      case DialogType.warning:
        return Icons.warning_amber_outlined;
      case DialogType.danger:
        return Icons.error_outline;
      case DialogType.success:
        return Icons.check_circle_outline;
      case DialogType.info:
        return Icons.info_outline;
    }
  }

  Color _getTypeColor() {
    if (isDangerous) return AppColors.error;

    switch (type) {
      case DialogType.confirm:
        return AppColors.primary;
      case DialogType.warning:
        return AppColors.warning;
      case DialogType.danger:
        return AppColors.error;
      case DialogType.success:
        return AppColors.success;
      case DialogType.info:
        return AppColors.info;
    }
  }

  Color _getConfirmColor() {
    if (isDangerous) return AppColors.error;

    switch (type) {
      case DialogType.confirm:
        return AppColors.primary;
      case DialogType.warning:
        return AppColors.warning;
      case DialogType.danger:
        return AppColors.error;
      case DialogType.success:
        return AppColors.success;
      case DialogType.info:
        return AppColors.info;
    }
  }
}

/// Dialog Button Widget
class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final bool isOutlined;

  const _DialogButton({
    required this.label,
    required this.onPressed,
    required this.color,
    required this.isOutlined,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(color: color),
        ),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.paddingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        elevation: 0,
      ),
      child: Text(
        label,
        style: AppTextStyles.button,
      ),
    );
  }
}

// ==================== SUCCESS DIALOG ====================

/// Success Dialog Widget
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? subtitle;
  final String buttonLabel;
  final IconData? icon;
  final VoidCallback? onDismiss;
  final Widget? customContent;
  final List<SuccessDialogAction>? actions;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.subtitle,
    this.buttonLabel = 'OK',
    this.icon,
    this.onDismiss,
    this.customContent,
    this.actions,
  });

  /// Show success dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? subtitle,
    String buttonLabel = 'OK',
    IconData? icon,
    VoidCallback? onDismiss,
    Widget? customContent,
    List<SuccessDialogAction>? actions,
  }) async {
    HapticFeedback.mediumImpact();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessDialog(
        title: title,
        message: message,
        subtitle: subtitle,
        buttonLabel: buttonLabel,
        icon: icon,
        onDismiss: onDismiss,
        customContent: customContent,
        actions: actions,
      ),
    );
  }

  /// Show transaction success
  static Future<void> showTransactionSuccess(
    BuildContext context, {
    required String transactionId,
    required double amount,
    String? customerName,
    VoidCallback? onPrint,
    VoidCallback? onNewTransaction,
    VoidCallback? onViewDetails,
  }) {
    return show(
      context,
      title: 'Transaction Complete!',
      message: 'Transaction $transactionId has been saved successfully.',
      subtitle: customerName != null ? 'Customer: $customerName' : null,
      icon: Icons.check_circle,
      actions: [
        if (onPrint != null)
          SuccessDialogAction(
            label: 'Print',
            icon: Icons.print_outlined,
            onPressed: onPrint,
          ),
        if (onViewDetails != null)
          SuccessDialogAction(
            label: 'Details',
            icon: Icons.visibility_outlined,
            onPressed: onViewDetails,
          ),
        if (onNewTransaction != null)
          SuccessDialogAction(
            label: 'New',
            icon: Icons.add,
            onPressed: onNewTransaction,
            isPrimary: true,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      contentPadding: const EdgeInsets.all(AppDimensions.paddingL),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? Icons.check_circle,
              size: AppDimensions.iconXXL,
              color: AppColors.success,
            ),
          ),

          const SizedBox(height: AppDimensions.paddingL),

          // Title
          Text(
            title,
            style: AppTextStyles.h5,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppDimensions.paddingS),

          // Message
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          // Subtitle
          if (subtitle != null) ...[
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              subtitle!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          // Custom content
          if (customContent != null) ...[
            const SizedBox(height: AppDimensions.paddingM),
            customContent!,
          ],

          const SizedBox(height: AppDimensions.paddingL),

          // Actions
          if (actions != null && actions!.isNotEmpty)
            _buildActions(context)
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onDismiss?.call();
                },
                child: Text(buttonLabel),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.paddingS,
      runSpacing: AppDimensions.paddingS,
      alignment: WrapAlignment.center,
      children: actions!.map((action) {
        if (action.isPrimary) {
          return ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              action.onPressed();
            },
            icon: Icon(action.icon, size: 18),
            label: Text(action.label),
          );
        }

        return OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            action.onPressed();
          },
          icon: Icon(action.icon, size: 18),
          label: Text(action.label),
        );
      }).toList(),
    );
  }
}

/// Success Dialog Action
class SuccessDialogAction {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const SuccessDialogAction({
    required this.label,
    this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });
}

// ==================== INPUT DIALOG ====================

/// Input Dialog for getting text input from user
class InputDialog extends StatefulWidget {
  final String title;
  final String? message;
  final String? initialValue;
  final String? hintText;
  final String? labelText;
  final String confirmLabel;
  final String cancelLabel;
  final TextInputType keyboardType;
  final int? maxLength;
  final int maxLines;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;

  const InputDialog({
    super.key,
    required this.title,
    this.message,
    this.initialValue,
    this.hintText,
    this.labelText,
    this.confirmLabel = 'OK',
    this.cancelLabel = 'Cancel',
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.maxLines = 1,
    this.validator,
    this.prefixIcon,
  });

  /// Show input dialog and return result
  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? message,
    String? initialValue,
    String? hintText,
    String? labelText,
    String confirmLabel = 'OK',
    String cancelLabel = 'Cancel',
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    int maxLines = 1,
    String? Function(String?)? validator,
    IconData? prefixIcon,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => InputDialog(
        title: title,
        message: message,
        initialValue: initialValue,
        hintText: hintText,
        labelText: labelText,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        keyboardType: keyboardType,
        maxLength: maxLength,
        maxLines: maxLines,
        validator: validator,
        prefixIcon: prefixIcon,
      ),
    );
  }

  @override
  State<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.validator != null) {
      final error = widget.validator!(_controller.text);
      if (error != null) {
        setState(() => _errorText = error);
        return;
      }
    }

    Navigator.pop(context, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      title: Text(widget.title, style: AppTextStyles.h5),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.message != null) ...[
              Text(
                widget.message!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),
            ],
            TextFormField(
              controller: _controller,
              keyboardType: widget.keyboardType,
              maxLength: widget.maxLength,
              maxLines: widget.maxLines,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.hintText,
                labelText: widget.labelText,
                errorText: _errorText,
                prefixIcon:
                    widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelLabel),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

// ==================== LOADING DIALOG ====================

/// Loading Dialog
class LoadingDialog extends StatelessWidget {
  final String? message;

  const LoadingDialog({super.key, this.message});

  /// Show loading dialog
  static Future<void> show(BuildContext context, {String? message}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(message: message),
    );
  }

  /// Hide loading dialog
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: AppDimensions.paddingL),
              Text(
                message!,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
