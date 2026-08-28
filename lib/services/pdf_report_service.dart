import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/salary_provider.dart';

class PdfReportService {
  static Future<void> generateAndSharePdf(SalaryProvider provider) async {
    final pdf = pw.Document();
    final currency = provider.currency;
    final formatter = NumberFormat.currency(symbol: currency, decimalDigits: 2, locale: 'fr_FR');
    final monthStr = DateFormat('MMMM yyyy', 'fr_FR').format(provider.selectedMonth);

    final monthIncomes = provider.incomes;
    final monthExpenses = provider.expenses.where((e) => e.date.year == provider.selectedMonth.year && e.date.month == provider.selectedMonth.month).toList();
    final totalIncomes = monthIncomes.fold<double>(0.0, (sum, i) => sum + i.amount);
    final totalExpenses = monthExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final remaining = totalIncomes - totalExpenses;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('MY SALARY', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.Text('Rapport Financier Mensuel - $monthStr', style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now()), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 14),

            // Summary Box
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(children: [
                    pw.Text('Total Revenus', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text(formatter.format(totalIncomes), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                  ]),
                  pw.Column(children: [
                    pw.Text('Total Dépenses', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text(formatter.format(totalExpenses), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                  ]),
                  pw.Column(children: [
                    pw.Text('Solde Restant', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text(formatter.format(remaining), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  ]),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Income Sources Section
            pw.Text('Sources de Revenus (${monthIncomes.length})', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            if (monthIncomes.isEmpty)
              pw.Text('Aucun revenu enregistré.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Source de Revenu', 'Répartition', 'Montant'],
                data: monthIncomes.map((inc) => [
                  inc.title,
                  '${inc.needsRatio.toInt()}/${inc.wantsRatio.toInt()}/${inc.savingsRatio.toInt()}',
                  formatter.format(inc.amount),
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              ),
            pw.SizedBox(height: 16),

            // Expenses Table
            pw.Text('Dépenses du Mois (${monthExpenses.length})', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            if (monthExpenses.isEmpty)
              pw.Text('Aucune dépense enregistrée pour ce mois.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Intitulé', 'Catégorie', 'Montant'],
                data: monthExpenses.map((exp) => [
                  DateFormat('dd/MM/yyyy').format(exp.date),
                  exp.title,
                  exp.category,
                  formatter.format(exp.amount),
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'rapport_my_salary_${provider.selectedMonth.year}_${provider.selectedMonth.month}.pdf',
    );
  }
}
