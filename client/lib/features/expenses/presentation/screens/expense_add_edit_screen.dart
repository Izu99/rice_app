import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/enums.dart';
import '../cubit/expenses_cubit.dart';
import '../cubit/expenses_state.dart';

class ExpenseAddEditScreen extends StatefulWidget {
  const ExpenseAddEditScreen({super.key});

  @override
  State<ExpenseAddEditScreen> createState() => _ExpenseAddEditScreenState();
}

class _ExpenseAddEditScreenState extends State<ExpenseAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<ExpensesCubit>().addExpense(
        title: _titleController.text.trim(),
        category: _selectedCategory,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        notes: _notesController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpensesCubit, ExpensesState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == ExpensesStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense added successfully'), backgroundColor: AppColors.success),
          );
          context.pop();
          context.read<ExpensesCubit>().resetStatus();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Add New Expense'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModernInput(
                  controller: _titleController,
                  label: 'Expense Title (Required)',
                  icon: Icons.title,
                  validator: (v) => v == null || v.isEmpty ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 20),
                
                _buildCategoryDropdown(),
                const SizedBox(height: 20),

                _buildModernInput(
                  controller: _amountController,
                  label: 'Amount (Rs.) (Required)',
                  icon: Icons.payments,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter an amount';
                    if (double.tryParse(v) == null) return 'Please enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildDatePicker(),
                const SizedBox(height: 20),

                _buildModernInput(
                  controller: _notesController,
                  label: 'Internal Notes (Optional)',
                  icon: Icons.note_alt,
                  maxLines: 3,
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('SAVE EXPENSE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<ExpenseCategory>(
      value: _selectedCategory,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Category (Required)',
        prefixIcon: const Icon(Icons.category, color: AppColors.primary),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      items: ExpenseCategory.values.map((cat) {
        return DropdownMenuItem(
          value: cat,
          child: Text('${cat.displayName} (${cat.sinhalaName})'),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _selectedCategory = v);
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                Text(DateFormat('dd MMMM yyyy').format(_selectedDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
