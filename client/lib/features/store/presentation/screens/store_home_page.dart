// lib/features/store/presentation/screens/store_home_page.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/store_data.dart';
import 'category_listings_page.dart';

class StoreHomePage extends StatelessWidget {
  const StoreHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = StoreRepository.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildWelcomeBanner(repo),
                  const SizedBox(height: 24),
                  _buildSectionChip('ප්‍රධාන කාණ්ඩ · Categories'),
                  const SizedBox(height: 14),
                  _buildCategoryGrid(context, repo),
                  const SizedBox(height: 24),
                  _buildInfoBanner(context, repo),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ─────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'සහල් වෙළෙඳපොළ',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            'Rice Marketplace',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ─── Welcome / Stats Banner ───────────────────────────────────────────────
  Widget _buildWelcomeBanner(StoreRepository repo) {
    final total = repo.getAll().length;
    final companies = repo.getAll().map((e) => e.companyId).toSet().length;
    final districts = repo.getAll().map((e) => e.district).toSet().length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Live Marketplace',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatPill(Icons.inventory_2_rounded, '$total', 'Listings'),
              const SizedBox(width: 10),
              _buildStatPill(Icons.business_rounded, '$companies', 'Companies'),
              const SizedBox(width: 10),
              _buildStatPill(
                  Icons.location_on_rounded, '$districts', 'Districts'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section Chip (matches home screen style) ─────────────────────────────
  Widget _buildSectionChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF444466),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ─── Category Grid (Helakuru circular icon style) ─────────────────────────
  Widget _buildCategoryGrid(BuildContext context, StoreRepository repo) {
    final categories = [
      _CategoryItem(
        category: StoreCategory.paddy,
        siLabel: 'වී',
        enLabel: 'Paddy',
        icon: Icons.grass_rounded,
        color: const Color(0xFF2E7D32),
        count: repo.countByCategory(StoreCategory.paddy),
      ),
      _CategoryItem(
        category: StoreCategory.rice,
        siLabel: 'සහල්',
        enLabel: 'Rice',
        icon: Icons.rice_bowl_rounded,
        color: const Color(0xFFE65100),
        count: repo.countByCategory(StoreCategory.rice),
      ),
      _CategoryItem(
        category: StoreCategory.riceMeal,
        siLabel: 'හාල් කුළු',
        enLabel: 'Bran / Flour',
        icon: Icons.grain_rounded,
        color: const Color(0xFF6D4C41),
        count: repo.countByCategory(StoreCategory.riceMeal),
      ),
      _CategoryItem(
        category: StoreCategory.other,
        siLabel: 'වෙනත්',
        enLabel: 'Other',
        icon: Icons.category_rounded,
        color: const Color(0xFF1565C0),
        count: repo.countByCategory(StoreCategory.other),
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 6,
      mainAxisSpacing: 8,
      childAspectRatio: 0.63,
      children: categories.map((c) => _buildCategoryItem(context, c)).toList(),
    );
  }

  Widget _buildCategoryItem(BuildContext context, _CategoryItem cat) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryListingsPage(
            category: cat.category,
            siLabel: cat.siLabel,
            enLabel: cat.enLabel,
            color: cat.color,
            icon: cat.icon,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: cat.color.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(cat.icon, color: cat.color, size: 24),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cat.siLabel,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C2C3E),
              height: 1.2,
            ),
          ),
          Text(
            cat.enLabel,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.grey,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${cat.count}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: cat.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Info Banner ──────────────────────────────────────────────────────────
  Widget _buildInfoBanner(BuildContext context, StoreRepository repo) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CategoryListingsPage(
            category: StoreCategory.paddy,
            siLabel: 'වී',
            enLabel: 'Paddy',
            color: Color(0xFF2E7D32),
            icon: Icons.grass_rounded,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ඔබගේ නිෂ්පාදන ලැයිස්තු කරන්න',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'List your rice & paddy products for other companies to see.',
                    style: TextStyle(color: Colors.black54, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────
class _CategoryItem {
  final StoreCategory category;
  final String siLabel;
  final String enLabel;
  final IconData icon;
  final Color color;
  final int count;

  const _CategoryItem({
    required this.category,
    required this.siLabel,
    required this.enLabel,
    required this.icon,
    required this.color,
    required this.count,
  });
}
