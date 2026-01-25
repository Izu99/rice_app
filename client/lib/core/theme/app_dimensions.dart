import 'package:flutter/material.dart';

/// Application dimensions and spacing constants
class AppDimensions {
  AppDimensions._();

  // ==================== SPACING / PADDING / MARGIN ====================

  /// Extra extra small spacing (2.0)
  static const double spaceXXS = 2.0;

  /// Extra small spacing (4.0)
  static const double spaceXS = 4.0;

  /// Small spacing (8.0)
  static const double spaceS = 8.0;

  /// Medium spacing (12.0)
  static const double spaceM = 12.0;

  /// Default spacing (16.0)
  static const double space = 16.0;

  /// Large spacing (24.0)
  static const double spaceL = 24.0;

  /// Extra large spacing (32.0)
  static const double spaceXL = 32.0;

  /// Extra extra large spacing (48.0)
  static const double spaceXXL = 48.0;

  /// Huge spacing (64.0)
  static const double spaceHuge = 64.0;

  // Padding aliases
  static const double paddingXXS = spaceXXS;
  static const double paddingXS = spaceXS;
  static const double paddingS = spaceS;
  static const double paddingM = space;
  static const double paddingMedium = paddingM; // Alias for paddingM
  static const double paddingL = spaceL;
  static const double paddingXL = spaceXL;
  static const double paddingXXL = spaceXXL;

  // Margin aliases
  static const double marginXS = spaceXS;
  static const double marginS = spaceS;
  static const double marginM = space;
  static const double marginL = spaceL;
  static const double marginXL = spaceXL;

  // ==================== BORDER RADIUS ====================

  /// Extra small radius (4.0)
  static const double radiusXS = 4.0;

  /// Small radius (8.0)
  static const double radiusS = 8.0;

  /// Medium radius (12.0)
  static const double radiusM = 12.0;

  /// Default radius (16.0)
  static const double radius = 16.0;

  /// Large radius (20.0)
  static const double radiusL = 20.0;

  /// Extra large radius (24.0)
  static const double radiusXL = 24.0;

  /// Extra extra large radius (32.0)
  static const double radiusXXL = 32.0;

  /// Circular/Round radius (100.0)
  static const double radiusRound = 100.0;

  /// Full circular radius (9999.0)
  static const double radiusFull = 9999.0;

  // Border radius objects
  static BorderRadius get borderRadiusXS => BorderRadius.circular(radiusXS);
  static BorderRadius get borderRadiusS => BorderRadius.circular(radiusS);
  static BorderRadius get borderRadiusM => BorderRadius.circular(radiusM);
  static BorderRadius get borderRadius => BorderRadius.circular(radius);
  static BorderRadius get borderRadiusL => BorderRadius.circular(radiusL);
  static BorderRadius get borderRadiusXL => BorderRadius.circular(radiusXL);
  static BorderRadius get borderRadiusRound =>
      BorderRadius.circular(radiusRound);

  // ==================== BORDER WIDTH ====================

  /// Thin border (0.5)
  static const double borderThin = 0.5;

  /// Default border (1.0)
  static const double border = 1.0;

  /// Medium border (1.5)
  static const double borderMedium = 1.5;

  /// Thick border (2.0)
  static const double borderThick = 2.0;

  /// Extra thick border (3.0)
  static const double borderExtraThick = 3.0;

  // ==================== ICON SIZES ====================

  /// Extra extra small icon (12.0)
  static const double iconXXS = 12.0;

  /// Extra small icon (16.0)
  static const double iconXS = 16.0;

  /// Small icon (20.0)
  static const double iconS = 20.0;

  /// Medium icon (24.0) - Default
  static const double iconM = 24.0;

  /// Large icon (32.0)
  static const double iconL = 32.0;

  /// Extra large icon (48.0)
  static const double iconXL = 48.0;

  /// Extra extra large icon (64.0)
  static const double iconXXL = 64.0;

  /// Huge icon (80.0)
  static const double iconHuge = 80.0;

  /// Giant icon (120.0)
  static const double iconGiant = 120.0;

  // ==================== BUTTON SIZES ====================

  /// Small button height (36.0)
  static const double buttonHeightS = 36.0;

  /// Medium button height (44.0)
  static const double buttonHeightM = 44.0;

  /// Default button height (48.0)
  static const double buttonHeight = 48.0;

  /// Large button height (56.0)
  static const double buttonHeightL = 56.0;

  /// Extra large button height (64.0)
  static const double buttonHeightXL = 64.0;

  /// Minimum button width (88.0)
  static const double buttonMinWidth = 88.0;

  /// Icon button size (40.0)
  static const double iconButtonSize = 40.0;

  /// Small icon button size (32.0)
  static const double iconButtonSizeS = 32.0;

  /// Large icon button size (48.0)
  static const double iconButtonSizeL = 48.0;

  /// FAB size (56.0)
  static const double fabSize = 56.0;

  /// Mini FAB size (40.0)
  static const double fabSizeMini = 40.0;

  /// Extended FAB height (48.0)
  static const double fabExtendedHeight = 48.0;

  // ==================== INPUT SIZES ====================

  /// Small input height (40.0)
  static const double inputHeightS = 40.0;

  /// Default input height (48.0)
  static const double inputHeight = 48.0;

  /// Large input height (56.0)
  static const double inputHeightL = 56.0;

  /// Search bar height (48.0)
  static const double searchBarHeight = 48.0;

  /// Text area minimum height (100.0)
  static const double textAreaMinHeight = 100.0;

  // ==================== CARD SIZES ====================

  /// Card elevation (2.0)
  static const double cardElevation = 2.0;

  /// Card elevation high (4.0)
  static const double cardElevationHigh = 4.0;

  /// Card radius (12.0)
  static const double cardRadius = 12.0;

  /// Card padding (16.0)
  static const double cardPadding = 16.0;

  /// Small card height (80.0)
  static const double cardHeightS = 80.0;

  /// Medium card height (120.0)
  static const double cardHeightM = 120.0;

  /// Large card height (160.0)
  static const double cardHeightL = 160.0;

  // ==================== ACTION CARD (DASHBOARD) ====================

  /// Action card height (160.0)
  static const double actionCardHeight = 160.0;

  /// Action card height small (120.0)
  static const double actionCardHeightS = 120.0;

  /// Action card icon size (48.0)
  static const double actionCardIconSize = 48.0;

  // ==================== AVATAR SIZES ====================

  /// Extra small avatar (24.0)
  static const double avatarXS = 24.0;

  /// Small avatar (32.0)
  static const double avatarS = 32.0;

  /// Medium avatar (40.0)
  static const double avatarM = 40.0;

  /// Default avatar (48.0)
  static const double avatar = 48.0;

  /// Large avatar (64.0)
  static const double avatarL = 64.0;

  /// Extra large avatar (80.0)
  static const double avatarXL = 80.0;

  /// Huge avatar (120.0)
  static const double avatarHuge = 120.0;

  // ==================== NAVIGATION ====================

  /// App bar height (56.0)
  static const double appBarHeight = 56.0;

  /// App bar height large (64.0)
  static const double appBarHeightL = 64.0;

  /// Bottom navigation height (60.0)
  static const double bottomNavHeight = 60.0;

  /// Bottom navigation height with labels (80.0)
  static const double bottomNavHeightWithLabels = 80.0;

  /// Tab bar height (48.0)
  static const double tabBarHeight = 48.0;

  /// Drawer width (280.0)
  static const double drawerWidth = 280.0;

  /// Drawer width ratio (0.75)
  static const double drawerWidthRatio = 0.75;

  // ==================== KEYBOARD ====================

  /// Keyboard key size (72.0)
  static const double keyboardKeySize = 72.0;

  /// Keyboard key size small (60.0)
  static const double keyboardKeySizeS = 60.0;

  /// Keyboard height (320.0)
  static const double keyboardHeight = 320.0;

  /// Keyboard height compact (280.0)
  static const double keyboardHeightCompact = 280.0;

  /// Keyboard padding (8.0)
  static const double keyboardPadding = 8.0;

  // ==================== BOTTOM SHEET ====================

  /// Bottom sheet handle width (40.0)
  static const double bottomSheetHandleWidth = 40.0;

  /// Bottom sheet handle height (4.0)
  static const double bottomSheetHandleHeight = 4.0;

  /// Bottom sheet max height ratio (0.9)
  static const double bottomSheetMaxHeightRatio = 0.9;

  /// Bottom sheet radius (24.0)
  static const double bottomSheetRadius = 24.0;

  // ==================== DIALOG ====================

  /// Dialog radius (16.0)
  static const double dialogRadius = 16.0;

  /// Dialog max width (400.0)
  static const double dialogMaxWidth = 400.0;

  /// Dialog padding (24.0)
  static const double dialogPadding = 24.0;

  // ==================== LIST ITEM ====================

  /// List item height (56.0)
  static const double listItemHeight = 56.0;

  /// List item height small (48.0)
  static const double listItemHeightS = 48.0;

  /// List item height large (72.0)
  static const double listItemHeightL = 72.0;

  /// List item padding horizontal (16.0)
  static const double listItemPaddingH = 16.0;

  /// List item padding vertical (12.0)
  static const double listItemPaddingV = 12.0;

  // ==================== DIVIDER ====================

  /// Divider height (1.0)
  static const double dividerHeight = 1.0;

  /// Divider indent (16.0)
  static const double dividerIndent = 16.0;

  /// Divider thickness (1.0)
  static const double dividerThickness = 1.0;

  // ==================== PROGRESS INDICATOR ====================

  /// Progress indicator size (24.0)
  static const double progressSize = 24.0;

  /// Progress indicator size small (16.0)
  static const double progressSizeS = 16.0;

  /// Progress indicator size large (48.0)
  static const double progressSizeL = 48.0;

  /// Progress indicator stroke width (3.0)
  static const double progressStrokeWidth = 3.0;

  /// Linear progress height (4.0)
  static const double linearProgressHeight = 4.0;

  // ==================== CHIP ====================

  /// Chip height (32.0)
  static const double chipHeight = 32.0;

  /// Chip height small (24.0)
  static const double chipHeightS = 24.0;

  /// Chip padding horizontal (12.0)
  static const double chipPaddingH = 12.0;

  /// Chip spacing (8.0)
  static const double chipSpacing = 8.0;

  // ==================== BADGE ====================

  /// Badge size (20.0)
  static const double badgeSize = 20.0;

  /// Badge size small (16.0)
  static const double badgeSizeS = 16.0;

  /// Badge size large (24.0)
  static const double badgeSizeL = 24.0;

  // ==================== TOOLTIP ====================

  /// Tooltip padding (8.0)
  static const double tooltipPadding = 8.0;

  /// Tooltip radius (4.0)
  static const double tooltipRadius = 4.0;

  // ==================== SNACKBAR ====================

  /// Snackbar margin (16.0)
  static const double snackbarMargin = 16.0;

  /// Snackbar radius (8.0)
  static const double snackbarRadius = 8.0;

  // ==================== IMAGE ====================

  /// Thumbnail size small (48.0)
  static const double thumbnailS = 48.0;

  /// Thumbnail size medium (80.0)
  static const double thumbnailM = 80.0;

  /// Thumbnail size large (120.0)
  static const double thumbnailL = 120.0;

  /// Image preview height (200.0)
  static const double imagePreviewHeight = 200.0;

  // ==================== SCROLL ====================

  /// Scroll threshold for pagination (200.0)
  static const double scrollThreshold = 200.0;

  /// Scroll physics bounce (0.5)
  static const double scrollBounce = 0.5;

  // ==================== ANIMATION ====================

  /// Animation duration short (150ms)
  static const int animationDurationShort = 150;

  /// Animation duration default (300ms)
  static const int animationDuration = 300;

  /// Animation duration long (500ms)
  static const int animationDurationLong = 500;

  // ==================== BREAKPOINTS ====================

  /// Mobile breakpoint (600.0)
  static const double breakpointMobile = 600.0;

  /// Tablet breakpoint (900.0)
  static const double breakpointTablet = 900.0;

  /// Desktop breakpoint (1200.0)
  static const double breakpointDesktop = 1200.0;

  // ==================== HELPER METHODS ====================

  /// Get responsive padding based on screen width
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= breakpointDesktop) {
      return const EdgeInsets.all(paddingXL);
    } else if (width >= breakpointTablet) {
      return const EdgeInsets.all(paddingL);
    } else {
      return const EdgeInsets.all(paddingM);
    }
  }

  /// Get responsive horizontal padding
  static double getResponsiveHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= breakpointDesktop) {
      return (width - breakpointDesktop) / 2 + paddingXL;
    } else if (width >= breakpointTablet) {
      return paddingL;
    } else {
      return paddingM;
    }
  }

  /// Check if screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < breakpointMobile;
  }

  /// Check if screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= breakpointMobile && width < breakpointDesktop;
  }

  /// Check if screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= breakpointDesktop;
  }
}

