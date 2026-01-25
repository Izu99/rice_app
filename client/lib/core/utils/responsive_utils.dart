import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes
class ResponsiveUtils {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Check if screen is mobile size
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if screen is desktop size
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get responsive padding based on screen size
  static double getResponsivePadding(
    BuildContext context, {
    double mobile = 16.0,
    double tablet = 24.0,
    double desktop = 32.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context, {
    double mobile = 14.0,
    double tablet = 16.0,
    double desktop = 18.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Get grid cross axis count based on screen width
  static int getGridCrossAxisCount(
    BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Get responsive spacing
  static double getResponsiveSpacing(
    BuildContext context, {
    double mobile = 8.0,
    double tablet = 12.0,
    double desktop = 16.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Get responsive card width
  static double getResponsiveCardWidth(
    BuildContext context, {
    double mobileWidthFactor = 0.9,
    double tabletWidthFactor = 0.7,
    double desktopWidthFactor = 0.5,
  }) {
    final width = screenWidth(context);
    if (isMobile(context)) return width * mobileWidthFactor;
    if (isTablet(context)) return width * tabletWidthFactor;
    return width * desktopWidthFactor;
  }

  /// Get responsive value based on screen size
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    required T tablet,
    required T desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Calculate grid child aspect ratio based on screen width
  static double getGridChildAspectRatio(
    BuildContext context, {
    double mobile = 1.0,
    double tablet = 1.2,
    double desktop = 1.5,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Get bottom navigation height
  static double getBottomNavHeight(BuildContext context) {
    return isMobile(context) ? 70.0 : 80.0;
  }

  /// Get app bar height
  static double getAppBarHeight(BuildContext context) {
    return isMobile(context) ? 56.0 : 64.0;
  }

  /// Scale text for better readability on different screens
  static TextStyle scaleTextStyle(
    BuildContext context,
    TextStyle style, {
    double mobileFactor = 1.0,
    double tabletFactor = 1.1,
    double desktopFactor = 1.2,
  }) {
    double factor = mobileFactor;
    if (isTablet(context)) factor = tabletFactor;
    if (isDesktop(context)) factor = desktopFactor;

    return style.copyWith(fontSize: (style.fontSize ?? 14) * factor);
  }

  /// Get max content width for centering on large screens
  static double getMaxContentWidth(BuildContext context) {
    return isDesktop(context) ? 1200.0 : double.infinity;
  }

  /// Wrap content with max width for desktop views
  static Widget constrainContent(BuildContext context, Widget child) {
    if (isDesktop(context)) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: getMaxContentWidth(context)),
          child: child,
        ),
      );
    }
    return child;
  }
}

