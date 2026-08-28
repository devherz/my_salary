import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/budget_rule.dart';
import '../providers/salary_provider.dart';
import '../screens/subscriptions_screen.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/transaction_tile.dart';

class ExpensesTab extends StatefulWidget {
  const ExpensesTab({super.key});

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  String _searchQuery = '';
  String _selectedFilter = 'Tous'; // Tous, Besoins, Envies, Épargne, Revenus
  String? _selectedIncomeSourceId;

  final List<String> _filters = ['Tous', 'Besoins', 'Envies', 'Épargne', 'Revenus'];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalaryProvider>(context);
    final currency = provider.currency;
    final formatter = NumberFormat.currency(
      symbol: currency,
      decimalDigits: 2,
      locale: 'fr_FR',
    );

    final monthExpenses = provider.currentMonthExpenses;
    final monthIncomes = provider.currentMonthIncomes;

    // Filter Logic
    final filteredExpenses = monthExpenses.where((exp) {
      final matchesSearch = exp.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          exp.category.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;
      if (_selectedIncomeSourceId != null && exp.incomeSourceId != _selectedIncomeSourceId) return false;

      if (_selectedFilter == 'Tous') return true;
      if (_selectedFilter == 'Besoins') return exp.budgetType == BudgetCategoryType.needs;
      if (_selectedFilter == 'Envies') return exp.budgetType == BudgetCategoryType.wants;
      if (_selectedFilter == 'Épargne') return exp.budgetType == BudgetCategoryType.savings;
      return false;
    }).toList();

    final filteredIncomes = monthIncomes.where((inc) {
      final matchesSearch = inc.title.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;
      return _selectedFilter == 'Tous' || _selectedFilter == 'Revenus';
    }).toList();

    final totalFilteredExpenseAmount = filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transactions & Dépenses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.autorenew, color: Color(0xFF10B981)),
            tooltip: 'Abonnements & Charges Fixes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionsScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddTransactionModal.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Input
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une dépense ou catégorie...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (provider.incomes.isNotEmpty) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          avatar: const Icon(Icons.apps, size: 14),
                          label: const Text('Toutes sources'),
                          selected: _selectedIncomeSourceId == null,
                          selectedColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                          onSelected: (_) => setState(() => _selectedIncomeSourceId = null),
                        ),
                        const SizedBox(width: 6),
                        ...provider.incomes.map((inc) {
                          final isSelected = _selectedIncomeSourceId == inc.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ChoiceChip(
                              avatar: const Icon(Icons.account_balance_wallet, size: 14),
                              label: Text(inc.title),
                              selected: isSelected,
                              selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                              onSelected: (_) => setState(() => _selectedIncomeSourceId = inc.id),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                // Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _selectedFilter = filter);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Total Summary Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Theme.of(context).cardColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredExpenses.length + (_selectedFilter == 'Revenus' || _selectedFilter == 'Tous' ? filteredIncomes.length : 0)} transaction(s)',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                if (_selectedFilter != 'Revenus')
                  Text(
                    'Total: ${formatter.format(totalFilteredExpenseAmount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFFEF4444),
                    ),
                  ),
              ],
            ),
          ),

          // List of Expenses & Incomes
          Expanded(
            child: (filteredExpenses.isEmpty && filteredIncomes.isEmpty)
                ? const Center(
                    child: Text(
                      'Aucune transaction trouvée.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      if (_selectedFilter == 'Tous' || _selectedFilter == 'Revenus') ...[
                        ...filteredIncomes.map((income) {
                          return IncomeTile(
                            income: income,
                            currency: currency,
                            onDelete: () => provider.deleteIncome(income.id),
                          );
                        }),
                      ],
                      if (_selectedFilter != 'Revenus') ...[
                        ...filteredExpenses.map((expense) {
                          return ExpenseTile(
                            expense: expense,
                            currency: currency,
                            onDelete: () => provider.deleteExpense(expense.id),
                          );
                        }),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
