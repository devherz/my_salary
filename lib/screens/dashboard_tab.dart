import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'income_source_details_screen.dart';
import '../models/savings_goal.dart';
import '../providers/salary_provider.dart';
import '../widgets/add_goal_modal.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/budget_progress_bar.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';

class DashboardTab extends StatelessWidget {
  final Function(int) onNavigateTab;

  const DashboardTab({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalaryProvider>(context);
    final currency = provider.currency;
    final formatter = NumberFormat.currency(
      symbol: currency,
      decimalDigits: 0,
      locale: 'fr_FR',
    );

    final recentExpenses = provider.currentMonthExpenses;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Income Sources Filter Bar
          if (provider.incomes.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    avatar: const Icon(Icons.apps, size: 16),
                    label: Text('Toutes (${provider.incomes.length})'),
                    selected: provider.selectedIncomeSourceId == null,
                    selectedColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                    onSelected: (_) => provider.setSelectedIncomeSourceId(null),
                  ),
                  const SizedBox(width: 8),
                  ...provider.incomes.map((inc) {
                    final isSelected = provider.selectedIncomeSourceId == inc.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        avatar: const Icon(Icons.account_balance_wallet, size: 16),
                        label: Text('${inc.title} (${inc.amount.toStringAsFixed(0)} ${provider.currency})'),
                        selected: isSelected,
                        selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        onSelected: (_) => provider.setSelectedIncomeSourceId(inc.id),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 1. Header Card (Balance, Salary & Expenses)
          const SummaryCard(),
          const SizedBox(height: 20),

          // 2. Quick Action Bar
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.add_circle_outline,
                  label: 'Ajouter',
                  color: const Color(0xFF10B981),
                  onTap: () => AddTransactionModal.show(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.savings_outlined,
                  label: '+ Objectif',
                  color: const Color(0xFF3B82F6),
                  onTap: () => AddGoalModal.show(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.bar_chart,
                  label: 'Analyses',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => onNavigateTab(3), // Navigate to Analytics Tab
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. 50/30/20 Budget Gauge Section
          const BudgetProgressBarSection(),
          const SizedBox(height: 24),

          // 2.5 Central Income Pages Grid Hub
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Color(0xFF10B981), size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Écrans Dédiés des Revenus',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('+ Source'),
                      onPressed: () => AddTransactionModal.show(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Cliquez sur une source pour ouvrir sa page dédiée (Dépenses, Objectifs, Actions) :',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 14),
                if (provider.incomes.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Aucune source de revenu configurée. Cliquez sur + Source pour commencer !',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.22,
                    ),
                    itemCount: provider.incomes.length,
                    itemBuilder: (context, index) {
                      final inc = provider.incomes[index];
                      final assignedExpenses = provider.expenses.where((e) => e.incomeSourceId == inc.id).toList();
                      final totalSpent = assignedExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
                      final remaining = inc.amount - totalSpent;

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => IncomeSourceDetailsScreen(incomeId: inc.id),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF10B981).withValues(alpha: 0.08),
                                const Color(0xFF3B82F6).withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      inc.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF10B981)),
                                ],
                              ),
                              Text(
                                formatter.format(inc.amount),
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Reste: ${formatter.format(remaining)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: remaining >= 0 ? const Color(0xFF10B981) : Colors.red,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Page dédiée',
                                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Savings Goals Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Objectifs d\'Épargne',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => onNavigateTab(2), // Navigate to Goals Tab
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (provider.savingsGoals.isEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withOpacity(0.15)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'Aucun objectif défini. Cliquez sur + Objectif pour commencer !',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.savingsGoals.length,
                itemBuilder: (context, index) {
                  final goal = provider.savingsGoals[index];
                  return _GoalMiniCard(
                    goal: goal,
                    currency: currency,
                    formatter: formatter,
                  );
                },
              ),
            ),
          const SizedBox(height: 24),

          // 5. Recent Transactions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dépenses Récentes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => onNavigateTab(1), // Navigate to Expenses Tab
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (recentExpenses.isEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withOpacity(0.15)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'Aucune dépense enregistrée ce mois-ci.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentExpenses.length > 5 ? 5 : recentExpenses.length,
              itemBuilder: (context, index) {
                final expense = recentExpenses[index];
                return ExpenseTile(
                  expense: expense,
                  currency: currency,
                  onDelete: () => provider.deleteExpense(expense.id),
                );
              },
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalMiniCard extends StatelessWidget {
  final SavingsGoal goal;
  final String currency;
  final NumberFormat formatter;

  const _GoalMiniCard({
    required this.goal,
    required this.currency,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(goal.colorHex);
    final percent = (goal.progressPercentage * 100).toInt();

    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${formatter.format(goal.currentAmount)} / ${formatter.format(goal.targetAmount)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: goal.progressPercentage,
                  backgroundColor: Colors.white,
                  color: color,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
