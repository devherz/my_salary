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
              Text(
                '${provider.incomes.length} source${provider.incomes.length > 1 ? 's' : ''}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold),
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

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IncomeSourceDetailsScreen(incomeId: inc.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10B981).withValues(alpha: 0.1),
                          const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                inc.statusTag,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF10B981)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inc.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${inc.needsRatio.toInt()}/${inc.wantsRatio.toInt()}/${inc.savingsRatio.toInt()} • ${inc.frequency}',
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatter.format(inc.amount),
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: remaining >= 0
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Solde: ${formatter.format(remaining)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: remaining >= 0 ? const Color(0xFF10B981) : Colors.red,
                                  ),
                                ),
                              ),
                              const Icon(Icons.open_in_new, size: 11, color: Color(0xFF10B981)),
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
