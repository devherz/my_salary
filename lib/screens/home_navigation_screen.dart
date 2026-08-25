import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/salary_provider.dart';
import 'analytics_tab.dart';
import 'dashboard_tab.dart';
import 'expenses_tab.dart';
import 'goals_tab.dart';
import 'password_lock_screen.dart';
import 'pin_lock_screen.dart';
import 'settings_tab.dart';

class HomeNavigationScreen extends StatefulWidget {
  const HomeNavigationScreen({super.key});

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalaryProvider>(context);

    // If app is locked, display the appropriate Lock Screen (PIN or Password)
    if (provider.isSecurityEnabled && !provider.isUnlocked) {
      if (provider.securityType == 'password') {
        return const PasswordLockScreen(isSetupMode: false);
      }
      return const PinLockScreen(isSetupMode: false);
    }

    final List<Widget> tabs = [
      DashboardTab(onNavigateTab: (index) {
        setState(() {
          _currentIndex = index;
        });
      }),
      const ExpensesTab(),
      const GoalsTab(),
      const AnalyticsTab(),
      const SettingsTab(),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: tabs,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF10B981)),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: Color(0xFF10B981)),
            label: 'Dépenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings, color: Color(0xFF10B981)),
            label: 'Objectifs',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart, color: Color(0xFF10B981)),
            label: 'Analyses',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Color(0xFF10B981)),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}
