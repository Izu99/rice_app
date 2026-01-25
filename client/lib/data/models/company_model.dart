// lib/data/models/company_model.dart

import 'package:equatable/equatable.dart';

/// Company subscription plan
enum SubscriptionPlan {
  free,
  basic,
  premium,
  enterprise,
}

/// Company status
enum CompanyStatus {
  active,
  inactive,
  pending,
  suspended,
}

/// Extension for CompanyStatus to provide display names
extension CompanyStatusExtension on CompanyStatus {
  String get displayName {
    switch (this) {
      case CompanyStatus.active:
        return 'Active';
      case CompanyStatus.inactive:
        return 'Inactive';
      case CompanyStatus.pending:
        return 'Pending';
      case CompanyStatus.suspended:
        return 'Suspended';
    }
  }
}

class CompanyModel extends Equatable {
  final String id;
  final String? serverId;
  final String name;
  final String? registrationNumber;
  final String? taxNumber;
  final String address;
  final String phone;
  final String? secondaryPhone;
  final String? email;
  final String? website;
  final String? logoUrl;
  final SubscriptionPlan plan;
  final DateTime? subscriptionExpiresAt;
  final CompanyStatus status;
  final bool isActive;
  final bool isEmailVerified;
  final int maxUsers;
  final int currentUsers;
  final String? ownerId;
  final String? ownerName;
  final Map<String, dynamic>? settings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final DateTime? syncedAt;

  const CompanyModel({
    required this.id,
    this.serverId,
    required this.name,
    this.registrationNumber,
    this.taxNumber,
    required this.address,
    required this.phone,
    this.secondaryPhone,
    this.email,
    this.website,
    this.logoUrl,
    this.plan = SubscriptionPlan.free,
    this.subscriptionExpiresAt,
    this.status = CompanyStatus.pending,
    this.isActive = true,
    this.isEmailVerified = false,
    this.maxUsers = 5,
    this.currentUsers = 1,
    this.ownerId,
    this.ownerName,
    this.settings,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.syncedAt,
  });

  /// Create from JSON
  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id']?.toString() ?? '',
      serverId: json['server_id']?.toString(),
      name: json['name']?.toString() ?? '',
      registrationNumber: json['registration_number']?.toString(),
      taxNumber: json['tax_number']?.toString(),
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      secondaryPhone: json['secondary_phone']?.toString(),
      email: json['email']?.toString(),
      website: json['website']?.toString(),
      logoUrl: json['logo_url']?.toString(),
      plan: _parseSubscriptionPlan(json['plan']),
      subscriptionExpiresAt: _parseDateTime(json['subscription_expires_at']),
      status: _parseCompanyStatus(json['status']),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      isEmailVerified:
          json['is_email_verified'] == true || json['is_email_verified'] == 1,
      maxUsers: _parseInt(json['max_users'], defaultValue: 5),
      currentUsers: _parseInt(json['current_users'], defaultValue: 1),
      ownerId: json['owner_id']?.toString(),
      ownerName: json['owner_name']?.toString(),
      settings: json['settings'] is Map
          ? Map<String, dynamic>.from(json['settings'])
          : null,
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
      'registration_number': registrationNumber,
      'tax_number': taxNumber,
      'address': address,
      'phone': phone,
      'secondary_phone': secondaryPhone,
      'email': email,
      'website': website,
      'logo_url': logoUrl,
      'plan': plan.name,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'status': status.name,
      'is_active': isActive ? 1 : 0,
      'is_email_verified': isEmailVerified ? 1 : 0,
      'max_users': maxUsers,
      'current_users': currentUsers,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'settings': settings,
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
      'registration_number': registrationNumber,
      'tax_number': taxNumber,
      'address': address,
      'phone': phone,
      'secondary_phone': secondaryPhone,
      'email': email,
      'website': website,
    };
  }

  /// Copy with new values
  CompanyModel copyWith({
    String? id,
    String? serverId,
    String? name,
    String? registrationNumber,
    String? taxNumber,
    String? address,
    String? phone,
    String? secondaryPhone,
    String? email,
    String? website,
    String? logoUrl,
    SubscriptionPlan? plan,
    DateTime? subscriptionExpiresAt,
    CompanyStatus? status,
    bool? isActive,
    bool? isEmailVerified,
    int? maxUsers,
    int? currentUsers,
    String? ownerId,
    String? ownerName,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? syncedAt,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      taxNumber: taxNumber ?? this.taxNumber,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      email: email ?? this.email,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      plan: plan ?? this.plan,
      subscriptionExpiresAt:
          subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      maxUsers: maxUsers ?? this.maxUsers,
      currentUsers: currentUsers ?? this.currentUsers,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  /// Parse helpers
  static SubscriptionPlan _parseSubscriptionPlan(dynamic value) {
    if (value == null) return SubscriptionPlan.free;
    if (value is SubscriptionPlan) return value;

    switch (value.toString().toLowerCase()) {
      case 'basic':
        return SubscriptionPlan.basic;
      case 'premium':
        return SubscriptionPlan.premium;
      case 'enterprise':
        return SubscriptionPlan.enterprise;
      default:
        return SubscriptionPlan.free;
    }
  }

  static CompanyStatus _parseCompanyStatus(dynamic value) {
    if (value == null) return CompanyStatus.pending;
    if (value is CompanyStatus) return value;

    switch (value.toString().toLowerCase()) {
      case 'active':
        return CompanyStatus.active;
      case 'inactive':
        return CompanyStatus.inactive;
      case 'pending':
        return CompanyStatus.pending;
      case 'suspended':
        return CompanyStatus.suspended;
      default:
        return CompanyStatus.pending;
    }
  }

  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Get setting value
  T? getSetting<T>(String key, {T? defaultValue}) {
    if (settings == null) return defaultValue;
    final value = settings![key];
    if (value is T) return value;
    return defaultValue;
  }

  /// Display helpers
  String get displayPlan {
    switch (plan) {
      case SubscriptionPlan.free:
        return 'Free';
      case SubscriptionPlan.basic:
        return 'Basic';
      case SubscriptionPlan.premium:
        return 'Premium';
      case SubscriptionPlan.enterprise:
        return 'Enterprise';
    }
  }

  bool get isSubscriptionExpired {
    if (subscriptionExpiresAt == null) return false;
    return DateTime.now().isAfter(subscriptionExpiresAt!);
  }

  bool get canAddMoreUsers => currentUsers < maxUsers;

  int get remainingUserSlots => maxUsers - currentUsers;

  bool get isPremium =>
      plan == SubscriptionPlan.premium || plan == SubscriptionPlan.enterprise;

  @override
  List<Object?> get props => [
        id,
        serverId,
        name,
        phone,
        isActive,
        plan,
        isSynced,
      ];

  @override
  String toString() => 'CompanyModel(id: $id, name: $name, plan: ${plan.name})';
}

