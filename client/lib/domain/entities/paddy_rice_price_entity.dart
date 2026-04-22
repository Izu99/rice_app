// lib/domain/entities/paddy_rice_price_entity.dart

import 'package:equatable/equatable.dart';

/// PaddyRicePrice Entity - Core business representation of paddy rice prices
class PaddyRicePriceEntity extends Equatable {
  final String id;
  final String companyId;
  final String companyName;
  final String district;
  final double price;
  final double? priceRangeEnd;
  final String? qualityGrade;
  final String priceType; // 'paddy' or 'rice'
  final String? variety;
  final String? notes;
  final String? createdByName;
  final String? createdByEmail;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  const PaddyRicePriceEntity({
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
}
