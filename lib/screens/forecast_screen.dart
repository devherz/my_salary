import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/salary_provider.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  double _extraMonthlySavings = 50.0;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalaryProvider>(context);
    final currency = provider.currency;
    final formatter = NumberFormat.currency(
      symbol: currency,
      decimalDigits: 2,
      locale: 'fr_FR',
    );

    final totalMonthlyIncomes = provider.incomes.fold<double>(0.0, (sum, i) => sum + i.amount);
    final totalMonthlyExpenses = provider.totalExpensesCurrentMonth;
    final netMonthlySavings = totalMonthlyIncomes - totalMonthlyExpenses;

    final forecast3Months = (netMonthlySavings * 3) + (_extraMonthlySavings * 3);
    final forecast6Months = (netMonthlySavings * 6) + (_extraMonthlySavings * 6);
    final forecast12Months = (netMonthlySavings * 12) + (_extraMonthlySavings * 12);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Projections & Simulations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Current Monthly Capacity Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
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
                      Icon(Icons.trending_up, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Capacité de Dépôt / Épargne Mensuelle',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatter.format(netMonthlySavings),
                    style: TextStyle(
                      color: netMonthlySavings >= 0 ? Colors.white : Colors.redAccent,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Revenus (${formatter.format(totalMonthlyIncomes)}) - Dépenses (${formatter.format(totalMonthlyExpenses)})',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Projections Cards (3, 6, 12 Months)
            const Text(
              'Projections de votre Patrimoine',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _ForecastItemCard(
                    title: 'Dans 3 mois',
                    amount: forecast3Months,
                    formatter: formatter,
                    color: const Color(0xFF3B82F6),
                    icon: Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ForecastItemCard(
                    title: 'Dans 6 mois',
                    amount: forecast6Months,
                    formatter: formatter,
                    color: const Color(0xFF8B5CF6),
                    icon: Icons.event,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ForecastItemCard(
              title: 'Dans 1 an (12 mois)',
              amount: forecast12Months,
              formatter: formatter,
              color: const Color(0xFF10B981),
              icon: Icons.stars,
              isFullWidth: true,
            ),

            const SizedBox(height: 24),

            // 3. Interactive Extra Savings Simulator
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune, color: Color(0xFF10B981), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Simulateur d\'Effort Supplémentaire',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Et si vous épargniez ${formatter.format(_extraMonthlySavings)} de plus par mois ?',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Slider(
                      value: _extraMonthlySavings,
                      min: 0,
                      max: 500,
                      divisions: 50,
                      activeColor: const Color(0xFF10B981),
                      label: formatter.format(_extraMonthlySavings),
                      onChanged: (val) => setState(() => _extraMonthlySavings = val),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.rocket_launch, color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'En ajoutant ${formatter.format(_extraMonthlySavings)} / mois, vous cumulerez +${formatter.format(_extraMonthlySavings * 12)} supplémentaires d\'ici 1 an !',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                            ),
                          ),
                        ],
                      ),
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
}

class _ForecastItemCard extends StatelessWidget {
  final String title;
  final double amount;
  final NumberFormat formatter;
  final Color color;
  final IconData icon;
  final bool isFullWidth;

  const _ForecastItemCard({
    required this.title,
    required this.amount,
    required this.formatter,
    required this.color,
    required this.icon,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatter.format(amount),
              style: TextStyle(
                fontSize: isFullWidth ? 22 : 18,
                fontWeight: FontWeight.bold,
                color: amount >= 0 ? Colors.black87 : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
