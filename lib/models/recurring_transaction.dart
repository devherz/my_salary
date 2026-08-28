import 'budget_rule.dart';

class RecurringTransaction {
  final String id;
  final String title;
  final double amount;
  final String category;
  final BudgetCategoryType budgetType;
  final int dayOfMonth; // 1 - 31
  final String? incomeSourceId;
  final bool isActive;

  RecurringTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.budgetType,
    required this.dayOfMonth,
    this.incomeSourceId,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'budgetType': budgetType.name,
        'dayOfMonth': dayOfMonth,
        'incomeSourceId': incomeSourceId,
        'isActive': isActive,
      };

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      budgetType: BudgetCategoryType.values.firstWhere(
        (e) => e.name == json['budgetType'],
        orElse: () => BudgetCategoryType.needs,
      ),
      dayOfMonth: json['dayOfMonth'] as int? ?? 1,
      incomeSourceId: json['incomeSourceId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
