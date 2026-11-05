import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/AppAPI/currency_provider.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppPages/home.dart';
import 'package:money_tracker/AppPages/insights.dart';
import 'package:money_tracker/AppPages/qna.dart';
import 'package:money_tracker/AppPages/receipt.dart';
import 'package:money_tracker/AppPages/settings.dart';
import 'package:money_tracker/AppPages/stats.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CurrencyProvider().init(); // Load rates once
  runApp(
    // ProviderScope holds the state of every Riverpod provider in the app.
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const Home(),
      ),
    ),
  );
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    MyHomeForm(),
    MyStatsPage(),
    MyInsightsForm(),
    MyReceiptForm(),
    MyQnAForm(),
    MySettingsForm(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.muted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Receipt'),
          BottomNavigationBarItem(icon: Icon(Icons.question_answer), label: 'QnA'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
