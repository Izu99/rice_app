// lib/data/models/paddy_rice_price_model.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/paddy_rice_price_entity.dart';

class PaddyRicePriceModel extends Equatable {
  final String id;
  final String companyId;
  final String companyName;
  final String district;
  final double price;
  final double? priceRangeEnd;
  final String qualityGrade;
  final String priceType; // 'paddy' or 'rice'
  final String? variety;
  final String? notes;
  final String? createdByName;
  final String? createdByEmail;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  const PaddyRicePriceModel({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.district,
    required this.price,
    this.priceRangeEnd,
    this.qualityGrade = 'standard',
    this.priceType = 'paddy',
    this.variety,
    this.notes,
    this.createdByName,
    this.createdByEmail,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  /// Create from JSON (API)
  factory PaddyRicePriceModel.fromJson(Map<String, dynamic> json) {
    return PaddyRicePriceModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      companyName: json['company']?['name']?.toString() ?? 'Unknown',
      district: json['district']?.toString() ?? '',
      price: _parseDouble(json['price']),
      priceRangeEnd: json['priceRangeEnd'] != null
          ? _parseDouble(json['priceRangeEnd'])
          : null,
      qualityGrade: json['qualityGrade'] ?? 'standard',
      priceType: json['priceType'] ?? 'paddy',
      variety: json['variety']?.toString(),
      notes: json['notes']?.toString(),
      createdByName: json['createdBy'] is Map
          ? json['createdBy']['name']?.toString()
          : null,
      createdByEmail: json['createdBy'] is Map
          ? json['createdBy']['email']?.toString()
          : null,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']) ??
          DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
      isActive: json['isActive'] == true || json['is_active'] == true,
    );
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'district': district,
      'price': price,
      'priceRangeEnd': priceRangeEnd,
      'qualityGrade': qualityGrade,
      'priceType': priceType,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to Entity
  PaddyRicePriceEntity toEntity() {
    return PaddyRicePriceEntity(
      id: id,
      companyId: companyId,
      companyName: companyName,
      district: district,
      price: price,
      priceRangeEnd: priceRangeEnd,
      qualityGrade: qualityGrade,
      priceType: priceType,
      variety: variety,
      notes: notes,
      createdByName: createdByName,
      createdByEmail: createdByEmail,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
    );
  }

  /// Create from Entity
  factory PaddyRicePriceModel.fromEntity(PaddyRicePriceEntity entity) {
    return PaddyRicePriceModel(
      id: entity.id,
      companyId: entity.companyId,
      companyName: entity.companyName,
      district: entity.district,
      price: entity.price,
      priceRangeEnd: entity.priceRangeEnd,
      qualityGrade: entity.qualityGrade ?? 'standard',
      priceType: entity.priceType,
      variety: entity.variety,
      notes: entity.notes,
      createdByName: entity.createdByName,
      createdByEmail: entity.createdByEmail,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isActive: entity.isActive,
    );
  }

  /// Get price display (single or range)
  String get priceDisplay {
    if (priceRangeEnd != null && priceRangeEnd! > price) {
      return '${price.toStringAsFixed(2)} - ${priceRangeEnd!.toStringAsFixed(2)}';
    }
    return price.toStringAsFixed(2);
  }

  /// Get formatted price for UI display
  String get formattedPrice => 'Rs. $priceDisplay';

  @override
  List<Object?> get props => [
        id,
        companyId,
        companyName,
        district,
        price,
        priceRangeEnd,
        qualityGrade,
        priceType,
        variety,
        notes,
        createdByName,
        createdByEmail,
        createdAt,
        updatedAt,
        isActive,
      ];

  /// Helper to parse double values
  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Helper to parse DateTime values
  static DateTime? _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}

/// Pagination response model
class PaddyRicePriceListResponse extends Equatable {
  final List<PaddyRicePriceModel> prices;
  final int total;
  final int limit;
  final int page;
  final int pages;

  const PaddyRicePriceListResponse({
    required this.prices,
    required this.total,
    required this.limit,
    required this.page,
    required this.pages,
  });

  factory PaddyRicePriceListResponse.fromJson(Map<String, dynamic> json) {
    List<PaddyRicePriceModel> prices = [];
    if (json['prices'] is List) {
      prices = (json['prices'] as List)
          .map((p) => PaddyRicePriceModel.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    final pagination = json['pagination'] ?? {};
    return PaddyRicePriceListResponse(
      prices: prices,
      total: pagination['total'] ?? 0,
      limit: pagination['limit'] ?? 50,
      page: pagination['page'] ?? 1,
      pages: pagination['pages'] ?? 1,
    );
  }

  @override
  List<Object?> get props => [prices, total, limit, page, pages];
}

/// Districts list response model
class DistrictWithPricesResponse extends Equatable {
  final String district;
  final int priceCount;
  final DateTime? lastUpdated;

  const DistrictWithPricesResponse({
    required this.district,
    required this.priceCount,
    this.lastUpdated,
  });

  factory DistrictWithPricesResponse.fromJson(Map<String, dynamic> json) {
    return DistrictWithPricesResponse(
      district: json['district']?.toString() ?? '',
      priceCount: json['priceCount'] ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'].toString())
          : null,
    );
  }

  @override
  List<Object?> get props => [district, priceCount, lastUpdated];
}
