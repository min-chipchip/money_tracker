import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppPages/home.dart';
import 'package:money_tracker/AppPages/accounts.dart';
import 'package:money_tracker/AppPages/qna.dart';
import 'package:money_tracker/AppPages/receipt.dart';
import 'package:money_tracker/AppPages/settings.dart';
import 'package:money_tracker/AppPages/stats.dart';
import 'package:money_tracker/state/providers.dart';

void main() {
  // No waiting for the network here: the app opens instantly using the
  // exchange rates cached in the database, and refreshes them in the
  // background (see _HomeState.initState).
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

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fire and forget: if it works, today's rates are saved and every screen
    // updates via fxRatesProvider; if offline (or no API key), nothing
    // changes and the cached rates keep working.
    ref.read(fxRepositoryProvider).refreshFromApi();
  }

  static const List<Widget> _pages = [
    MyHomeForm(),
    MyStatsPage(),
    AccountsPage(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Receipt'),
          BottomNavigationBarItem(
            icon: Icon(Icons.question_answer),
            label: 'QnA',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
