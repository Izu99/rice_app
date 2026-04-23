import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/h_app_bar.dart';
import '../../../../domain/entities/store_listing_entity.dart';
import '../cubit/store_cubit.dart';
import '../cubit/store_state.dart';

class AddListingPage extends StatefulWidget {
  final StoreCategory? preselectedCategory;
  final Color categoryColor;
  final StoreListingEntity? existingListing;

  const AddListingPage({
    super.key,
    this.preselectedCategory,
    this.categoryColor = AppColors.primary,
    this.existingListing,
  });

  bool get isEditing => existingListing != null;

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final _formKey = GlobalKey<FormState>();

  StoreCategory? _selectedCategory;
  final _varietyCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _selectedDistrict;

  static const _categories = [
    _CatOption(StoreCategory.paddy, 'Paddy (වී)', Icons.grass_rounded, Color(0xFF2E7D32)),
    _CatOption(StoreCategory.rice, 'Rice (සහල්)', Icons.rice_bowl_rounded, Color(0xFFE65100)),
    _CatOption(StoreCategory.riceMeal, 'Rice Bran / Flour (හාල් කුළු / පිටි)', Icons.grain_rounded, Color(0xFF6D4C41)),
    _CatOption(StoreCategory.other, 'Other (වෙනත්)', Icons.category_rounded, Color(0xFF1565C0)),
  ];

  static const _districts = [
    'කොළඹ', 'ගම්පහ', 'කළුතර', 'කණ්ඩි', 'මාතලේ', 'නුවරඑළිය', 'ගාල්ල', 'මාතර',
    'හම්බන්තොට', 'යාපනය', 'කිලිනොච්චිය', 'මන්නාරම', 'මුලතිව්', 'වවුනියාව',
    'ත්‍රිකුණාමලය', 'බත්තිකලෝව', 'අම්පාර', 'කුරුණෑගල', 'පුත්තලම',
    'අනුරාධපුර', 'පොළොන්නරුව', 'බදුල්ල', 'මොණරාගල', 'රත්නපුර', 'කෑගල්ල',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingListing;
    if (existing != null) {
      // Edit mode — pre-fill all fields
      _selectedCategory = existing.category;
      _varietyCtrl.text = existing.variety;
      _quantityCtrl.text =
          existing.quantityKg > 0 ? existing.quantityKg.toStringAsFixed(0) : '';
      _priceCtrl.text =
          existing.pricePerKg > 0 ? existing.pricePerKg.toStringAsFixed(0) : '';
      _descriptionCtrl.text = existing.description;
      _phoneCtrl.text = existing.contactPhone;
      _selectedDistrict = existing.district;
    } else {
      _selectedCategory = widget.preselectedCategory;
    }
  }

  @override
  void dispose() {
    _varietyCtrl.dispose();
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _descriptionCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Color get _accentColor {
    if (_selectedCategory == null) return widget.categoryColor;
    return _categories.firstWhere((c) => c.category == _selectedCategory).color;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }
    if (_selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a district')));
      return;
    }

    final cubit = context.read<StoreCubit>();
    final bool success;

    if (widget.isEditing) {
      success = await cubit.updateListing(
        widget.existingListing!.id,
        variety: _varietyCtrl.text.trim(),
        district: _selectedDistrict,
        contactPhone: _phoneCtrl.text.trim(),
        quantityKg: double.tryParse(_quantityCtrl.text) ?? 0,
        pricePerKg: double.tryParse(_priceCtrl.text) ?? 0,
        description: _descriptionCtrl.text.trim(),
      );
    } else {
      success = await cubit.addListing(
        category: _selectedCategory!,
        variety: _varietyCtrl.text.trim(),
        district: _selectedDistrict!,
        contactPhone: _phoneCtrl.text.trim(),
        quantityKg: double.tryParse(_quantityCtrl.text) ?? 0,
        pricePerKg: double.tryParse(_priceCtrl.text) ?? 0,
        description: _descriptionCtrl.text.trim(),
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing ? 'Listing updated!' : 'Listing added successfully!'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cubit.state.errorMessage ?? (widget.isEditing ? 'Failed to update' : 'Failed to add listing')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: HAppBar(
        title: widget.isEditing ? 'සංස්කරණය කරන්න' : 'ලැයිස්තු කරන්න',
        subtitle: widget.isEditing ? 'Edit Listing' : 'Add New Listing',
      ),
      body: BlocBuilder<StoreCubit, StoreState>(
        builder: (context, state) {
          final isSaving = state.status == StoreStatus.adding ||
              state.status == StoreStatus.updating;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionLabel('Category / කාණ්ඩය'),
                const SizedBox(height: 8),
                // Category is locked in edit mode — changing it would require
                // a different API and breaks stock type consistency
                if (widget.isEditing)
                  _buildLockedCategory()
                else
                  _buildCategorySelector(),
                const SizedBox(height: 20),
                _buildSectionLabel('Variety / ප්‍රභේදය'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _varietyCtrl,
                  hint: 'e.g. සම්බා, BG 252, Rice Bran...',
                  icon: Icons.grain_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('Quantity (kg)'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _quantityCtrl,
                            hint: '0',
                            icon: Icons.scale_rounded,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('Price / kg (Rs.)'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _priceCtrl,
                            hint: '0.00',
                            icon: Icons.attach_money_rounded,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('District / දිස්ත්‍රික්කය'),
                const SizedBox(height: 8),
                _buildDistrictDropdown(),
                const SizedBox(height: 16),
                _buildSectionLabel('Contact Phone / දුරකථනය'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _phoneCtrl,
                  hint: '07XXXXXXXX',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (v.length < 9) return 'Enter valid phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('Description / විස්තරය (Optional)'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _descriptionCtrl,
                  hint: 'Additional details about the item...',
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: isSaving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            widget.isEditing ? 'Update Listing' : 'Post Listing',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54));
  }

  Widget _buildLockedCategory() {
    if (_selectedCategory == null) return const SizedBox.shrink();
    final opt = _categories.firstWhere((c) => c.category == _selectedCategory);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: opt.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: opt.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(opt.icon, color: opt.color, size: 18),
          const SizedBox(width: 8),
          Text(opt.label,
              style: TextStyle(
                  color: opt.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
          const SizedBox(width: 8),
          Text('(cannot change)',
              style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.map((opt) {
        final isSelected = _selectedCategory == opt.category;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = opt.category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? opt.color : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isSelected ? opt.color : Colors.grey.shade300, width: 1.5),
              boxShadow: isSelected
                  ? [BoxShadow(color: opt.color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(opt.icon, color: isSelected ? Colors.white : opt.color, size: 18),
                const SizedBox(width: 8),
                Text(opt.label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
        prefixIcon: Icon(icon, size: 20, color: Colors.black38),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _accentColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDistrictDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDistrict,
      hint: const Text('Select district', style: TextStyle(fontSize: 13, color: Colors.black38)),
      onChanged: (v) => setState(() => _selectedDistrict = v),
      items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.location_on_rounded, size: 20, color: Colors.black38),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _accentColor, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _CatOption {
  final StoreCategory category;
  final String label;
  final IconData icon;
  final Color color;
  const _CatOption(this.category, this.label, this.icon, this.color);
}
