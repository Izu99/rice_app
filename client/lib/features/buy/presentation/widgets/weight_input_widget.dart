// lib/features/buy/presentation/widgets/weight_input_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Weight entry model for individual bag weights
class WeightEntry {
  final String id;
  final double weight;
  final DateTime addedAt;

  WeightEntry({
    required this.id,
    required this.weight,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  WeightEntry copyWith({
    String? id,
    double? weight,
    DateTime? addedAt,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      weight: weight ?? this.weight,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

/// Weight Input Widget - High-speed weight entry for multiple bags
class WeightInputWidget extends StatefulWidget {
  final List<WeightEntry> entries;
  final ValueChanged<List<WeightEntry>> onEntriesChanged;
  final double? tareWeight;
  final bool showTotalCard;
  final bool allowEdit;
  final bool autoFocus;
  final String? title;
  final String? subtitle;
  final int? maxEntries;
  final VoidCallback? onComplete;

  const WeightInputWidget({
    super.key,
    required this.entries,
    required this.onEntriesChanged,
    this.tareWeight,
    this.showTotalCard = true,
    this.allowEdit = true,
    this.autoFocus = false,
    this.title,
    this.subtitle,
    this.maxEntries,
    this.onComplete,
  });

  @override
  State<WeightInputWidget> createState() => _WeightInputWidgetState();
}

class _WeightInputWidgetState extends State<WeightInputWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  String _currentInput = '';
  int? _editingIndex;
  final ScrollController _scrollController = ScrollController();
  final bool _showKeyboard = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Get total weight
  double get totalWeight =>
      widget.entries.fold(0.0, (sum, entry) => sum + entry.weight);

  /// Get total bags
  int get totalBags => widget.entries.length;

  /// Get average weight per bag
  double get averageWeight => totalBags > 0 ? totalWeight / totalBags : 0;

  /// Add new entry
  void _addEntry() {
    final weight = double.tryParse(_currentInput) ?? 0;
    if (weight <= 0) {
      _showError('Please enter a valid weight');
      return;
    }

    // Check max entries
    if (widget.maxEntries != null &&
        widget.entries.length >= widget.maxEntries!) {
      _showError('Maximum ${widget.maxEntries} entries allowed');
      return;
    }

    // Apply tare weight if set
    final finalWeight =
        widget.tareWeight != null ? weight - widget.tareWeight! : weight;

    if (finalWeight <= 0) {
      _showError('Weight must be greater than tare weight');
      return;
    }

    final newEntry = WeightEntry(
      id: 'W_${DateTime.now().millisecondsSinceEpoch}',
      weight: finalWeight,
    );

    final updatedEntries = [...widget.entries, newEntry];
    widget.onEntriesChanged(updatedEntries);

    // Reset input
    setState(() {
      _currentInput = '';
      _editingIndex = null;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Update existing entry
  void _updateEntry(int index) {
    final weight = double.tryParse(_currentInput) ?? 0;
    if (weight <= 0) {
      _showError('Please enter a valid weight');
      return;
    }

    final finalWeight =
        widget.tareWeight != null ? weight - widget.tareWeight! : weight;

    if (finalWeight <= 0) {
      _showError('Weight must be greater than tare weight');
      return;
    }

    final updatedEntries = List<WeightEntry>.from(widget.entries);
    updatedEntries[index] = updatedEntries[index].copyWith(weight: finalWeight);
    widget.onEntriesChanged(updatedEntries);

    setState(() {
      _currentInput = '';
      _editingIndex = null;
    });

    HapticFeedback.lightImpact();
  }

  /// Delete entry
  void _deleteEntry(int index) {
    final updatedEntries = List<WeightEntry>.from(widget.entries);
    updatedEntries.removeAt(index);
    widget.onEntriesChanged(updatedEntries);

    if (_editingIndex == index) {
      setState(() {
        _currentInput = '';
        _editingIndex = null;
      });
    }

    HapticFeedback.mediumImpact();
  }

  /// Start editing an entry
  void _startEditing(int index) {
    if (!widget.allowEdit) return;

    setState(() {
      _editingIndex = index;
      _currentInput = widget.entries[index].weight.toStringAsFixed(2);
    });
  }

  /// Cancel editing
  void _cancelEditing() {
    setState(() {
      _currentInput = '';
      _editingIndex = null;
    });
  }

  /// Handle key press
  void _onKeyPressed(String key) {
    HapticFeedback.selectionClick();

    setState(() {
      if (key == 'C') {
        _currentInput = '';
      } else if (key == '⌫') {
        if (_currentInput.isNotEmpty) {
          _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        }
      } else if (key == '.') {
        if (!_currentInput.contains('.')) {
          _currentInput = _currentInput.isEmpty ? '0.' : '$_currentInput.';
        }
      } else if (key == '00') {
        if (_currentInput.isNotEmpty && !_currentInput.startsWith('0.')) {
          _currentInput = '${_currentInput}00';
        }
      } else if (key == 'ENTER') {
        if (_editingIndex != null) {
          _updateEntry(_editingIndex!);
        } else {
          _addEntry();
        }
      } else {
        // Prevent leading zeros
        if (_currentInput == '0' && key != '.') {
          _currentInput = key;
        } else {
          // Limit decimal places to 2
          if (_currentInput.contains('.')) {
            final parts = _currentInput.split('.');
            if (parts.length > 1 && parts[1].length >= 2) {
              return;
            }
          }
          _currentInput = '$_currentInput$key';
        }
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        if (widget.title != null || widget.subtitle != null) _buildHeader(),

        // Entries list
        if (widget.entries.isNotEmpty) ...[
          _buildEntriesList(),
          const SizedBox(height: 12),
        ],

        // Total card
        if (widget.showTotalCard && widget.entries.isNotEmpty) ...[
          _buildTotalCard(),
          const SizedBox(height: 16),
        ],

        // Current input display
        _buildInputDisplay(),
        const SizedBox(height: 16),

        // Numeric keypad
        if (_showKeyboard) _buildKeypad(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.title != null)
                Text(
                  widget.title!,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (widget.subtitle != null)
                Text(
                  widget.subtitle!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          if (widget.tareWeight != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.remove_circle_outline,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tare: ${widget.tareWeight!.toStringAsFixed(1)} kg',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEntriesList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
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
      child: ListView.separated(
        controller: _scrollController,
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
        itemCount: widget.entries.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = widget.entries[index];
          final isEditing = _editingIndex == index;

          return _WeightEntryTile(
            entry: entry,
            index: index,
            isEditing: isEditing,
            onTap: () => _startEditing(index),
            onDelete: () => _deleteEntry(index),
            allowEdit: widget.allowEdit,
          );
        },
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTotalItem(
            icon: Icons.shopping_bag,
            value: totalBags.toString(),
            label: 'Bags',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.white.withOpacity(0.3),
          ),
          _buildTotalItem(
            icon: Icons.scale,
            value: '${totalWeight.toStringAsFixed(2)} kg',
            label: 'Total Weight',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.white.withOpacity(0.3),
          ),
          _buildTotalItem(
            icon: Icons.analytics,
            value: '${averageWeight.toStringAsFixed(2)} kg',
            label: 'Average',
          ),
        ],
      ),
    );
  }

  Widget _buildTotalItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.white.withOpacity(0.8), size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildInputDisplay() {
    final displayValue = _currentInput.isEmpty ? '0' : _currentInput;
    final isEditing = _editingIndex != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isEditing
            ? AppColors.warning.withOpacity(0.1)
            : AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEditing
              ? AppColors.warning.withOpacity(0.3)
              : AppColors.success.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Status indicator
          if (isEditing)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit, color: AppColors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Editing Bag #${_editingIndex! + 1}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _cancelEditing,
                    child: const Icon(
                      Icons.close,
                      color: AppColors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),

          // Weight display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                displayValue,
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: isEditing ? AppColors.warning : AppColors.success,
                  fontFamily: 'monospace',
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 8),
                child: Text(
                  'kg',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: isEditing
                        ? AppColors.warning.withOpacity(0.7)
                        : AppColors.success.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),

          // Hint text
          Text(
            isEditing
                ? 'Enter new weight and press ENTER'
                : 'Enter weight and press ENTER to add',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: 1, 2, 3, ⌫
          _buildKeypadRow(['1', '2', '3', '⌫']),
          const SizedBox(height: 8),

          // Row 2: 4, 5, 6, C
          _buildKeypadRow(['4', '5', '6', 'C']),
          const SizedBox(height: 8),

          // Row 3: 7, 8, 9, 00
          _buildKeypadRow(['7', '8', '9', '00']),
          const SizedBox(height: 8),

          // Row 4: ., 0, ENTER (spans 2)
          Row(
            children: [
              Expanded(child: _buildKey('.')),
              const SizedBox(width: 8),
              Expanded(child: _buildKey('0')),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildEnterKey(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: keys.indexOf(key) < keys.length - 1 ? 8 : 0,
            ),
            child: _buildKey(key),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKey(String key) {
    Color backgroundColor;
    Color textColor;
    IconData? icon;

    switch (key) {
      case '⌫':
        backgroundColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        icon = Icons.backspace_outlined;
        break;
      case 'C':
        backgroundColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        break;
      case '00':
        backgroundColor = AppColors.info.withOpacity(0.1);
        textColor = AppColors.info;
        break;
      case '.':
        backgroundColor = AppColors.surface;
        textColor = AppColors.textPrimary;
        break;
      default:
        backgroundColor = AppColors.surface;
        textColor = AppColors.textPrimary;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _onKeyPressed(key),
          onTapDown: (_) => _animationController.forward(),
          onTapUp: (_) => _animationController.reverse(),
          onTapCancel: () => _animationController.reverse(),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 64,
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, color: textColor, size: 28)
                : Text(
                    key,
                    style: TextStyle(
                      fontSize: key == '00' ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnterKey() {
    final isEditing = _editingIndex != null;

    return Material(
      color: isEditing ? AppColors.warning : AppColors.success,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _onKeyPressed('ENTER'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 64,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isEditing ? Icons.check : Icons.add_circle,
                color: AppColors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isEditing ? 'UPDATE' : 'ADD',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Weight entry tile widget
class _WeightEntryTile extends StatelessWidget {
  final WeightEntry entry;
  final int index;
  final bool isEditing;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool allowEdit;

  const _WeightEntryTile({
    required this.entry,
    required this.index,
    required this.isEditing,
    required this.onTap,
    required this.onDelete,
    required this.allowEdit,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color:
            isEditing ? AppColors.warning.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: allowEdit ? onTap : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isEditing
                ? AppColors.warning
                : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            '#${index + 1}',
            style: AppTextStyles.titleSmall.copyWith(
              color: isEditing ? AppColors.white : AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${entry.weight.toStringAsFixed(2)} kg',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Added at ${_formatTime(entry.addedAt)}',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textHint,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (allowEdit && isEditing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Editing',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            if (allowEdit)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppColors.error,
                iconSize: 22,
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}

/// Compact weight input for inline use
class CompactWeightInput extends StatefulWidget {
  final double? initialValue;
  final ValueChanged<double> onChanged;
  final String? label;
  final String? hint;
  final bool enabled;

  const CompactWeightInput({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.label,
    this.hint,
    this.enabled = true,
  });

  @override
  State<CompactWeightInput> createState() => _CompactWeightInputState();
}

class _CompactWeightInputState extends State<CompactWeightInput> {
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        Focus(
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          child: Container(
            decoration: BoxDecoration(
              color: widget.enabled ? AppColors.white : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFocused ? AppColors.primary : AppColors.border,
                width: _isFocused ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: widget.enabled,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint ?? '0.00',
                      hintStyle: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (value) {
                      final weight = double.tryParse(value) ?? 0;
                      widget.onChanged(weight);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(11),
                    ),
                  ),
                  child: Text(
                    'kg',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Quick weight buttons for common values
class QuickWeightButtons extends StatelessWidget {
  final List<double> values;
  final ValueChanged<double> onSelected;
  final double? selectedValue;

  const QuickWeightButtons({
    super.key,
    this.values = const [25.0, 50.0, 75.0, 100.0],
    required this.onSelected,
    this.selectedValue,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        final isSelected = selectedValue == value;
        return InkWell(
          onTap: () => onSelected(value),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Text(
              '${value.toStringAsFixed(0)} kg',
              style: AppTextStyles.labelLarge.copyWith(
                color: isSelected ? AppColors.white : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Weight summary widget
class WeightSummary extends StatelessWidget {
  final int bags;
  final double totalWeight;
  final double? pricePerKg;
  final bool compact;

  const WeightSummary({
    super.key,
    required this.bags,
    required this.totalWeight,
    this.pricePerKg,
    this.compact = false,
  });

  double get averageWeight => bags > 0 ? totalWeight / bags : 0;
  double get totalValue => pricePerKg != null ? totalWeight * pricePerKg! : 0;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact();
    }
    return _buildFull();
  }

  Widget _buildCompact() {
    return Row(
      children: [
        _buildCompactItem(Icons.shopping_bag, '$bags bags'),
        const SizedBox(width: 16),
        _buildCompactItem(Icons.scale, '${totalWeight.toStringAsFixed(2)} kg'),
        if (pricePerKg != null) ...[
          const SizedBox(width: 16),
          _buildCompactItem(
            Icons.attach_money,
            'Rs. ${totalValue.toStringAsFixed(0)}',
          ),
        ],
      ],
    );
  }

  Widget _buildCompactItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFull() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Bags', bags.toString(), Icons.shopping_bag),
              _buildSummaryItem(
                'Total',
                '${totalWeight.toStringAsFixed(2)} kg',
                Icons.scale,
              ),
              _buildSummaryItem(
                'Average',
                '${averageWeight.toStringAsFixed(2)} kg',
                Icons.analytics,
              ),
            ],
          ),
          if (pricePerKg != null) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price per kg:',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Rs. ${pricePerKg!.toStringAsFixed(2)}',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Value:',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Rs. ${totalValue.toStringAsFixed(2)}',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

