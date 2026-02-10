import 'package:flutter/material.dart';
import 'si_strings.dart';

/// User roles in the system
enum UserRole {
  admin('admin', 'Admin', 'පරිපාලක'),
  company('company', 'Company', 'සමාගම'),
  customer('customer', 'Customer', 'පාරිභෝගිකයා'),
  manager('manager', 'Manager', 'කළමනාකරු'),
  operator('operator', 'Operator', 'ක්‍රියාකරු'),
  viewer('viewer', 'Viewer', 'නරඹන්නා');

  final String value;
  final String displayName;
  final String sinhalaName;

  const UserRole(this.value, this.displayName, this.sinhalaName);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => UserRole.viewer,
    );
  }

  bool get canManageUsers => this == admin || this == company;
  bool get canManageCompanies => this == admin;
  bool get canManageStock => this != viewer && this != customer;
  bool get canCreateTransactions => this != viewer && this != customer;
  bool get canDeleteTransactions => this == admin || this == company;
  bool get canViewReports => this != customer;
  bool get canExportData => this != viewer && this != customer;
}

/// Item types in stock
enum ItemType {
  paddy('paddy', 'Paddy', 'වී', '🌾'),
  rice('rice', 'Rice', 'සහල්', '🍚'),
  bran('bran', 'Rice Bran', 'කුඩු', '🌰'),
  husk('husk', 'Rice Husk', 'දහල්', '🌿');

  final String value;
  final String displayName;
  final String sinhalaName;
  final String emoji;

  const ItemType(this.value, this.displayName, this.sinhalaName, this.emoji);

  static ItemType fromString(String value) {
    return ItemType.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => ItemType.paddy,
    );
  }

  bool get isPaddy => this == paddy;
  bool get isRice => this == rice;
  bool get isMainItem => this == paddy || this == rice;
  bool get isByProduct => this == bran || this == husk;
}

/// Transaction types
enum TransactionType {
  buy('buy', 'Buy', 'මිලදී ගැනීම', '📥'),
  sell('sell', 'Sell', 'විකිණීම', '📤'),
  milling('milling', 'Milling', 'මෝල් කිරීම', '⚙️'),
  adjustment('adjustment', 'Adjustment', 'සංශෝධනය', '📝'),
  transfer('transfer', 'Transfer', 'මාරු කිරීම', '🔄');

  final String value;
  final String displayName;
  final String sinhalaName;
  final String emoji;

  const TransactionType(
      this.value, this.displayName, this.sinhalaName, this.emoji);

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => TransactionType.buy,
    );
  }

  bool get isBuy => this == buy;
  bool get isSell => this == sell;
  bool get isMilling => this == milling;
  bool get affectsStock =>
      this == buy || this == sell || this == milling || this == adjustment;
  bool get requiresCustomer => this == buy || this == sell;
  bool get requiresPayment => this == buy || this == sell;
}

/// Transaction status
enum TransactionStatus {
  pending('pending', 'Pending', 'බලාපොරොත්තු'),
  completed('completed', 'Completed', 'සම්පූර්ණයි'),
  cancelled('cancelled', 'Cancelled', 'අවලංගු');

  final String value;
  final String displayName;
  final String sinhalaName;

  const TransactionStatus(this.value, this.displayName, this.sinhalaName);

  static TransactionStatus fromString(String value) {
    return TransactionStatus.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => TransactionStatus.pending,
    );
  }

  bool get isPending => this == pending;
  bool get isCompleted => this == completed;
  bool get isCancelled => this == cancelled;
}

/// Payment status
enum PaymentStatus {
  pending('pending', 'Pending', 'බලාපොරොත්තු', '⏳'),
  partial('partial', 'Partial', 'අර්ධ වශයෙන්', '🔶'),
  completed('completed', 'Completed', 'සම්පූර්ණයි', '✅'),
  overdue('overdue', 'Overdue', 'ප්‍රමාද', '⚠️'),
  cancelled('cancelled', 'Cancelled', 'අවලංගු', '❌');

  final String value;
  final String displayName;
  final String sinhalaName;
  final String emoji;

  const PaymentStatus(
      this.value, this.displayName, this.sinhalaName, this.emoji);

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }

  bool get isPending => this == pending;
  bool get isPartial => this == partial;
  bool get isCompleted => this == completed;
  bool get isCancelled => this == cancelled;
  bool get isOverdue => this == overdue;
  bool get requiresAction =>
      this == pending || this == partial || this == overdue;
}

/// Payment methods
enum PaymentMethod {
  cash('cash', 'Cash', 'මුදල්', '💵'),
  bankTransfer('bank_transfer', 'Bank Transfer', 'බැංකු මාරුව', '🏦'),
  cheque('cheque', 'Cheque', 'චෙක්පත', '📄'),
  credit('credit', 'Credit', 'ණය', '💳'),
  mobile('mobile', 'Mobile Payment', 'ජංගම ගෙවීම', '📱');

  final String value;
  final String displayName;
  final String sinhalaName;
  final String emoji;

  const PaymentMethod(
      this.value, this.displayName, this.sinhalaName, this.emoji);

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => PaymentMethod.cash,
    );
  }

  bool get isCash => this == cash;
  bool get isElectronic => this == bankTransfer || this == mobile;
  bool get requiresReference => this == bankTransfer || this == cheque;
}

/// Sync status
enum SyncStatus {
  pending('pending', 'Pending', 'බලාපොරොත්තු'),
  syncing('syncing', 'Syncing', 'සමමුහුර්ත කරමින්'),
  synced('synced', 'Synced', 'සමමුහුර්ත'),
  failed('failed', 'Failed', 'අසාර්ථක'),
  conflict('conflict', 'Conflict', 'ගැටුම');

  final String value;
  final String displayName;
  final String sinhalaName;

  const SyncStatus(this.value, this.displayName, this.sinhalaName);

  static SyncStatus fromString(String value) {
    return SyncStatus.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => SyncStatus.pending,
    );
  }

  bool get isPending => this == pending;
  bool get isSyncing => this == syncing;
  bool get isSynced => this == synced;
  bool get isFailed => this == failed;
  bool get hasConflict => this == conflict;
  bool get needsSync => this == pending || this == failed;
}

/// Sync operations
enum SyncOperation {
  create('create', 'Create'),
  update('update', 'Update'),
  delete('delete', 'Delete');

  final String value;
  final String displayName;

  const SyncOperation(this.value, this.displayName);

  static SyncOperation fromString(String value) {
    return SyncOperation.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => SyncOperation.create,
    );
  }
}

/// Stock movement types
enum MovementType {
  initial('initial', 'Initial Stock', 'ආරම්භක තොග'),
  stockIn('stock_in', 'Stock In', 'තොග ඇතුළත් කිරීම'),
  stockOut('stock_out', 'Stock Out', 'තොග පිටත කිරීම'),
  adjustment('adjustment', 'Adjustment', 'සංශෝධනය'),
  transfer('transfer', 'Transfer', 'මාරු කිරීම');

  final String value;
  final String displayName;
  final String sinhalaName;

  const MovementType(this.value, this.displayName, this.sinhalaName);

  static MovementType fromString(String value) {
    return MovementType.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => MovementType.stockIn,
    );
  }

  bool get isIncrease =>
      this == initial || this == stockIn || this == adjustment;
  bool get isDecrease => this == stockOut || this == transfer;
}

/// Customer types
enum CustomerType {
  buyer('buyer', 'Buyer', 'පාරිභෝගිකයා (Buyer)'),
  seller('seller', 'Seller', 'සැපයුම්කරු (Seller)'),
  both('both', 'Both', 'දෙකම (Both)');

  final String value;
  final String displayName;
  final String sinhalaName;

  const CustomerType(this.value, this.displayName, this.sinhalaName);

  static CustomerType fromString(String value) {
    return CustomerType.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => CustomerType.both,
    );
  }

  bool get canBuy => this == seller || this == both;
  bool get canSell => this == buyer || this == both;
}

/// Weight units
enum WeightUnit {
  kg('kg', 'Kilogram', 'කිලෝග්‍රෑම්', 1.0),
  g('g', 'Gram', 'ග්‍රෑම්', 0.001),
  ton('ton', 'Ton', 'ටොන්', 1000.0),
  lb('lb', 'Pound', 'පවුම්', 0.453592);

  final String value;
  final String displayName;
  final String sinhalaName;
  final double toKgFactor;

  const WeightUnit(
      this.value, this.displayName, this.sinhalaName, this.toKgFactor);

  static WeightUnit fromString(String value) {
    return WeightUnit.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => WeightUnit.kg,
    );
  }

  double toKg(double value) => value * toKgFactor;
  double fromKg(double kg) => kg / toKgFactor;
}

/// Expense categories
enum ExpenseCategory {
  electricity('electricity', 'Electricity', 'විදුලිය', Icons.bolt),
  water('water', 'Water', 'ජලය', Icons.water_drop),
  fuel('fuel', 'Fuel', 'ඉන්ධන', Icons.local_gas_station),
  transport('transport', 'Transport', 'ප්‍රවාහනය', Icons.local_shipping),
  labor('labor', 'Labor / Wages', 'වැටුප්', Icons.groups),
  maintenance('maintenance', 'Maintenance', 'නඩත්තු', Icons.build),
  rent('rent', 'Rent', 'කුලිය', Icons.home_work),
  taxes('taxes', 'Taxes', 'බදු', Icons.account_balance),
  other('other', 'Other', 'වෙනත්', Icons.more_horiz);

  final String value;
  final String displayName;
  final String sinhalaName;
  final IconData icon;

  const ExpenseCategory(
      this.value, this.displayName, this.sinhalaName, this.icon);

  String get displayNameLocal => SiStrings.isSinhala ? sinhalaName : displayName;

  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}

/// Report types
enum ReportType {
  daily('daily', 'Daily Report', 'දෛනික වාර්තාව'),
  weekly('weekly', 'Weekly Report', 'සතිපතා වාර්තාව'),
  monthly('monthly', 'Monthly Report', 'මාසික වාර්තාව'),
  yearly('yearly', 'Yearly Report', 'වාර්ෂික වාර්තාව'),
  custom('custom', 'Custom Report', 'අභිරුචි වාර්තාව'),
  stock('stock', 'Stock Report', 'තොග වාර්තාව'),
  customer('customer', 'Customer Report', 'ගනුදෙනුකාර වාර්තාව'),
  transaction('transaction', 'Transaction Report', 'ගනුදෙනු වාර්තාව'),
  profitLoss('profit_loss', 'Profit/Loss Report', 'ලාභ/හානි වාර්තාව');

  final String value;
  final String displayName;
  final String sinhalaName;

  const ReportType(this.value, this.displayName, this.sinhalaName);

  static ReportType fromString(String value) {
    return ReportType.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => ReportType.daily,
    );
  }
}

/// Export formats
enum ExportFormat {
  pdf('pdf', 'PDF', 'application/pdf'),
  excel('xlsx', 'Excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
  csv('csv', 'CSV', 'text/csv'),
  json('json', 'JSON', 'application/json');

  final String extension;
  final String displayName;
  final String mimeType;

  const ExportFormat(this.extension, this.displayName, this.mimeType);

  static ExportFormat fromString(String value) {
    return ExportFormat.values.firstWhere(
      (e) => e.extension == value || e.name == value,
      orElse: () => ExportFormat.pdf,
    );
  }
}

/// Stock alert levels
enum StockAlertLevel {
  normal('normal', 'Normal', 'සාමාන්‍ය', 0xFF4CAF50),
  low('low', 'Low Stock', 'අඩු තොග', 0xFFFFA726),
  critical('critical', 'Critical', 'අවදානම්', 0xFFE53935),
  outOfStock('out_of_stock', 'Out of Stock', 'තොග අවසන්', 0xFF9E9E9E);

  final String value;
  final String displayName;
  final String sinhalaName;
  final int colorValue;

  const StockAlertLevel(
      this.value, this.displayName, this.sinhalaName, this.colorValue);

  static StockAlertLevel fromString(String value) {
    return StockAlertLevel.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => StockAlertLevel.normal,
    );
  }

  static StockAlertLevel fromStock(double current, double minLevel) {
    if (current <= 0) return outOfStock;
    if (minLevel <= 0) return normal;

    final ratio = current / minLevel;
    if (ratio <= 0.25) return critical;
    if (ratio <= 0.5) return low;
    return normal;
  }
}

/// Stock add status
enum StockAddStatus {
  initial('initial', 'Initial'),
  adding('adding', 'Adding Stock'),
  success('success', 'Stock Added Successfully'),
  failure('failure', 'Failed to Add Stock');

  final String value;
  final String displayName;

  const StockAddStatus(this.value, this.displayName);

  static StockAddStatus fromString(String value) {
    return StockAddStatus.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => StockAddStatus.initial,
    );
  }

  bool get isInitial => this == initial;
  bool get isAdding => this == adding;
  bool get isSuccess => this == success;
  bool get isFailure => this == failure;
}

/// Theme modes
enum AppThemeMode {
  light('light', 'Light', 'සැහැල්ලු'),
  dark('dark', 'Dark', 'අඳුරු'),
  system('system', 'System', 'පද්ධතිය');

  final String value;
  final String displayName;
  final String sinhalaName;

  const AppThemeMode(this.value, this.displayName, this.sinhalaName);

  static AppThemeMode fromString(String value) {
    return AppThemeMode.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => AppThemeMode.light,
    );
  }
}

/// Languages
enum AppLanguage {
  sinhala('si', 'LK', 'සිංහල', 'Sinhala'),
  english('en', 'US', 'English', 'English'),
  tamil('ta', 'LK', 'தமிழ்', 'Tamil');

  final String languageCode;
  final String countryCode;
  final String nativeName;
  final String englishName;

  const AppLanguage(
      this.languageCode, this.countryCode, this.nativeName, this.englishName);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (e) => e.languageCode == code,
      orElse: () => AppLanguage.sinhala,
    );
  }

  String get localeCode => '${languageCode}_$countryCode';
}

/// Notification types
enum NotificationType {
  transaction('transaction', 'Transaction', '💰'),
  stock('stock', 'Stock Alert', '📦'),
  payment('payment', 'Payment', '💳'),
  sync('sync', 'Sync', '🔄'),
  system('system', 'System', '⚙️');

  final String value;
  final String displayName;
  final String emoji;

  const NotificationType(this.value, this.displayName, this.emoji);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => NotificationType.system,
    );
  }
}

/// Date range helper class
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange(this.start, this.end);

  Duration get duration => end.difference(start);
  int get days => duration.inDays + 1;
}

/// Date range presets
enum DateRangePreset {
  today('today', 'Today', 'අද'),
  yesterday('yesterday', 'Yesterday', 'ඊයේ'),
  thisWeek('this_week', 'This Week', 'මේ සතිය'),
  lastWeek('last_week', 'Last Week', 'පසුගිය සතිය'),
  thisMonth('this_month', 'This Month', 'මේ මාසය'),
  lastMonth('last_month', 'Last Month', 'පසුගිය මාසය'),
  thisYear('this_year', 'This Year', 'මේ වසර'),
  lastYear('last_year', 'Last Year', 'පසුගිය වසර'),
  custom('custom', 'Custom', 'අභිරුචි');

  final String value;
  final String displayName;
  final String sinhalaName;

  const DateRangePreset(this.value, this.displayName, this.sinhalaName);

  static DateRangePreset fromString(String value) {
    return DateRangePreset.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => DateRangePreset.today,
    );
  }

  /// Get date range for this preset
  DateRange getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case DateRangePreset.today:
        return DateRange(today, today);
      case DateRangePreset.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return DateRange(yesterday, yesterday);
      case DateRangePreset.thisWeek:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return DateRange(startOfWeek, today);
      case DateRangePreset.lastWeek:
        final startOfLastWeek =
            today.subtract(Duration(days: today.weekday + 6));
        final endOfLastWeek = today.subtract(Duration(days: today.weekday));
        return DateRange(startOfLastWeek, endOfLastWeek);
      case DateRangePreset.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return DateRange(startOfMonth, today);
      case DateRangePreset.lastMonth:
        final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final endOfLastMonth = DateTime(now.year, now.month, 0);
        return DateRange(startOfLastMonth, endOfLastMonth);
      case DateRangePreset.thisYear:
        final startOfYear = DateTime(now.year, 1, 1);
        return DateRange(startOfYear, today);
      case DateRangePreset.lastYear:
        final startOfLastYear = DateTime(now.year - 1, 1, 1);
        final endOfLastYear = DateTime(now.year - 1, 12, 31);
        return DateRange(startOfLastYear, endOfLastYear);
      case DateRangePreset.custom:
        return DateRange(today, today);
    }
  }
}

/// Sort options
enum SortOption {
  newest('newest', 'Newest First', 'created_at DESC'),
  oldest('oldest', 'Oldest First', 'created_at ASC'),
  nameAsc('name_asc', 'Name (A-Z)', 'name ASC'),
  nameDesc('name_desc', 'Name (Z-A)', 'name DESC'),
  amountHigh('amount_high', 'Amount (High-Low)', 'total_amount DESC'),
  amountLow('amount_low', 'Amount (Low-High)', 'total_amount ASC'),
  weightHigh('weight_high', 'Weight (High-Low)', 'total_weight_kg DESC'),
  weightLow('weight_low', 'Weight (Low-High)', 'total_weight_kg ASC');

  final String value;
  final String displayName;
  final String orderBy;

  const SortOption(this.value, this.displayName, this.orderBy);

  static SortOption fromString(String value) {
    return SortOption.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => SortOption.newest,
    );
  }
}
