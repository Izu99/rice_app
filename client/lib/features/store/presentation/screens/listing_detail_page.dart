import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/store_listing_entity.dart';

class ListingDetailPage extends StatelessWidget {
  final StoreListingEntity item;
  final Color color;

  const ListingDetailPage({
    super.key,
    required this.item,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompanyCard(),
                  const SizedBox(height: 16),
                  _buildDetailsCard(),
                  const SizedBox(height: 16),
                  if (item.description.isNotEmpty) _buildDescriptionCard(),
                  if (item.description.isNotEmpty) const SizedBox(height: 16),
                  _buildContactCard(context),
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
    return SliverAppBar(
      pinned: true,
      backgroundColor: color,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.variety,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          Text(_categoryLabel(item.category), style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCompanyCard() {
    final daysSince = DateTime.now().difference(item.postedDate).inDays;
    final timeLabel = daysSince == 0 ? 'Posted today' : daysSince == 1 ? 'Posted yesterday' : 'Posted $daysSince days ago';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Center(
              child: Text(
                item.companyName.isNotEmpty ? item.companyName[0].toUpperCase() : '?',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.companyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 13, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text(item.district, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(timeLabel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          if (item.isOwn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Text('My Listing', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.variety, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 16),
          if (item.pricePerKg > 0) ...[
            _buildDetailRow(icon: Icons.attach_money_rounded, label: 'Price per kg', value: 'Rs. ${item.pricePerKg.toStringAsFixed(2)}', valueColor: const Color(0xFF2E7D32)),
            const SizedBox(height: 12),
          ],
          if (item.quantityKg > 0) ...[
            _buildDetailRow(icon: Icons.scale_rounded, label: 'Available quantity', value: '${item.quantityKg.toStringAsFixed(0)} kg', valueColor: const Color(0xFF1565C0)),
            const SizedBox(height: 12),
          ],
          if (item.pricePerKg > 0 && item.quantityKg > 0) ...[
            _buildDetailRow(icon: Icons.calculate_rounded, label: 'Total value', value: 'Rs. ${(item.pricePerKg * item.quantityKg).toStringAsFixed(0)}', valueColor: Colors.black87),
            const SizedBox(height: 12),
          ],
          _buildDetailRow(icon: Icons.location_on_rounded, label: 'District', value: item.district, valueColor: Colors.black87),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value, required Color valueColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: valueColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, size: 18, color: Colors.black54),
              SizedBox(width: 8),
              Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 10),
          Text(item.description, style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.08), color.withOpacity(0.04)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              const Text('Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(item.contactPhone, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color, letterSpacing: 1)),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: item.contactPhone));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phone number copied!'), duration: Duration(seconds: 2)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Copy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _categoryLabel(StoreCategory cat) {
    switch (cat) {
      case StoreCategory.paddy:
        return 'Paddy';
      case StoreCategory.rice:
        return 'Rice';
      case StoreCategory.riceMeal:
        return 'Rice Bran / Flour';
      case StoreCategory.other:
        return 'Other';
    }
  }
}
