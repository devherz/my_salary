import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'income_source_details_screen.dart';
import '../providers/salary_provider.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/summary_card.dart';

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sleek Overall Solde & Month Summary Banner
          const SummaryCard(),
          const SizedBox(height: 20),


          // 3. Main Income Sources Selection Cards Grid Hub
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vos Sources de Revenus',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ Source', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => AddTransactionModal.show(context, initialIsExpense: false),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (provider.incomes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 40, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text(
                    'Aucune source de revenu configurée.',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cliquez sur "+ Source de Revenu" pour démarrer !',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: provider.incomes.length,
              itemBuilder: (context, index) {
                final inc = provider.incomes[index];
                final assignedExpenses = provider.expenses.where((e) => e.incomeSourceId == inc.id).toList();
                final totalSpent = assignedExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
                final remaining = inc.amount - totalSpent;

                final spentRatio = inc.amount > 0 ? (totalSpent / inc.amount).clamp(0.0, 1.0) : 0.0;
                final isPrimary = inc.statusTag == 'Principal';

                final List<Color> cardGradient = isPrimary
                    ? [const Color(0xFF10B981).withValues(alpha: 0.15), const Color(0xFF059669).withValues(alpha: 0.08)]
                    : [const Color(0xFF3B82F6).withValues(alpha: 0.12), const Color(0xFF1D4ED8).withValues(alpha: 0.06)];

                final Color accentColor = isPrimary ? const Color(0xFF10B981) : const Color(0xFF3B82F6);

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IncomeSourceDetailsScreen(incomeId: inc.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: cardGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                inc.statusTag,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.arrow_forward_ios_rounded, size: 10, color: accentColor),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inc.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Règle ${inc.needsRatio.toInt()}/${inc.wantsRatio.toInt()}/${inc.savingsRatio.toInt()} • ${inc.frequency}',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                formatter.format(inc.amount),
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: spentRatio,
                                minHeight: 4,
                                backgroundColor: accentColor.withValues(alpha: 0.15),
                                color: remaining >= 0 ? accentColor : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: remaining >= 0
                                ? accentColor.withValues(alpha: 0.12)
                                : Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: remaining >= 0
                                  ? accentColor.withValues(alpha: 0.25)
                                  : Colors.red.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Solde: ${formatter.format(remaining)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: remaining >= 0 ? accentColor : Colors.red,
                                  ),
                                ),
                              ),
                              Icon(Icons.touch_app_rounded, size: 12, color: accentColor),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
