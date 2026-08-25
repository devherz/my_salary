import 'budget_rule.dart';

class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final BudgetCategoryType budgetType;
  final DateTime date;
  final String? note;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.budgetType,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'budgetType': budgetType.name,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      budgetType: BudgetCategoryType.values.firstWhere(
        (e) => e.name == json['budgetType'],
        orElse: () => BudgetCategoryType.needs,
      ),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }
}

class CategoryHelper {
  static const List<String> defaultCategories = [
    'Logement',
    'Alimentation',
    'Transport',
    'Factures & Abonnements',
    'Santé & Bien-être',
    'Shopping & Vêtements',
    'Loisirs & Sorties',
    'Épargne & Projets',
    'Autres',
  ];

  static BudgetCategoryType defaultBudgetTypeForCategory(String category) {
    switch (category) {
      case 'Logement':
      case 'Alimentation':
      case 'Transport':
      case 'Factures & Abonnements':
      case 'Santé & Bien-être':
        return BudgetCategoryType.needs;
      case 'Shopping & Vêtements':
      case 'Loisirs & Sorties':
        return BudgetCategoryType.wants;
      case 'Épargne & Projets':
        return BudgetCategoryType.savings;
      default:
        return BudgetCategoryType.wants;
    }
  }
}
