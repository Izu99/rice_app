import '../../core/constants/enums.dart';
import '../../domain/entities/expense_entity.dart';

class ExpenseModel {
  final String id;
  final String title;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String? notes;
  final String? createdByName;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.notes,
    this.createdByName,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      category: ExpenseCategory.fromString(json['category'] ?? 'other'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['expenseDate'] != null 
          ? DateTime.parse(json['expenseDate']) 
          : DateTime.now(),
      notes: json['notes'],
      createdByName: json['createdBy'] != null 
          ? (json['createdBy'] is Map ? json['createdBy']['name'] : json['createdBy'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category.value,
      'amount': amount,
      'expenseDate': date.toIso8601String(),
      'notes': notes,
    };
  }

  ExpenseEntity toEntity() {
    return ExpenseEntity(
      id: id,
      title: title,
      category: category,
      amount: amount,
      date: date,
      notes: notes,
      createdByName: createdByName,
    );
  }
}
