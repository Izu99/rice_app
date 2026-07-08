import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/h_app_bar.dart';
import '../../../../domain/entities/store_listing_entity.dart';
import '../../../../injection_container.dart' as di;
import '../cubit/store_cubit.dart';
import '../cubit/store_state.dart';
import 'add_listing_page.dart';
import 'listing_detail_page.dart';
import '../../../../core/shared_widgets/app_fab.dart';

class CategoryListingsPage extends StatefulWidget {
  final StoreCategory category;
  final String siLabel;
  final String enLabel;
  final Color color;
  final IconData icon;

  const CategoryListingsPage({
    super.key,
    required this.category,
    required this.siLabel,
    required this.enLabel,
    required this.color,
    required this.icon,
  });

  @override
  State<CategoryListingsPage> createState() => _CategoryListingsPageState();
}

class _CategoryListingsPageState extends State<CategoryListingsPage> {
  late final StoreCubit _cubit;
  String? _selectedDistrict;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = di.sl<StoreCubit>()..loadListingsByCategory(widget.category);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<StoreListingEntity> _filtered(List<StoreListingEntity> all) {
    return all.where((item) {
      final matchesDistrict = _selectedDistrict == null || item.district == _selectedDistrict;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          item.variety.toLowerCase().contains(q) ||
          item.companyName.toLowerCase().contains(q) ||
          item.district.toLowerCase().contains(q);
      return matchesDistrict && matchesSearch;
    }).toList();
  }

  List<String> _districts(List<StoreListingEntity> all) {
    return all.map((e) => e.district).toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<StoreCubit, StoreState>(
        builder: (context, state) {
          final allItems = state.listings;
          final items = _filtered(allItems);

          return Scaffold(
            backgroundColor: const Color(0xFFF4F6FA),
            body: CustomScrollView(
              slivers: [
                _buildAppBar(context, items.length),
                SliverToBoxAdapter(child: _buildSearchBar()),
                SliverToBoxAdapter(child: _buildDistrictFilter(_districts(allItems))),
                if (state.status == StoreStatus.loading)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                else if (items.isEmpty)
                  SliverFillRemaining(child: _buildEmpty())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final item = items[i];
                          if (item.isOwn) {
                            return Dismissible(
                              key: Key(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.delete_rounded,
                                        color: Colors.white, size: 26),
                                    const SizedBox(height: 4),
                                    Text(SiStrings.remove,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              confirmDismiss: (_) =>
                                  _confirmRemoveListing(context),
                              onDismissed: (_) => _cubit.deleteListing(item.id),
                              child: _buildListingCard(context, item),
                            );
                          }
                          return _buildListingCard(context, item);
                        },
                        childCount: items.length,
                      ),
                    ),
                  ),
              ],
            ),
            floatingActionButton: AppFab(
              label: SiStrings.addListing,
              color: widget.color,
              onPressed: () async {
                final added = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: _cubit,
                      child: AddListingPage(
                        preselectedCategory: widget.category,
                        categoryColor: widget.color,
                      ),
                    ),
                  ),
                );
                if (added == true) {
                  _cubit.refreshCategory();
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, int count) {
    return HSliverAppBar(
      pinned: true,
      onRefresh: () => _cubit.refreshCategory(),
      title: widget.siLabel,
      subtitle: '${widget.enLabel} • $count ${SiStrings.listingsWord}',
    );
  }

  void _openEdit(BuildContext context, StoreListingEntity item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _cubit,
          child: AddListingPage(
            preselectedCategory: item.category,
            categoryColor: widget.color,
            existingListing: item,
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmRemoveListing(BuildContext context) =>
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(SiStrings.removeListingTitle),
          content: Text(SiStrings.removeListingContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(SiStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(SiStrings.remove),
            ),
          ],
        ),
      );

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: SiStrings.searchListingHint,
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildDistrictFilter(List<String> districts) {
    if (districts.isEmpty) return const SizedBox(height: 10);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: districts.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return _buildFilterChip(SiStrings.all, _selectedDistrict == null, () => setState(() => _selectedDistrict = null));
          }
          final d = districts[i - 1];
          return _buildFilterChip(d, _selectedDistrict == d, () => setState(() => _selectedDistrict = d));
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? widget.color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? widget.color : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.black54),
        ),
      ),
    );
  }

  Widget _buildListingCard(BuildContext context, StoreListingEntity item) {
    final daysSince = DateTime.now().difference(item.postedDate).inDays;
    final timeLabel = daysSince == 0
        ? SiStrings.today
        : daysSince == 1
            ? SiStrings.yesterday
            : SiStrings.daysAgo(daysSince);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ListingDetailPage(item: item, color: widget.color)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: widget.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Center(
                      child: Text(
                        item.companyName.isNotEmpty ? item.companyName[0].toUpperCase() : '?',
                        style: TextStyle(color: widget.color, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.companyName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87), overflow: TextOverflow.ellipsis),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 12, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(item.district, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(width: 8),
                            const Icon(Icons.schedule_rounded, size: 12, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(timeLabel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (item.isOwn)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(SiStrings.myListing, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _openEdit(context, item),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: widget.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.edit_rounded, size: 14, color: widget.color),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 12),
              Text(item.variety, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.color)),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(item.description, style: const TextStyle(fontSize: 12, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (item.pricePerKg > 0) ...[
                    _buildInfoChip(icon: Icons.attach_money_rounded, label: 'Rs.${item.pricePerKg.toStringAsFixed(0)}/kg', bgColor: const Color(0xFFE8F5E9), textColor: const Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
                  ],
                  if (item.quantityKg > 0) ...[
                    _buildInfoChip(icon: Icons.scale_rounded, label: '${_formatQty(item.quantityKg)} kg', bgColor: const Color(0xFFE3F2FD), textColor: const Color(0xFF1565C0)),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: widget.color, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label, required Color bgColor, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(SiStrings.noListingsFound, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text(SiStrings.beFirstToList, style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  String _formatQty(double qty) {
    if (qty >= 1000) return '${(qty / 1000).toStringAsFixed(1)}k';
    return qty.toStringAsFixed(0);
  }
}
