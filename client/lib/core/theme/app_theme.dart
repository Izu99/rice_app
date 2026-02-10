import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

/// Application theme configuration
class AppTheme {
  AppTheme._();

  // ==================== LIGHT THEME ====================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTextStyles.fontFamily,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        onPrimary: AppColors.white,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondary: AppColors.white,
        onSecondaryContainer: AppColors.secondaryDark,
        tertiary: AppColors.tertiary,
        tertiaryContainer: AppColors.tertiarySurface,
        onTertiary: AppColors.white,
        error: AppColors.error,
        errorContainer: AppColors.errorLight,
        onError: AppColors.white,
        onErrorContainer: AppColors.errorDark,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.grey100,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        outlineVariant: AppColors.borderLight,
        shadow: AppColors.shadow,
        scrim: AppColors.barrier,
        inverseSurface: AppColors.grey900,
        onInverseSurface: AppColors.white,
        inversePrimary: AppColors.primaryLight,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.scaffoldBackground,

      // App Bar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.shadow,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: AppDimensions.iconM,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: AppDimensions.iconM,
        ),
        titleTextStyle: AppTextStyles.appBarTitle,
        toolbarHeight: AppDimensions.appBarHeight,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey500,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.labelSmall,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.primarySurface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        height: AppDimensions.bottomNavHeight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTextStyles.labelSmall.copyWith(
            color: AppColors.grey600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.primary,
              size: AppDimensions.iconM,
            );
          }
          return const IconThemeData(
            color: AppColors.grey600,
            size: AppDimensions.iconM,
          );
        }),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: AppDimensions.cardElevation,
        shadowColor: AppColors.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        ),
        color: AppColors.cardBackground,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.grey300,
          disabledForegroundColor: AppColors.grey500,
          elevation: 2,
          shadowColor: AppColors.primary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingL,
            vertical: AppDimensions.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          textStyle: AppTextStyles.button,
          minimumSize: const Size(
            AppDimensions.buttonMinWidth,
            AppDimensions.buttonHeight,
          ),
        ),
      ),

      // Filled Button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.grey300,
          disabledForegroundColor: AppColors.grey500,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingL,
            vertical: AppDimensions.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          textStyle: AppTextStyles.button,
          minimumSize: const Size(
            AppDimensions.buttonMinWidth,
            AppDimensions.buttonHeight,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.grey400,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingL,
            vertical: AppDimensions.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
          minimumSize: const Size(
            AppDimensions.buttonMinWidth,
            AppDimensions.buttonHeight,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.grey400,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
        ),
      ),

      // Icon Button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          disabledForegroundColor: AppColors.grey400,
          highlightColor: AppColors.highlightOverlay,
          padding: const EdgeInsets.all(AppDimensions.paddingS),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 8,
        highlightElevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingL,
        ),
        extendedTextStyle: AppTextStyles.button,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide.none,
        ),
        hintStyle: AppTextStyles.inputHint,
        labelStyle: AppTextStyles.inputLabel,
        errorStyle: AppTextStyles.inputError,
        helperStyle: AppTextStyles.caption,
        prefixIconColor: AppColors.grey500,
        suffixIconColor: AppColors.grey500,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        floatingLabelStyle: AppTextStyles.inputLabel.copyWith(
          color: AppColors.primary,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: AppDimensions.dividerThickness,
        space: AppDimensions.dividerHeight,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.grey100,
        disabledColor: AppColors.grey200,
        selectedColor: AppColors.primarySurface,
        secondarySelectedColor: AppColors.primarySurface,
        labelStyle: AppTextStyles.labelMedium,
        secondaryLabelStyle: AppTextStyles.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        ),
        side: BorderSide.none,
        brightness: Brightness.light,
        elevation: 0,
        pressElevation: 2,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.dialogBackground,
        elevation: 24,
        shadowColor: AppColors.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.dialogRadius),
        ),
        titleTextStyle: AppTextStyles.h5,
        contentTextStyle: AppTextStyles.bodyMedium,
        actionsPadding: const EdgeInsets.all(AppDimensions.paddingM),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bottomSheetBackground,
        elevation: 8,
        shadowColor: AppColors.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.bottomSheetRadius),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.grey300,
        dragHandleSize: Size(
          AppDimensions.bottomSheetHandleWidth,
          AppDimensions.bottomSheetHandleHeight,
        ),
        modalBackgroundColor: AppColors.bottomSheetBackground,
        modalElevation: 8,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.grey800,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.snackbarRadius),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        actionTextColor: AppColors.primaryLight,
        insetPadding: const EdgeInsets.all(AppDimensions.snackbarMargin),
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.grey600,
        labelStyle: AppTextStyles.tabLabel.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.tabLabel,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 3,
          ),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.divider,
        overlayColor: WidgetStateProperty.all(AppColors.primarySurface),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.grey200,
        circularTrackColor: AppColors.grey200,
        linearMinHeight: AppDimensions.linearProgressHeight,
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.grey300,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withOpacity(0.12),
        valueIndicatorColor: AppColors.primary,
        valueIndicatorTextStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.white,
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.grey400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight.withOpacity(0.5);
          }
          return AppColors.grey300;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.white),
        side: const BorderSide(color: AppColors.grey400, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
        ),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.grey400;
        }),
      ),

      // List Tile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimensions.listItemPaddingH,
          vertical: AppDimensions.listItemPaddingV,
        ),
        minVerticalPadding: AppDimensions.paddingS,
        horizontalTitleGap: AppDimensions.paddingM,
        minLeadingWidth: AppDimensions.iconM,
        iconColor: AppColors.grey600,
        textColor: AppColors.textPrimary,
        dense: false,
        enableFeedback: true,
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.grey800,
          borderRadius: BorderRadius.circular(AppDimensions.tooltipRadius),
        ),
        textStyle: AppTextStyles.tooltip,
        padding: const EdgeInsets.all(AppDimensions.tooltipPadding),
        waitDuration: const Duration(milliseconds: 500),
        showDuration: const Duration(seconds: 2),
      ),

      // Badge
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.error,
        textColor: AppColors.white,
        textStyle: AppTextStyles.badge,
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingS,
        ),
      ),

      // Drawer
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.white,
        elevation: 16,
        shadowColor: AppColors.shadow,
        surfaceTintColor: Colors.transparent,
        width: AppDimensions.drawerWidth,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(AppDimensions.radiusL),
          ),
        ),
      ),

      // Date Picker
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: AppColors.white,
        dayStyle: AppTextStyles.bodyMedium,
        weekdayStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.grey600,
        ),
        yearStyle: AppTextStyles.bodyMedium,
        todayBorder: const BorderSide(color: AppColors.primary),
        todayForegroundColor: WidgetStateProperty.all(AppColors.primary),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.white;
          }
          return AppColors.textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
      ),

      // Time Picker
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.white,
        hourMinuteTextColor: AppColors.textPrimary,
        dayPeriodTextColor: AppColors.textPrimary,
        dialHandColor: AppColors.primary,
        dialBackgroundColor: AppColors.grey100,
        dialTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.white;
          }
          return AppColors.textPrimary;
        }),
        entryModeIconColor: AppColors.grey600,
        hourMinuteColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primarySurface;
          }
          return AppColors.grey100;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
      ),

      // Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // Visual Density
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // Splash Factory
      splashFactory: InkRipple.splashFactory,

      // Highlight Color
      highlightColor: AppColors.highlightOverlay,

      // Splash Color
      splashColor: AppColors.splashOverlay,

      // Hover Color
      hoverColor: AppColors.hoverOverlay,

      // Focus Color
      focusColor: AppColors.focusOverlay,
    );
  }

  // ==================== DARK THEME ====================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTextStyles.fontFamily,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        primaryContainer: AppColors.primaryDark,
        onPrimary: AppColors.black,
        onPrimaryContainer: AppColors.primaryLighter,
        secondary: AppColors.secondaryLight,
        secondaryContainer: AppColors.secondaryDark,
        onSecondary: AppColors.black,
        tertiary: AppColors.tertiaryLight,
        error: AppColors.error,
        errorContainer: AppColors.errorDark,
        onError: AppColors.black,
        surface: Color(0xFF1E1E1E),
        onSurface: AppColors.white,
        surfaceContainerHighest: Color(0xFF2C2C2C),
        onSurfaceVariant: AppColors.grey400,
        outline: AppColors.grey700,
        outlineVariant: AppColors.grey800,
        shadow: Colors.black,
        scrim: Colors.black87,
        inverseSurface: AppColors.grey100,
        onInverseSurface: AppColors.grey900,
        inversePrimary: AppColors.primaryDark,
      ),

      // Scaffold
      scaffoldBackgroundColor: const Color(0xFF121212),

      // App Bar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(
          color: AppColors.white,
          size: AppDimensions.iconM,
        ),
        titleTextStyle: AppTextStyles.appBarTitle.copyWith(
          color: AppColors.white,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: const Color(0xFF1E1E1E),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: AppDimensions.cardElevation,
        shadowColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        ),
        color: const Color(0xFF1E1E1E),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(
            color: AppColors.primaryLight,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        hintStyle: AppTextStyles.inputHint.copyWith(
          color: AppColors.grey500,
        ),
        labelStyle: AppTextStyles.inputLabel.copyWith(
          color: AppColors.grey400,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2C2C2C),
        thickness: AppDimensions.dividerThickness,
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.bottomSheetRadius),
          ),
        ),
        dragHandleColor: AppColors.grey600,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.dialogRadius),
        ),
        titleTextStyle: AppTextStyles.h5.copyWith(color: AppColors.white),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.grey300,
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.grey200,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.grey900,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.snackbarRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Visual Density
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  // ==================== THEME MODE HELPERS ====================

  /// Get theme based on brightness
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }

  /// Get system overlay style for light theme
  static SystemUiOverlayStyle get lightSystemOverlayStyle {
    return SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    );
  }

  /// Get system overlay style for dark theme
  static SystemUiOverlayStyle get darkSystemOverlayStyle {
    return SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: const Color(0xFF1E1E1E),
      systemNavigationBarIconBrightness: Brightness.light,
    );
  }
}
