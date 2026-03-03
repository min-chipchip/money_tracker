import 'package:flutter/material.dart';
import 'package:money_tracker/database.dart';
import 'package:money_tracker/insights.dart';
import 'package:money_tracker/receipt.dart';
import 'package:money_tracker/stats.dart';
import 'package:money_tracker/home.dart';
import 'package:money_tracker/qna.dart';
import 'package:money_tracker/settings.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Home(),
));

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0; // Fixed: Defined the index variable

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
        body: _pages[_selectedIndex], // Fixed: Use _selectedIndex

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex, // Fixed: Use _selectedIndex
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
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart),
              label: 'Stats'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.lightbulb),
              label: 'Insights'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt),
              label: 'Receipt',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.question_answer),
              label: "QnA",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "Settings",
            )
          ]
        ),
      );
  }
}
