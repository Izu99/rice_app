// lib/data/models/user_model.dart

import 'package:equatable/equatable.dart';
import '../../core/constants/enums.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends Equatable {
  final String id;
  final String? serverId;
  final String name;
  final String phone;
  final String? email;
  final String? avatar;
  final UserRole role;
  final String companyId;
  final String? companyName;
  final bool isActive;
  final bool isPhoneVerified;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final DateTime? syncedAt;

  const UserModel({
    required this.id,
    this.serverId,
    required this.name,
    required this.phone,
    this.email,
    this.avatar,
    required this.role,
    required this.companyId,
    this.companyName,
    this.isActive = true,
    this.isPhoneVerified = false,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.syncedAt,
  });

  /// Create from JSON (API or Local DB)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    print('👤 [UserModel] Parsing JSON: keys=${json.keys.toList()}');
    if (json.containsKey('companyId'))
      print('👤 [UserModel] found companyId: ${json['companyId']}');
    if (json.containsKey('company_id'))
      print('👤 [UserModel] found company_id: ${json['company_id']}');

    return UserModel(
      id: json['id']?.toString() ?? '',
      serverId: json['server_id']?.toString(),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      avatar: json['avatar']?.toString(),
      role: _parseUserRole(json['role']),
      companyId: _parseCompanyId(json),
      companyName:
          json['company_name']?.toString() ?? json['companyName']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      isPhoneVerified:
          json['is_phone_verified'] == true || json['is_phone_verified'] == 1,
      lastLoginAt: _parseDateTime(json['last_login_at']),
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
      isSynced: json['is_synced'] == true || json['is_synced'] == 1,
      syncedAt: _parseDateTime(json['synced_at']),
    );
  }

  /// Convert to JSON for Local DB
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'server_id': serverId,
      'name': name,
      'phone': phone,
      'email': email,
      'avatar': avatar,
      'role': role.value,
      'company_id': companyId,
      'company_name': companyName,
      'is_active': isActive ? 1 : 0,
      'is_phone_verified': isPhoneVerified ? 1 : 0,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'synced_at': syncedAt?.toIso8601String(),
    };
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJsonForApi() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'avatar': avatar,
      'role': role.value,
      'company_id': companyId,
    };
  }

  /// Convert to Entity
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      phone: phone,
      email: email,
      avatar: avatar,
      role: role,
      companyId: companyId,
      isActive: isActive,
    );
  }

  /// Create from Entity
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      phone: entity.phone,
      email: entity.email,
      avatar: entity.avatar,
      role: entity.role,
      companyId: entity.companyId,
      isActive: entity.isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Copy with new values
  UserModel copyWith({
    String? id,
    String? serverId,
    String? name,
    String? phone,
    String? email,
    String? avatar,
    UserRole? role,
    String? companyId,
    String? companyName,
    bool? isActive,
    bool? isPhoneVerified,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? syncedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      isActive: isActive ?? this.isActive,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  static String _parseCompanyId(Map<String, dynamic> json) {
    // Try direct keys first
    final directId = json['companyId'] ?? json['company_id'];
    if (directId != null) {
      if (directId is String) return directId;
      if (directId is Map && directId.containsKey('_id'))
        return directId['_id'].toString();
      if (directId is Map && directId.containsKey('id'))
        return directId['id'].toString();
      return directId.toString();
    }

    // Try nested company object
    final company = json['company'];
    if (company is Map) {
      return (company['_id'] ?? company['id'] ?? '').toString();
    }

    return '';
  }

  /// Helper to parse UserRole
  static UserRole _parseUserRole(dynamic value) {
    if (value == null) return UserRole.viewer;
    if (value is UserRole) return value;

    final roleStr = value.toString().toLowerCase();
    switch (roleStr) {
      case 'admin':
      case 'super_admin':
      case 'superadmin':
        return UserRole.admin;
      case 'company':
        return UserRole.company;
      case 'customer':
        return UserRole.customer;
      case 'manager':
        return UserRole.manager;
      case 'operator':
        return UserRole.operator;
      default:
        return UserRole.viewer;
    }
  }

  /// Helper to parse DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// Check if user is global admin
  bool get isAdmin => role == UserRole.admin;

  /// Get display role name
  String get displayRole {
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

  /// Get initials for avatar
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  @override
  List<Object?> get props => [
        id,
        serverId,
        name,
        phone,
        email,
        avatar,
        role,
        companyId,
        isActive,
        isPhoneVerified,
        isSynced,
      ];

  @override
  String toString() => 'UserModel(id: $id, name: $name, role: $role)';
}
