import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Application text styles
class AppTextStyles {
  AppTextStyles._();

  // ==================== FONT FAMILY ====================

  /// Primary font family
  static const String fontFamily = 'Poppins';

  /// Secondary font family (for numbers)
  static const String fontFamilyMono = 'RobotoMono';

  /// Sinhala font family
  static const String fontFamilySinhala = 'NotoSansSinhala';

  // ==================== FONT WEIGHTS ====================

  static const FontWeight weightThin = FontWeight.w100;
  static const FontWeight weightExtraLight = FontWeight.w200;
  static const FontWeight weightLight = FontWeight.w300;
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;
  static const FontWeight weightExtraBold = FontWeight.w800;
  static const FontWeight weightBlack = FontWeight.w900;

  // ==================== DISPLAY STYLES ====================

  /// Display Large - 57sp
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 57,
    fontWeight: weightRegular,
    letterSpacing: -0.25,
    height: 1.12,
    color: AppColors.textPrimary,
  );

  /// Display Medium - 45sp
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 45,
    fontWeight: weightRegular,
    letterSpacing: 0,
    height: 1.16,
    color: AppColors.textPrimary,
  );

  /// Display Small - 36sp
  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: weightRegular,
    letterSpacing: 0,
    height: 1.22,
    color: AppColors.textPrimary,
  );

  // ==================== HEADLINE STYLES ====================

  /// Headline Large - 32sp
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: weightBold,
    letterSpacing: 0,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  /// Headline Medium - 28sp
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: weightBold,
    letterSpacing: 0,
    height: 1.29,
    color: AppColors.textPrimary,
  );

  /// Headline Small - 24sp
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: weightSemiBold,
    letterSpacing: 0,
    height: 1.33,
    color: AppColors.textPrimary,
  );

  // ==================== HEADING SHORTCUTS (H1-H6) ====================

  /// H1 - 32sp Bold
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: weightBold,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  /// H2 - 28sp Bold
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: weightBold,
    letterSpacing: -0.25,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  /// H3 - 24sp SemiBold
  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: weightSemiBold,
    letterSpacing: 0,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  /// H4 - 20sp SemiBold
  static const TextStyle h4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: weightSemiBold,
    letterSpacing: 0.15,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  /// H5 - 18sp SemiBold
  static const TextStyle h5 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: weightSemiBold,
    letterSpacing: 0.15,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  /// H6 - 16sp SemiBold
  static const TextStyle h6 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: weightSemiBold,
    letterSpacing: 0.15,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  // ==================== TITLE STYLES ====================

  /// Title Large - 22sp
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: weightMedium,
    letterSpacing: 0,
    height: 1.27,
    color: AppColors.textPrimary,
  );

  /// Title Medium - 16sp
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: weightMedium,
    letterSpacing: 0.15,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Title Small - 14sp
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: weightMedium,
    letterSpacing: 0.1,
    height: 1.43,
    color: AppColors.textPrimary,
  );

  // ==================== BODY STYLES ====================

  /// Body Large - 16sp
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: weightRegular,
    letterSpacing: 0.5,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Body Medium - 14sp (Default body text)
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: weightRegular,
    letterSpacing: 0.25,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Body Small - 12sp
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: weightRegular,
    letterSpacing: 0.4,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // ==================== LABEL STYLES ====================

  /// Label Large - 14sp Medium
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: weightMedium,
    letterSpacing: 0.1,
    height: 1.43,
    color: AppColors.textPrimary,
  );

  /// Label Medium - 12sp Medium
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: weightMedium,
    letterSpacing: 0.5,
    height: 1.33,
    color: AppColors.textPrimary,
  );

  /// Label Small - 10sp Medium
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: weightMedium,
    letterSpacing: 0.5,
    height: 1.6,
    color: AppColors.textSecondary,
  );

  // ==================== BUTTON STYLES ====================

  /// Button text style
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: weightSemiBold,
    letterSpacing: 0.5,
    height: 1.43,
    color: AppColors.white,
  );

  /// Button small text style
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: weightSemiBold,
    letterSpacing: 0.5,
    height: 1.33,
    color: AppColors.white,
  );

  /// Button large text style
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: weightSemiBold,
    letterSpacing: 0.5,
    height: 1.5,
    color: AppColors.white,
  );

  // ==================== CAPTION & OVERLINE ====================

  /// Caption - 12sp
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: weightRegular,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.textSecondary,
  );

  /// Overline - 10sp
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: weightMedium,
    letterSpacing: 1.5,
    height: 1.6,
    color: AppColors.textSecondary,
  );

  // ==================== NUMBER STYLES (FOR KEYBOARD/PRICES) ====================

  /// Number large - For keyboard display
  static const TextStyle numberLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: weightBold,
    letterSpacing: 0,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  /// Number extra large
  static const TextStyle numberXL = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: weightBold,
    letterSpacing: 0,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  /// Number medium
  static const TextStyle numberMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: weightSemiBold,
    letterSpacing: 0,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  /// Number small
  static const TextStyle numberSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: weightMedium,
    letterSpacing: 0,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // ==================== PRICE STYLES ====================

  /// Price large
  static const TextStyle priceLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: weightBold,
    letterSpacing: 0,
    height: 1.2,
    color: AppColors.primary,
  );

  /// Price medium
  static const TextStyle priceMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: weightBold,
    letterSpacing: 0,
    height: 1.3,
    color: AppColors.primary,
  );

  /// Price small
  static const TextStyle priceSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: weightSemiBold,
    letterSpacing: 0,
    height: 1.4,
    color: AppColors.primary,
  );

  /// Price strikethrough (original price)
  static const TextStyle priceStrike = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: weightRegular,
    letterSpacing: 0,
    height: 1.4,
    color: AppColors.textSecondary,
    decoration: TextDecoration.lineThrough,
  );

  // ==================== LINK STYLE ====================

  /// Link text style
  static const TextStyle link = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: weightMedium,
    letterSpacing: 0.25,
    height: 1.5,
    color: AppColors.textLink,
    decoration: TextDecoration.underline,
  );

  // ==================== INPUT STYLES ====================

  /// Input text style
  static const TextStyle input = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: weightRegular,
    letterSpacing: 0.15,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Input hint style
  static const TextStyle inputHint = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: weightRegular,
    letterSpacing: 0.15,
    height: 1.5,
    color: AppColors.textHint,
  );

  /// Input label style
  static const TextStyle inputLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: weightMedium,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.textSecondary,
  );

  /// Input error style
  static const TextStyle inputError = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: weightRegular,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.error,
  );

  // ==================== BADGE STYLE ====================

  /// Badge text style
  static const TextStyle badge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: weightBold,
    letterSpacing: 0.5,
    height: 1.0,
    color: AppColors.white,
  );

  // ==================== APP BAR STYLE ====================

  /// App bar title style
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: weightSemiBold,
    letterSpacing: 0.15,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // ==================== TAB STYLE ====================

  /// Tab label style
  static const TextStyle tabLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: weightMedium,
    letterSpacing: 0.5,
    height: 1.43,
  );

  // ==================== TOOLTIP STYLE ====================

  /// Tooltip text style
  static const TextStyle tooltip = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: weightRegular,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.white,
  );

  // ==================== HELPER METHODS ====================

  /// Get text style with custom color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Get text style with primary color
  static TextStyle primary(TextStyle style) {
    return style.copyWith(color: AppColors.primary);
  }

  /// Get text style with secondary text color
  static TextStyle secondary(TextStyle style) {
    return style.copyWith(color: AppColors.textSecondary);
  }

  /// Get text style with error color
  static TextStyle error(TextStyle style) {
    return style.copyWith(color: AppColors.error);
  }

  /// Get text style with success color
  static TextStyle success(TextStyle style) {
    return style.copyWith(color: AppColors.success);
  }

  /// Get text style with white color
  static TextStyle white(TextStyle style) {
    return style.copyWith(color: AppColors.white);
  }

  /// Get bold version of text style
  static TextStyle bold(TextStyle style) {
    return style.copyWith(fontWeight: weightBold);
  }

  /// Get medium version of text style
  static TextStyle medium(TextStyle style) {
    return style.copyWith(fontWeight: weightMedium);
  }

  /// Get underlined version of text style
  static TextStyle underline(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.underline);
  }

  /// Get italic version of text style
  static TextStyle italic(TextStyle style) {
    return style.copyWith(fontStyle: FontStyle.italic);
  }
}

