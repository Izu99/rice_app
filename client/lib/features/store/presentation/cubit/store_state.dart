import 'package:equatable/equatable.dart';
import '../../../../domain/entities/store_listing_entity.dart';

enum StoreStatus { initial, loading, adding, updating, success, error }

class StoreState extends Equatable {
  final StoreStatus status;
  final List<StoreListingEntity> listings;
  final Map<StoreCategory, int> categoryCounts;
  final int totalListings;
  final int totalCompanies;
  final int totalDistricts;
  final StoreCategory? currentCategory;
  final String? errorMessage;

  const StoreState({
    this.status = StoreStatus.initial,
    this.listings = const [],
    this.categoryCounts = const {},
    this.totalListings = 0,
    this.totalCompanies = 0,
    this.totalDistricts = 0,
    this.currentCategory,
    this.errorMessage,
  });

  StoreState copyWith({
    StoreStatus? status,
    List<StoreListingEntity>? listings,
    Map<StoreCategory, int>? categoryCounts,
    int? totalListings,
    int? totalCompanies,
    int? totalDistricts,
    StoreCategory? currentCategory,
    String? errorMessage,
  }) {
    return StoreState(
      status: status ?? this.status,
      listings: listings ?? this.listings,
      categoryCounts: categoryCounts ?? this.categoryCounts,
      totalListings: totalListings ?? this.totalListings,
      totalCompanies: totalCompanies ?? this.totalCompanies,
      totalDistricts: totalDistricts ?? this.totalDistricts,
      currentCategory: currentCategory ?? this.currentCategory,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        listings,
        categoryCounts,
        totalListings,
        totalCompanies,
        totalDistricts,
        currentCategory,
        errorMessage,
      ];
}
