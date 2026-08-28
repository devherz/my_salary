import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/budget_rule.dart';
import '../providers/salary_provider.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  int _touchedIndex = -1;

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

    final breakdown = provider.categoryBreakdown;
    final totalExpenses = provider.totalExpensesCurrentMonth;

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
            // 1. Category Pie Chart Card
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Répartition par Catégorie',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (breakdown.isEmpty || totalExpenses <= 0)
                      const SizedBox(
                        height: 180,
                        child: Center(
                          child: Text(
                            'Aucune donnée de dépense disponible pour ce mois.',
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

            // 2. Budget Rule Distribution Card (50/30/20)
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Synthèse Règle Budgétaire',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _AnalysisBudgetTypeRow(
                      type: BudgetCategoryType.needs,
                      spent: provider.needsExpensesSpent,
                      target: provider.needsBudgetAllowed,
                      formatter: formatter,
                      color: const Color(0xFF3B82F6),
                    ),
                    const Divider(height: 24),
                    _AnalysisBudgetTypeRow(
                      type: BudgetCategoryType.wants,
                      spent: provider.wantsExpensesSpent,
                      target: provider.wantsBudgetAllowed,
                      formatter: formatter,
                      color: const Color(0xFFF59E0B),
                    ),
                    const Divider(height: 24),
                    _AnalysisBudgetTypeRow(
                      type: BudgetCategoryType.savings,
                      spent: provider.savingsExpensesSpent,
                      target: provider.savingsBudgetAllowed,
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
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Plafonds & Alertes Budgétaires',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
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
                      'Définissez des limites mensuelles par catégorie avec alerte automatique à 80% et 100% :',
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
                            'Aucun plafond défini. Cliquez sur + Plafond pour ajouter une limite (ex: Alimentation <= 300 €)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: provider.categoryCaps.map((cap) {
                          final spent = breakdown[cap.category] ?? 0.0;
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
                                    Text(
                                      cap.category,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
