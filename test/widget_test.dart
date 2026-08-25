import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:salary/main.dart';
import 'package:salary/models/budget_rule.dart';
import 'package:salary/models/expense.dart';
import 'package:salary/models/income.dart';
import 'package:salary/providers/salary_provider.dart';
import 'package:salary/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Salary app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SalaryProvider(storage),
        child: const SalaryManagerApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(SalaryManagerApp), findsOneWidget);
  });

  test('PIN & Password security provider unit test', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final provider = SalaryProvider(storage);

    expect(provider.isSecurityEnabled, false);
    expect(provider.isUnlocked, true);

    // Test PIN Mode
    await provider.enableSecurity('1234');
    expect(provider.isSecurityEnabled, true);
    expect(provider.securityType, 'pin');
    expect(provider.pinCode, '1234');

    provider.lockApp();
    expect(provider.isUnlocked, false);
    expect(provider.verifyAndUnlock('1234'), true);

    // Test Password Mode
    await provider.enablePasswordSecurity('MonSuperPass123');
    expect(provider.securityType, 'password');
    expect(provider.password, 'MonSuperPass123');

    provider.lockApp();
    expect(provider.isUnlocked, false);
    expect(provider.verifyAndUnlock('mauvaisPass'), false);
    expect(provider.verifyAndUnlock('MonSuperPass123'), true);
  });

  test('Local backup export and import test', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final provider = SalaryProvider(storage);

    await provider.updateBaseSalary(3200.0);
    await provider.addIncome(
      Income(
        id: 'test_inc_1',
        title: 'Revenu Test',
        amount: 500.0,
        date: DateTime.now(),
      ),
    );

    final exportedJson = provider.exportBackupData();
    expect(exportedJson.contains('Revenu Test'), true);
    expect(exportedJson.contains('3200.0'), true);

    // Clear state
    await provider.clearAllData();
    expect(provider.incomes.isEmpty, true);

    // Import backup back
    final importSuccess = await provider.importBackupData(exportedJson);
    expect(importSuccess, true);
    expect(provider.baseSalary, 3200.0);
    expect(provider.incomes.length, 1);
    expect(provider.incomes.first.title, 'Revenu Test');
  });

  test('Date range start and end filtering test', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final provider = SalaryProvider(storage);

    final exp1 = Expense(
      id: 'e1',
      title: 'Achat Juillet',
      amount: 100.0,
      category: 'Courses',
      date: DateTime(2026, 7, 15),
      budgetType: BudgetCategoryType.needs,
    );
    final exp2 = Expense(
      id: 'e2',
      title: 'Achat Août',
      amount: 250.0,
      category: 'Loisirs',
      date: DateTime(2026, 8, 20),
      budgetType: BudgetCategoryType.wants,
    );

    await provider.addExpense(exp1);
    await provider.addExpense(exp2);

    expect(provider.isCustomDateRange, false);

    // Filter range: 1er Août 2026 au 31 Août 2026
    provider.setDateRange(DateTime(2026, 8, 1), DateTime(2026, 8, 31));
    expect(provider.isCustomDateRange, true);
    expect(provider.currentMonthExpenses.length, 1);
    expect(provider.currentMonthExpenses.first.title, 'Achat Août');

    // Reset range
    provider.clearDateRange();
    expect(provider.isCustomDateRange, false);
  });
}
