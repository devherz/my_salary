import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/budget_rule.dart';
import '../providers/salary_provider.dart';
import '../services/csv_report_service.dart';
import '../services/notification_service.dart';
import '../services/pdf_report_service.dart';
import 'password_lock_screen.dart';
import 'pin_lock_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late TextEditingController _salaryController;
  late double _needs;

  final List<String> _currencies = ['€', '\$', 'FCFA', 'DH', 'CHF', '£', 'DA', 'DT'];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SalaryProvider>(context, listen: false);
    _salaryController = TextEditingController(text: provider.baseSalary.toStringAsFixed(0));
    _needs = provider.budgetRule.needsPercent;
  }

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  void _saveSalary(SalaryProvider provider) {
    final val = double.tryParse(_salaryController.text.replaceAll(',', '.')) ?? 0.0;
    if (val > 0) {
      provider.updateBaseSalary(val);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salaire mensuel mis à jour !')),
      );
    }
  }

  void _updateRule(SalaryProvider provider, double needs, double wants, double savings) {
    setState(() {
      _needs = needs;
    });
    provider.updateBudgetRule(
      BudgetRule(needsPercent: needs, wantsPercent: wants, savingsPercent: savings),
    );
  }

  void _showCustomRuleModal(BuildContext context, SalaryProvider provider) {
    double needs = provider.budgetRule.needsPercent;
    double wants = provider.budgetRule.wantsPercent;
    double savings = provider.budgetRule.savingsPercent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final total = needs + wants + savings;
            final isValid = (total - 100.0).abs() < 0.1;
            final baseSalary = provider.baseSalary;
            final currency = provider.currency;

            return Padding(
              padding: EdgeInsets.only(
                top: 24.0,
                left: 24.0,
                right: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
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
                    'Créer ma Règle sur-mesure ⚙️',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ajustez les pourcentages selon votre choix (Total = 100%).',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),

                  // Total Indicator Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isValid ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isValid ? const Color(0xFF10B981) : Colors.red,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total des pourcentages :',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isValid ? const Color(0xFF10B981) : Colors.red,
                          ),
                        ),
                        Text(
                          '${total.toStringAsFixed(0)} %',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isValid ? const Color(0xFF10B981) : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Needs Slider (Besoins)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🏠 Besoins (${needs.toStringAsFixed(0)}%)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${((needs / 100) * baseSalary).toStringAsFixed(0)} $currency',
                        style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Slider(
                    value: needs,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    activeColor: const Color(0xFF3B82F6),
                    label: '${needs.toStringAsFixed(0)}%',
                    onChanged: (val) {
                      setModalState(() {
                        needs = val;
                      });
                    },
                  ),

                  // Wants Slider (Envies)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🎯 Envies / Loisirs (${wants.toStringAsFixed(0)}%)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${((wants / 100) * baseSalary).toStringAsFixed(0)} $currency',
                        style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Slider(
                    value: wants,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    activeColor: const Color(0xFF8B5CF6),
                    label: '${wants.toStringAsFixed(0)}%',
                    onChanged: (val) {
                      setModalState(() {
                        wants = val;
                      });
                    },
                  ),

                  // Savings Slider (Épargne)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '💰 Épargne & Projets (${savings.toStringAsFixed(0)}%)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${((savings / 100) * baseSalary).toStringAsFixed(0)} $currency',
                        style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Slider(
                    value: savings,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    activeColor: const Color(0xFF10B981),
                    label: '${savings.toStringAsFixed(0)}%',
                    onChanged: (val) {
                      setModalState(() {
                        savings = val;
                      });
                    },
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isValid ? const Color(0xFF10B981) : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: isValid
                          ? () {
                              _updateRule(provider, needs, wants, savings);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Règle de budget personnalisée appliquée !')),
                              );
                            }
                          : null,
                      child: Text(
                        isValid ? 'Enregistrer ma Règle' : 'Ajustez le total à 100%',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSecurityChoiceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choisir le type de sécurité',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.pin, color: Color(0xFF10B981)),
              title: const Text('Code PIN à 4 chiffres'),
              subtitle: const Text('Verrouillage rapide par pavé numérique'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PinLockScreen(isSetupMode: true),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.key, color: Color(0xFF3B82F6)),
              title: const Text('Mot de passe (Texte)'),
              subtitle: const Text('Mot de passe personnalisable avec lettres et chiffres'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PasswordLockScreen(isSetupMode: true),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context, SalaryProvider provider) {
    final jsonStr = provider.exportBackupData();
    final nowStr = DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(DateTime.now());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 10),
            Text('Sauvegarde Pro', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Synthèse de votre portefeuille à sauvegarder :',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 14),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('📅 Date de la copie :', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(nowStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('💰 Sources de Revenus :', style: TextStyle(fontSize: 13)),
                      Text('${provider.incomes.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('💸 Dépenses enregistrées :', style: TextStyle(fontSize: 13)),
                      Text('${provider.expenses.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('🎯 Objectifs d\'Épargne :', style: TextStyle(fontSize: 13)),
                      Text('${provider.savingsGoals.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('⚙️ Règle de Répartition :', style: TextStyle(fontSize: 13)),
                      Text('${provider.budgetRule.needsPercent.toInt()}/${provider.budgetRule.wantsPercent.toInt()}/${provider.budgetRule.savingsPercent.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Exportez un fichier de sauvegarde (.json) réutilisable à tout moment sur n\'importe quel téléphone.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copier JSON'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code JSON de sauvegarde copié dans le presse-papier !')),
              );
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Exporter Fichier'),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final tempDir = await getTemporaryDirectory();
                final fileName = 'Mon_Salaire_Sauvegarde_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';
                final file = File('${tempDir.path}/$fileName');
                await file.writeAsString(jsonStr);

                await Share.shareXFiles(
                  [XFile(file.path)],
                  text: 'Sauvegarde Mon Salaire & Budget par GRIMM',
                );
              } catch (e) {
                Clipboard.setData(ClipboardData(text: jsonStr));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sauvegarde copiée au presse-papier !')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, SalaryProvider provider) {
    final controller = TextEditingController();
    String? validationMessage;
    bool isValidJson = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.cloud_download, color: Color(0xFF3B82F6), size: 28),
                SizedBox(width: 10),
                Text('Restaurer une Sauvegarde', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Collez le code JSON de votre sauvegarde ci-dessous :',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 6,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    decoration: InputDecoration(
                      hintText: '{\n  "version": 1,\n  "baseSalary": 2500,\n  ...\n}',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onChanged: (val) {
                      setDialogState(() {
                        if (val.trim().isEmpty) {
                          validationMessage = null;
                          isValidJson = false;
                        } else {
                          try {
                            final parsed = jsonDecode(val.trim()) as Map<String, dynamic>;
                            final incCount = (parsed['incomes'] as List?)?.length ?? 0;
                            final expCount = (parsed['expenses'] as List?)?.length ?? 0;
                            final goalCount = (parsed['savingsGoals'] as List?)?.length ?? 0;
                            validationMessage = '✔ Sauvegarde Valide — $incCount Revenus, $expCount Dépenses, $goalCount Objectifs trouvés';
                            isValidJson = true;
                          } catch (_) {
                            validationMessage = '❌ Format de sauvegarde invalide';
                            isValidJson = false;
                          }
                        }
                      });
                    },
                  ),
                  if (validationMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isValidJson ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        validationMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isValidJson ? const Color(0xFF10B981) : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isValidJson ? const Color(0xFF3B82F6) : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isValidJson
                    ? () async {
                        final success = await provider.importBackupData(controller.text.trim());
                        Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Portefeuille restauré avec succès !'
                                    : 'Erreur lors de la restauration.',
                              ),
                            ),
                          );
                        }
                      }
                    : null,
                child: const Text('Restaurer mon portefeuille'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalaryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paramètres & Configuration',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Base Salary Setting Card
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_wallet, color: Color(0xFF10B981)),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Salaire Mensuel Net',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _salaryController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Montant de base',
                              suffixText: provider.currency,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => _saveSalary(provider),
                          child: const Text('Enregistrer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Currency Selector Card
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.currency_exchange, color: Color(0xFF3B82F6)),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Devise / Monnaie',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _currencies.map((curr) {
                        final isSelected = provider.currency == curr;
                        return ChoiceChip(
                          label: Text(curr, style: const TextStyle(fontWeight: FontWeight.bold)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF3B82F6).withOpacity(0.2),
                          onSelected: (_) => provider.updateCurrency(curr),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Budget Rule (50/30/20) Preset Selector Card
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.tune, color: Color(0xFF8B5CF6)),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Règle de Répartition Budgétaire',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.tune, size: 18),
                        label: Text(
                          'Créer ma règle sur-mesure (${provider.budgetRule.needsPercent.toInt()}/${provider.budgetRule.wantsPercent.toInt()}/${provider.budgetRule.savingsPercent.toInt()})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () => _showCustomRuleModal(context, provider),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ou choisir un modèle rapide :',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _needs == 50 ? const Color(0xFF8B5CF6).withOpacity(0.1) : null,
                              side: BorderSide(
                                color: _needs == 50 ? const Color(0xFF8B5CF6) : Colors.grey[300]!,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _updateRule(provider, 50, 30, 20),
                            child: const Column(
                              children: [
                                Text('50 / 30 / 20', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Équilibré', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _needs == 60 ? const Color(0xFF8B5CF6).withOpacity(0.1) : null,
                              side: BorderSide(
                                color: _needs == 60 ? const Color(0xFF8B5CF6) : Colors.grey[300]!,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _updateRule(provider, 60, 20, 20),
                            child: const Column(
                              children: [
                                Text('60 / 20 / 20', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Charges +', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _needs == 70 ? const Color(0xFF8B5CF6).withOpacity(0.1) : null,
                              side: BorderSide(
                                color: _needs == 70 ? const Color(0xFF8B5CF6) : Colors.grey[300]!,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _updateRule(provider, 70, 20, 10),
                            child: const Column(
                              children: [
                                Text('70 / 20 / 10', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Prudent', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4. Dark Theme Switch Card
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: SwitchListTile(
                title: const Text('Mode Sombre', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Basculer en thème sombre pour une meilleure lisibilité nocturne'),
                value: provider.isDarkMode,
                secondary: Icon(
                  provider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: const Color(0xFFF59E0B),
                ),
                onChanged: (val) => provider.toggleDarkMode(val),
              ),
            ),
            const SizedBox(height: 20),

            // Notification Reminder Card (Rappel du 28 du mois)
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Rappel du 28 du Mois', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Notification automatique chaque 28 du mois à 09:00 pour votre épargne et budget'),
                      value: provider.isMonthlyReminderEnabled,
                      secondary: const Icon(
                        Icons.notifications_active,
                        color: Color(0xFF10B981),
                      ),
                      onChanged: (val) => provider.toggleMonthlyReminder(val),
                    ),
                    if (provider.isMonthlyReminderEnabled) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notification_add, color: Color(0xFF3B82F6)),
                        title: const Text('Tester la notification de rappel'),
                        subtitle: const Text('Déclencher immédiatement une notification de démonstration'),
                        onTap: () async {
                          await NotificationService().showTestNotification();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Notification de test envoyée !')),
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 5. Security & Authentication Card
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Sécurité & Protection', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        provider.isSecurityEnabled
                            ? 'Protection active (${provider.securityType == 'password' ? 'Mot de passe' : 'Code PIN'})'
                            : 'Protéger l\'accès à l\'application',
                      ),
                      value: provider.isSecurityEnabled,
                      secondary: const Icon(
                        Icons.security,
                        color: Color(0xFF10B981),
                      ),
                      onChanged: (val) {
                        if (val) {
                          _showSecurityChoiceModal(context);
                        } else {
                          provider.disableSecurity();
                        }
                      },
                    ),
                    if (provider.isSecurityEnabled) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.password, color: Color(0xFF3B82F6)),
                        title: Text('Changer de ${provider.securityType == 'password' ? 'mot de passe' : 'code PIN'}'),
                        onTap: () {
                          if (provider.securityType == 'password') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PasswordLockScreen(isSetupMode: true),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PinLockScreen(isSetupMode: true),
                              ),
                            );
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.lock_clock, color: Color(0xFFEF4444)),
                        title: const Text('Verrouiller maintenant'),
                        onTap: () {
                          provider.lockApp();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 6. Local Backup & Restore Card
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444)),
                      title: const Text('Imprimer / Exporter le Rapport PDF du Mois', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Générer un bilan PDF officiel avec graphiques et tableaux'),
                      onTap: () => PdfReportService.generateAndSharePdf(provider),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.table_chart, color: Color(0xFF10B981)),
                      title: const Text('Exporter le Mois en CSV (Excel)', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Exporter les données au format tableur CSV'),
                      onTap: () => CsvReportService.exportAndShareCsv(provider),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF8B5CF6)),
                      title: const Text('Exporter la sauvegarde locale (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Générer un code de sauvegarde JSON'),
                      onTap: () => _showExportDialog(context, provider),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.cloud_download_outlined, color: Color(0xFF3B82F6)),
                      title: const Text('Restaurer une sauvegarde locale', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Importer vos données financières à partir d\'une sauvegarde'),
                      onTap: () => _showImportDialog(context, provider),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 20),

            // 6. Reset Data Card
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Réinitialiser toutes les données', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                subtitle: const Text('Effacer définitivement toutes les dépenses, revenus et objectifs'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Confirmer la réinitialisation'),
                      content: const Text('Êtes-vous sûr de vouloir effacer toutes vos données ? Cette action est irréversible.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            provider.clearAllData();
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Toutes les données ont été réinitialisées !')),
                            );
                          },
                          child: const Text('Effacer tout'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            // Footer Credit: Created by GRIMM
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.code,
                        size: 16,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Created by GRIMM',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mon Salaire & Budget v1.0.0',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
