/// Number formatting utilities
class NumberFormatter {
  /// Format number with thousand separators (spaces)
  /// Example: 1431550.00 → 1 431 550.00
  static String formatWithSpaces(double value, {int decimals = 2}) {
    final formatted = value.toStringAsFixed(decimals);
    final parts = formatted.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '00';

    // Add spaces as thousand separators
    final chars = integerPart.split('').reversed.toList();
    final result = <String>[];

    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        result.add(' ');
      }
      result.add(chars[i]);
    }

    final reversed = result.reversed.join('');
    return '$reversed.$decimalPart';
  }

  /// Format currency with thousand separators
  /// Example: 1431550 → Rs. 1 431 550.00
  static String formatCurrency(double value, {String prefix = 'Rs. '}) {
    return '$prefix${formatWithSpaces(value)}';
  }

  /// Format number without decimals with thousand separators
  /// Example: 1431550 → 1 431 550
  static String formatInteger(double value) {
    final intValue = value.toInt();
    final formatted = intValue.toString();

    final chars = formatted.split('').reversed.toList();
    final result = <String>[];

    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        result.add(' ');
      }
      result.add(chars[i]);
    }

    return result.reversed.join('');
  }
}
