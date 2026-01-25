import 'package:flutter/material.dart';

/// Application-wide constants
class AppConstants {
  AppConstants._();

  // ==================== APP INFO ====================

  /// Application name
  static const String appName = 'Rice Mill ERP';

  /// Application name in Sinhala
  static const String appNameSinhala = 'සහල් මෝල් කළමනාකරණය';

  /// Application version
  static const String appVersion = '1.0.0';

  /// Build number
  static const int buildNumber = 1;

  /// Package name
  static const String packageName = 'com.ricemill.erp';

  /// Company name
  static const String companyName = 'Rice Mill Solutions';

  // ==================== STORAGE KEYS ====================

  /// Authentication token key
  static const String tokenKey = 'auth_token';

  /// Refresh token key
  static const String refreshTokenKey = 'refresh_token';

  /// User data key
  static const String userKey = 'user_data';

  /// Company data key
  static const String companyKey = 'company_data';

  /// Last sync timestamp key
  static const String lastSyncKey = 'last_sync_time';

  /// Theme mode key
  static const String themeKey = 'theme_mode';

  /// Language key
  static const String languageKey = 'language';

  /// First launch key
  static const String firstLaunchKey = 'first_launch';

  /// Remember me key
  static const String rememberMeKey = 'remember_me';

  /// Biometric enabled key
  static const String biometricKey = 'biometric_enabled';

  /// Notification enabled key
  static const String notificationKey = 'notification_enabled';

  /// Offline mode key
  static const String offlineModeKey = 'offline_mode';

  // ==================== TIMEOUTS ====================

  /// Connection timeout duration
  static const Duration connectionTimeout = Duration(seconds: 10);

  /// Receive timeout duration
  static const Duration receiveTimeout = Duration(seconds: 10);

  /// Send timeout duration
  static const Duration sendTimeout = Duration(seconds: 10);

  /// Splash screen duration
  static const Duration splashDuration = Duration(seconds: 2);

  /// Snackbar duration
  static const Duration snackBarDuration = Duration(seconds: 3);

  /// Debounce duration for search
  static const Duration searchDebounceDuration = Duration(milliseconds: 500);

  /// Animation duration
  static const Duration animationDuration = Duration(milliseconds: 300);

  /// Session timeout duration
  static const Duration sessionTimeout = Duration(hours: 24);

  // ==================== SYNC SETTINGS ====================

  /// Sync interval duration
  static const Duration syncInterval = Duration(minutes: 5);

  /// Maximum retry attempts for sync
  static const int maxRetryAttempts = 3;

  /// Retry delay base duration
  static const Duration retryDelay = Duration(seconds: 1);

  /// Maximum items per sync batch
  static const int syncBatchSize = 50;

  /// Maximum offline days before warning
  static const int maxOfflineDays = 7;

  // ==================== PAGINATION ====================

  /// Default page size
  static const int defaultPageSize = 20;

  /// Maximum page size
  static const int maxPageSize = 100;

  /// Minimum page size
  static const int minPageSize = 10;

  /// Infinite scroll threshold
  static const double scrollThreshold = 200.0;

  // ==================== VALIDATION ====================

  /// Minimum password length
  static const int minPasswordLength = 6;

  /// Maximum password length
  static const int maxPasswordLength = 50;

  /// Minimum name length
  static const int minNameLength = 2;

  /// Maximum name length
  static const int maxNameLength = 100;

  /// Phone number length (Sri Lanka)
  static const int phoneLength = 10;

  /// NIC length (old format)
  static const int nicLengthOld = 10;

  /// NIC length (new format)
  static const int nicLengthNew = 12;

  /// Maximum notes length
  static const int maxNotesLength = 500;

  /// Maximum address length
  static const int maxAddressLength = 255;

  // ==================== TRANSACTION IDS ====================

  /// Buy transaction prefix
  static const String buyTransactionPrefix = 'BUY';

  /// Sell transaction prefix
  static const String sellTransactionPrefix = 'SELL';

  /// Stock adjustment prefix
  static const String stockTransactionPrefix = 'STK';

  /// Milling transaction prefix
  static const String millingTransactionPrefix = 'MIL';

  /// Payment transaction prefix
  static const String paymentTransactionPrefix = 'PAY';

  // ==================== WEIGHT & MEASUREMENT ====================

  /// Default weight unit
  static const String defaultWeightUnit = 'kg';

  /// Kilograms per ton
  static const double kgPerTon = 1000.0;

  /// Default bag weight (kg)
  static const double defaultBagWeight = 50.0;

  /// Maximum weight per entry (kg)
  static const double maxWeightPerEntry = 10000.0;

  /// Weight decimal places
  static const int weightDecimalPlaces = 3;

  /// Price decimal places
  static const int priceDecimalPlaces = 2;

  // ==================== MILLING ====================

  /// Default milling ratio (paddy to rice)
  static const double defaultMillingRatio = 0.65;

  /// Default bran percentage
  static const double defaultBranPercentage = 0.08;

  /// Default husk percentage
  static const double defaultHuskPercentage = 0.22;

  /// Minimum milling ratio
  static const double minMillingRatio = 0.50;

  /// Maximum milling ratio
  static const double maxMillingRatio = 0.75;

  // ==================== CURRENCY ====================

  /// Currency code
  static const String currencyCode = 'LKR';

  /// Currency symbol
  static const String currencySymbol = 'Rs.';

  /// Currency locale
  static const String currencyLocale = 'si_LK';

  // ==================== DATE & TIME FORMATS ====================

  /// Date format
  static const String dateFormat = 'yyyy-MM-dd';

  /// Time format
  static const String timeFormat = 'HH:mm';

  /// Date time format
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';

  /// Display date format
  static const String displayDateFormat = 'dd MMM yyyy';

  /// Display date time format
  static const String displayDateTimeFormat = 'dd MMM yyyy, hh:mm a';

  /// Short date format
  static const String shortDateFormat = 'dd/MM/yy';

  // ==================== LOCALE ====================

  /// Default locale
  static const Locale defaultLocale = Locale('si', 'LK');

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('si', 'LK'), // Sinhala
    Locale('en', 'US'), // English
    Locale('ta', 'LK'), // Tamil
  ];

  // ==================== FILE & MEDIA ====================

  /// Maximum file size (MB)
  static const int maxFileSizeMB = 10;

  /// Maximum image size (MB)
  static const int maxImageSizeMB = 5;

  /// Allowed image extensions
  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp'
  ];

  /// Allowed document extensions
  static const List<String> allowedDocumentExtensions = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx'
  ];

  /// Image quality for compression
  static const int imageQuality = 85;

  /// Thumbnail size
  static const int thumbnailSize = 150;

  // ==================== CACHE ====================

  /// Cache duration
  static const Duration cacheDuration = Duration(hours: 1);

  /// Maximum cache size (items)
  static const int maxCacheSize = 100;

  /// Image cache duration
  static const Duration imageCacheDuration = Duration(days: 7);

  // ==================== UI ====================

  /// Maximum lines for text
  static const int maxTextLines = 3;

  /// Keyboard height
  static const double keyboardHeight = 320.0;

  /// Bottom sheet max height ratio
  static const double bottomSheetMaxHeightRatio = 0.9;

  /// Drawer width ratio
  static const double drawerWidthRatio = 0.75;

  // ==================== REPORTS ====================

  /// Maximum days for daily report
  static const int maxDailyReportDays = 31;

  /// Maximum months for monthly report
  static const int maxMonthlyReportMonths = 12;

  /// Default report date range (days)
  static const int defaultReportDays = 7;

  // ==================== FEATURE FLAGS ====================

  /// Enable offline mode
  static const bool enableOfflineMode = true;

  /// Enable sync
  static const bool enableSync = true;

  /// Enable notifications
  static const bool enableNotifications = true;

  /// Enable biometric auth
  static const bool enableBiometric = true;

  /// Enable PDF export
  static const bool enablePdfExport = true;

  /// Enable printing
  static const bool enablePrinting = true;

  /// Debug mode (set to false for production)
  static const bool debugMode = true;
}

