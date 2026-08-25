import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget_rule.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/savings_goal.dart';

class StorageService {
  static const String _keyBaseSalary = 'base_salary';
  static const String _keyCurrency = 'currency';
  static const String _keyPayDay = 'pay_day';
  static const String _keyBudgetRule = 'budget_rule';
  static const String _keyIncomes = 'incomes_list';
  static const String _keyExpenses = 'expenses_list';
  static const String _keySavingsGoals = 'savings_goals_list';
  static const String _keyDarkMode = 'is_dark_mode';
  static const String _keyPinCode = 'pin_code';
  static const String _keyPassword = 'app_password';
  static const String _keySecurityType = 'security_type';
  static const String _keyIsSecurityEnabled = 'is_security_enabled';

  final SharedPreferences prefs;

  StorageService(this.prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Base Salary
  double getBaseSalary() {
    return prefs.getDouble(_keyBaseSalary) ?? 2500.0; // Default sample salary
  }

  Future<void> saveBaseSalary(double salary) async {
    await prefs.setDouble(_keyBaseSalary, salary);
  }

  // Currency
  String getCurrency() {
    return prefs.getString(_keyCurrency) ?? '€';
  }

  Future<void> saveCurrency(String currency) async {
    await prefs.setString(_keyCurrency, currency);
  }

  // Pay Day
  int getPayDay() {
    return prefs.getInt(_keyPayDay) ?? 1;
  }

  Future<void> savePayDay(int day) async {
    await prefs.setInt(_keyPayDay, day);
  }

  // Budget Rule
  BudgetRule getBudgetRule() {
    final raw = prefs.getString(_keyBudgetRule);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        return BudgetRule.fromJson(json);
      } catch (_) {}
    }
    return const BudgetRule();
  }

  Future<void> saveBudgetRule(BudgetRule rule) async {
    await prefs.setString(_keyBudgetRule, jsonEncode(rule.toJson()));
  }

  // Incomes
  List<Income> getIncomes() {
    final rawList = prefs.getStringList(_keyIncomes);
    if (rawList == null || rawList.isEmpty) return [];
    return rawList
        .map((item) => Income.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveIncomes(List<Income> incomes) async {
    final stringList = incomes.map((i) => jsonEncode(i.toJson())).toList();
    await prefs.setStringList(_keyIncomes, stringList);
  }

  // Expenses
  List<Expense> getExpenses() {
    final rawList = prefs.getStringList(_keyExpenses);
    if (rawList == null || rawList.isEmpty) return [];
    return rawList
        .map((item) => Expense.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final stringList = expenses.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_keyExpenses, stringList);
  }

  // Savings Goals
  List<SavingsGoal> getSavingsGoals() {
    final rawList = prefs.getStringList(_keySavingsGoals);
    if (rawList == null || rawList.isEmpty) return [];
    return rawList
        .map((item) => SavingsGoal.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSavingsGoals(List<SavingsGoal> goals) async {
    final stringList = goals.map((g) => jsonEncode(g.toJson())).toList();
    await prefs.setStringList(_keySavingsGoals, stringList);
  }

  // Theme Mode
  bool isDarkMode() {
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  Future<void> saveDarkMode(bool isDark) async {
    await prefs.setBool(_keyDarkMode, isDark);
  }

  // Security & Authentication
  bool isSecurityEnabled() {
    return prefs.getBool(_keyIsSecurityEnabled) ?? false;
  }

  Future<void> saveSecurityEnabled(bool enabled) async {
    await prefs.setBool(_keyIsSecurityEnabled, enabled);
  }

  String getSecurityType() {
    return prefs.getString(_keySecurityType) ?? 'pin'; // 'pin' or 'password'
  }

  Future<void> saveSecurityType(String type) async {
    await prefs.setString(_keySecurityType, type);
  }

  String? getPinCode() {
    return prefs.getString(_keyPinCode);
  }

  Future<void> savePinCode(String pin) async {
    await prefs.setString(_keyPinCode, pin);
  }

  String? getPassword() {
    return prefs.getString(_keyPassword);
  }

  Future<void> savePassword(String password) async {
    await prefs.setString(_keyPassword, password);
  }

  Future<void> clearAllData() async {
    await prefs.remove(_keyIncomes);
    await prefs.remove(_keyExpenses);
    await prefs.remove(_keySavingsGoals);
  }

  String exportBackupJson() {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'baseSalary': getBaseSalary(),
      'currency': getCurrency(),
      'payDay': getPayDay(),
      'budgetRule': getBudgetRule().toJson(),
      'incomes': getIncomes().map((i) => i.toJson()).toList(),
      'expenses': getExpenses().map((e) => e.toJson()).toList(),
      'savingsGoals': getSavingsGoals().map((g) => g.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<bool> importBackupJson(String jsonStr) async {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (data.containsKey('baseSalary')) {
        await saveBaseSalary((data['baseSalary'] as num).toDouble());
      }
      if (data.containsKey('currency')) {
        await saveCurrency(data['currency'] as String);
      }
      if (data.containsKey('payDay')) {
        await savePayDay(data['payDay'] as int);
      }
      if (data.containsKey('budgetRule')) {
        await saveBudgetRule(BudgetRule.fromJson(data['budgetRule'] as Map<String, dynamic>));
      }
      if (data.containsKey('incomes')) {
        final list = (data['incomes'] as List)
            .map((item) => Income.fromJson(item as Map<String, dynamic>))
            .toList();
        await saveIncomes(list);
      }
      if (data.containsKey('expenses')) {
        final list = (data['expenses'] as List)
            .map((item) => Expense.fromJson(item as Map<String, dynamic>))
            .toList();
        await saveExpenses(list);
      }
      if (data.containsKey('savingsGoals')) {
        final list = (data['savingsGoals'] as List)
            .map((item) => SavingsGoal.fromJson(item as Map<String, dynamic>))
            .toList();
        await saveSavingsGoals(list);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
