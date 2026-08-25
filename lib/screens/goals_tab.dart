import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/savings_goal.dart';
import '../providers/salary_provider.dart';
import '../widgets/add_goal_modal.dart';

class GoalsTab extends StatefulWidget {
  const GoalsTab({super.key});

  @override
  State<GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends State<GoalsTab> {
  String _getRemainingDaysText(DateTime targetDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final diff = target.difference(today).inDays;

    if (diff < 0) return 'Échéance dépassée';
    if (diff == 0) return 'Échéance aujourd\'hui';
    if (diff == 1) return 'Reste 1 jour';
    return 'Reste $diff jours';
  }

  void _showDepositDialog(BuildContext context, SavingsGoal goal, String currency) {
    final controller = TextEditingController();
    final provider = Provider.of<SalaryProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Alimenter: ${goal.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Montant disponible à ajouter à cet objectif d\'épargne :',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Montant à ajouter ($currency)',
                hintText: 'ex: 150.00',
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
              backgroundColor: Color(goal.colorHex),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final amount = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0;
              if (amount > 0) {
                provider.depositToGoal(goal.id, amount);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Déposer'),
          ),
        ],
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

    final goals = provider.savingsGoals;
    final totalSavedAllGoals = goals.fold(0.0, (sum, g) => sum + g.currentAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Objectifs d\'Épargne',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddGoalModal.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Créer un objectif'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Savings Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.savings, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Épargné (Tous objectifs)',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatter.format(totalSavedAllGoals),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Vos Projets & Fonds',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (goals.isEmpty)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'Aucun objectif créé pour le moment.\nCréez votre premier objectif d\'épargne !',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  final color = Color(goal.colorHex);
                  final percent = (goal.progressPercentage * 100).toInt();

                  return Card(
                    elevation: 0.5,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: color.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: color.withOpacity(0.15),
                                    child: Icon(Icons.stars, color: color, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        goal.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          if (goal.startDate != null) ...[
                                            const Icon(Icons.play_circle_outline, size: 12, color: Colors.blue),
                                            const SizedBox(width: 3),
                                            Text(
                                              'Début : ${DateFormat('dd/MM/yy', 'fr_FR').format(goal.startDate!)}',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          if (goal.targetDate != null) ...[
                                            const Icon(Icons.event, size: 12, color: Color(0xFF10B981)),
                                            const SizedBox(width: 3),
                                            Text(
                                              'Échéance : ${DateFormat('dd/MM/yy', 'fr_FR').format(goal.targetDate!)}',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                onPressed: () => provider.deleteGoal(goal.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (goal.calculatedMonthlyTarget > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_month, size: 14, color: color),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Épargne conseillée : ${formatter.format(goal.calculatedMonthlyTarget)} / mois',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Actuel : ${formatter.format(goal.currentAmount)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Cible : ${formatter.format(goal.targetAmount)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: goal.progressPercentage,
                              minHeight: 10,
                              backgroundColor: Colors.grey[200],
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$percent%',
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if (goal.targetDate != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getRemainingDaysText(goal.targetDate!),
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Alimenter'),
                                onPressed: () => _showDepositDialog(context, goal, currency),
                              ),
                            ],
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
