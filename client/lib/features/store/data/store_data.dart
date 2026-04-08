// lib/features/store/data/store_data.dart

enum StoreCategory { paddy, rice, riceMeal, other }

class StoreItem {
  final String id;
  final String companyName;
  final String companyId;
  final StoreCategory category;
  final String variety;
  final double quantityKg;
  final double pricePerKg;
  final String district;
  final String description;
  final String contactPhone;
  final DateTime postedDate;
  bool isOwn; // true if added by current session user

  StoreItem({
    required this.id,
    required this.companyName,
    required this.companyId,
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
}

// ─── Singleton in-memory store ───────────────────────────────────────────────
class StoreRepository {
  StoreRepository._();
  static final StoreRepository instance = StoreRepository._();

  final List<StoreItem> _items = [
    // ── Paddy listings ────────────────────────────────────────────────────
    StoreItem(
      id: 'p1',
      companyName: 'ගමුණු රයිස් මිල්',
      companyId: 'c1',
      category: StoreCategory.paddy,
      variety: 'සම්බා (Samba)',
      quantityKg: 5000,
      pricePerKg: 68,
      district: 'පොළොන්නරුව',
      description: 'හොඳ තත්ත්වයේ සම්බා වී. අළුතෙන් අස්වනු නෙළූ.',
      contactPhone: '0712345678',
      postedDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    StoreItem(
      id: 'p2',
      companyName: 'සේනානායක ඇග්‍රො',
      companyId: 'c2',
      category: StoreCategory.paddy,
      variety: 'නාඩු (Nadu)',
      quantityKg: 8000,
      pricePerKg: 58,
      district: 'කුරුණෑගල',
      description: 'BG 352 නාඩු වී. ගබඩාවේ ගුවන්කාලීනව ගබඩා කළ.',
      contactPhone: '0723456789',
      postedDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
    StoreItem(
      id: 'p3',
      companyName: 'රනිල් ෆාම්',
      companyId: 'c3',
      category: StoreCategory.paddy,
      variety: 'කීරි සම්බා (Keeri Samba)',
      quantityKg: 3000,
      pricePerKg: 85,
      district: 'අනුරාධපුර',
      description: 'දේශීය ප්‍රභේදය. රසාවිලින් ඉහළ.',
      contactPhone: '0734567890',
      postedDate: DateTime.now().subtract(const Duration(days: 3)),
    ),
    StoreItem(
      id: 'p4',
      companyName: 'Mahaweli Paddy Hub',
      companyId: 'c4',
      category: StoreCategory.paddy,
      variety: 'BG 250',
      quantityKg: 12000,
      pricePerKg: 55,
      district: 'මහනුවර',
      description: 'Large quantity available. Freshly harvested.',
      contactPhone: '0745678901',
      postedDate: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    StoreItem(
      id: 'p5',
      companyName: 'දිසාපතිරාජ ගොවි',
      companyId: 'c5',
      category: StoreCategory.paddy,
      variety: 'BG 379',
      quantityKg: 4500,
      pricePerKg: 62,
      district: 'ගාල්ල',
      description: 'දකුණු ශ්‍රී ලංකාවේ වගා කළ. BG 379.',
      contactPhone: '0756789012',
      postedDate: DateTime.now().subtract(const Duration(days: 4)),
    ),

    // ── Rice listings ─────────────────────────────────────────────────────
    StoreItem(
      id: 'r1',
      companyName: 'ගමුණු රයිස් මිල්',
      companyId: 'c1',
      category: StoreCategory.rice,
      variety: 'සුදු සහල් - සම්බා',
      quantityKg: 3000,
      pricePerKg: 145,
      district: 'පොළොන්නරුව',
      description: 'කෝල්ඩ් ස්ටෝරේජ් සහල්. ඉහළ තත්ත්වය.',
      contactPhone: '0712345678',
      postedDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    StoreItem(
      id: 'r2',
      companyName: 'කොළඹ රයිස් ට්‍රේඩ්',
      companyId: 'c6',
      category: StoreCategory.rice,
      variety: 'රතු සහල් (Red Rice)',
      quantityKg: 1500,
      pricePerKg: 175,
      district: 'කොළඹ',
      description: 'ශ්‍රී ලංකා ස්වාභාවික රතු සහල්.',
      contactPhone: '0767890123',
      postedDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
    StoreItem(
      id: 'r3',
      companyName: 'Agrex Lanka',
      companyId: 'c7',
      category: StoreCategory.rice,
      variety: 'Keeri Samba White',
      quantityKg: 2000,
      pricePerKg: 195,
      district: 'ගම්පහ',
      description: 'Premium quality keeri samba. Ready for retail.',
      contactPhone: '0778901234',
      postedDate: DateTime.now().subtract(const Duration(hours: 12)),
    ),

    // ── Rice Meal / Bran listings ──────────────────────────────────────────
    StoreItem(
      id: 'm1',
      companyName: 'සේනානායක ඇග්‍රො',
      companyId: 'c2',
      category: StoreCategory.riceMeal,
      variety: 'හාල් කුළු (Rice Bran)',
      quantityKg: 10000,
      pricePerKg: 22,
      district: 'කුරුණෑගල',
      description: 'නැවුම් හාල් කුළු. සත්ව ආහාර සඳහා සුදුසු.',
      contactPhone: '0723456789',
      postedDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    StoreItem(
      id: 'm2',
      companyName: 'ගමුණු රයිස් මිල්',
      companyId: 'c1',
      category: StoreCategory.riceMeal,
      variety: 'හාල් පිටි (Rice Flour)',
      quantityKg: 2000,
      pricePerKg: 95,
      district: 'පොළොන්නරුව',
      description: '100% හාල් පිටි. රොටී සහ ආහාර සඳහා.',
      contactPhone: '0712345678',
      postedDate: DateTime.now().subtract(const Duration(days: 3)),
    ),

    // ── Other items ───────────────────────────────────────────────────────
    StoreItem(
      id: 'o1',
      companyName: 'Agrex Lanka',
      companyId: 'c7',
      category: StoreCategory.other,
      variety: 'PP මල්ල (PP Bags) 50kg',
      quantityKg: 0,
      pricePerKg: 0,
      district: 'ගම්පහ',
      description: '50kg PP bags - 1000 units available. Rs.45 each.',
      contactPhone: '0778901234',
      postedDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
    StoreItem(
      id: 'o2',
      companyName: 'Lanka Agri Tools',
      companyId: 'c8',
      category: StoreCategory.other,
      variety: 'මීට්ටු යෙදීමේ යන්ත්‍රය (Paddy Thresher)',
      quantityKg: 0,
      pricePerKg: 0,
      district: 'කළුතර',
      description: 'Used paddy thresher. Good condition. Rs.95,000.',
      contactPhone: '0789012345',
      postedDate: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  List<StoreItem> getAll() => List.unmodifiable(_items);

  List<StoreItem> getByCategory(StoreCategory category) =>
      _items.where((i) => i.category == category).toList();

  void addItem(StoreItem item) => _items.insert(0, item);

  int countByCategory(StoreCategory category) =>
      _items.where((i) => i.category == category).length;
}
