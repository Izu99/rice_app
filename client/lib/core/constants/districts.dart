/// Sri Lankan Districts
class SriLankanDistricts {
  SriLankanDistricts._();

  /// All Sri Lankan districts
  static const List<String> allDistricts = [
    'Colombo',
    'Gampaha',
    'Kalutara',
    'Kandy',
    'Matara',
    'Galle',
    'Hambantota',
    'Jaffna',
    'Mullaitivu',
    'Batticaloa',
    'Trincomalee',
    'Kurunegala',
    'Puttalam',
    'Anuradhapura',
    'Polonnaruwa',
    'Badulla',
    'Nuwara Eliya',
    'Ratnapura',
    'Kegalle',
  ];

  /// Get all districts sorted alphabetically
  static List<String> get sortedDistricts {
    final sorted = [...allDistricts];
    sorted.sort();
    return sorted;
  }

  /// Check if a district is valid
  static bool isValidDistrict(String? district) {
    if (district == null || district.isEmpty) return false;
    return allDistricts
        .map((d) => d.toLowerCase())
        .contains(district.toLowerCase());
  }

  /// Normalize district name (capitalize properly)
  static String normalizeDistrict(String district) {
    return allDistricts.firstWhere(
      (d) => d.toLowerCase() == district.toLowerCase(),
      orElse: () => district,
    );
  }
}
