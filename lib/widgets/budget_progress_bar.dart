import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/budget_rule.dart';
import '../providers/salary_provider.dart';

class BudgetProgressBarSection extends StatelessWidget {
  const BudgetProgressBarSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalaryProvider>(context);
    final rule = provider.budgetRule;
    final currency = provider.currency;
    final formatter = NumberFormat.currency(
      symbol: currency,
      decimalDigits: 0,
      locale: 'fr_FR',
    );

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.pie_chart,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Règle ${rule.needsPercent.toInt()}/${rule.wantsPercent.toInt()}/${rule.savingsPercent.toInt()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Budget Alloué',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Besoins Bar (50%)
            _BudgetItemProgress(
              title: BudgetCategoryType.needs.displayName,
              subtitle: 'Logement, factures, courses...',
              spent: provider.needsExpensesSpent,
              allowed: provider.needsBudgetAllowed,
              targetPercent: rule.needsPercent,
              color: const Color(0xFF3B82F6), // Blue
              formatter: formatter,
            ),
            const SizedBox(height: 16),
            // Envies Bar (30%)
            _BudgetItemProgress(
              title: BudgetCategoryType.wants.displayName,
              subtitle: 'Sorties, shopping, loisirs...',
              spent: provider.wantsExpensesSpent,
              allowed: provider.wantsBudgetAllowed,
              targetPercent: rule.wantsPercent,
              color: const Color(0xFFF59E0B), // Amber
              formatter: formatter,
            ),
            const SizedBox(height: 16),
            // Épargne Bar (20%)
            _BudgetItemProgress(
              title: BudgetCategoryType.savings.displayName,
              subtitle: 'Investissement, objectifs...',
              spent: provider.savingsExpensesSpent,
              allowed: provider.savingsBudgetAllowed,
              targetPercent: rule.savingsPercent,
              color: const Color(0xFF10B981), // Emerald Green
              formatter: formatter,
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetItemProgress extends StatelessWidget {
  final String title;
  final String subtitle;
  final double spent;
  final double allowed;
  final double targetPercent;
  final Color color;
  final NumberFormat formatter;

  const _BudgetItemProgress({
    required this.title,
    required this.subtitle,
    required this.spent,
    required this.allowed,
    required this.targetPercent,
    required this.color,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final progress = allowed > 0 ? (spent / allowed).clamp(0.0, 1.0) : 0.0;
    final isExceeded = spent > allowed && allowed > 0;
    final spentRatioPercent = allowed > 0 ? ((spent / allowed) * 100).toInt() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${targetPercent.toInt()}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${formatter.format(spent)} / ${formatter.format(allowed)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isExceeded ? Colors.red : Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: isExceeded ? Colors.red : color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
            Text(
              isExceeded ? 'Dépassé de ${(spent - allowed).toInt()} ${formatter.currencySymbol}' : '$spentRatioPercent% utilisé',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isExceeded ? Colors.red : Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
