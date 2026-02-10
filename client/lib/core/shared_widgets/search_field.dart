import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rice_mill_erp/core/shared_widgets/empty_state_widget.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

/// Search Field Widget with debounce support
class SearchField extends StatefulWidget {
  final String? hint;
  final String? label;
  final void Function(String) onSearch;
  final void Function(String)? onSubmit;
  final VoidCallback? onClear;
  final VoidCallback? onTap;
  final Duration debounceDuration;
  final bool autofocus;
  final bool enabled;
  final bool showClearButton;
  final bool showSearchIcon;
  final bool filled;
  final Color? fillColor;
  final Color? borderColor;
  final Color? iconColor;
  final double? height;
  final double borderRadius;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefix;
  final Widget? suffix;
  final EdgeInsets? padding;
  final EdgeInsets? contentPadding;

  const SearchField({
    super.key,
    this.hint,
    this.label,
    required this.onSearch,
    this.onSubmit,
    this.onClear,
    this.onTap,
    this.debounceDuration = const Duration(milliseconds: 500),
    this.autofocus = false,
    this.enabled = true,
    this.showClearButton = true,
    this.showSearchIcon = true,
    this.filled = true,
    this.fillColor,
    this.borderColor,
    this.iconColor,
    this.height,
    this.borderRadius = AppDimensions.radiusRound,
    this.controller,
    this.focusNode,
    this.textInputAction = TextInputAction.search,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.prefix,
    this.suffix,
    this.padding,
    this.contentPadding,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Timer? _debounceTimer;
  bool _isExternalController = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();

    _isExternalController = widget.controller != null;
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();

    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.removeListener(_onFocusChange);

    if (!_isExternalController) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }

    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();

    setState(() {}); // Update clear button visibility

    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onSearch(value);
    });
  }

  void _onClear() {
    HapticFeedback.lightImpact();
    _controller.clear();
    widget.onSearch('');
    widget.onClear?.call();
    _focusNode.requestFocus();
    setState(() {});
  }

  void _onSubmit(String value) {
    widget.onSubmit?.call(value);
    widget.onSearch(value);
    _debounceTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: AppTextStyles.labelMedium,
            ),
            const SizedBox(height: AppDimensions.paddingS),
          ],

          // Search field
          SizedBox(
            height: widget.height,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              autofocus: widget.autofocus,
              textInputAction: widget.textInputAction,
              textCapitalization: widget.textCapitalization,
              inputFormatters: widget.inputFormatters,
              style: AppTextStyles.bodyMedium,
              onChanged: _onChanged,
              onSubmitted: _onSubmit,
              onTap: widget.onTap,
              decoration: InputDecoration(
                hintText: widget.hint ?? 'Search...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
                filled: widget.filled,
                fillColor: widget.fillColor ?? AppColors.grey100,
                contentPadding: widget.contentPadding ??
                    const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingM,
                      vertical: AppDimensions.paddingM,
                    ),
                prefixIcon: _buildPrefixIcon(),
                suffixIcon: _buildSuffixIcon(),
                border: _buildBorder(),
                enabledBorder: _buildBorder(),
                focusedBorder: _buildFocusedBorder(),
                disabledBorder: _buildDisabledBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildPrefixIcon() {
    if (widget.prefix != null) return widget.prefix;

    if (!widget.showSearchIcon) return null;

    return Icon(
      Icons.search,
      color: _isFocused
          ? AppColors.primary
          : (widget.iconColor ?? AppColors.grey500),
      size: AppDimensions.iconM,
    );
  }

  Widget? _buildSuffixIcon() {
    final List<Widget> suffixItems = [];

    // Clear button
    if (widget.showClearButton && _controller.text.isNotEmpty) {
      suffixItems.add(
        _SearchIconButton(
          icon: Icons.clear,
          onPressed: _onClear,
          color: widget.iconColor ?? AppColors.grey500,
        ),
      );
    }

    // Custom suffix
    if (widget.suffix != null) {
      suffixItems.add(widget.suffix!);
    }

    if (suffixItems.isEmpty) return null;

    if (suffixItems.length == 1) return suffixItems.first;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: suffixItems,
    );
  }

  OutlineInputBorder _buildBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(
        color: widget.borderColor ?? Colors.transparent,
        width: 1,
      ),
    );
  }

  OutlineInputBorder _buildFocusedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(
        color: widget.borderColor ?? AppColors.primary,
        width: 2,
      ),
    );
  }

  OutlineInputBorder _buildDisabledBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(
        color: widget.borderColor ?? Colors.transparent,
        width: 1,
      ),
    );
  }
}

/// Search Icon Button
class _SearchIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _SearchIconButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color, size: AppDimensions.iconS),
      onPressed: onPressed,
      splashRadius: 20,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(AppDimensions.paddingS),
    );
  }
}

// ==================== SEARCH BAR WITH FILTERS ====================

/// Advanced Search Bar with filter options
class SearchBarWithFilters extends StatefulWidget {
  final String? hint;
  final void Function(String) onSearch;
  final void Function(String)? onSubmit;
  final VoidCallback? onClear;
  final VoidCallback? onFilterTap;
  final Duration debounceDuration;
  final bool showFilter;
  final int activeFilterCount;
  final Widget? filterBadge;
  final List<SearchSuggestion>? suggestions;
  final void Function(SearchSuggestion)? onSuggestionTap;

  const SearchBarWithFilters({
    super.key,
    this.hint,
    required this.onSearch,
    this.onSubmit,
    this.onClear,
    this.onFilterTap,
    this.debounceDuration = const Duration(milliseconds: 500),
    this.showFilter = true,
    this.activeFilterCount = 0,
    this.filterBadge,
    this.suggestions,
    this.onSuggestionTap,
  });

  @override
  State<SearchBarWithFilters> createState() => _SearchBarWithFiltersState();
}

class _SearchBarWithFiltersState extends State<SearchBarWithFilters> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus &&
            widget.suggestions != null &&
            widget.suggestions!.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Search field
            Expanded(
              child: SearchField(
                controller: _controller,
                focusNode: _focusNode,
                hint: widget.hint,
                onSearch: widget.onSearch,
                onSubmit: widget.onSubmit,
                onClear: () {
                  widget.onClear?.call();
                  setState(() => _showSuggestions = false);
                },
                debounceDuration: widget.debounceDuration,
              ),
            ),

            // Filter button
            if (widget.showFilter) ...[
              const SizedBox(width: AppDimensions.paddingS),
              _FilterButton(
                onTap: widget.onFilterTap,
                activeCount: widget.activeFilterCount,
                badge: widget.filterBadge,
              ),
            ],
          ],
        ),

        // Suggestions
        if (_showSuggestions && widget.suggestions != null)
          _SuggestionsList(
            suggestions: widget.suggestions!,
            onTap: (suggestion) {
              _controller.text = suggestion.text;
              widget.onSuggestionTap?.call(suggestion);
              _focusNode.unfocus();
              setState(() => _showSuggestions = false);
            },
          ),
      ],
    );
  }
}

/// Filter Button
class _FilterButton extends StatelessWidget {
  final VoidCallback? onTap;
  final int activeCount;
  final Widget? badge;

  const _FilterButton({
    this.onTap,
    this.activeCount = 0,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: activeCount > 0 ? AppColors.primarySurface : AppColors.grey100,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: badge ??
              Stack(
                children: [
                  Icon(
                    Icons.tune,
                    color:
                        activeCount > 0 ? AppColors.primary : AppColors.grey600,
                    size: AppDimensions.iconM,
                  ),
                  if (activeCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          activeCount.toString(),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
        ),
      ),
    );
  }
}

/// Suggestions List
class _SuggestionsList extends StatelessWidget {
  final List<SearchSuggestion> suggestions;
  final void Function(SearchSuggestion) onTap;

  const _SuggestionsList({
    required this.suggestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.paddingS),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingS),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return _SuggestionTile(
            suggestion: suggestion,
            onTap: () => onTap(suggestion),
          );
        },
      ),
    );
  }
}

/// Suggestion Tile
class _SuggestionTile extends StatelessWidget {
  final SearchSuggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        child: Row(
          children: [
            Icon(
              suggestion.icon ?? Icons.search,
              color: AppColors.grey500,
              size: AppDimensions.iconS,
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.text,
                    style: AppTextStyles.bodyMedium,
                  ),
                  if (suggestion.subtitle != null)
                    Text(
                      suggestion.subtitle!,
                      style: AppTextStyles.caption,
                    ),
                ],
              ),
            ),
            if (suggestion.trailing != null) suggestion.trailing!,
          ],
        ),
      ),
    );
  }
}

/// Search Suggestion Model
class SearchSuggestion {
  final String text;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final dynamic data;

  const SearchSuggestion({
    required this.text,
    this.subtitle,
    this.icon,
    this.trailing,
    this.data,
  });
}

// ==================== SEARCH DELEGATE ====================

/// Custom Search Delegate for full-screen search
class AppSearchDelegate<T> extends SearchDelegate<T?> {
  final String searchHint;
  final Future<List<T>> Function(String query) onSearch;
  final Widget Function(T item) itemBuilder;
  final Widget Function()? emptyBuilder;
  final Widget Function()? loadingBuilder;
  final Widget Function(String error)? errorBuilder;
  final void Function(T item)? onItemTap;
  final List<T>? recentItems;
  final String? recentItemsTitle;

  AppSearchDelegate({
    this.searchHint = 'Search...',
    required this.onSearch,
    required this.itemBuilder,
    this.emptyBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.onItemTap,
    this.recentItems,
    this.recentItemsTitle,
  });

  @override
  String get searchFieldLabel => searchHint;

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppColors.textHint),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _SearchResults<T>(
      query: query,
      onSearch: onSearch,
      itemBuilder: itemBuilder,
      emptyBuilder: emptyBuilder,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      onItemTap: (item) {
        onItemTap?.call(item);
        close(context, item);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty && recentItems != null && recentItems!.isNotEmpty) {
      return _RecentItems<T>(
        items: recentItems!,
        title: recentItemsTitle ?? 'Recent',
        itemBuilder: itemBuilder,
        onItemTap: (item) {
          onItemTap?.call(item);
          close(context, item);
        },
      );
    }

    return buildResults(context);
  }
}

/// Search Results Widget
class _SearchResults<T> extends StatefulWidget {
  final String query;
  final Future<List<T>> Function(String query) onSearch;
  final Widget Function(T item) itemBuilder;
  final Widget Function()? emptyBuilder;
  final Widget Function()? loadingBuilder;
  final Widget Function(String error)? errorBuilder;
  final void Function(T item)? onItemTap;

  const _SearchResults({
    required this.query,
    required this.onSearch,
    required this.itemBuilder,
    this.emptyBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.onItemTap,
  });

  @override
  State<_SearchResults<T>> createState() => _SearchResultsState<T>();
}

class _SearchResultsState<T> extends State<_SearchResults<T>> {
  late Future<List<T>> _searchFuture;

  @override
  void initState() {
    super.initState();
    _searchFuture = widget.onSearch(widget.query);
  }

  @override
  void didUpdateWidget(covariant _SearchResults<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _searchFuture = widget.onSearch(widget.query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingBuilder?.call() ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return widget.errorBuilder?.call(snapshot.error.toString()) ??
              Center(child: Text('Error: ${snapshot.error}'));
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return widget.emptyBuilder?.call() ??
              EmptyStateWidget.noSearchResults(query: widget.query);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          itemCount: results.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppDimensions.paddingS),
          itemBuilder: (context, index) {
            final item = results[index];
            return InkWell(
              onTap: () => widget.onItemTap?.call(item),
              child: widget.itemBuilder(item),
            );
          },
        );
      },
    );
  }
}

/// Recent Items Widget
class _RecentItems<T> extends StatelessWidget {
  final List<T> items;
  final String title;
  final Widget Function(T item) itemBuilder;
  final void Function(T item)? onItemTap;

  const _RecentItems({
    required this.items,
    required this.title,
    required this.itemBuilder,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding:
                const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppDimensions.paddingS),
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                onTap: () => onItemTap?.call(item),
                child: itemBuilder(item),
              );
            },
          ),
        ),
      ],
    );
  }
}
