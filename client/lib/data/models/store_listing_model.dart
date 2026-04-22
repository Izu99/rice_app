import '../../domain/entities/store_listing_entity.dart';

class StoreListingModel {
  final String id;
  final String companyId;
  final String companyName;
  final String category;
  final String variety;
  final double quantityKg;
  final double pricePerKg;
  final String district;
  final String description;
  final String contactPhone;
  final bool isOwn;
  final DateTime createdAt;

  const StoreListingModel({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.category,
    required this.variety,
    required this.quantityKg,
    required this.pricePerKg,
    required this.district,
    required this.description,
    required this.contactPhone,
    required this.isOwn,
    required this.createdAt,
  });

  factory StoreListingModel.fromJson(Map<String, dynamic> json) {
    return StoreListingModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? 'Unknown',
      category: json['category']?.toString() ?? 'other',
      variety: json['variety']?.toString() ?? '',
      quantityKg: _parseDouble(json['quantityKg']),
      pricePerKg: _parseDouble(json['pricePerKg']),
      district: json['district']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      contactPhone: json['contactPhone']?.toString() ?? '',
      isOwn: json['isOwn'] == true,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'variety': variety,
        'quantityKg': quantityKg,
        'pricePerKg': pricePerKg,
        'district': district,
        'description': description,
        'contactPhone': contactPhone,
      };

  StoreListingEntity toEntity() {
    return StoreListingEntity(
      id: id,
      companyId: companyId,
      companyName: companyName,
      category: _parseCategory(category),
      variety: variety,
      quantityKg: quantityKg,
      pricePerKg: pricePerKg,
      district: district,
      description: description,
      contactPhone: contactPhone,
      postedDate: createdAt,
      isOwn: isOwn,
    );
  }

  static StoreCategory _parseCategory(String cat) {
    switch (cat) {
      case 'paddy':
        return StoreCategory.paddy;
      case 'rice':
        return StoreCategory.rice;
      case 'riceMeal':
        return StoreCategory.riceMeal;
      default:
        return StoreCategory.other;
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class StoreListingsResponse {
  final List<StoreListingModel> items;
  final int total;
  final int page;
  final int pages;

  const StoreListingsResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pages,
  });

  factory StoreListingsResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return StoreListingsResponse(
      items: rawItems
          .map((e) => StoreListingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pages: json['pages'] as int? ?? 1,
    );
  }
}
