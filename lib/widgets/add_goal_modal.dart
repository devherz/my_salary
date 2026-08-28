import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/savings_goal.dart';
import '../providers/salary_provider.dart';

class AddGoalModal extends StatefulWidget {
  final String? initialIncomeSourceId;
  const AddGoalModal({super.key, this.initialIncomeSourceId});

  static void show(BuildContext context, {String? incomeSourceId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddGoalModal(initialIncomeSourceId: incomeSourceId),
    );
  }

  @override
  State<AddGoalModal> createState() => _AddGoalModalState();
}

class _AddGoalModalState extends State<AddGoalModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();
  final _monthlyAmountController = TextEditingController();

  DateTime? _startDate = DateTime.now();
  DateTime? _targetDate;
  int _selectedColor = 0xFF10B981; // Default Emerald
  String? _selectedIncomeSourceId;

  final List<int> _colors = [
    0xFF10B981, // Emerald
    0xFF3B82F6, // Blue
    0xFF8B5CF6, // Purple
    0xFFF59E0B, // Amber
    0xFFEC4899, // Pink
    0xFF14B8A6, // Teal
  ];

  @override
  void initState() {
    super.initState();
    _selectedIncomeSourceId = widget.initialIncomeSourceId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    _monthlyAmountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<SalaryProvider>(context, listen: false);
    final target = double.tryParse(_targetAmountController.text.replaceAll(',', '.')) ?? 0.0;
    final current = double.tryParse(_currentAmountController.text.replaceAll(',', '.')) ?? 0.0;
    final monthly = double.tryParse(_monthlyAmountController.text.replaceAll(',', '.'));

    // Default to primary income source if still null
    String? finalIncomeId = _selectedIncomeSourceId;
    if (finalIncomeId == null && provider.incomes.isNotEmpty) {
      final primary = provider.incomes.firstWhere(
        (i) => i.isRecurringSalary || i.statusTag == 'Principal',
        orElse: () => provider.incomes.first,
      );
      finalIncomeId = primary.id;
    }

    final goal = SavingsGoal(
      id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      targetAmount: target,
      currentAmount: current,
      startDate: _startDate,
      targetDate: _targetDate,
      monthlyAmount: monthly,
      colorHex: _selectedColor,
      incomeSourceId: finalIncomeId,
    );

    provider.addSavingsGoal(goal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalaryProvider>(context);

    if (_selectedIncomeSourceId == null && provider.incomes.isNotEmpty) {
      final primary = provider.incomes.firstWhere(
        (i) => i.isRecurringSalary || i.statusTag == 'Principal',
        orElse: () => provider.incomes.first,
      );
      _selectedIncomeSourceId = primary.id;
    }

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
              const Text(
                'Nouvel Objectif d\'Épargne',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Nom de l\'objectif',
                  hintText: 'ex: Fonds d\'urgence, Permis, Voyage',
                  prefixIcon: const Icon(Icons.savings),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Veuillez entrer un titre' : null,
              ),
              const SizedBox(height: 16),

              // Specific Income Source Dropdown
              if (provider.incomes.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: provider.incomes.any((i) => i.id == _selectedIncomeSourceId) ? _selectedIncomeSourceId : provider.incomes.first.id,
                  decoration: InputDecoration(
                    labelText: 'Source de Revenu Rattachée *',
                    prefixIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF10B981)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: provider.incomes.map((inc) {
                    return DropdownMenuItem<String>(
                      value: inc.id,
                      child: Text(
                        '[${inc.statusTag}] ${inc.title} (${inc.amount.toStringAsFixed(0)} ${provider.currency})',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedIncomeSourceId = val),
                  validator: (val) => val == null || val.isEmpty ? 'Veuillez sélectionner une source' : null,
                ),
                const SizedBox(height: 16),
              ],

              // Target Total Amount
              TextFormField(
                controller: _targetAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Montant Cible Total (${provider.currency})',
                  hintText: 'ex: 3000',
                  prefixIcon: const Icon(Icons.flag),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Veuillez entrer un montant cible';
                  final parsed = double.tryParse(val.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Montant invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Monthly Amount
              TextFormField(
                controller: _monthlyAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Montant Mensuel à Épargner (${provider.currency}/mois) - Optionnel',
                  hintText: 'ex: 200.00',
                  prefixIcon: const Icon(Icons.calendar_month),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),

              // Current Saved Amount
              TextFormField(
                controller: _currentAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Montant déjà épargné (${provider.currency}) - Optionnel',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.account_balance),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),

              // Start Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                    helpText: 'Date de début de l\'épargne',
                    cancelText: 'Annuler',
                    confirmText: 'Choisir',
                  );
                  if (picked != null) {
                    setState(() => _startDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle_outline, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date de début de l\'épargne',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _startDate == null
                                  ? 'Aujourd\'hui'
                                  : DateFormat('dd MMMM yyyy', 'fr_FR').format(_startDate!),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Target Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2040),
                    helpText: 'Date cible d\'achèvement',
                    cancelText: 'Annuler',
                    confirmText: 'Choisir',
                  );
                  if (picked != null) {
                    setState(() => _targetDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, color: Color(0xFF10B981)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date cible (Optionnel)',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _targetDate == null
                                  ? 'Aucune date limite'
                                  : DateFormat('dd MMMM yyyy', 'fr_FR').format(_targetDate!),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      if (_targetDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _targetDate = null),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Color Selector
              const Text(
                'Couleur de l\'objectif',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _colors.map((c) {
                  final isSelected = _selectedColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Theme.of(context).primaryColor, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _submit,
                  child: const Text(
                    'Créer l\'Objectif',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
