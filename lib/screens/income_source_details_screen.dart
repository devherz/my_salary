import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/budget_rule.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/savings_goal.dart';
import '../providers/salary_provider.dart';
import '../widgets/add_goal_modal.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/transaction_tile.dart';

class IncomeSourceDetailsScreen extends StatefulWidget {
  final String incomeId;

  const IncomeSourceDetailsScreen({
    super.key,
    required this.incomeId,
  });

  @override
  State<IncomeSourceDetailsScreen> createState() => _IncomeSourceDetailsScreenState();
}

class _IncomeSourceDetailsScreenState extends State<IncomeSourceDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditIncomeDialog(BuildContext context, Income income, SalaryProvider provider) {
    final titleController = TextEditingController(text: income.title);
    final amountController = TextEditingController(text: income.amount.toStringAsFixed(2));
    double needs = income.needsRatio;
    double wants = income.wantsRatio;
    double savings = income.savingsRatio;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.edit, color: Color(0xFF10B981)),
                SizedBox(width: 10),
                Text('Modifier la Source'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Nom de la source',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Montant (${provider.currency})',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Répartition Budgétaire Dédiée :',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPresetChip('50/30/20', 50, 30, 20, needs, wants, savings, (n, w, s) {
                          setDialogState(() {
                            needs = n;
                            wants = w;
                            savings = s;
                          });
                        }),
                        _buildPresetChip('70/20/10', 70, 20, 10, needs, wants, savings, (n, w, s) {
                          setDialogState(() {
                            needs = n;
                            wants = w;
                            savings = s;
                          });
                        }),
                        _buildPresetChip('60/20/20', 60, 20, 20, needs, wants, savings, (n, w, s) {
                          setDialogState(() {
                            needs = n;
                            wants = w;
                            savings = s;
                          });
                        }),
                        _buildPresetChip('40/40/20', 40, 40, 20, needs, wants, savings, (n, w, s) {
                          setDialogState(() {
                            needs = n;
                            wants = w;
                            savings = s;
                          });
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('🏠 Besoins : ${needs.toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                  Slider(
                    value: needs,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: const Color(0xFF3B82F6),
                    onChanged: (val) {
                      setDialogState(() {
                        needs = val;
                        final remain = 100 - needs;
                        wants = (remain * 0.6).roundToDouble();
                        savings = 100 - needs - wants;
                      });
                    },
                  ),
                  Text('🎯 Envies : ${wants.toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                  Slider(
                    value: wants,
                    min: 0,
                    max: (100 - needs) > 0 ? 100 - needs : 1,
                    divisions: (100 - needs) > 0 ? (100 - needs).toInt() : 1,
                    activeColor: const Color(0xFF8B5CF6),
                    onChanged: (val) {
                      setDialogState(() {
                        wants = val;
                        savings = 100 - needs - wants;
                      });
                    },
                  ),
                  Text('💰 Épargne : ${savings.toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final newTitle = titleController.text.trim();
                  final newAmount = double.tryParse(amountController.text.replaceAll(',', '.')) ?? income.amount;

                  if (newTitle.isNotEmpty && newAmount > 0) {
                    final updated = Income(
                      id: income.id,
                      title: newTitle,
                      amount: newAmount,
                      date: income.date,
                      isRecurringSalary: income.isRecurringSalary,
                      note: income.note,
                      needsRatio: needs,
                      wantsRatio: wants,
                      savingsRatio: savings,
                    );
                    await provider.updateIncome(updated);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPresetChip(
    String label,
    double n,
    double w,
    double s,
    double curN,
    double curW,
    double curS,
    Function(double, double, double) onSelect,
  ) {
    final isSelected = (curN == n && curW == w && curS == s);
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: isSelected,
        selectedColor: const Color(0xFF10B981).withValues(alpha: 0.2),
        onSelected: (_) => onSelect(n, w, s),
      ),
    );
  }

  void _confirmDeleteIncome(BuildContext context, Income income, SalaryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer cette source ?'),
        content: Text('Voulez-vous vraiment supprimer "${income.title}" ? Ses dépenses et objectifs associés seront conservés en mode global.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await provider.deleteIncome(income.id);
              if (ctx.mounted) {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Return to Dashboard
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalaryProvider>(context);
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: provider.currency);

    // Find target income
    final income = provider.incomes.firstWhere(
      (i) => i.id == widget.incomeId,
      orElse: () => Income(
        id: widget.incomeId,
        title: 'Source de revenu',
        amount: 0.0,
        date: DateTime.now(),
      ),
    );

    // Associated expenses and goals
    final assignedExpenses = provider.expenses.where((e) => e.incomeSourceId == income.id).toList();
    final totalSpent = assignedExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final remaining = income.amount - totalSpent;
    final assignedGoals = provider.savingsGoals.where((g) => g.incomeSourceId == income.id).toList();

    // Specific budget rule allocations for THIS income source
    final needsBudget = (income.needsRatio / 100) * income.amount;
    final wantsBudget = (income.wantsRatio / 100) * income.amount;
    final savingsBudget = (income.savingsRatio / 100) * income.amount;

    final needsSpent = assignedExpenses.where((e) => e.budgetType == BudgetCategoryType.needs).fold<double>(0.0, (sum, e) => sum + e.amount);
    final wantsSpent = assignedExpenses.where((e) => e.budgetType == BudgetCategoryType.wants).fold<double>(0.0, (sum, e) => sum + e.amount);
    final savingsSpent = assignedExpenses.where((e) => e.budgetType == BudgetCategoryType.savings).fold<double>(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(income.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier',
            onPressed: () => _showEditIncomeDialog(context, income, provider),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Supprimer',
            onPressed: () => _confirmDeleteIncome(context, income, provider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        income.title.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              income.statusTag,
                              style: const TextStyle(color: Color(0xFF059669), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              income.frequency,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    formatter.format(income.amount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Dépensé', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            formatter.format(totalSpent),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Solde Reste', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            formatter.format(remaining),
                            style: TextStyle(
                              color: remaining >= 0 ? Colors.white : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Action Bar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('+ Dépense', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => AddTransactionModal.show(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.savings_outlined, size: 18),
                    label: const Text('+ Objectif', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => AddGoalModal.show(context, incomeSourceId: income.id),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Budget Allocations for THIS income
            Text(
              'Répartition Budgétaire (${income.needsRatio.toInt()}/${income.wantsRatio.toInt()}/${income.savingsRatio.toInt()})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _BudgetItemProgress(
              title: '🏠 Besoins (${income.needsRatio.toInt()}%)',
              budget: needsBudget,
              spent: needsSpent,
              color: const Color(0xFF3B82F6),
              formatter: formatter,
            ),
            const SizedBox(height: 8),
            _BudgetItemProgress(
              title: '🎯 Envies (${income.wantsRatio.toInt()}%)',
              budget: wantsBudget,
              spent: wantsSpent,
              color: const Color(0xFF8B5CF6),
              formatter: formatter,
            ),
            const SizedBox(height: 8),
            _BudgetItemProgress(
              title: '💰 Épargne (${income.savingsRatio.toInt()}%)',
              budget: savingsBudget,
              spent: savingsSpent,
              color: const Color(0xFF10B981),
              formatter: formatter,
            ),
            const SizedBox(height: 24),

            // 4. Tab Header (Dépenses vs Objectifs)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[700],
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'Dépenses (${assignedExpenses.length})'),
                  Tab(text: 'Objectifs (${assignedGoals.length})'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Content
            SizedBox(
              height: 300,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Expenses
                  assignedExpenses.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucune dépense affectée à ce revenu pour l\'instant.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: assignedExpenses.length,
                          itemBuilder: (context, index) {
                            final expense = assignedExpenses[index];
                            return ExpenseTile(
                              expense: expense,
                              currency: provider.currency,
                              onDelete: () => provider.deleteExpense(expense.id),
                            );
                          },
                        ),

                  // Tab 2: Savings Goals
                  assignedGoals.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucun objectif d\'épargne rattaché à ce revenu.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: assignedGoals.length,
                          itemBuilder: (context, index) {
                            final goal = assignedGoals[index];
                            final color = Color(goal.colorHex);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: color.withValues(alpha: 0.15),
                                  child: Icon(Icons.stars, color: color),
                                ),
                                title: Text(goal.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${formatter.format(goal.currentAmount)} / ${formatter.format(goal.targetAmount)}'),
                                trailing: Text(
                                  '${(goal.progressPercentage * 100).toInt()}%',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetItemProgress extends StatelessWidget {
  final String title;
  final double budget;
  final double spent;
  final Color color;
  final NumberFormat formatter;

  const _BudgetItemProgress({
    required this.title,
    required this.budget,
    required this.spent,
    required this.color,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final remaining = budget - spent;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(
                '${formatter.format(spent)} / ${formatter.format(budget)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Reste: ${formatter.format(remaining)}',
            style: TextStyle(fontSize: 11, color: remaining >= 0 ? Colors.grey[600] : Colors.red),
          ),
        ],
      ),
    );
  }
}
