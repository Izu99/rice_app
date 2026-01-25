import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ==================== STRING EXTENSIONS ====================

extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Capitalize each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Capitalize first letter of each sentence
  String get capitalizeSentences {
    if (isEmpty) return this;
    return split('. ').map((s) => s.capitalize).join('. ');
  }

  /// Truncate with ellipsis
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Remove all whitespace
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Replace multiple spaces with single space
  String get normalizeSpaces => replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Check if string is numeric
  bool get isNumeric => double.tryParse(this) != null;

  /// Check if string is integer
  bool get isInteger => int.tryParse(this) != null;

  /// Check if string is valid email
  bool get isValidEmail {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(this);
  }

  /// Check if string is valid phone (Sri Lankan)
  bool get isValidPhone {
    final cleaned = replaceAll(RegExp(r'[\s\-()]'), '');
    final regex = RegExp(r'^(?:\+?94|0)?[0-9]{9,10}$');
    return regex.hasMatch(cleaned);
  }

  /// Check if string is valid NIC (Sri Lankan)
  bool get isValidNic {
    final cleaned = trim().toUpperCase();
    final oldFormat = RegExp(r'^[0-9]{9}[VX]$');
    final newFormat = RegExp(r'^[0-9]{12}$');
    return oldFormat.hasMatch(cleaned) || newFormat.hasMatch(cleaned);
  }

  /// Check if string is null or empty
  bool get isNullOrEmpty => isEmpty;

  /// Check if string is not null or empty
  bool get isNotNullOrEmpty => isNotEmpty;

  /// Convert to double or null
  double? toDoubleOrNull() => double.tryParse(this);

  /// Convert to int or null
  int? toIntOrNull() => int.tryParse(this);

  /// Convert to double with default
  double toDoubleOr(double defaultValue) =>
      double.tryParse(this) ?? defaultValue;

  /// Convert to int with default
  int toIntOr(int defaultValue) => int.tryParse(this) ?? defaultValue;

  /// Get initials (first letter of each word)
  String initials({int count = 2}) {
    final words = trim().split(RegExp(r'\s+'));
    return words
        .where((w) => w.isNotEmpty)
        .take(count)
        .map((w) => w[0].toUpperCase())
        .join();
  }

  /// Mask string (e.g., for phone numbers)
  String mask(
      {int visibleStart = 3, int visibleEnd = 3, String maskChar = '*'}) {
    if (length <= visibleStart + visibleEnd) return this;
    final start = substring(0, visibleStart);
    final end = substring(length - visibleEnd);
    final masked = maskChar * (length - visibleStart - visibleEnd);
    return '$start$masked$end';
  }

  /// Convert camelCase to Title Case
  String get camelToTitle {
    return replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    ).trim().capitalizeWords;
  }

  /// Convert snake_case to Title Case
  String get snakeToTitle {
    return split('_').map((w) => w.capitalize).join(' ');
  }

  /// Reverse string
  String get reversed => split('').reversed.join();

  /// Check if contains only digits
  bool get isDigitsOnly => RegExp(r'^[0-9]+$').hasMatch(this);

  /// Check if contains only letters
  bool get isLettersOnly => RegExp(r'^[a-zA-Z]+$').hasMatch(this);

  /// Check if contains only alphanumeric
  bool get isAlphanumeric => RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);
}

// ==================== STRING? EXTENSIONS ====================

extension NullableStringExtensions on String? {
  /// Check if null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Check if not null and not empty
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;

  /// Get value or default
  String orDefault(String defaultValue) => isNullOrEmpty ? defaultValue : this!;

  /// Get value or empty string
  String get orEmpty => this ?? '';
}

// ==================== DATETIME EXTENSIONS ====================

extension DateTimeExtensions on DateTime {
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Check if date is this week
  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return isAfter(weekStart.subtract(const Duration(days: 1))) &&
        isBefore(weekEnd.add(const Duration(days: 1)));
  }

  /// Check if date is this month
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// Check if date is this year
  bool get isThisYear {
    return year == DateTime.now().year;
  }

  /// Check if date is weekend
  bool get isWeekend {
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }

  /// Check if date is weekday
  bool get isWeekday => !isWeekend;

  /// Get start of day
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get end of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Get start of month
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Get end of month
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59);

  /// Get start of week (Monday)
  DateTime get startOfWeek {
    return subtract(Duration(days: weekday - 1)).startOfDay;
  }

  /// Get end of week (Sunday)
  DateTime get endOfWeek {
    return add(Duration(days: 7 - weekday)).endOfDay;
  }

  /// Get start of year
  DateTime get startOfYear => DateTime(year, 1, 1);

  /// Get end of year
  DateTime get endOfYear => DateTime(year, 12, 31, 23, 59, 59);

  /// Format date
  String format([String pattern = 'yyyy-MM-dd']) {
    return DateFormat(pattern).format(this);
  }

  /// Format for display
  String get displayFormat => DateFormat('dd MMM yyyy').format(this);

  /// Format with time
  String get displayWithTime => DateFormat('dd MMM yyyy, HH:mm').format(this);

  /// Get relative time string
  String get relative {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return displayFormat;
    }
  }

  /// Get age in years
  int get age {
    final now = DateTime.now();
    var age = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) {
      age--;
    }
    return age;
  }

  /// Add months
  DateTime addMonths(int months) {
    var newMonth = month + months;
    var newYear = year;
    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }
    while (newMonth < 1) {
      newMonth += 12;
      newYear--;
    }
    final lastDay = DateTime(newYear, newMonth + 1, 0).day;
    return DateTime(newYear, newMonth, day > lastDay ? lastDay : day);
  }

  /// Check if same day as another date
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Check if same month as another date
  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }
}

// ==================== NUM EXTENSIONS ====================

extension NumExtensions on num {
  /// Convert to currency string
  String get toCurrency => NumberFormat.currency(
        locale: 'si_LK',
        symbol: 'Rs. ',
        decimalDigits: 2,
      ).format(this);

  /// Convert to compact currency
  String get toCompactCurrency {
    if (abs() >= 1000000) {
      return 'Rs. ${(this / 1000000).toStringAsFixed(1)}M';
    } else if (abs() >= 1000) {
      return 'Rs. ${(this / 1000).toStringAsFixed(1)}K';
    }
    return toCurrency;
  }

  /// Convert to weight string
  String get toWeight => '${toStringAsFixed(3)} kg';

  /// Convert to percentage string
  String get toPercentage => '${toStringAsFixed(1)}%';

  /// Format with separators
  String get formatted => NumberFormat('#,##0.##').format(this);

  /// Clamp between min and max
  num clampBetween(num min, num max) =>
      this < min ? min : (this > max ? max : this);

  /// Check if between range
  bool isBetween(num min, num max) => this >= min && this <= max;

  /// Convert to duration (seconds)
  Duration get seconds => Duration(seconds: toInt());

  /// Convert to duration (milliseconds)
  Duration get milliseconds => Duration(milliseconds: toInt());

  /// Convert to duration (minutes)
  Duration get minutes => Duration(minutes: toInt());

  /// Convert to duration (hours)
  Duration get hours => Duration(hours: toInt());

  /// Convert to duration (days)
  Duration get days => Duration(days: toInt());
}

extension DoubleExtensions on double {
  /// Round to specific decimal places
  double toPrecision(int decimals) {
    return double.parse(toStringAsFixed(decimals));
  }
}

// ==================== LIST EXTENSIONS ====================

extension ListExtensions<T> on List<T> {
  /// Get first element or null
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last element or null
  T? get lastOrNull => isEmpty ? null : last;

  /// Get element at index or null
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Separate list with element
  List<T> separatedBy(T separator) {
    if (length <= 1) return this;
    final result = <T>[];
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) result.add(separator);
    }
    return result;
  }

  /// Group by key
  Map<K, List<T>> groupBy<K>(K Function(T) keySelector) {
    final map = <K, List<T>>{};
    for (final item in this) {
      final key = keySelector(item);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  /// Distinct by key
  List<T> distinctBy<K>(K Function(T) keySelector) {
    final seen = <K>{};
    return where((item) => seen.add(keySelector(item))).toList();
  }

  /// Chunk list into smaller lists
  List<List<T>> chunked(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }

  /// Safe sublist
  List<T> safeSublist(int start, [int? end]) {
    final safeStart = start.clamp(0, length);
    final safeEnd = (end ?? length).clamp(safeStart, length);
    return sublist(safeStart, safeEnd);
  }
}

// ==================== MAP EXTENSIONS ====================

extension MapExtensions<K, V> on Map<K, V> {
  /// Get value or default
  V getOrDefault(K key, V defaultValue) => this[key] ?? defaultValue;

  /// Get value or null (safe)
  V? getOrNull(K key) => this[key];

  /// Filter map entries
  Map<K, V> filter(bool Function(K, V) predicate) {
    return Map.fromEntries(
      entries.where((e) => predicate(e.key, e.value)),
    );
  }

  /// Map values
  Map<K, R> mapValues<R>(R Function(V) transform) {
    return map((k, v) => MapEntry(k, transform(v)));
  }
}

// ==================== ITERABLE EXTENSIONS ====================

extension IterableExtensions<T> on Iterable<T> {
  /// Sum of numeric values
  double sumBy(num Function(T) selector) {
    return fold(0.0, (sum, item) => sum + selector(item));
  }

  /// Average of numeric values
  double averageBy(num Function(T) selector) {
    if (isEmpty) return 0;
    return sumBy(selector) / length;
  }

  /// Max by selector
  T? maxBy<R extends Comparable>(R Function(T) selector) {
    if (isEmpty) return null;
    return reduce((a, b) => selector(a).compareTo(selector(b)) > 0 ? a : b);
  }

  /// Min by selector
  T? minBy<R extends Comparable>(R Function(T) selector) {
    if (isEmpty) return null;
    return reduce((a, b) => selector(a).compareTo(selector(b)) < 0 ? a : b);
  }
}

// ==================== CONTEXT EXTENSIONS ====================

extension ContextExtensions on BuildContext {
  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Get media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get safe area padding
  EdgeInsets get padding => MediaQuery.of(this).padding;

  /// Get view insets (keyboard)
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;

  /// Check if dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Check if portrait
  bool get isPortrait =>
      MediaQuery.of(this).orientation == Orientation.portrait;

  /// Check if landscape
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;

  /// Show snackbar
  void showSnackBar(String message,
      {bool isError = false, Duration? duration}) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  /// Show success snackbar
  void showSuccess(String message) {
    showSnackBar(message, isError: false);
  }

  /// Show error snackbar
  void showError(String message) {
    showSnackBar(message, isError: true);
  }

  /// Pop navigation
  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  /// Push named route
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Push replacement named
  Future<T?> pushReplacementNamed<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this)
        .pushReplacementNamed<T, dynamic>(routeName, arguments: arguments);
  }

  /// Hide keyboard
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }

  /// Request focus
  void requestFocus(FocusNode node) {
    FocusScope.of(this).requestFocus(node);
  }
}

// ==================== DURATION EXTENSIONS ====================

extension DurationExtensions on Duration {
  /// Format as HH:mm:ss
  String get formatted {
    final hours = inHours.toString().padLeft(2, '0');
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Format as mm:ss
  String get shortFormatted {
    final minutes = inMinutes.toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Format as human readable
  String get humanReadable {
    if (inDays > 0) {
      return '${inDays}d ${inHours.remainder(24)}h';
    } else if (inHours > 0) {
      return '${inHours}h ${inMinutes.remainder(60)}m';
    } else if (inMinutes > 0) {
      return '${inMinutes}m ${inSeconds.remainder(60)}s';
    } else {
      return '${inSeconds}s';
    }
  }
}

// ==================== COLOR EXTENSIONS ====================

extension ColorExtensions on Color {
  /// Darken color
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Lighten color
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Get hex string
  String get toHex {
    return '#${value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  /// Check if dark color
  bool get isDark => computeLuminance() < 0.5;

  /// Check if light color
  bool get isLight => !isDark;

  /// Get contrasting text color
  Color get contrastingColor => isDark ? Colors.white : Colors.black;
}

