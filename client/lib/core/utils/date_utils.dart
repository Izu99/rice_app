import 'package:intl/intl.dart';

/// Application date utilities
class AppDateUtils {
  AppDateUtils._();

  // ==================== DATE GETTERS ====================

  /// Get current date (without time)
  static DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Get yesterday's date
  static DateTime get yesterday {
    return today.subtract(const Duration(days: 1));
  }

  /// Get tomorrow's date
  static DateTime get tomorrow {
    return today.add(const Duration(days: 1));
  }

  /// Get current month start
  static DateTime get startOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Get current month end
  static DateTime get endOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  /// Get current year start
  static DateTime get startOfYear {
    final now = DateTime.now();
    return DateTime(now.year, 1, 1);
  }

  /// Get current year end
  static DateTime get endOfYear {
    final now = DateTime.now();
    return DateTime(now.year, 12, 31, 23, 59, 59);
  }

  /// Get current week start (Monday)
  static DateTime get startOfWeek {
    final now = today;
    final weekday = now.weekday;
    return now.subtract(Duration(days: weekday - 1));
  }

  /// Get current week end (Sunday)
  static DateTime get endOfWeek {
    return startOfWeek.add(const Duration(days: 6));
  }

  // ==================== DATE CALCULATIONS ====================

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Get start of month for given date
  static DateTime startOfMonthFor(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month for given date
  static DateTime endOfMonthFor(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  /// Get start of year for given date
  static DateTime startOfYearFor(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  /// Get end of year for given date
  static DateTime endOfYearFor(DateTime date) {
    return DateTime(date.year, 12, 31, 23, 59, 59);
  }

  /// Get start of week for given date
  static DateTime startOfWeekFor(DateTime date) {
    final weekday = date.weekday;
    return startOfDay(date.subtract(Duration(days: weekday - 1)));
  }

  /// Get end of week for given date
  static DateTime endOfWeekFor(DateTime date) {
    return endOfDay(startOfWeekFor(date).add(const Duration(days: 6)));
  }

  /// Get first day of quarter
  static DateTime startOfQuarter(DateTime date) {
    final quarter = (date.month - 1) ~/ 3;
    return DateTime(date.year, quarter * 3 + 1, 1);
  }

  /// Get last day of quarter
  static DateTime endOfQuarter(DateTime date) {
    final quarter = (date.month - 1) ~/ 3;
    return DateTime(date.year, (quarter + 1) * 3 + 1, 0, 23, 59, 59);
  }

  // ==================== DATE COMPARISONS ====================

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Check if date is in this week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final weekStart = startOfWeekFor(now);
    final weekEnd = endOfWeekFor(now);
    return date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
        date.isBefore(weekEnd.add(const Duration(seconds: 1)));
  }

  /// Check if date is in last week
  static bool isLastWeek(DateTime date) {
    final lastWeekStart = startOfWeek.subtract(const Duration(days: 7));
    final lastWeekEnd = endOfWeek.subtract(const Duration(days: 7));
    return date.isAfter(lastWeekStart.subtract(const Duration(seconds: 1))) &&
        date.isBefore(lastWeekEnd.add(const Duration(seconds: 1)));
  }

  /// Check if date is in this month
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Check if date is in last month
  static bool isLastMonth(DateTime date) {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    return date.year == lastMonth.year && date.month == lastMonth.month;
  }

  /// Check if date is in this year
  static bool isThisYear(DateTime date) {
    return date.year == DateTime.now().year;
  }

  /// Check if dates are same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Check if dates are same month
  static bool isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  /// Check if dates are same year
  static bool isSameYear(DateTime date1, DateTime date2) {
    return date1.year == date2.year;
  }

  /// Check if date is weekend
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// Check if date is weekday
  static bool isWeekday(DateTime date) {
    return !isWeekend(date);
  }

  /// Check if date is in future
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  /// Check if date is in past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  // ==================== DATE RANGES ====================

  /// Get date range for preset
  static DateRange getDateRange(DateRangePreset preset) {
    final now = DateTime.now();

    switch (preset) {
      case DateRangePreset.today:
        return DateRange(today, today);
      case DateRangePreset.yesterday:
        return DateRange(yesterday, yesterday);
      case DateRangePreset.thisWeek:
        return DateRange(startOfWeek, today);
      case DateRangePreset.lastWeek:
        final lastWeekStart = startOfWeek.subtract(const Duration(days: 7));
        final lastWeekEnd = lastWeekStart.add(const Duration(days: 6));
        return DateRange(lastWeekStart, lastWeekEnd);
      case DateRangePreset.thisMonth:
        return DateRange(startOfMonth, today);
      case DateRangePreset.lastMonth:
        final lastMonthEnd = DateTime(now.year, now.month, 0);
        final lastMonthStart =
            DateTime(lastMonthEnd.year, lastMonthEnd.month, 1);
        return DateRange(lastMonthStart, lastMonthEnd);
      case DateRangePreset.last7Days:
        return DateRange(today.subtract(const Duration(days: 6)), today);
      case DateRangePreset.last30Days:
        return DateRange(today.subtract(const Duration(days: 29)), today);
      case DateRangePreset.last90Days:
        return DateRange(today.subtract(const Duration(days: 89)), today);
      case DateRangePreset.thisYear:
        return DateRange(startOfYear, today);
      case DateRangePreset.lastYear:
        final lastYearStart = DateTime(now.year - 1, 1, 1);
        final lastYearEnd = DateTime(now.year - 1, 12, 31);
        return DateRange(lastYearStart, lastYearEnd);
      case DateRangePreset.allTime:
        return DateRange(DateTime(2000, 1, 1), today);
    }
  }

  /// Get list of dates in range
  static List<DateTime> getDatesInRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    var current = startOfDay(start);
    final endDay = startOfDay(end);

    while (!current.isAfter(endDay)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  /// Get list of months in range
  static List<DateTime> getMonthsInRange(DateTime start, DateTime end) {
    final months = <DateTime>[];
    var current = DateTime(start.year, start.month, 1);
    final endMonth = DateTime(end.year, end.month, 1);

    while (!current.isAfter(endMonth)) {
      months.add(current);
      current = DateTime(current.year, current.month + 1, 1);
    }

    return months;
  }

  /// Get number of days between dates
  static int daysBetween(DateTime start, DateTime end) {
    final startDay = startOfDay(start);
    final endDay = startOfDay(end);
    return endDay.difference(startDay).inDays;
  }

  /// Get number of weeks between dates
  static int weeksBetween(DateTime start, DateTime end) {
    return (daysBetween(start, end) / 7).ceil();
  }

  /// Get number of months between dates
  static int monthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + end.month - start.month;
  }

  // ==================== DATE ADDITIONS ====================

  /// Add days to date
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  /// Add weeks to date
  static DateTime addWeeks(DateTime date, int weeks) {
    return date.add(Duration(days: weeks * 7));
  }

  /// Add months to date
  static DateTime addMonths(DateTime date, int months) {
    var year = date.year;
    var month = date.month + months;

    while (month > 12) {
      month -= 12;
      year++;
    }
    while (month < 1) {
      month += 12;
      year--;
    }

    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDayOfMonth ? lastDayOfMonth : date.day;

    return DateTime(year, month, day, date.hour, date.minute, date.second);
  }

  /// Add years to date
  static DateTime addYears(DateTime date, int years) {
    return DateTime(
      date.year + years,
      date.month,
      date.day,
      date.hour,
      date.minute,
      date.second,
    );
  }

  // ==================== DATE NAMES ====================

  /// Get day name
  static String dayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  /// Get short day name
  static String dayNameShort(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  /// Get month name
  static String monthName(DateTime date) {
    return DateFormat('MMMM').format(date);
  }

  /// Get short month name
  static String monthNameShort(DateTime date) {
    return DateFormat('MMM').format(date);
  }

  /// Get day names for week
  static List<String> get weekDayNames {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  }

  /// Get month names
  static List<String> get monthNames {
    return [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
  }

  /// Get short month names
  static List<String> get monthNamesShort {
    return [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
  }

  // ==================== DATE UTILITIES ====================

  /// Get days in month
  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Get days in current month
  static int get daysInCurrentMonth {
    final now = DateTime.now();
    return daysInMonth(now.year, now.month);
  }

  /// Check if year is leap year
  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
  }

  /// Get quarter of year (1-4)
  static int getQuarter(DateTime date) {
    return ((date.month - 1) / 3).floor() + 1;
  }

  /// Get week number of year
  static int getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(firstDayOfYear).inDays;
    return ((daysDifference + firstDayOfYear.weekday) / 7).ceil();
  }

  /// Get age from birthdate
  static int getAge(DateTime birthDate) {
    final now = DateTime.now();
    var age = now.year - birthDate.year;

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  /// Parse date safely
  static DateTime? tryParse(String? value, [String format = 'yyyy-MM-dd']) {
    if (value == null || value.isEmpty) return null;

    try {
      return DateFormat(format).parse(value);
    } catch (_) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
  }

  /// Format duration
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

// ==================== DATE RANGE ====================

/// Date range model
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange(this.start, this.end);

  Duration get duration => end.difference(start);
  int get days => duration.inDays + 1;

  bool contains(DateTime date) {
    return !date.isBefore(start) && !date.isAfter(end);
  }

  bool overlaps(DateRange other) {
    return start.isBefore(other.end) && end.isAfter(other.start);
  }

  @override
  String toString() =>
      '${AppDateUtils.startOfDay(start)} - ${AppDateUtils.startOfDay(end)}';
}

/// Date range presets
enum DateRangePreset {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  last7Days,
  last30Days,
  last90Days,
  thisYear,
  lastYear,
  allTime,
}

