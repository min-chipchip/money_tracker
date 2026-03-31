import 'package:flutter/material.dart';
import 'package:money_tracker/AppPages/insights.dart';
import 'package:money_tracker/AppPages/receipt.dart';
import 'package:money_tracker/AppPages/stats.dart';
import 'package:money_tracker/AppPages/home.dart';
import 'package:money_tracker/AppPages/qna.dart';
import 'package:money_tracker/AppPages/settings.dart';
import 'package:money_tracker/AppAPI/currency_provider.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await CurrencyProvider().init(); // Load rates once
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: const Home()));
}


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const MyHomeForm(),
    const MyStatsPage(),
    const MyInsightsForm(),
    const MyReceiptForm(),
    const MyQnAForm(),
    const MySettingsForm(),
  ];



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Stats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb),
            label: 'Insights',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Receipt'),
          BottomNavigationBarItem(
            icon: Icon(Icons.question_answer),
            label: "QnA",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
