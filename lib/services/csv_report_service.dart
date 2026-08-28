import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/salary_provider.dart';

class CsvReportService {
  static Future<void> exportAndShareCsv(SalaryProvider provider) async {
    final monthExpenses = provider.expenses.where((e) => e.date.year == provider.selectedMonth.year && e.date.month == provider.selectedMonth.month).toList();
    final monthIncomes = provider.incomes;

    final buffer = StringBuffer();
    buffer.writeln('Type;Date;Intitulé;Montant;Catégorie;Source');

    for (final inc in monthIncomes) {
      final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());
      buffer.writeln('Revenu;$dateStr;"${inc.title}";${inc.amount.toStringAsFixed(2)};Revenu;${inc.title}');
    }

    for (final exp in monthExpenses) {
      final dateStr = DateFormat('dd/MM/yyyy').format(exp.date);
      final incomeSource = provider.incomes.where((i) => i.id == exp.incomeSourceId).firstOrNull;
      final sourceTitle = incomeSource?.title ?? 'Global';
      buffer.writeln('Dépense;$dateStr;"${exp.title}";${exp.amount.toStringAsFixed(2)};"${exp.category}";"$sourceTitle"');
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/export_my_salary_${provider.selectedMonth.year}_${provider.selectedMonth.month}.csv');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Export CSV My Salary - ${DateFormat('MMMM yyyy', 'fr_FR').format(provider.selectedMonth)}',
    );
  }
}
