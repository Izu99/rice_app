// lib/features/customers/presentation/widgets/customer_search.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Customer search widget with debounce
class CustomerSearch extends StatefulWidget {
  final String? initialQuery;
  final ValueChanged<String> onSearch;
  final VoidCallback? onClear;
  final String? hintText;
  final bool autofocus;

  const CustomerSearch({
    super.key,
    this.initialQuery,
    required this.onSearch,
    this.onClear,
    this.hintText,
    this.autofocus = false,
  });

  @override
  State<CustomerSearch> createState() => _CustomerSearchState();
}

class _CustomerSearchState extends State<CustomerSearch> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Timer? _debounceTimer;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(value);
    });
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearch('');
    widget.onClear?.call();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused ? AppColors.primary : AppColors.border,
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onChanged: _onSearchChanged,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Search by name or phone...',
          hintStyle: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textHint,
          ),
          prefixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isFocused
                ? const Icon(
                    Icons.search,
                    color: AppColors.primary,
                    key: ValueKey('focused'),
                  )
                : const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    key: ValueKey('unfocused'),
                  ),
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  color: AppColors.textSecondary,
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

/// Search field with voice input support
class VoiceSearchField extends StatefulWidget {
  final String? initialQuery;
  final ValueChanged<String> onSearch;
  final VoidCallback? onVoiceSearch;
  final bool voiceEnabled;

  const VoiceSearchField({
    super.key,
    this.initialQuery,
    required this.onSearch,
    this.onVoiceSearch,
    this.voiceEnabled = true,
  });

  @override
  State<VoiceSearchField> createState() => _VoiceSearchFieldState();
}

class _VoiceSearchFieldState extends State<VoiceSearchField> {
  late TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textHint,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        color: AppColors.textSecondary,
                        onPressed: () {
                          _controller.clear();
                          widget.onSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          if (widget.voiceEnabled) ...[
            Container(
              width: 1,
              height: 30,
              color: AppColors.divider,
            ),
            IconButton(
              icon: const Icon(Icons.mic),
              color: AppColors.primary,
              onPressed: widget.onVoiceSearch,
            ),
          ],
        ],
      ),
    );
  }
}

/// Inline search for selection dialogs
class InlineCustomerSearch extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const InlineCustomerSearch({
    super.key,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Search...',
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textHint,
        ),
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
          color: AppColors.textSecondary,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  controller.clear();
                  onClear?.call();
                },
                child: const Icon(
                  Icons.close,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}

/// Search with suggestions dropdown
class CustomerSearchWithSuggestions extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final List<String> suggestions;
  final ValueChanged<String>? onSuggestionSelected;

  const CustomerSearchWithSuggestions({
    super.key,
    required this.onSearch,
    this.suggestions = const [],
    this.onSuggestionSelected,
  });

  @override
  State<CustomerSearchWithSuggestions> createState() =>
      _CustomerSearchWithSuggestionsState();
}

class _CustomerSearchWithSuggestionsState
    extends State<CustomerSearchWithSuggestions> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _showSuggestions = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus && widget.suggestions.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(value);
    });
    setState(() {
      _showSuggestions = value.isNotEmpty && widget.suggestions.isNotEmpty;
    });
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    widget.onSuggestionSelected?.call(suggestion);
    _focusNode.unfocus();
    setState(() {
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _focusNode.hasFocus ? AppColors.primary : AppColors.border,
            ),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Search customers...',
              hintStyle: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textHint,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (_showSuggestions) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final suggestion = widget.suggestions[index];
                return ListTile(
                  dense: true,
                  title: Text(suggestion),
                  leading: const Icon(
                    Icons.history,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onTap: () => _selectSuggestion(suggestion),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

