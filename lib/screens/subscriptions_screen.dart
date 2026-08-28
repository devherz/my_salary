import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/budget_rule.dart';
import '../models/expense.dart';
import '../models/recurring_transaction.dart';
import '../providers/salary_provider.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  void _showAddSubscriptionDialog(BuildContext context, SalaryProvider provider) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    int selectedDay = 1;
    String selectedCategory = CategoryHelper.defaultCategories.first;
    BudgetCategoryType selectedType = BudgetCategoryType.needs;
    String? selectedIncomeId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.autorenew, color: Color(0xFF10B981)),
                SizedBox(width: 10),
                Text('Nouvel Abonnement'),
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
                      labelText: 'Intitulé (ex: Loyer, Netflix, Fibre)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Montant mensuel (${provider.currency})',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: CategoryHelper.defaultCategories
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedCategory = val;
                          selectedType = CategoryHelper.defaultBudgetTypeForCategory(val);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedDay,
                    decoration: InputDecoration(
                      labelText: 'Jour du prélèvement dans le mois',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: List.generate(28, (i) => i + 1)
                        .map((d) => DropdownMenuItem(value: d, child: Text('Chaque $d du mois')))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedDay = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (provider.incomes.isNotEmpty)
                    DropdownButtonFormField<String?>(
                      value: selectedIncomeId,
                      decoration: InputDecoration(
                        labelText: 'Source de revenu prélevée',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Toutes sources (Global)'),
                        ),
                        ...provider.incomes.map((inc) {
                          return DropdownMenuItem<String?>(
                            value: inc.id,
                            child: Text('${inc.title} (${inc.amount.toStringAsFixed(0)} ${provider.currency})'),
                          );
                        }),
                      ],
                      onChanged: (val) => setDialogState(() => selectedIncomeId = val),
                    ),
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
                onPressed: () {
                  final title = titleController.text.trim();
                  final amount = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0.0;

                  if (title.isNotEmpty && amount > 0) {
                    final item = RecurringTransaction(
                      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
                      title: title,
                      amount: amount,
                      category: selectedCategory,
                      budgetType: selectedType,
                      dayOfMonth: selectedDay,
                      incomeSourceId: selectedIncomeId,
                      isActive: true,
                    );
                    provider.addRecurringTransaction(item);
                    Navigator.pop(ctx);
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalaryProvider>(context);
    final currency = provider.currency;
    final formatter = NumberFormat.currency(
      symbol: currency,
      decimalDigits: 2,
      locale: 'fr_FR',
    );

    final subscriptions = provider.recurringTransactions;
    final totalMonthly = subscriptions
        .where((s) => s.isActive)
        .fold<double>(0.0, (sum, s) => sum + s.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Abonnements & Charges Fixes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubscriptionDialog(context, provider),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel Abonnement'),
        backgroundColor: const Color(0xFF10B981),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.autorenew, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Total Charges Récurrentes Mensuelles',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatter.format(totalMonthly),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${subscriptions.where((s) => s.isActive).length} abonnement(s) actif(s)',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Vos Charges Récurrentes Automatiques',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (subscriptions.isEmpty)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'Aucun abonnement configuré.\nCliquez sur + Nouvel Abonnement pour ajouter des charges automatiques (Loyer, Netflix, Fibre...).',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subscriptions.length,
                itemBuilder: (context, index) {
                  final sub = subscriptions[index];
                  final incomeSource = provider.incomes.where((i) => i.id == sub.incomeSourceId).firstOrNull;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: sub.isActive
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.autorenew,
                          color: sub.isActive ? const Color(0xFF10B981) : Colors.grey,
                        ),
                      ),
                      title: Text(
                        sub.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: sub.isActive ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Prélèvement chaque ${sub.dayOfMonth} du mois'),
                          if (incomeSource != null)
                            Text(
                              'Source: ${incomeSource.title}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatter.format(sub.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: sub.isActive,
                            activeColor: const Color(0xFF10B981),
                            onChanged: (_) => provider.toggleRecurringTransaction(sub.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                            onPressed: () => provider.deleteRecurringTransaction(sub.id),
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
    );
  }
}
