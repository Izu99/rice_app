import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

/// Empty State Widget - Shows when there's no data
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final Widget? customAction;
  final Widget? customIcon;
  final double iconSize;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final bool compact;
  final EdgeInsets? padding;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.customAction,
    this.customIcon,
    this.iconSize = AppDimensions.iconXXL,
    this.iconColor,
    this.iconBackgroundColor,
    this.compact = false,
    this.padding,
  });

  // ==================== PRESET CONSTRUCTORS ====================

  /// Empty customers list
  factory EmptyStateWidget.noCustomers({VoidCallback? onAddCustomer}) {
    return EmptyStateWidget(
      icon: Icons.people_outline,
      title: 'ගනුදෙනුකරුවන් නැත', // No Customers Yet
      subtitle: 'පළමු ගනුදෙනුකරු එක් කර ආරම්භ කරන්න',
      actionLabel: 'ගනුදෙනුකරුවෙකු එක් කරන්න',
      actionIcon: Icons.person_add_outlined,
      onAction: onAddCustomer,
    );
  }

  /// Empty transactions list
  factory EmptyStateWidget.noTransactions({VoidCallback? onCreateTransaction}) {
    return EmptyStateWidget(
      icon: Icons.receipt_long_outlined,
      title: 'ගනුදෙනු නැත', // No Transactions
      subtitle: 'ඔබගේ ගනුදෙනු මෙහි දිස්වනු ඇත',
      actionLabel: 'නව ගනුදෙනුවක්',
      actionIcon: Icons.add,
      onAction: onCreateTransaction,
    );
  }

  /// Empty stock
  factory EmptyStateWidget.noStock({VoidCallback? onAddStock}) {
    return EmptyStateWidget(
      icon: Icons.inventory_2_outlined,
      title: 'තොගය හිස්ව ඇත', // Stock Empty
      subtitle: 'ඔබගේ තොගයට අයිතම එක් කරන්න',
      actionLabel: 'තොග එක් කරන්න',
      actionIcon: Icons.add_box_outlined,
      onAction: onAddStock,
    );
  }

  /// Search no results
  factory EmptyStateWidget.noSearchResults({
    String query = '',
    VoidCallback? onClearSearch,
  }) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'ප්‍රතිඵල නැත', // No Results Found
      subtitle: query.isNotEmpty
          ? '"$query" සඳහා ප්‍රතිඵල හමු නොවීය'
          : 'වෙනත් පදයක් සොයා බලන්න',
      actionLabel: onClearSearch != null ? 'සෙවුම ඉවත් කරන්න' : null,
      actionIcon: Icons.clear,
      onAction: onClearSearch,
    );
  }

  /// No internet connection
  factory EmptyStateWidget.noInternet({VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.wifi_off_outlined,
      title: 'අන්තර්ජාල සම්බන්ධතාවය නැත', // No Internet Connection
      subtitle: 'කරුණාකර ඔබගේ සම්බන්ධතාවය පරීක්ෂා කර නැවත උත්සාහ කරන්න',
      actionLabel: 'නැවත උත්සාහ කරන්න',
      actionIcon: Icons.refresh,
      onAction: onRetry,
      iconColor: AppColors.warning,
    );
  }

  /// Error state
  factory EmptyStateWidget.error({
    String? message,
    VoidCallback? onRetry,
  }) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: 'දෝෂයක් සිදු විය', // Something Went Wrong
      subtitle: message ?? 'අනපේක්ෂිත දෝෂයක් සිදු විය',
      actionLabel: onRetry != null ? 'නැවත උත්සාහ කරන්න' : null,
      actionIcon: Icons.refresh,
      onAction: onRetry,
      iconColor: AppColors.error,
      iconBackgroundColor: AppColors.errorLight,
    );
  }

  /// No notifications
  factory EmptyStateWidget.noNotifications() {
    return const EmptyStateWidget(
      icon: Icons.notifications_none_outlined,
      title: 'දැනුම්දීම් නැත', // No Notifications
      subtitle: 'ඔබ සියලු දැනුම්දීම් දැක ඇත!',
    );
  }

  /// Empty cart/items
  factory EmptyStateWidget.emptyCart({VoidCallback? onBrowse}) {
    return EmptyStateWidget(
      icon: Icons.shopping_cart_outlined,
      title: 'අයිතම එක් කර නැත', // No Items Added
      subtitle: 'ඉදිරියට යාමට අයිතම එක් කරන්න',
      actionLabel: onBrowse != null ? 'අයිතම එක් කරන්න' : null,
      actionIcon: Icons.add_shopping_cart,
      onAction: onBrowse,
    );
  }

  /// No reports
  factory EmptyStateWidget.noReports({
    String? dateRange,
    VoidCallback? onChangeDateRange,
  }) {
    return EmptyStateWidget(
      icon: Icons.analytics_outlined,
      title: 'තොරතුරු නැත', // No Data Available
      subtitle: dateRange != null
          ? '$dateRange සඳහා තොරතුරු හමු නොවීය'
          : 'තෝරාගත් කාලය සඳහා තොරතුරු හමු නොවීය',
      actionLabel: onChangeDateRange != null ? 'කාලය වෙනස් කරන්න' : null,
      actionIcon: Icons.date_range,
      onAction: onChangeDateRange,
    );
  }

  /// Coming soon
  factory EmptyStateWidget.comingSoon({String? featureName}) {
    return EmptyStateWidget(
      icon: Icons.construction_outlined,
      title: 'ළඟදීම බලාපොරොත්තු වන්න', // Coming Soon
      subtitle: featureName != null
          ? '$featureName සඳහා වැඩ කටයුතු සිදු වෙමින් පවතී'
          : 'මෙම අංගය සඳහා වැඩ කටයුතු සිදු වෙමින් පවතී',
      iconColor: AppColors.info,
      iconBackgroundColor: AppColors.infoLight,
    );
  }

  /// Maintenance
  factory EmptyStateWidget.maintenance({VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.engineering_outlined,
      title: 'නඩත්තු කටයුතු සිදු වේ', // Under Maintenance
      subtitle: 'අප ඉක්මනින් නැවත පැමිණෙනු ඇත',
      actionLabel: onRetry != null ? 'යාවත්කාලීන කරන්න' : null,
      actionIcon: Icons.refresh,
      onAction: onRetry,
      iconColor: AppColors.warning,
      iconBackgroundColor: AppColors.warningLight,
    );
  }


  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildFull(context);
  }

  Widget _buildFull(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: padding ?? const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            _buildIcon(),

            const SizedBox(height: AppDimensions.paddingL),

            // Title
            Text(
              title,
              style: AppTextStyles.h5.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: AppDimensions.paddingS),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  subtitle!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // Action button
            if (customAction != null) ...[
              const SizedBox(height: AppDimensions.paddingL),
              customAction!,
            ] else if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDimensions.paddingL),
              _buildActionButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(AppDimensions.paddingL),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: iconBackgroundColor ?? AppColors.grey100,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Icon(
              icon,
              size: AppDimensions.iconL,
              color: iconColor ?? AppColors.grey400,
            ),
          ),

          const SizedBox(width: AppDimensions.paddingM),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Action
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    if (customIcon != null) return customIcon!;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      decoration: BoxDecoration(
        color: iconBackgroundColor ?? AppColors.grey100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor ?? AppColors.grey400,
      ),
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton.icon(
      onPressed: onAction,
      icon: actionIcon != null
          ? Icon(actionIcon, size: 20)
          : const SizedBox.shrink(),
      label: Text(actionLabel!),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingL,
          vertical: AppDimensions.paddingM,
        ),
      ),
    );
  }
}

// ==================== ERROR STATE WIDGET ====================

/// Error State Widget - Shows when an error occurs
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;
  final bool compact;
  final EdgeInsets? padding;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.retryLabel = 'Try Again',
    this.icon = Icons.error_outline,
    this.compact = false,
    this.padding,
  });

  /// Network error
  factory ErrorStateWidget.network({VoidCallback? onRetry}) {
    return ErrorStateWidget(
      title: 'Network Error',
      message: 'Unable to connect. Please check your internet connection.',
      icon: Icons.wifi_off_outlined,
      onRetry: onRetry,
    );
  }

  /// Server error
  factory ErrorStateWidget.server({VoidCallback? onRetry}) {
    return ErrorStateWidget(
      title: 'Server Error',
      message: 'Something went wrong on our end. Please try again later.',
      icon: Icons.cloud_off_outlined,
      onRetry: onRetry,
    );
  }

  /// Timeout error
  factory ErrorStateWidget.timeout({VoidCallback? onRetry}) {
    return ErrorStateWidget(
      title: 'Request Timeout',
      message: 'The request took too long. Please try again.',
      icon: Icons.timer_off_outlined,
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }

    return Center(
      child: SingleChildScrollView(
        padding: padding ?? const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              decoration: const BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppDimensions.iconXXL,
                color: AppColors.error,
              ),
            ),

            const SizedBox(height: AppDimensions.paddingL),

            // Title
            if (title != null)
              Text(
                title!,
                style: AppTextStyles.h5.copyWith(
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),

            if (title != null) const SizedBox(height: AppDimensions.paddingS),

            // Message
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Retry button
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.paddingL),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 20),
                label: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.error,
            size: AppDimensions.iconM,
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
          if (onRetry != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              color: AppColors.error,
              onPressed: onRetry,
              iconSize: 20,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(AppDimensions.paddingS),
            ),
        ],
      ),
    );
  }
}

// ==================== LOADING STATE WIDGET ====================

/// Loading State Widget
class LoadingStateWidget extends StatelessWidget {
  final String? message;
  final bool useShimmer;
  final int shimmerCount;
  final double? shimmerHeight;

  const LoadingStateWidget({
    super.key,
    this.message,
    this.useShimmer = false,
    this.shimmerCount = 3,
    this.shimmerHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (useShimmer) {
      return _buildShimmer();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppDimensions.paddingL),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: shimmerCount,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimensions.paddingM),
      itemBuilder: (_, __) => _ShimmerItem(height: shimmerHeight),
    );
  }
}

class _ShimmerItem extends StatefulWidget {
  final double? height;

  const _ShimmerItem({this.height});

  @override
  State<_ShimmerItem> createState() => _ShimmerItemState();
}

class _ShimmerItemState extends State<_ShimmerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height ?? 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                AppColors.grey200,
                AppColors.grey100,
                AppColors.grey200,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
