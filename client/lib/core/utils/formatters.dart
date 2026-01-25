import 'package:intl/intl.dart';

/// Application formatters for displaying data
class Formatters {
  Formatters._();

  // ==================== CURRENCY FORMATTERS ====================

  /// Currency format for Sri Lankan Rupees
  static final _currencyFormat = NumberFormat.currency(
    locale: 'si_LK',
    symbol: 'Rs. ',
    decimalDigits: 2,
  );

  /// Currency format without symbol
  static final _currencyNoSymbol = NumberFormat('#,##0.00', 'en_US');

  /// Compact currency format
  static final _currencyCompact = NumberFormat.compactCurrency(
    locale: 'en_US',
    symbol: 'Rs. ',
  );

  /// Format as currency
  static String currency(double value) {
    return _currencyFormat.format(value);
  }

  /// Format as currency without symbol
  static String currencyValue(double value) {
    return _currencyNoSymbol.format(value);
  }

  /// Format as compact currency (e.g., Rs. 1.5M)
  static String currencyCompact(double value) {
    if (value.abs() >= 1000000) {
      return 'Rs. ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return 'Rs. ${(value / 1000).toStringAsFixed(1)}K';
    }
    return currency(value);
  }

  /// Format as currency with custom symbol
  static String currencyWithSymbol(double value, String symbol) {
    return '$symbol ${_currencyNoSymbol.format(value)}';
  }

  /// Parse currency string to double
  static double? parseCurrency(String value) {
    try {
      final cleaned = value
          .replaceAll('Rs.', '')
          .replaceAll('Rs', '')
          .replaceAll(',', '')
          .replaceAll(' ', '')
          .trim();
      return double.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }

  // ==================== NUMBER FORMATTERS ====================

  /// Number format with 2 decimal places
  static final _numberFormat = NumberFormat('#,##0.00', 'en_US');

  /// Integer format
  static final _integerFormat = NumberFormat('#,##0', 'en_US');

  /// Weight format with 3 decimal places
  static final _weightFormat = NumberFormat('#,##0.000', 'en_US');

  /// Percentage format
  static final _percentFormat = NumberFormat('#,##0.0', 'en_US');

  /// Format number with decimals
  static String number(double value, {int decimals = 2}) {
    if (decimals == 0) return _integerFormat.format(value);
    if (decimals == 2) return _numberFormat.format(value);
    if (decimals == 3) return _weightFormat.format(value);
    return NumberFormat('#,##0.${'0' * decimals}', 'en_US').format(value);
  }

  /// Format as integer
  static String integer(int value) {
    return _integerFormat.format(value);
  }

  /// Format as integer (from double)
  static String integerFromDouble(double value) {
    return _integerFormat.format(value.round());
  }

  /// Format as percentage
  static String percentage(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Format number compact (e.g., 1.5K, 2.3M)
  static String numberCompact(double value) {
    if (value.abs() >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  /// Format with sign (+ or -)
  static String withSign(double value, {int decimals = 2}) {
    final prefix = value >= 0 ? '+' : '';
    return '$prefix${number(value, decimals: decimals)}';
  }

  // ==================== WEIGHT FORMATTERS ====================

  /// Format weight in kg
  static String weight(double value, {bool showUnit = true}) {
    final formatted = _weightFormat.format(value);
    return showUnit ? '$formatted kg' : formatted;
  }

  /// Format weight compact (for display)
  static String weightCompact(double value, {bool showUnit = true}) {
    String formatted;
    if (value >= 1000) {
      formatted = '${(value / 1000).toStringAsFixed(2)} ton';
    } else {
      formatted = '${value.toStringAsFixed(value < 10 ? 2 : 1)} kg';
    }
    return showUnit
        ? formatted
        : formatted.replaceAll(RegExp(r'\s*(kg|ton)'), '');
  }

  /// Format weight in grams
  static String weightGrams(double value, {bool showUnit = true}) {
    final formatted = _integerFormat.format(value);
    return showUnit ? '$formatted g' : formatted;
  }

  /// Format weight in tons
  static String weightTons(double value, {bool showUnit = true}) {
    final formatted = value.toStringAsFixed(3);
    return showUnit ? '$formatted ton' : formatted;
  }

  /// Format bags count
  static String bags(int count) {
    return '$count ${count == 1 ? 'bag' : 'bags'}';
  }

  /// Format bags count (Sinhala)
  static String bagsSinhala(int count) {
    return 'බෑග් $count';
  }

  // ==================== DATE FORMATTERS ====================

  /// Date format (ISO)
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  /// Time format (24h)
  static final _timeFormat = DateFormat('HH:mm');

  /// Time format (12h)
  static final _timeFormat12 = DateFormat('hh:mm a');

  /// Date time format
  static final _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

  /// Display date format
  static final _displayDateFormat = DateFormat('dd MMM yyyy');

  /// Display date time format
  static final _displayDateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  /// Short date format
  static final _shortDateFormat = DateFormat('dd/MM/yy');

  /// Month year format
  static final _monthYearFormat = DateFormat('MMMM yyyy');

  /// Day month format
  static final _dayMonthFormat = DateFormat('dd MMM');

  /// Format date (ISO)
  static String date(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format time (24h)
  static String time(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Format time (12h)
  static String time12(DateTime date) {
    return _timeFormat12.format(date);
  }

  /// Format date and time
  static String dateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Format for display
  static String displayDate(DateTime date) {
    return _displayDateFormat.format(date);
  }

  /// Format date time for display
  static String displayDateTime(DateTime date) {
    return _displayDateTimeFormat.format(date);
  }

  /// Format short date
  static String shortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }

  /// Format month year
  static String monthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Format day month
  static String dayMonth(DateTime date) {
    return _dayMonthFormat.format(date);
  }

  /// Format relative time (e.g., "2 hours ago")
  static String relativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.isNegative) {
      return _formatFutureTime(difference.abs());
    }

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      return displayDate(date);
    }
  }

  static String _formatFutureTime(Duration difference) {
    if (difference.inMinutes < 60) {
      return 'in ${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return 'in ${difference.inHours} hours';
    } else {
      return 'in ${difference.inDays} days';
    }
  }

  /// Format relative time (Sinhala)
  static String relativeTimeSinhala(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'දැන්';
    } else if (difference.inMinutes < 60) {
      return 'මිනිත්තු ${difference.inMinutes}කට පෙර';
    } else if (difference.inHours < 24) {
      return 'පැය ${difference.inHours}කට පෙර';
    } else if (difference.inDays < 7) {
      return 'දින ${difference.inDays}කට පෙර';
    } else {
      return displayDate(date);
    }
  }

  /// Format date range
  static String dateRange(DateTime start, DateTime end) {
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return displayDate(start);
    }

    if (start.year == end.year && start.month == end.month) {
      return '${start.day} - ${end.day} ${DateFormat('MMM yyyy').format(end)}';
    }

    if (start.year == end.year) {
      return '${dayMonth(start)} - ${displayDate(end)}';
    }

    return '${displayDate(start)} - ${displayDate(end)}';
  }

  /// Parse date from string
  static DateTime? parseDate(String value, [String format = 'yyyy-MM-dd']) {
    try {
      return DateFormat(format).parse(value);
    } catch (_) {
      return null;
    }
  }

  // ==================== PHONE FORMATTERS ====================

  /// Format phone number
  static String phone(String phone) {
    // Remove all non-digits
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');

    // Format based on length
    if (cleaned.length == 10) {
      // Format: 0XX XXX XXXX
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    } else if (cleaned.length == 9) {
      // Format: XX XXX XXXX (without leading 0)
      return '0${cleaned.substring(0, 2)} ${cleaned.substring(2, 5)} ${cleaned.substring(5)}';
    } else if (cleaned.length == 11 && cleaned.startsWith('94')) {
      // Format: +94 XX XXX XXXX
      return '+94 ${cleaned.substring(2, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7)}';
    } else if (cleaned.length == 12 && cleaned.startsWith('94')) {
      // Format: +94 XXX XXX XXXX
      return '+94 ${cleaned.substring(2, 5)} ${cleaned.substring(5, 8)} ${cleaned.substring(8)}';
    }

    return phone; // Return original if format unknown
  }

  /// Format phone for display (masked)
  static String phoneMasked(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length >= 6) {
      return '${cleaned.substring(0, 3)} *** ${cleaned.substring(cleaned.length - 3)}';
    }
    return phone;
  }

  /// Format phone for calling
  static String phoneForCall(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('0')) {
      return '+94${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('94')) {
      return '+94$cleaned';
    }
    return '+$cleaned';
  }

  // ==================== NIC FORMATTERS ====================

  /// Format NIC
  static String nic(String nic) {
    final cleaned = nic.trim().toUpperCase();

    // Old format
    if (cleaned.length == 10) {
      return '${cleaned.substring(0, 5)} ${cleaned.substring(5, 9)} ${cleaned.substring(9)}';
    }

    // New format
    if (cleaned.length == 12) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 8)} ${cleaned.substring(8)}';
    }

    return nic;
  }

  // ==================== TRANSACTION ID FORMATTERS ====================

  /// Format transaction ID
  static String transactionId(String prefix, int id) {
    return '$prefix-${id.toString().padLeft(6, '0')}';
  }

  /// Generate transaction ID with date
  static String transactionIdWithDate(
      String prefix, DateTime date, int sequence) {
    final dateStr = DateFormat('yyyyMMdd').format(date);
    return '$prefix-$dateStr-${sequence.toString().padLeft(4, '0')}';
  }

  /// Format reference number
  static String referenceNumber(String value) {
    if (value.length <= 4) return value;

    // Add spaces every 4 characters
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(value[i]);
    }
    return buffer.toString();
  }

  // ==================== TEXT FORMATTERS ====================

  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }

  /// Capitalize each word
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Truncate text
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Format name (proper case)
  static String name(String name) {
    return capitalizeWords(name.toLowerCase().trim());
  }

  /// Format initials
  static String initials(String name, {int count = 2}) {
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words
        .where((w) => w.isNotEmpty)
        .take(count)
        .map((w) => w[0].toUpperCase())
        .join();
    return initials;
  }

  /// Format file size
  static String fileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  // ==================== LIST FORMATTERS ====================

  /// Format list as comma separated
  static String listToString(List<String> items, {String separator = ', '}) {
    return items.join(separator);
  }

  /// Format list with "and"
  static String listWithAnd(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    if (items.length == 2) return '${items[0]} and ${items[1]}';

    final last = items.last;
    final rest = items.sublist(0, items.length - 1);
    return '${rest.join(', ')}, and $last';
  }

  /// Format count with label
  static String count(int value, String singular, [String? plural]) {
    final label = value == 1 ? singular : (plural ?? '${singular}s');
    return '$value $label';
  }
}

