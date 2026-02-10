import 'package:equatable/equatable.dart';
import '../../core/constants/enums.dart';

class ExpenseEntity extends Equatable {
  final String id;
  final String title;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String? notes;
  final String? createdByName;

  const ExpenseEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.notes,
    this.createdByName,
  });

  @override
  List<Object?> get props => [id, title, category, amount, date, notes, createdByName];

  factory ExpenseEntity.empty() {
    return ExpenseEntity(
      id: '',
      title: '',
      category: ExpenseCategory.other,
      amount: 0,
      date: DateTime.now(),
    );
  }
}
