import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/budget_rule.dart';
import '../models/income.dart';
import '../providers/salary_provider.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  int _touchedIndex = -1;
  String? _selectedAnalyticsIncomeId;

  final List<Color> _chartColors = [
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF10B981), // Emerald
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFF14B8A6), // Teal
    const Color(0xFFF97316), // Orange
    const Color(0xFF64748B), // Slate
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalaryProvider>(context);
    final currency = provider.currency;
    final formatter = NumberFormat.currency(
      symbol: currency,
      decimalDigits: 2,
      locale: 'fr_FR',
    );

    final selectedIncome = _selectedAnalyticsIncomeId == null
        ? null
        : provider.incomes.firstWhere(
            (i) => i.id == _selectedAnalyticsIncomeId,
            orElse: () => provider.incomes.isNotEmpty ? provider.incomes.first : Income(id: '', title: 'Source', amount: 0, date: DateTime.now()),
          );

    final filteredExpenses = _selectedAnalyticsIncomeId == null
        ? provider.currentMonthExpenses
        : provider.currentMonthExpenses.where((e) => e.incomeSourceId == null || e.incomeSourceId == _selectedAnalyticsIncomeId).toList();

    final Map<String, double> breakdown = {};
    for (final exp in filteredExpenses) {
      breakdown[exp.category] = (breakdown[exp.category] ?? 0.0) + exp.amount;
    }
    final totalExpenses = filteredExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);

    final totalIncomeAmount = _selectedAnalyticsIncomeId == null
        ? provider.totalIncomeCurrentMonth
        : (selectedIncome?.amount ?? 0.0);

    final needsRatio = _selectedAnalyticsIncomeId == null ? provider.budgetRule.needsPercent : (selectedIncome?.needsRatio ?? 50.0);
    final wantsRatio = _selectedAnalyticsIncomeId == null ? provider.budgetRule.wantsPercent : (selectedIncome?.wantsRatio ?? 30.0);
    final savingsRatio = _selectedAnalyticsIncomeId == null ? provider.budgetRule.savingsPercent : (selectedIncome?.savingsRatio ?? 20.0);

    final needsTarget = (needsRatio / 100) * totalIncomeAmount;
    final wantsTarget = (wantsRatio / 100) * totalIncomeAmount;
    final savingsTarget = (savingsRatio / 100) * totalIncomeAmount;

    final needsSpent = filteredExpenses.where((e) => e.budgetType == BudgetCategoryType.needs).fold<double>(0.0, (sum, e) => sum + e.amount);
    final wantsSpent = filteredExpenses.where((e) => e.budgetType == BudgetCategoryType.wants).fold<double>(0.0, (sum, e) => sum + e.amount);
    final savingsSpent = filteredExpenses.where((e) => e.budgetType == BudgetCategoryType.savings).fold<double>(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analyses & Graphiques',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Income Source Filter Chips
            if (provider.incomes.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      avatar: const Icon(Icons.bar_chart, size: 16),
                      label: Text('Toutes (${provider.incomes.length})'),
                      selected: _selectedAnalyticsIncomeId == null,
                      selectedColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                      onSelected: (_) => setState(() => _selectedAnalyticsIncomeId = null),
                    ),
                    const SizedBox(width: 8),
                    ...provider.incomes.map((inc) {
                      final isSelected = _selectedAnalyticsIncomeId == inc.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          avatar: const Icon(Icons.account_balance_wallet, size: 16),
                          label: Text('[${inc.statusTag}] ${inc.title}'),
                          selected: isSelected,
                          selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          onSelected: (_) => setState(() => _selectedAnalyticsIncomeId = inc.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 1. Category Pie Chart Card
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedAnalyticsIncomeId == null
                          ? 'Répartition globale par Catégorie'
                          : 'Répartition Catégorie: ${selectedIncome?.title}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (breakdown.isEmpty || totalExpenses <= 0)
                      const SizedBox(
                        height: 180,
                        child: Center(
                          child: Text(
                            'Aucune donnée de dépense disponible pour cette sélection.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else ...[
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = pieTouchResponse
                                      .touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 3,
                            centerSpaceRadius: 45,
                            sections: _generatePieSections(breakdown, totalExpenses),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Legend List
                      ...breakdown.entries.toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final category = entry.value.key;
                        final amount = entry.value.value;
                        final percent = (amount / totalExpenses * 100).toStringAsFixed(1);
                        final color = _chartColors[index % _chartColors.length];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        category,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${formatter.format(amount)} ($percent%)',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Budget Rule Distribution Card
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Synthèse Règle (${needsRatio.toInt()}/${wantsRatio.toInt()}/${savingsRatio.toInt()})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _AnalysisBudgetTypeRow(
                      type: BudgetCategoryType.needs,
                      spent: needsSpent,
                      target: needsTarget,
                      formatter: formatter,
                      color: const Color(0xFF3B82F6),
                    ),
                    const Divider(height: 24),
                    _AnalysisBudgetTypeRow(
                      type: BudgetCategoryType.wants,
                      spent: wantsSpent,
                      target: wantsTarget,
                      formatter: formatter,
                      color: const Color(0xFFF59E0B),
                    ),
                    const Divider(height: 24),
                    _AnalysisBudgetTypeRow(
                      type: BudgetCategoryType.savings,
                      spent: savingsSpent,
                      target: savingsTarget,
                      formatter: formatter,
                      color: const Color(0xFF10B981),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. Category Budget Caps & Alert System
            Card(
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
                        Expanded(
                          child: Row(
                            children: const [
                              Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 22),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Plafonds (Revenu Principal)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('+ Plafond'),
                          onPressed: () => _showSetCapDialog(context, provider),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Limites mensuelles par catégorie appliquées exclusivement au Revenu Principal :',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    if (provider.categoryCaps.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'Aucun plafond défini pour le Revenu Principal. Cliquez sur + Plafond pour ajouter une limite (ex: Alimentation <= 300 €)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: provider.categoryCaps.map((cap) {
                          final primaryIncome = provider.incomes.firstWhere(
                            (i) => i.isRecurringSalary || i.statusTag == 'Principal',
                            orElse: () => provider.incomes.isNotEmpty ? provider.incomes.first : Income(id: '', title: '', amount: 0, date: DateTime.now()),
                          );

                          final primaryExpenses = provider.currentMonthExpenses.where(
                            (e) => e.category == cap.category && (e.incomeSourceId == null || e.incomeSourceId == primaryIncome.id),
                          );
                          final spent = primaryExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
                          final ratio = cap.limitAmount > 0 ? (spent / cap.limitAmount) : 0.0;
                          final percent = (ratio * 100).toInt();

                          Color statusColor = const Color(0xFF10B981);
                          String statusText = 'Normal ($percent%)';
                          if (ratio >= 1.0) {
                            statusColor = Colors.red;
                            final over = spent - cap.limitAmount;
                            statusText = 'Dépassement +${formatter.format(over)}';
                          } else if (ratio >= 0.8) {
                            statusColor = const Color(0xFFF59E0B);
                            statusText = 'Alerte ($percent%)';
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        cap.category,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            statusText,
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                          onPressed: () => provider.removeCategoryCap(cap.category),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Consommé: ${formatter.format(spent)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    ),
                                    Text(
                                      'Plafond: ${formatter.format(cap.limitAmount)}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: ratio.clamp(0.0, 1.0),
                                    color: statusColor,
                                    backgroundColor: statusColor.withValues(alpha: 0.2),
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetCapDialog(BuildContext context, SalaryProvider provider) {
    final breakdown = provider.categoryBreakdown;
    String selectedCat = breakdown.isNotEmpty ? breakdown.keys.first : 'Alimentation';
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.tune, color: Color(0xFF10B981)),
                SizedBox(width: 10),
                Text('Définir un Plafond'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCat,
                  decoration: InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: [
                    'Alimentation',
                    'Logement',
                    'Transport',
                    'Factures & Abonnements',
                    'Santé & Bien-être',
                    'Shopping & Vêtements',
                    'Loisirs & Sorties',
                    'Épargne & Projets',
                  ].map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCat = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Plafond mensuel max (${provider.currency})',
                    hintText: 'ex: 300.00',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
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
                  final limit = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0;
                  if (limit > 0) {
                    provider.setCategoryCap(selectedCat, limit);
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

  List<PieChartSectionData> _generatePieSections(
    Map<String, double> breakdown,
    double total,
  ) {
    final entries = breakdown.entries.toList();
    return List.generate(entries.length, (i) {
      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 55.0 : 45.0;
      final fontSize = isTouched ? 14.0 : 11.0;
      final amount = entries[i].value;
      final percent = ((amount / total) * 100).round();
      final color = _chartColors[i % _chartColors.length];

      return PieChartSectionData(
        color: color,
        value: amount,
        title: '$percent%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }
}

class _AnalysisBudgetTypeRow extends StatelessWidget {
  final BudgetCategoryType type;
  final double spent;
  final double target;
  final NumberFormat formatter;
  final Color color;

  const _AnalysisBudgetTypeRow({
    required this.type,
    required this.spent,
    required this.target,
    required this.formatter,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isExceeded = spent > target && target > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.circle, color: color, size: 12),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      type.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatter.format(spent),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isExceeded ? Colors.red : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            Text(
              'Cible: ${formatter.format(target)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }
}
