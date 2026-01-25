import 'package:flutter/material.dart';

/// Application color palette
/// Green/White/Grey theme for Rice Mill ERP
class AppColors {
  AppColors._();

  // ==================== PRIMARY COLORS (GREEN THEME) ====================

  /// Primary green - Main brand color
  static const Color primary = Color(0xFF2E7D32);

  /// Primary light - Hover/Focus states
  static const Color primaryLight = Color(0xFF4CAF50);

  /// Primary lighter - Very light accent
  static const Color primaryLighter = Color(0xFF81C784);

  /// Primary dark - Pressed states
  static const Color primaryDark = Color(0xFF1B5E20);

  /// Primary darker - Deep accent
  static const Color primaryDarker = Color(0xFF0D3B0F);

  /// Primary surface - Background with primary tint
  static const Color primarySurface = Color(0xFFE8F5E9);

  /// Primary container - Container background
  static const Color primaryContainer = Color(0xFFC8E6C9);

  /// Admin primary color
  static const Color adminPrimary = Color(0xFF2E7D32);

  // ==================== SECONDARY COLORS (TEAL) ====================

  /// Secondary color - Accent color
  static const Color secondary = Color(0xFF00897B);

  /// Secondary light
  static const Color secondaryLight = Color(0xFF26A69A);

  /// Secondary lighter
  static const Color secondaryLighter = Color(0xFF80CBC4);

  /// Secondary dark
  static const Color secondaryDark = Color(0xFF00695C);

  /// Secondary surface
  static const Color secondarySurface = Color(0xFFE0F2F1);

  /// Secondary container
  static const Color secondaryContainer = Color(0xFFB2DFDB);

  // ==================== TERTIARY COLORS (AMBER) ====================

  /// Tertiary color - For highlights
  static const Color tertiary = Color(0xFFFF8F00);

  /// Tertiary light
  static const Color tertiaryLight = Color(0xFFFFB300);

  /// Tertiary dark
  static const Color tertiaryDark = Color(0xFFFF6F00);

  /// Tertiary surface
  static const Color tertiarySurface = Color(0xFFFFF8E1);

  // ==================== NEUTRAL COLORS (GREY SCALE) ====================

  /// Pure white
  static const Color white = Color(0xFFFFFFFF);

  /// Pure black
  static const Color black = Color(0xFF000000);

  /// Grey scale
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ==================== SEMANTIC COLORS ====================

  // Success (Green)
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color successDark = Color(0xFF388E3C);
  static const Color onSuccess = Color(0xFFFFFFFF);

  // Warning (Orange/Amber)
  static const Color warning = Color(0xFFFFA726);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color warningDark = Color(0xFFF57C00);
  static const Color onWarning = Color(0xFF000000);

  // Error (Red)
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color errorDark = Color(0xFFC62828);
  static const Color onError = Color(0xFFFFFFFF);

  // Info (Blue)
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);
  static const Color infoDark = Color(0xFF1976D2);
  static const Color onInfo = Color(0xFFFFFFFF);

  // ==================== BACKGROUND COLORS ====================

  /// Main background color
  static const Color background = Color(0xFFF5F5F5);

  /// Surface color (cards, sheets)
  static const Color surface = Color(0xFFFFFFFF);

  /// Scaffold background
  static const Color scaffoldBackground = Color(0xFFFAFAFA);

  /// Canvas color
  static const Color canvas = Color(0xFFFFFFFF);

  /// Dialog background
  static const Color dialogBackground = Color(0xFFFFFFFF);

  /// Bottom sheet background
  static const Color bottomSheetBackground = Color(0xFFFFFFFF);

  /// Card background
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ==================== TEXT COLORS ====================

  /// Primary text color
  static const Color textPrimary = Color(0xFF212121);

  /// Secondary text color
  static const Color textSecondary = Color(0xFF757575);

  /// Tertiary/Hint text color
  static const Color textHint = Color(0xFFBDBDBD);

  /// Disabled text color
  static const Color textDisabled = Color(0xFF9E9E9E);

  /// Text on primary color
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Text on secondary color
  static const Color textOnSecondary = Color(0xFFFFFFFF);

  /// Text on error color
  static const Color textOnError = Color(0xFFFFFFFF);

  /// Tertiary text color
  static const Color textTertiary = Color(0xFF9E9E9E);

  /// Inverse text color
  static const Color textInverse = Color(0xFFFFFFFF);

  /// Link text color
  static const Color textLink = Color(0xFF1976D2);

  /// Accent color
  static const Color accent = Color(0xFFFFB300);

  /// Rice color (alias for riceAccent)
  static const Color riceColor = riceAccent;

  /// Paddy color (alias for paddy)
  static const Color paddyColor = paddy;

  // ==================== BORDER & DIVIDER COLORS ====================

  /// Default border color
  static const Color border = Color(0xFFE0E0E0);

  /// Light border
  static const Color borderLight = Color(0xFFEEEEEE);

  /// Focus border
  static const Color borderFocus = Color(0xFF2E7D32);

  /// Error border
  static const Color borderError = Color(0xFFE53935);

  /// Divider color
  static const Color divider = Color(0xFFEEEEEE);

  /// Divider dark
  static const Color dividerDark = Color(0xFFBDBDBD);

  // ==================== SHADOW COLORS ====================

  /// Default shadow
  static const Color shadow = Color(0x1A000000);

  /// Light shadow
  static const Color shadowLight = Color(0x0D000000);

  /// Dark shadow
  static const Color shadowDark = Color(0x33000000);

  // ==================== OVERLAY COLORS ====================

  /// Barrier/Scrim color
  static const Color barrier = Color(0x80000000);

  /// Light overlay
  static const Color overlayLight = Color(0x0DFFFFFF);

  /// Dark overlay
  static const Color overlayDark = Color(0x0D000000);

  /// Hover overlay
  static const Color hoverOverlay = Color(0x0A000000);

  /// Focus overlay
  static const Color focusOverlay = Color(0x1A000000);

  /// Splash overlay
  static const Color splashOverlay = Color(0x1A000000);

  /// Highlight overlay
  static const Color highlightOverlay = Color(0x0A000000);

  // ==================== SYNC STATUS COLORS ====================

  /// Sync pending
  static const Color syncPending = Color(0xFFFFA726);

  /// Sync in progress
  static const Color syncProgress = Color(0xFF2196F3);

  /// Sync complete
  static const Color syncComplete = Color(0xFF4CAF50);

  /// Sync error
  static const Color syncError = Color(0xFFE53935);

  /// Offline status
  static const Color syncOffline = Color(0xFF9E9E9E);

  // ==================== ACTION CARD COLORS ====================

  /// Buy action card
  static const Color cardBuy = Color(0xFF4CAF50);
  static const Color cardBuyDark = Color(0xFF388E3C);

  /// Sell action card
  static const Color cardSell = Color(0xFF2196F3);
  static const Color cardSellDark = Color(0xFF1976D2);

  /// Stock action card
  static const Color cardStock = Color(0xFFFF9800);
  static const Color cardStockDark = Color(0xFFF57C00);

  /// Report action card
  static const Color cardReport = Color(0xFF9C27B0);
  static const Color cardReportDark = Color(0xFF7B1FA2);

  /// Milling action card
  static const Color cardMilling = Color(0xFF795548);
  static const Color cardMillingDark = Color(0xFF5D4037);

  // ==================== ITEM TYPE COLORS ====================

  /// Paddy color
  static const Color paddy = Color(0xFFFFA726);
  static const Color paddyLight = Color(0xFFFFF3E0);

  /// Rice color
  static const Color rice = Color(0xFFFFFFFF);
  static const Color riceAccent = Color(0xFF4CAF50);

  /// Bran color
  static const Color bran = Color(0xFF8D6E63);
  static const Color branLight = Color(0xFFEFEBE9);

  /// Husk color
  static const Color husk = Color(0xFFA1887F);
  static const Color huskLight = Color(0xFFD7CCC8);

  // ==================== STATUS COLORS ====================

  /// Active/Online status
  static const Color statusActive = Color(0xFF4CAF50);

  /// Inactive/Offline status
  static const Color statusInactive = Color(0xFF9E9E9E);

  /// Pending status
  static const Color statusPending = Color(0xFFFFA726);

  /// Processing status
  static const Color statusProcessing = Color(0xFF2196F3);

  /// Completed status
  static const Color statusCompleted = Color(0xFF4CAF50);

  /// Cancelled status
  static const Color statusCancelled = Color(0xFFE53935);

  // ==================== CHART COLORS ====================

  static const List<Color> chartColors = [
    Color(0xFF4CAF50), // Green
    Color(0xFF2196F3), // Blue
    Color(0xFFFFA726), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFFE53935), // Red
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFFFF5722), // Deep Orange
  ];

  // ==================== GRADIENTS ====================

  /// Primary gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  /// Primary vertical gradient
  static const LinearGradient primaryVerticalGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryLight, primary],
  );

  /// Secondary gradient
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, secondary],
  );

  /// Success gradient
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
  );

  /// Danger gradient
  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF5350), Color(0xFFD32F2F)],
  );

  /// Dark overlay gradient (for images)
  static const LinearGradient darkOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0x99000000)],
  );

  /// Card shine gradient
  static const LinearGradient cardShineGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1AFFFFFF),
      Color(0x00FFFFFF),
      Color(0x00FFFFFF),
      Color(0x0DFFFFFF),
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  // ==================== HELPER METHODS ====================

  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Get status color based on string
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'online':
      case 'completed':
      case 'success':
      case 'paid':
        return statusCompleted;
      case 'inactive':
      case 'offline':
        return statusInactive;
      case 'pending':
      case 'waiting':
        return statusPending;
      case 'processing':
      case 'in_progress':
        return statusProcessing;
      case 'cancelled':
      case 'failed':
      case 'error':
        return statusCancelled;
      default:
        return statusInactive;
    }
  }

  /// Get item type color
  static Color getItemTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'paddy':
        return paddy;
      case 'rice':
        return riceAccent;
      case 'bran':
        return bran;
      case 'husk':
        return husk;
      default:
        return grey500;
    }
  }

  /// Get chart color by index
  static Color getChartColor(int index) {
    return chartColors[index % chartColors.length];
  }

  /// Darken a color
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final darkened =
        hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }

  /// Lighten a color
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightened =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lightened.toColor();
  }
}

