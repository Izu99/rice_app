// lib/domain/entities/user_entity.dart

import 'package:equatable/equatable.dart';
import '../../core/constants/enums.dart';

/// User Entity - Core business representation of a user
/// This entity contains only essential business logic properties
/// without any data layer dependencies
class UserEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? avatar;
  final UserRole role;
  final String companyId;
  final bool isActive;

  const UserEntity({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.avatar,
    required this.role,
    required this.companyId,
    this.isActive = true,
  });

  /// Check if user is a global admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is a company user
  bool get isCompany => role == UserRole.company;

  /// Check if user is a manager or higher
  bool get isManagerOrHigher =>
      role == UserRole.admin ||
      role == UserRole.company ||
      role == UserRole.manager;

  /// Check if user can manage other users
  bool get canManageUsers => role == UserRole.admin || role == UserRole.company;

  /// Check if user can manage stock
  bool get canManageStock => isManagerOrHigher;

  /// Check if user can view reports
  bool get canViewReports => isManagerOrHigher;

  /// Check if user can create transactions
  bool get canCreateTransactions => isActive && role != UserRole.customer;

  /// Check if user can cancel transactions
  bool get canCancelTransactions => isManagerOrHigher;

  /// Check if user can manage customers
  bool get canManageCustomers => isActive && role != UserRole.customer;

  /// Check if user can export data
  bool get canExportData => isManagerOrHigher;

  /// Check if user can manage company settings
  bool get canManageCompanySettings =>
      role == UserRole.admin || role == UserRole.company;

  /// Check if user has permission for a specific role level
  bool hasPermission(UserRole requiredRole) {
    const roleHierarchy = {
      UserRole.admin: 4,
      UserRole.company: 3,
      UserRole.manager: 2,
      UserRole.operator: 1,
      UserRole.customer: 0,
      UserRole.viewer: 0,
    };

    return (roleHierarchy[role] ?? 0) >= (roleHierarchy[requiredRole] ?? 0);
  }

  /// Get role display name
  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.company:
        return 'Company';
      case UserRole.customer:
        return 'Customer';
      case UserRole.manager:
        return 'Manager';
      case UserRole.operator:
        return 'Operator';
      case UserRole.viewer:
        return 'Viewer';
    }
  }

  /// Get role display name in Sinhala
  String get roleDisplayNameSinhala {
    switch (role) {
      case UserRole.admin:
        return 'පරිපාලක';
      case UserRole.company:
        return 'සමාගම';
      case UserRole.customer:
        return 'පාරිභෝගිකයා';
      case UserRole.manager:
        return 'කළමනාකරු';
      case UserRole.operator:
        return 'ක්‍රියාකරු';
      case UserRole.viewer:
        return 'නරඹන්නා';
    }
  }

  /// Get user initials for avatar fallback
  String get initials {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return 'U';

    final parts = trimmedName.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmedName[0].toUpperCase();
  }

  /// Get formatted phone number
  String get formattedPhone {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length == 10) {
      return '${cleanPhone.substring(0, 3)} ${cleanPhone.substring(3, 6)} ${cleanPhone.substring(6)}';
    }
    return phone;
  }

  /// Get display name (name or phone if name is empty)
  String get displayName => name.isNotEmpty ? name : phone;

  /// Create a copy with updated fields
  UserEntity copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? avatar,
    UserRole? role,
    String? companyId,
    bool? isActive,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Create an empty user entity
  factory UserEntity.empty() {
    return const UserEntity(
      id: '',
      name: '',
      phone: '',
      role: UserRole.operator,
      companyId: '',
    );
  }

  /// Check if entity is empty/invalid
  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        email,
        avatar,
        role,
        companyId,
        isActive,
      ];

  @override
  String toString() {
    return 'UserEntity(id: $id, name: $name, role: $role, isActive: $isActive)';
  }
}
