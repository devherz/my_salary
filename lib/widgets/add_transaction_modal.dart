import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/budget_rule.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../providers/salary_provider.dart';

class AddTransactionModal extends StatefulWidget {
  const AddTransactionModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionModal(),
    );
  }

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  bool _isExpense = true;

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedCategory = CategoryHelper.defaultCategories.first;
  BudgetCategoryType _selectedBudgetType = BudgetCategoryType.needs;
  DateTime _selectedDate = DateTime.now();
  String? _selectedIncomeSourceId;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String? category) {
    if (category == null) return;
    setState(() {
      _selectedCategory = category;
      _selectedBudgetType = CategoryHelper.defaultBudgetTypeForCategory(category);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<SalaryProvider>(context, listen: false);
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    final title = _titleController.text.trim();
    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

    if (_isExpense) {
      final expense = Expense(
        id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        amount: amount,
        category: _selectedCategory,
        budgetType: _selectedBudgetType,
        date: _selectedDate,
        note: note,
        incomeSourceId: _selectedIncomeSourceId,
      );
      provider.addExpense(expense);
    } else {
      final income = Income(
        id: 'inc_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        amount: amount,
        date: _selectedDate,
        isRecurringSalary: false,
        note: note,
      );
      provider.addIncome(income);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalaryProvider>(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle Indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Segmented Switch (Dépense / Revenu)
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Nouvelle Dépense')),
                      selected: _isExpense,
                      selectedColor: const Color(0xFFEF4444).withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: _isExpense ? const Color(0xFFEF4444) : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _isExpense = true;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Nouveau Revenu')),
                      selected: !_isExpense,
                      selectedColor: const Color(0xFF10B981).withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: !_isExpense ? const Color(0xFF10B981) : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _isExpense = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: _isExpense ? 'Intitulé de la dépense' : 'Source du revenu',
                  hintText: _isExpense ? 'ex: Courses Carrefour' : 'ex: Prime de projet',
                  prefixIcon: Icon(_isExpense ? Icons.shopping_bag : Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Veuillez saisir un intitulé' : null,
              ),
              const SizedBox(height: 16),
              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Montant (${provider.currency})',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.euro),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Veuillez entrer un montant';
                  final parsed = double.tryParse(val.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Montant invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_isExpense) ...[
                if (provider.incomes.isNotEmpty) ...[
                  DropdownButtonFormField<String?>(
                    value: _selectedIncomeSourceId,
                    decoration: InputDecoration(
                      labelText: 'Source de Revenu associée (Optionnel)',
                      prefixIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF10B981)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Toutes les sources (Global)'),
                      ),
                      ...provider.incomes.map((inc) {
                        return DropdownMenuItem<String?>(
                          value: inc.id,
                          child: Text('${inc.title} (${inc.amount.toStringAsFixed(0)} ${provider.currency})'),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedIncomeSourceId = val),
                  ),
                  const SizedBox(height: 16),
                ],
                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Catégorie',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: CategoryHelper.defaultCategories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: _onCategoryChanged,
                ),
                const SizedBox(height: 16),
                // Budget Category Selector (Besoin / Envie / Épargne)
                const Text(
                  'Classification Budgétaire (Règle 50/30/20)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: BudgetCategoryType.values.map((type) {
                    final selected = _selectedBudgetType == type;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: FilterChip(
                          label: FittedBox(
                            child: Text(
                              type.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _selectedBudgetType = type;
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              // Date Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        'Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _pickDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _submit,
                  child: Text(
                    _isExpense ? 'Ajouter la dépense' : 'Ajouter le revenu',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
