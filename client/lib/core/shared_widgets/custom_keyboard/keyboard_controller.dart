import 'package:flutter/foundation.dart';

/// Controller for custom numeric keyboard
class KeyboardController extends ChangeNotifier {
  String _value;
  int _maxLength;
  int _decimalPlaces;
  bool _allowDecimal;
  bool _allowNegative;
  double? _minValue;
  double? _maxValue;

  KeyboardController({
    String initialValue = '',
    int maxLength = 12,
    int decimalPlaces = 3,
    bool allowDecimal = true,
    bool allowNegative = false,
    double? minValue,
    double? maxValue,
  })  : _value = initialValue,
        _maxLength = maxLength,
        _decimalPlaces = decimalPlaces,
        _allowDecimal = allowDecimal,
        _allowNegative = allowNegative,
        _minValue = minValue,
        _maxValue = maxValue;

  // ==================== GETTERS ====================

  /// Current string value
  String get value => _value;

  /// Current value as double
  double get doubleValue => double.tryParse(_value) ?? 0.0;

  /// Current value as int
  int get intValue => int.tryParse(_value.split('.')[0]) ?? 0;

  /// Check if value is empty
  bool get isEmpty => _value.isEmpty;

  /// Check if value is not empty
  bool get isNotEmpty => _value.isNotEmpty;

  /// Check if value has decimal
  bool get hasDecimal => _value.contains('.');

  /// Check if value is valid
  bool get isValid => _validateValue();

  /// Get decimal part length
  int get decimalLength {
    if (!hasDecimal) return 0;
    final parts = _value.split('.');
    return parts.length > 1 ? parts[1].length : 0;
  }

  /// Max length
  int get maxLength => _maxLength;

  /// Decimal places allowed
  int get decimalPlaces => _decimalPlaces;

  /// Whether decimal is allowed
  bool get allowDecimal => _allowDecimal;

  // ==================== SETTERS ====================

  set maxLength(int value) {
    _maxLength = value;
    notifyListeners();
  }

  set decimalPlaces(int value) {
    _decimalPlaces = value;
    notifyListeners();
  }

  set allowDecimal(bool value) {
    _allowDecimal = value;
    if (!value && hasDecimal) {
      _value = _value.split('.')[0];
    }
    notifyListeners();
  }

  set allowNegative(bool value) {
    _allowNegative = value;
    if (!value && _value.startsWith('-')) {
      _value = _value.substring(1);
    }
    notifyListeners();
  }

  set minValue(double? value) {
    _minValue = value;
    notifyListeners();
  }

  set maxValue(double? value) {
    _maxValue = value;
    notifyListeners();
  }

  // ==================== METHODS ====================

  /// Set value directly
  void setValue(String newValue) {
    _value = newValue;
    notifyListeners();
  }

  /// Set from double
  void setDouble(double value) {
    if (_allowDecimal) {
      _value = value.toStringAsFixed(_decimalPlaces);
      // Remove trailing zeros
      _value =
          _value.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    } else {
      _value = value.toInt().toString();
    }
    notifyListeners();
  }

  /// Set from int
  void setInt(int value) {
    _value = value.toString();
    notifyListeners();
  }

  /// Append a digit or decimal point
  void appendDigit(String digit) {
    // Validate input
    if (!_isValidInput(digit)) return;

    // Handle negative sign
    if (digit == '-') {
      if (!_allowNegative) return;
      if (_value.isEmpty) {
        _value = '-';
        notifyListeners();
        return;
      }
      if (_value.startsWith('-')) {
        _value = _value.substring(1);
      } else {
        _value = '-$_value';
      }
      notifyListeners();
      return;
    }

    // Handle decimal point
    if (digit == '.') {
      if (!_allowDecimal) return;
      if (_value.contains('.')) return;
      if (_value.isEmpty || _value == '-') {
        _value = '${_value}0.';
        notifyListeners();
        return;
      }
      _value += '.';
      notifyListeners();
      return;
    }

    // Check max length (excluding minus sign and decimal point)
    final cleanValue = _value.replaceAll(RegExp(r'[.-]'), '');
    if (cleanValue.length >= _maxLength) return;

    // Check decimal places
    if (hasDecimal && decimalLength >= _decimalPlaces) return;

    // Prevent leading zeros (except for decimals)
    if (_value == '0' && digit != '.' && digit != '0') {
      _value = digit;
      notifyListeners();
      return;
    }

    if (_value == '-0' && digit != '.') {
      _value = '-$digit';
      notifyListeners();
      return;
    }

    // Append digit
    _value += digit;
    notifyListeners();
  }

  /// Remove last character
  void backspace() {
    if (_value.isEmpty) return;
    _value = _value.substring(0, _value.length - 1);
    notifyListeners();
  }

  /// Clear all value
  void clear() {
    _value = '';
    notifyListeners();
  }

  /// Add percentage of current value
  void addPercentage(double percentage) {
    final current = doubleValue;
    final addition = current * (percentage / 100);
    setDouble(current + addition);
  }

  /// Multiply current value
  void multiply(double factor) {
    setDouble(doubleValue * factor);
  }

  /// Round to decimal places
  void round([int? places]) {
    final p = places ?? _decimalPlaces;
    setDouble(double.parse(doubleValue.toStringAsFixed(p)));
  }

  /// Validate value is within range
  bool _validateValue() {
    if (_value.isEmpty) return true;

    final numValue = doubleValue;

    if (_minValue != null && numValue < _minValue!) return false;
    if (_maxValue != null && numValue > _maxValue!) return false;

    return true;
  }

  /// Check if input is valid
  bool _isValidInput(String input) {
    if (input.length != 1) return false;
    if (input == '.') return true;
    if (input == '-') return true;
    return RegExp(r'^[0-9]$').hasMatch(input);
  }

  /// Format value for display
  String formatForDisplay({
    String? prefix,
    String? suffix,
    bool showZero = true,
    int? minDecimalPlaces,
  }) {
    if (_value.isEmpty && !showZero) return '';

    String displayValue = _value.isEmpty ? '0' : _value;

    // Add minimum decimal places if needed
    if (minDecimalPlaces != null && _allowDecimal) {
      final numValue = double.tryParse(displayValue) ?? 0;
      displayValue = numValue.toStringAsFixed(minDecimalPlaces);
    }

    // Add prefix and suffix
    if (prefix != null) displayValue = '$prefix$displayValue';
    if (suffix != null) displayValue = '$displayValue$suffix';

    return displayValue;
  }

  /// Copy value from another controller
  void copyFrom(KeyboardController other) {
    _value = other._value;
    notifyListeners();
  }
}

/// Extension for easy value access
extension KeyboardControllerExtension on KeyboardController {
  /// Get value as formatted currency
  String get asCurrency {
    return formatForDisplay(prefix: 'Rs. ', minDecimalPlaces: 2);
  }

  /// Get value as formatted weight
  String get asWeight {
    return formatForDisplay(suffix: ' kg', minDecimalPlaces: 3);
  }

  /// Get value as formatted bags
  String get asBags {
    return formatForDisplay(suffix: ' bags');
  }
}

