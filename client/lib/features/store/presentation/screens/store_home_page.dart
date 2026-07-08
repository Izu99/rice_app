import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/h_app_bar.dart';
import '../../../../domain/entities/store_listing_entity.dart';
import '../../../../injection_container.dart' as di;
import '../cubit/store_cubit.dart';
import '../cubit/store_state.dart';
import 'category_listings_page.dart';

class StoreHomePage extends StatelessWidget {
  const StoreHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<StoreCubit>()..loadStats(),
      child: const _StoreHomeBody(),
    );
  }
}

class _StoreHomeBody extends StatelessWidget {
  const _StoreHomeBody();

  @override
  Widget build(BuildContext context) {
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
                  _buildWelcomeBanner(),
                  const SizedBox(height: 24),
                  _buildSectionChip('ප්‍රධාන කාණ්ඩ · Categories'),
                  const SizedBox(height: 14),
                  _buildCategoryGrid(context),
                  const SizedBox(height: 24),
                  _buildInfoBanner(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return HSliverAppBar(
      pinned: true,
      onRefresh: () => context.read<StoreCubit>().loadStats(),
      title: 'සහල් වෙළෙඳපොළ',
      subtitle: 'Rice Marketplace',
    );
  }

  Widget _buildWelcomeBanner() {
    return BlocBuilder<StoreCubit, StoreState>(
      builder: (context, state) {
        final total = state.totalListings;
        final companies = state.totalCompanies;
        final districts = state.totalDistricts;

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
              Row(
                children: [
                  const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    SiStrings.liveMarketplace,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              state.status == StoreStatus.loading
                  ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                  : Row(
                      children: [
                        _buildStatPill(Icons.inventory_2_rounded, '$total', SiStrings.listingsWord),
                        const SizedBox(width: 10),
                        _buildStatPill(Icons.business_rounded, '$companies', SiStrings.companiesWord),
                        const SizedBox(width: 10),
                        _buildStatPill(Icons.location_on_rounded, '$districts', SiStrings.districtsWord),
                      ],
                    ),
            ],
          ),
        );
      },
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
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

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

  Widget _buildCategoryGrid(BuildContext context) {
    final categories = [
      _CategoryItem(
        category: StoreCategory.paddy,
        siLabel: 'වී',
        enLabel: 'Paddy',
        icon: Icons.grass_rounded,
        color: const Color(0xFF2E7D32),
      ),
      _CategoryItem(
        category: StoreCategory.rice,
        siLabel: 'සහල්',
        enLabel: 'Rice',
        icon: Icons.rice_bowl_rounded,
        color: const Color(0xFFE65100),
      ),
      _CategoryItem(
        category: StoreCategory.riceMeal,
        siLabel: 'හාල් කුළු',
        enLabel: 'Bran / Flour',
        icon: Icons.grain_rounded,
        color: const Color(0xFF6D4C41),
      ),
      _CategoryItem(
        category: StoreCategory.other,
        siLabel: 'වෙනත්',
        enLabel: 'Other',
        icon: Icons.category_rounded,
        color: const Color(0xFF1565C0),
      ),
    ];

    return BlocBuilder<StoreCubit, StoreState>(
      builder: (context, state) {
        return GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 6,
          mainAxisSpacing: 8,
          childAspectRatio: 0.63,
          children: categories.map((c) => _buildCategoryItem(context, c, state)).toList(),
        );
      },
    );
  }

  Widget _buildCategoryItem(BuildContext context, _CategoryItem cat, StoreState state) {
    final count = state.categoryCounts[cat.category] ?? 0;
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
              border: Border.all(color: cat.color.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Center(child: Icon(cat.icon, color: cat.color, size: 24)),
          ),
          const SizedBox(height: 6),
          Text(
            cat.siLabel,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2C2C3E), height: 1.2),
          ),
          Text(
            cat.enLabel,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: Colors.grey, height: 1.2),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cat.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
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
              child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SiStrings.listYourProductsTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    SiStrings.listYourProductsSubtitle,
                    style: const TextStyle(color: Colors.black54, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  final StoreCategory category;
  final String siLabel;
  final String enLabel;
  final IconData icon;
  final Color color;

  const _CategoryItem({
    required this.category,
    required this.siLabel,
    required this.enLabel,
    required this.icon,
    required this.color,
  });
}
