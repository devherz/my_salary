import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget_rule.dart';
import '../models/expense.dart';
import '../models/income.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final String currency;
  final VoidCallback? onDelete;

  const ExpenseTile({
    super.key,
    required this.expense,
    required this.currency,
    this.onDelete,
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Logement':
        return Icons.home;
      case 'Alimentation':
        return Icons.shopping_cart;
      case 'Transport':
        return Icons.directions_car;
      case 'Factures & Abonnements':
        return Icons.receipt_long;
      case 'Santé & Bien-être':
        return Icons.medical_services;
      case 'Shopping & Vêtements':
        return Icons.shopping_bag;
      case 'Loisirs & Sorties':
        return Icons.sports_esports;
      case 'Épargne & Projets':
        return Icons.savings;
      default:
        return Icons.category;
    }
  }

  Color _getBudgetTypeColor(BudgetCategoryType type) {
    switch (type) {
      case BudgetCategoryType.needs:
        return const Color(0xFF3B82F6);
      case BudgetCategoryType.wants:
        return const Color(0xFFF59E0B);
      case BudgetCategoryType.savings:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: currency,
      decimalDigits: 2,
      locale: 'fr_FR',
    );
    final dateStr = DateFormat('dd MMM', 'fr_FR').format(expense.date);
    final typeColor = _getBudgetTypeColor(expense.budgetType);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.15)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getCategoryIcon(expense.category),
            color: typeColor,
            size: 22,
          ),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              dateStr,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  expense.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '- ${formatter.format(expense.amount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFFEF4444),
                  ),
                ),
                Text(
                  expense.budgetType.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    color: typeColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

class IncomeTile extends StatelessWidget {
  final Income income;
  final String currency;
  final VoidCallback? onDelete;

  const IncomeTile({
    super.key,
    required this.income,
    required this.currency,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: currency,
      decimalDigits: 2,
      locale: 'fr_FR',
    );
    final dateStr = DateFormat('dd MMM', 'fr_FR').format(income.date);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.15)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFFD1FAE5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            color: Color(0xFF059669),
            size: 22,
          ),
        ),
        title: Text(
          income.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          '$dateStr ${income.isRecurringSalary ? '• Recurrent' : ''}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+ ${formatter.format(income.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF10B981),
              ),
            ),
            if (onDelete != null && !income.isRecurringSalary)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
