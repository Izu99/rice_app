// lib/data/models/customer_model.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/customer_entity.dart';
import '../../core/constants/db_constants.dart';
import '../../core/constants/enums.dart';

class CustomerModel extends Equatable {
  final int? localId;
  final String id;
  final String? serverId;
  final String name;
  final String phone;
  final String? secondaryPhone;
  final String? email;
  final String? address;
  final String? city;
  final String? nicNumber;
  final String companyId;
  final double totalPurchases; // Total amount we bought from them
  final double totalSales; // Total amount we sold to them
  final double balance; // Outstanding balance (+ they owe us, - we owe them)
  final CustomerType customerType;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final SyncStatus syncStatus;
  final DateTime? syncedAt;
  final bool isDeleted;

  const CustomerModel({
    this.localId,
    required this.id,
    this.serverId,
    required this.name,
    required this.phone,
    this.secondaryPhone,
    this.email,
    this.address,
    this.city,
    this.nicNumber,
    required this.companyId,
    this.totalPurchases = 0.0,
    this.totalSales = 0.0,
    this.balance = 0.0,
    this.customerType = CustomerType.seller,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.syncStatus = SyncStatus.pending,
    this.syncedAt,
    this.isDeleted = false,
  });

  /// Create from JSON (API)
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      serverId: json['server_id']?.toString() ?? json['_id']?.toString(),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      secondaryPhone: json['secondary_phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      nicNumber: json['nic_number']?.toString() ?? json['nic']?.toString(),
      companyId: json['company_id']?.toString() ?? '',
      totalPurchases:
          _parseDouble(json['total_purchases'] ?? json['totalBuyAmount']),
      totalSales: _parseDouble(json['total_sales'] ?? json['totalSellAmount']),
      balance: _parseDouble(json['balance']),
      customerType: CustomerType.fromString(json['customer_type'] ?? 'both'),
      notes: json['notes']?.toString(),
      isActive: json['is_active'] == true ||
          json['is_active'] == 1 ||
          json['isActive'] == true,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']) ??
          DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']) ??
          DateTime.now(),
      isSynced: json['is_synced'] == true ||
          json['is_synced'] == 1 ||
          json['isSynced'] == true,
      syncStatus: _parseSyncStatus(json['sync_status']),
      syncedAt: _parseDateTime(json['synced_at']),
      isDeleted: json['is_deleted'] == true ||
          json['is_deleted'] == 1 ||
          json['isDeleted'] == true,
    );
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'server_id': serverId,
      'name': name,
      'phone': phone,
      'secondary_phone': secondaryPhone,
      'email': email,
      'address': address,
      'city': city,
      'nic_number': nicNumber,
      'company_id': companyId,
      'total_purchases': totalPurchases,
      'total_sales': totalSales,
      'balance': balance,
      'customer_type': customerType.value,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'sync_status': syncStatus.value,
      'synced_at': syncedAt?.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  /// Create from DB map
  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      localId: (map[DbConstants.colLocalId] is int)
          ? map[DbConstants.colLocalId] as int
          : (map[DbConstants.colLocalId] != null
              ? int.tryParse(map[DbConstants.colLocalId].toString())
              : null),
      id: map['id']?.toString() ?? '',
      serverId: map[DbConstants.colServerId]?.toString(),
      name: map[DbConstants.colName]?.toString() ?? '',
      phone: map[DbConstants.colPhone]?.toString() ?? '',
      secondaryPhone: map[DbConstants.colSecondaryPhone]?.toString(),
      email: map[DbConstants.colEmail]?.toString(),
      address: map[DbConstants.colAddress]?.toString(),
      city: map[DbConstants.colCity]?.toString() ?? map['city']?.toString(),
      nicNumber: map[DbConstants.colNic]?.toString(),
      companyId: map[DbConstants.colCompanyId]?.toString() ?? '',
      totalPurchases:
          CustomerModel._parseDouble(map[DbConstants.colTotalPurchases]),
      totalSales: CustomerModel._parseDouble(map[DbConstants.colTotalSales]),
      balance: CustomerModel._parseDouble(
          map[DbConstants.colBalance] ?? map['balance']),
      customerType: CustomerType.fromString(map['customer_type'] ?? 'both'),
      notes: map[DbConstants.colNotes]?.toString() ?? map['notes']?.toString(),
      isActive: (map['is_active'] == 1) || (map['is_active'] == true),
      createdAt: CustomerModel._parseDateTime(map[DbConstants.colCreatedAt]) ??
          DateTime.now(),
      updatedAt: CustomerModel._parseDateTime(map[DbConstants.colUpdatedAt]) ??
          DateTime.now(),
      isSynced: (map['is_synced'] == 1) ||
          (map['is_synced'] == true) ||
          (map[DbConstants.colSyncStatus] == SyncStatus.synced.value),
      syncStatus: _parseSyncStatus(
          map[DbConstants.colSyncStatus] ?? map['sync_status']),
      syncedAt: CustomerModel._parseDateTime(map[DbConstants.colSyncedAt]),
      isDeleted: (map[DbConstants.colIsDeleted] == 1) ||
          (map[DbConstants.colIsDeleted] == true),
    );
  }

  /// Convert to DB map
  Map<String, dynamic> toMap() {
    return {
      DbConstants.colLocalId: localId,
      'id': id,
      DbConstants.colServerId: serverId,
      DbConstants.colName: name,
      DbConstants.colPhone: phone,
      DbConstants.colSecondaryPhone: secondaryPhone,
      DbConstants.colEmail: email,
      DbConstants.colAddress: address,
      DbConstants.colCity: city,
      DbConstants.colNic: nicNumber,
      DbConstants.colCompanyId: companyId,
      DbConstants.colTotalPurchases: totalPurchases,
      DbConstants.colTotalSales: totalSales,
      DbConstants.colBalance: balance,
      'customer_type': customerType.value,
      DbConstants.colNotes: notes,
      'is_active': isActive ? 1 : 0,
      DbConstants.colCreatedAt: createdAt.toIso8601String(),
      DbConstants.colUpdatedAt: updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      DbConstants.colSyncStatus: syncStatus.value,
      DbConstants.colSyncedAt: syncedAt?.toIso8601String(),
      DbConstants.colIsDeleted: isDeleted ? 1 : 0,
    };
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJsonForApi() {
    final Map<String, dynamic> data = {
      'name': name,
      'phone': phone,
      'customer_type': customerType.value,
      'isActive': isActive,
      'clientId': id,
    };

    // Only add optional fields if they are not null and not empty
    if (secondaryPhone != null && secondaryPhone!.isNotEmpty) {
      data['secondary_phone'] = secondaryPhone;
    }
    if (email != null && email!.isNotEmpty) {
      data['email'] = email;
    }
    if (address != null && address!.isNotEmpty) {
      data['address'] = address;
    }
    if (city != null && city!.isNotEmpty) {
      data['city'] = city;
    }
    if (nicNumber != null && nicNumber!.isNotEmpty) {
      data['nic'] = nicNumber;
    }
    if (notes != null && notes!.isNotEmpty) {
      data['notes'] = notes;
    }

    return data;
  }

  /// Convert to JSON for Sync
  Map<String, dynamic> toJsonForSync() {
    return {
      'local_id': id,
      'server_id': serverId,
      'name': name,
      'phone': phone,
      'secondary_phone': secondaryPhone,
      'email': email,
      'address': address,
      'city': city,
      'nic_number': nicNumber,
      'total_purchases': totalPurchases,
      'total_sales': totalSales,
      'balance': balance,
      'customer_type': customerType.value,
      'notes': notes,
      'is_active': isActive,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to Entity
  CustomerEntity toEntity() {
    return CustomerEntity(
      id: id,
      serverId: serverId,
      name: name,
      phone: phone,
      secondaryPhone: secondaryPhone,
      email: email,
      address: address,
      city: city,
      nic: nicNumber,
      notes: notes,
      balance: balance,
      customerType: customerType,
      isActive: isActive,
    );
  }

  /// Create from Entity
  factory CustomerModel.fromEntity(CustomerEntity entity, String companyId) {
    return CustomerModel(
      id: entity.id,
      serverId: entity.serverId,
      name: entity.name,
      phone: entity.phone,
      secondaryPhone: entity.secondaryPhone,
      email: entity.email,
      address: entity.address,
      city: entity.city,
      nicNumber: entity.nic,
      notes: entity.notes,
      companyId: companyId,
      balance: entity.balance,
      customerType: entity.customerType,
      isActive: entity.isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create new customer with generated ID
  factory CustomerModel.create({
    required String name,
    required String phone,
    String? secondaryPhone,
    String? email,
    String? address,
    String? city,
    String? nicNumber,
    required String companyId,
    CustomerType customerType = CustomerType.seller,
    String? notes,
  }) {
    final now = DateTime.now();
    return CustomerModel(
      id: 'CUST_${now.millisecondsSinceEpoch}',
      name: name,
      phone: phone.replaceAll(RegExp(r'[^\d+]'), ''),
      secondaryPhone: secondaryPhone?.replaceAll(RegExp(r'[^\d+]'), ''),
      email: email,
      address: address,
      city: city,
      nicNumber: nicNumber,
      companyId: companyId,
      customerType: customerType,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Copy with new values
  CustomerModel copyWith({
    String? id,
    String? serverId,
    String? name,
    String? phone,
    String? secondaryPhone,
    String? email,
    String? address,
    String? city,
    String? nicNumber,
    String? companyId,
    double? totalPurchases,
    double? totalSales,
    double? balance,
    CustomerType? customerType,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? localId,
    bool? isSynced,
    SyncStatus? syncStatus,
    DateTime? syncedAt,
    bool? isDeleted,
  }) {
    return CustomerModel(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      nicNumber: nicNumber ?? this.nicNumber,
      companyId: companyId ?? this.companyId,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      totalSales: totalSales ?? this.totalSales,
      balance: balance ?? this.balance,
      customerType: customerType ?? this.customerType,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      syncStatus: syncStatus ?? this.syncStatus,
      syncedAt: syncedAt ?? this.syncedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// Helper to parse double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Helper to parse DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static SyncStatus _parseSyncStatus(dynamic value) {
    if (value == null) return SyncStatus.pending;
    if (value is SyncStatus) return value;
    return SyncStatus.fromString(value.toString());
  }

  /// Get initials for avatar
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'C';
  }

  /// Format phone for display
  String get formattedPhone {
    if (phone.length == 10) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
    }
    return phone;
  }

  /// Check if customer has outstanding balance
  bool get hasOutstandingBalance => balance != 0;

  /// Check if we owe them money
  bool get weOweThem => balance < 0;

  /// Check if they owe us money
  bool get theyOweUs => balance > 0;

  /// Getters used by widgets
  bool get customerOwesUs => theyOweUs;
  double get absoluteBalance => balance.abs();
  String get shortAddress => address != null && address!.length > 30
      ? '${address!.substring(0, 30)}...'
      : (address ?? '');

  @override
  List<Object?> get props => [
        id,
        serverId,
        name,
        phone,
        companyId,
        balance,
        customerType,
        isActive,
        isSynced,
        isDeleted,
        city,
      ];

  @override
  String toString() => 'CustomerModel(id: $id, name: $name, phone: $phone)';
}
