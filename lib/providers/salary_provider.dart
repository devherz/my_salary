import 'package:flutter/material.dart';
import '../models/budget_rule.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/savings_goal.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class SalaryProvider extends ChangeNotifier {
  final StorageService storage;

  double _baseSalary = 0.0;
  String _currency = '€';
  int _payDay = 1;
  BudgetRule _budgetRule = const BudgetRule();
  List<Income> _incomes = [];
  List<Expense> _expenses = [];
  List<SavingsGoal> _savingsGoals = [];
  bool _isDarkMode = false;
  DateTime _selectedMonth = DateTime.now();
  bool _isSecurityEnabled = false;
  String _securityType = 'pin'; // 'pin' or 'password'
  String? _pinCode;
  String? _password;
  bool _isUnlocked = true;
  bool _isMonthlyReminderEnabled = true;

  SalaryProvider(this.storage) {
    _loadFromStorage();
  }

  // Getters
  double get baseSalary => _baseSalary;
  String get currency => _currency;
  int get payDay => _payDay;
  BudgetRule get budgetRule => _budgetRule;
  List<Income> get incomes => _incomes;
  List<Expense> get expenses => _expenses;
  List<SavingsGoal> get savingsGoals => _savingsGoals;
  bool get isDarkMode => _isDarkMode;
  DateTime get selectedMonth => _selectedMonth;
  bool get isSecurityEnabled => _isSecurityEnabled;
  String get securityType => _securityType;
  String? get pinCode => _pinCode;
  String? get password => _password;
  bool get isUnlocked => _isUnlocked;
  bool get isMonthlyReminderEnabled => _isMonthlyReminderEnabled;

  void _loadFromStorage() {
    _baseSalary = storage.getBaseSalary();
    _currency = storage.getCurrency();
    _payDay = storage.getPayDay();
    _budgetRule = storage.getBudgetRule();
    _incomes = storage.getIncomes();
    _expenses = storage.getExpenses();
    _savingsGoals = storage.getSavingsGoals();
    _isDarkMode = storage.isDarkMode();
    _isSecurityEnabled = storage.isSecurityEnabled();
    _securityType = storage.getSecurityType();
    _pinCode = storage.getPinCode();
    _password = storage.getPassword();
    _isUnlocked = !_isSecurityEnabled;
    _isMonthlyReminderEnabled = storage.isMonthlyReminderEnabled();
    notifyListeners();
  }

  Future<void> toggleMonthlyReminder(bool enabled) async {
    _isMonthlyReminderEnabled = enabled;
    await storage.saveMonthlyReminderEnabled(enabled);
    if (enabled) {
      try {
        await NotificationService().scheduleMonthly28thReminder();
      } catch (e) {
        debugPrint('Error scheduling reminder: $e');
      }
    } else {
      try {
        await NotificationService().cancelReminder();
      } catch (e) {
        debugPrint('Error canceling reminder: $e');
      }
    }
    notifyListeners();
  }

  Future<void> clearAllData() async {
    _baseSalary = 0.0;
    _incomes.clear();
    _expenses.clear();
    _savingsGoals.clear();
    await storage.clearAllData();
    notifyListeners();
  }

  String exportBackupData() {
    return storage.exportBackupJson();
  }

  Future<bool> importBackupData(String jsonString) async {
    final success = await storage.importBackupJson(jsonString);
    if (success) {
      _loadFromStorage();
    }
    return success;
  }

  Future<void> enableSecurity(String pin) async {
    _securityType = 'pin';
    _pinCode = pin;
    _isSecurityEnabled = true;
    _isUnlocked = true;
    await storage.saveSecurityType('pin');
    await storage.savePinCode(pin);
    await storage.saveSecurityEnabled(true);
    notifyListeners();
  }

  Future<void> enablePasswordSecurity(String pass) async {
    _securityType = 'password';
    _password = pass;
    _isSecurityEnabled = true;
    _isUnlocked = true;
    await storage.saveSecurityType('password');
    await storage.savePassword(pass);
    await storage.saveSecurityEnabled(true);
    notifyListeners();
  }

  Future<void> disableSecurity() async {
    _isSecurityEnabled = false;
    _isUnlocked = true;
    await storage.saveSecurityEnabled(false);
    notifyListeners();
  }

  bool verifyAndUnlock(String input) {
    if (_securityType == 'password') {
      if (_password == input) {
        _isUnlocked = true;
        notifyListeners();
        return true;
      }
    } else {
      if (_pinCode == input) {
        _isUnlocked = true;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void lockApp() {
    if (_isSecurityEnabled) {
      _isUnlocked = false;
      notifyListeners();
    }
  }



  DateTime? _startDate;
  DateTime? _endDate;

  // Date Range Getters & Methods
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get isCustomDateRange => _startDate != null && _endDate != null;

  void setDateRange(DateTime start, DateTime end) {
    _startDate = DateTime(start.year, start.month, start.day, 0, 0, 0);
    _endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);
    notifyListeners();
  }

  void clearDateRange() {
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  // Month navigation
  void changeMonth(DateTime newMonth) {
    _selectedMonth = newMonth;
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  // Computed Properties for Current Selected Period (Month or Custom Range)
  List<Income> get currentMonthIncomes {
    if (isCustomDateRange) {
      return _incomes.where((i) {
        return i.date.isAfter(_startDate!.subtract(const Duration(seconds: 1))) &&
            i.date.isBefore(_endDate!.add(const Duration(seconds: 1)));
      }).toList();
    }
    return _incomes.where((i) {
      return i.date.year == _selectedMonth.year &&
          i.date.month == _selectedMonth.month;
    }).toList();
  }

  List<Expense> get currentMonthExpenses {
    if (isCustomDateRange) {
      return _expenses.where((e) {
        return e.date.isAfter(_startDate!.subtract(const Duration(seconds: 1))) &&
            e.date.isBefore(_endDate!.add(const Duration(seconds: 1)));
      }).toList();
    }
    return _expenses.where((e) {
      return e.date.year == _selectedMonth.year &&
          e.date.month == _selectedMonth.month;
    }).toList();
  }

  double get totalIncomeCurrentMonth {
    final extraIncomes = currentMonthIncomes.fold<double>(
      0.0,
      (sum, item) => sum + item.amount,
    );
    // If no explicit salary income object added for this month, include base salary
    final hasSalaryIncome = currentMonthIncomes.any((i) => i.isRecurringSalary);
    if (!hasSalaryIncome) {
      return _baseSalary + extraIncomes;
    }
    return extraIncomes;
  }

  double get totalExpensesCurrentMonth {
    return currentMonthExpenses.fold<double>(
      0.0,
      (sum, item) => sum + item.amount,
    );
  }

  double get remainingBalance {
    return totalIncomeCurrentMonth - totalExpensesCurrentMonth;
  }

  // 50/30/20 Budget Allocations & Spent
  double get needsBudgetAllowed =>
      totalIncomeCurrentMonth * (_budgetRule.needsPercent / 100);
  double get wantsBudgetAllowed =>
      totalIncomeCurrentMonth * (_budgetRule.wantsPercent / 100);
  double get savingsBudgetAllowed =>
      totalIncomeCurrentMonth * (_budgetRule.savingsPercent / 100);

  double get needsExpensesSpent {
    return currentMonthExpenses
        .where((e) => e.budgetType == BudgetCategoryType.needs)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get wantsExpensesSpent {
    return currentMonthExpenses
        .where((e) => e.budgetType == BudgetCategoryType.wants)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get savingsExpensesSpent {
    return currentMonthExpenses
        .where((e) => e.budgetType == BudgetCategoryType.savings)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Map<String, double> get categoryBreakdown {
    final Map<String, double> map = {};
    for (var expense in currentMonthExpenses) {
      map[expense.category] = (map[expense.category] ?? 0) + expense.amount;
    }
    return map;
  }

  // Actions
  Future<void> updateBaseSalary(double newSalary) async {
    _baseSalary = newSalary;
    await storage.saveBaseSalary(newSalary);

    // Update or add recurring salary income entry for this month
    final idx = _incomes.indexWhere((i) => i.isRecurringSalary);
    if (idx != -1) {
      final old = _incomes[idx];
      _incomes[idx] = Income(
        id: old.id,
        title: old.title,
        amount: newSalary,
        date: old.date,
        isRecurringSalary: true,
        note: old.note,
      );
      await storage.saveIncomes(_incomes);
    }
    notifyListeners();
  }

  Future<void> updateCurrency(String newCurrency) async {
    _currency = newCurrency;
    await storage.saveCurrency(newCurrency);
    notifyListeners();
  }

  Future<void> updateBudgetRule(BudgetRule rule) async {
    _budgetRule = rule;
    await storage.saveBudgetRule(rule);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    await storage.saveDarkMode(isDark);
    notifyListeners();
  }

  Future<void> addIncome(Income income) async {
    _incomes.add(income);
    await storage.saveIncomes(_incomes);
    notifyListeners();
  }

  Future<void> deleteIncome(String id) async {
    _incomes.removeWhere((i) => i.id == id);
    await storage.saveIncomes(_incomes);
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    await storage.saveExpenses(_expenses);
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    final idx = _expenses.indexWhere((e) => e.id == expense.id);
    if (idx != -1) {
      _expenses[idx] = expense;
      await storage.saveExpenses(_expenses);
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    await storage.saveExpenses(_expenses);
    notifyListeners();
  }

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    _savingsGoals.add(goal);
    await storage.saveSavingsGoals(_savingsGoals);
    notifyListeners();
  }

  Future<void> depositToGoal(String goalId, double amount) async {
    final idx = _savingsGoals.indexWhere((g) => g.id == goalId);
    if (idx != -1) {
      final old = _savingsGoals[idx];
      _savingsGoals[idx] = old.copyWith(
        currentAmount: old.currentAmount + amount,
      );
      await storage.saveSavingsGoals(_savingsGoals);

      // Also record as a savings expense for tracking
      await addExpense(
        Expense(
          id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Dépôt: ${old.title}',
          amount: amount,
          category: 'Épargne & Projets',
          budgetType: BudgetCategoryType.savings,
          date: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  Future<void> deleteGoal(String id) async {
    _savingsGoals.removeWhere((g) => g.id == id);
    await storage.saveSavingsGoals(_savingsGoals);
    notifyListeners();
  }
}
