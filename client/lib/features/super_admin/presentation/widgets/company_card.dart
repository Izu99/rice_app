import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/company_model.dart';

class CompanyCard extends StatelessWidget {
  final CompanyModel company;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(CompanyStatus)? onStatusChange;
  final bool isCompact;

  const CompanyCard({
    super.key,
    required this.company,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onStatusChange,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: _getStatusColor().withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        side: BorderSide(color: _getStatusColor().withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: isCompact ? _buildCompactContent() : _buildFullContent(),
        ),
      ),
    );
  }

  Widget _buildCompactContent() {
    return Row(
      children: [
        _buildAvatar(size: 50),
        const SizedBox(width: AppDimensions.paddingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                company.name,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                company.ownerName ?? 'N/A',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildFullContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(size: 60),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          company.ownerName ?? 'N/A',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildStatusBadge(),
                ],
              ),
            ),
            if (onEdit != null || onDelete != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.grey500),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'activate':
                      onStatusChange?.call(CompanyStatus.active);
                      break;
                    case 'deactivate':
                      onStatusChange?.call(CompanyStatus.inactive);
                      break;
                    case 'suspend':
                      onStatusChange?.call(CompanyStatus.suspended);
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  if (company.status != CompanyStatus.active)
                    const PopupMenuItem(
                      value: 'activate',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 20, color: Colors.green),
                          SizedBox(width: 12),
                          Text('Activate'),
                        ],
                      ),
                    ),
                  if (company.status == CompanyStatus.active)
                    const PopupMenuItem(
                      value: 'deactivate',
                      child: Row(
                        children: [
                          Icon(Icons.pause_circle,
                              size: 20, color: Colors.orange),
                          SizedBox(width: 12),
                          Text('Deactivate'),
                        ],
                      ),
                    ),
                  if (company.status != CompanyStatus.suspended)
                    const PopupMenuItem(
                      value: 'suspend',
                      child: Row(
                        children: [
                          Icon(Icons.block, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Suspend'),
                        ],
                      ),
                    ),
                  if (onDelete != null) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),

        const Divider(height: AppDimensions.paddingL),

        // Contact Info Row
        Row(
          children: [
            Expanded(
              child:
                  _buildInfoItem(Icons.email_outlined, company.email ?? 'N/A'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child:
                  _buildInfoItem(Icons.phone_outlined, company.phone ?? 'N/A'),
            ),
          ],
        ),

        if (company.address.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildInfoItem(Icons.location_on_outlined, company.address),
        ],

        const SizedBox(height: AppDimensions.paddingS),

        // Footer Row
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingS),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_outline,
                      size: 16, color: AppColors.grey500),
                  const SizedBox(width: 4),
                  Text(
                    '${company.currentUsers}/${company.maxUsers} users',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    company.isEmailVerified ? Icons.verified : Icons.pending,
                    size: 16,
                    color: company.isEmailVerified
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    company.isEmailVerified ? 'Verified' : 'Unverified',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: company.isEmailVerified
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ],
              ),
              Text(
                _formatDate(company.createdAt),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.adminPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.adminPrimary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: company.logoUrl != null && company.logoUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM - 2),
              child: Image.network(
                company.logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildInitials(size),
              ),
            )
          : _buildInitials(size),
    );
  }

  Widget _buildInitials(double size) {
    return Center(
      child: Text(
        company.name.isNotEmpty ? company.name[0].toUpperCase() : 'C',
        style: TextStyle(
          color: AppColors.adminPrimary,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            company.status.displayName,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (company.status) {
      case CompanyStatus.active:
        return AppColors.success;
      case CompanyStatus.inactive:
        return AppColors.warning;
      case CompanyStatus.pending:
        return Colors.orange;
      case CompanyStatus.suspended:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon() {
    switch (company.status) {
      case CompanyStatus.active:
        return Icons.check_circle;
      case CompanyStatus.inactive:
        return Icons.pause_circle;
      case CompanyStatus.pending:
        return Icons.pending;
      case CompanyStatus.suspended:
        return Icons.block;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

