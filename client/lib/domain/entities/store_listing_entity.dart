import 'package:equatable/equatable.dart';

enum StoreCategory { paddy, rice, riceMeal, other }

class StoreListingEntity extends Equatable {
  final String id;
  final String companyId;
  final String companyName;
  final StoreCategory category;
  final String variety;
  final double quantityKg;
  final double pricePerKg;
  final String district;
  final String description;
  final String contactPhone;
  final DateTime postedDate;
  final bool isOwn;

  const StoreListingEntity({
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
    required this.postedDate,
    this.isOwn = false,
  });

  @override
  List<Object?> get props => [id, companyId, category, variety, district, postedDate];
}
