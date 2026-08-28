import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/salary_provider.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key});

  Future<void> _pickDateRange(BuildContext context, SalaryProvider provider) async {
    final initialStart = provider.startDate ??
        DateTime(provider.selectedMonth.year, provider.selectedMonth.month, 1);
    final initialEnd = provider.endDate ??
        DateTime(provider.selectedMonth.year, provider.selectedMonth.month + 1, 0);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      helpText: 'Sélectionner la période (Début - Fin)',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF10B981),
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalaryProvider>(context);
    final currency = provider.currency;
    final formatter = NumberFormat.currency(
      symbol: currency,
      decimalDigits: 0,
      locale: 'fr_FR',
    );

    final totalIncome = provider.totalIncomeCurrentMonth;
    final totalExpenses = provider.totalExpensesCurrentMonth;
    final balance = provider.remainingBalance;
    final isNegative = balance < 0;
    final remainingRatio = totalIncome > 0 ? (balance / totalIncome).clamp(0.0, 1.0) : 0.0;
    final remainingPercent = (remainingRatio * 100).toInt();

    String datePeriodTitle;
    if (provider.isCustomDateRange) {
      final startStr = DateFormat('dd/MM', 'fr_FR').format(provider.startDate!);
      final endStr = DateFormat('dd/MM/yyyy', 'fr_FR').format(provider.endDate!);
      datePeriodTitle = '$startStr → $endStr';
    } else {
      final monthStr = DateFormat('MMMM yyyy', 'fr_FR').format(provider.selectedMonth);
      datePeriodTitle = monthStr.isNotEmpty
          ? monthStr[0].toUpperCase() + monthStr.substring(1)
          : monthStr;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: provider.isDarkMode
              ? [const Color(0xFF0B132B), const Color(0xFF1C2541), const Color(0xFF3A506B)]
              : [const Color(0xFF064E3B), const Color(0xFF047857), const Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Month & Control Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        datePeriodTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (provider.isCustomDateRange) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => provider.clearDateRange(),
                          child: const Icon(Icons.close, color: Colors.white70, size: 14),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_calendar, color: Colors.white, size: 20),
                      onPressed: () => _pickDateRange(context, provider),
                      tooltip: 'Sélectionner une période',
                    ),
                    if (!provider.isCustomDateRange) ...[
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
                        onPressed: () {
                          final prev = DateTime(
                            provider.selectedMonth.year,
                            provider.selectedMonth.month - 1,
                          );
                          provider.changeMonth(prev);
                        },
                        tooltip: 'Mois précédent',
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white, size: 22),
                        onPressed: () {
                          final next = DateTime(
                            provider.selectedMonth.year,
                            provider.selectedMonth.month + 1,
                          );
                          provider.changeMonth(next);
                        },
                        tooltip: 'Mois suivant',
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Balance Display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SOLDE NET DISPONIBLE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatter.format(balance),
                          style: TextStyle(
                            color: isNegative ? const Color(0xFFFCA5A5) : Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isNegative
                        ? Colors.red.withValues(alpha: 0.25)
                        : const Color(0xFF10B981).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isNegative ? Colors.redAccent : const Color(0xFF34D399),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isNegative ? Icons.trending_down : Icons.trending_up,
                        color: isNegative ? Colors.redAccent : const Color(0xFF34D399),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isNegative ? 'Déficit' : '$remainingPercent% Libre',
                        style: TextStyle(
                          color: isNegative ? Colors.redAccent : const Color(0xFF34D399),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Financial Health Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: remainingRatio,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                color: isNegative ? Colors.redAccent : const Color(0xFF34D399),
              ),
            ),
            const SizedBox(height: 20),

            // Income & Expense Breakdown Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_downward_rounded,
                            color: Color(0xFF6EE7B7),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Revenus Totaux',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  formatter.format(totalIncome),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 32,
                    width: 1,
                    color: Colors.white24,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_upward_rounded,
                            color: Color(0xFFFCA5A5),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dépenses Totales',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  formatter.format(totalExpenses),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
