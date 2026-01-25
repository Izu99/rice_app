import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

/// Custom text field widget
class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final FocusNode? focusNode;
  final EdgeInsets? contentPadding;
  final Color? fillColor;
  final bool showCounter;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.onSuffixTap,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.contentPadding,
    this.fillColor,
    this.showCounter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTextStyles.labelMedium),
          const SizedBox(height: AppDimensions.paddingS),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            errorText: errorText,
            counterText: showCounter ? null : '',
            fillColor: fillColor,
            contentPadding: contentPadding,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.grey500, size: 22)
                : prefix,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(suffixIcon, color: AppColors.grey500, size: 22),
                    onPressed: onSuffixTap,
                  )
                : suffix,
          ),
        ),
      ],
    );
  }
}

/// Password text field with visibility toggle
class PasswordTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool enabled;

  const PasswordTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.focusNode,
    this.enabled = true,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint ?? 'Enter password',
      errorText: widget.errorText,
      obscureText: _obscureText,
      prefixIcon: Icons.lock_outline,
      suffixIcon: _obscureText ? Icons.visibility_off : Icons.visibility,
      onSuffixTap: () => setState(() => _obscureText = !_obscureText),
      validator: widget.validator,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: widget.textInputAction,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      keyboardType: TextInputType.visiblePassword,
    );
  }
}

/// Phone number text field
class PhoneTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;

  const PhoneTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label ?? 'Phone Number',
      hint: hint ?? '07X XXX XXXX',
      errorText: errorText,
      prefixIcon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      inputFormatters: [
        LengthLimitingTextInputFormatter(12), // Allow country code + phone
        _PhoneNumberFormatter(),
      ],
    );
  }
}

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.length <= 3) {
      return TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }

    if (digits.length <= 6) {
      final formatted = '${digits.substring(0, 3)} ${digits.substring(3)}';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    final formatted =
        '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Search text field with debounce
class SearchTextField extends StatefulWidget {
  final String? hint;
  final void Function(String) onSearch;
  final void Function()? onClear;
  final Duration debounceDuration;
  final TextEditingController? controller;
  final bool autofocus;
  final FocusNode? focusNode;

  const SearchTextField({
    super.key,
    this.hint,
    required this.onSearch,
    this.onClear,
    this.debounceDuration = const Duration(milliseconds: 500),
    this.controller,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  late TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onSearch(_controller.text);
    });
    setState(() {}); // Update clear button visibility
  }

  void _onClear() {
    _controller.clear();
    widget.onSearch('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      style: AppTextStyles.bodyMedium,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hint ?? 'Search...',
        prefixIcon: const Icon(Icons.search, color: AppColors.grey500),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.grey500),
                onPressed: _onClear,
              )
            : null,
        filled: true,
        fillColor: AppColors.grey100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingM,
        ),
      ),
      onSubmitted: widget.onSearch,
    );
  }
}

/// Amount/Number text field
class AmountTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? prefix;
  final String? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final int decimalPlaces;

  const AmountTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.prefix,
    this.suffix,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.decimalPlaces = 2,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint ?? '0.00',
      errorText: errorText,
      prefix: prefix != null
          ? Padding(
              padding: const EdgeInsets.only(left: AppDimensions.paddingM),
              child: Text(prefix!, style: AppTextStyles.bodyMedium),
            )
          : null,
      suffix: suffix != null
          ? Padding(
              padding: const EdgeInsets.only(right: AppDimensions.paddingM),
              child: Text(
                suffix!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : null,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        _DecimalInputFormatter(decimalPlaces: decimalPlaces),
      ],
    );
  }
}

class _DecimalInputFormatter extends TextInputFormatter {
  final int decimalPlaces;

  _DecimalInputFormatter({this.decimalPlaces = 2});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Check decimal places
    if (newValue.text.contains('.')) {
      final parts = newValue.text.split('.');
      if (parts.length > 2) return oldValue;
      if (parts[1].length > decimalPlaces) return oldValue;
    }

    // Prevent multiple leading zeros
    if (newValue.text.length > 1 &&
        newValue.text.startsWith('0') &&
        !newValue.text.startsWith('0.')) {
      return oldValue;
    }

    return newValue;
  }
}

