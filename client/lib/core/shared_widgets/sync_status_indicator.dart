import 'package:flutter/material.dart';

// SyncEngine removed from API-first path; using status model only
import '../sync/sync_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';

/// Sync status indicator widget
class SyncStatusIndicator extends StatelessWidget {
  /// Current sync status (preferred path)
  final SyncStatusModel? status;

  /// Whether to show label
  final bool showLabel;

  /// Whether to use compact mode
  final bool compact;

  /// Callback when tapped
  final VoidCallback? onTap;

  /// Custom icon size
  final double? iconSize;

  const SyncStatusIndicator(
      {super.key,
      this.status,
      this.showLabel = false,
      this.compact = true,
      this.onTap,
      this.iconSize});

  @override
  Widget build(BuildContext context) {
    if (status != null) {
      return _buildIndicator(context, status!);
    }
    return const SizedBox.shrink();
  }

  Widget _buildIndicator(BuildContext context, SyncStatusModel status) {
    if (compact) {
      return _buildCompactIndicator(context, status);
    }
    return _buildFullIndicator(context, status);
  }

  Widget _buildCompactIndicator(BuildContext context, SyncStatusModel status) {
    return GestureDetector(
      onTap: onTap ?? () => _showSyncDetails(context, status),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingS),
        child: _buildIcon(status),
      ),
    );
  }

  Widget _buildFullIndicator(BuildContext context, SyncStatusModel status) {
    return GestureDetector(
      onTap: onTap ?? () => _showSyncDetails(context, status),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        decoration: BoxDecoration(
          color: _getBackgroundColor(status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          border: Border.all(
            color: _getBackgroundColor(status).withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(status),
            if (showLabel) ...[
              const SizedBox(width: AppDimensions.paddingS),
              Text(
                _getLabel(status),
                style: AppTextStyles.labelSmall.copyWith(
                  color: _getBackgroundColor(status),
                ),
              ),
            ],
            if (status.hasPending) ...[
              const SizedBox(width: AppDimensions.paddingXS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusRound),
                ),
                child: Text(
                  '${status.pendingCount}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(SyncStatusModel status) {
    final size = iconSize ?? AppDimensions.iconS;

    switch (status.state) {
      case SyncState.syncing:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getBackgroundColor(status),
            ),
          ),
        );
      case SyncState.success:
        return Icon(
          Icons.cloud_done_outlined,
          size: size,
          color: _getBackgroundColor(status),
        );
      case SyncState.error:
        return Icon(
          Icons.cloud_off_outlined,
          size: size,
          color: _getBackgroundColor(status),
        );
      case SyncState.offline:
        return Icon(
          Icons.cloud_off_outlined,
          size: size,
          color: _getBackgroundColor(status),
        );
      case SyncState.paused:
        return Icon(
          Icons.pause_circle_outline,
          size: size,
          color: _getBackgroundColor(status),
        );
      case SyncState.cancelled:
        return Icon(
          Icons.block,
          size: size,
          color: _getBackgroundColor(status),
        );
      case SyncState.idle:
        if (status.hasPending) {
          return Icon(
            Icons.cloud_upload_outlined,
            size: size,
            color: _getBackgroundColor(status),
          );
        }
        return Icon(
          Icons.cloud_done_outlined,
          size: size,
          color: _getBackgroundColor(status),
        );
    }
  }

  Color _getBackgroundColor(SyncStatusModel status) {
    switch (status.state) {
      case SyncState.syncing:
        return AppColors.info;
      case SyncState.success:
        return AppColors.success;
      case SyncState.error:
        return AppColors.error;
      case SyncState.offline:
        return AppColors.grey500;
      case SyncState.paused:
        return AppColors.warning;
      case SyncState.cancelled:
        return AppColors.error;
      case SyncState.idle:
        return status.hasPending ? AppColors.warning : AppColors.success;
    }
  }

  String _getLabel(SyncStatusModel status) {
    switch (status.state) {
      case SyncState.syncing:
        return 'සමමුහුර්ත කරමින්...';
      case SyncState.success:
        return 'සමමුහුර්තයි';
      case SyncState.error:
        return 'සමමුහුර්ත දෝෂයක්';
      case SyncState.offline:
        return 'නොබැඳි (Offline)';
      case SyncState.paused:
        return 'නතර කර ඇත';
      case SyncState.cancelled:
        return 'අවලංගුයි';
      case SyncState.idle:
        return status.hasPending ? 'බලාපොරොත්තුවෙන්' : 'සමමුහුර්තයි';
    }
  }


  void _showSyncDetails(BuildContext context, SyncStatusModel status) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      builder: (context) => SyncDetailsSheet(
        status: status,
        onSync: null,
      ),
    );
  }
}

/// Sync details bottom sheet
class SyncDetailsSheet extends StatelessWidget {
  final SyncStatusModel status;
  final VoidCallback? onSync;

  const SyncDetailsSheet({
    super.key,
    required this.status,
    this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppDimensions.paddingL),
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const Text('සමමුහුර්ත තත්ත්වය', style: AppTextStyles.h5), // Sync Status
          const SizedBox(height: AppDimensions.paddingL),

          // Status icon
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(),
              size: 48,
              color: _getStatusColor(),
            ),
          ),

          const SizedBox(height: AppDimensions.paddingM),

          Text(
            _getStatusText(),
            style: AppTextStyles.h6.copyWith(color: _getStatusColor()),
          ),

          const SizedBox(height: AppDimensions.paddingL),

          // Details
          _buildDetailRow('තත්ත්වය', _getStatusText(), _getStatusColor()), // Status

          if (status.lastSyncTime != null)
            _buildDetailRow(
              'අවසන් වරට සමමුහුර්ත කළේ', // Last Synced
              Formatters.relativeTime(status.lastSyncTime!),
              AppColors.textSecondary,
            ),

          _buildDetailRow(
            'බලාපොරොත්තුවෙන් පවතින වෙනස්කම්', // Pending Changes
            'අයිතම ${status.pendingCount}',
            status.hasPending ? AppColors.warning : AppColors.success,
          ),

          if (status.hasError && status.errorMessage != null)
            _buildDetailRow(
              'දෝෂය', // Error
              status.errorMessage!,
              AppColors.error,
            ),

          const SizedBox(height: AppDimensions.paddingL),

          // Sync button
          if (onSync != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: status.isSyncing ? null : onSync,
                icon: status.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.sync),
                label: Text(status.isSyncing ? 'සමමුහුර්ත කරමින්...' : 'දැන් සමමුහුර්ත කරන්න'), // Sync Now
              ),
            ),


          const SizedBox(height: AppDimensions.paddingM),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (status.state) {
      case SyncState.syncing:
        return 'සමමුහුර්ත කරමින්...';
      case SyncState.success:
        return 'සියලු දත්ත සමමුහුර්තයි';
      case SyncState.error:
        return 'සමමුහුර්තය අසාර්ථකයි';
      case SyncState.offline:
        return 'නොබැඳි (Offline) ක්‍රමය';
      case SyncState.paused:
        return 'නතර කර ඇත';
      case SyncState.cancelled:
        return 'අවලංගු කර ඇත';
      case SyncState.idle:
        return status.hasPending ? 'වෙනස්කම් බලාපොරොත්තුවෙන්' : 'යාවත්කාලීනයි';
    }
  }


  Color _getStatusColor() {
    switch (status.state) {
      case SyncState.syncing:
        return AppColors.info;
      case SyncState.success:
        return AppColors.success;
      case SyncState.error:
        return AppColors.error;
      case SyncState.offline:
        return AppColors.grey500;
      case SyncState.paused:
        return AppColors.warning;
      case SyncState.cancelled:
        return AppColors.error;
      case SyncState.idle:
        return status.hasPending ? AppColors.warning : AppColors.success;
    }
  }

  IconData _getStatusIcon() {
    switch (status.state) {
      case SyncState.syncing:
        return Icons.sync;
      case SyncState.success:
        return Icons.cloud_done;
      case SyncState.error:
        return Icons.cloud_off;
      case SyncState.offline:
        return Icons.wifi_off;
      case SyncState.paused:
        return Icons.pause_circle;
      case SyncState.cancelled:
        return Icons.block;
      case SyncState.idle:
        return status.hasPending ? Icons.cloud_upload : Icons.cloud_done;
    }
  }
}
