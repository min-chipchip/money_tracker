import 'package:flutter/material.dart';
import 'package:money_tracker/database.dart';
import 'package:money_tracker/insights.dart';
import 'package:money_tracker/receipt.dart';
import 'package:money_tracker/stats.dart';
import 'package:money_tracker/home.dart';
import 'package:money_tracker/qna.dart';
import 'package:money_tracker/settings.dart';

void main() => runApp(MaterialApp(
      home: Home()
));

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _DropdownButton extends StatefulWidget {
  final List<String> currentList;

  const _DropdownButton(this.currentList);

  @override
  State<_DropdownButton> createState() => _DropdownButtonState();
}

class _DropdownButtonState extends State<_DropdownButton> {
  late String dropdownValue;

  @override
  void initState() {
    super.initState();
    dropdownValue = widget.currentList.first;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: dropdownValue,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
      isExpanded: true,
      elevation: 16,
      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, fontFamily: 'Nunito', color: Colors.black),
      underline: Container(),
      onChanged: (String? newValue) {
        setState(() {
          dropdownValue = newValue!;
        });
      },
      items: widget.currentList.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }
}

class _HomeState extends State<Home> {
  DateTime selectedDate = DateTime.now();
  bool isHighlighted = false;
  int rating = 3;

  final List<Widget> _pages = [
    const MyHomeForm(),
    const MyStatsPage(),
    const MyInsightsForm(),
    const MyReceiptForm(),
    const MyQnAForm(),
    const MySettingsForm(),
  ];

  Widget ratingCircle(int value) {
    bool isSelected = rating >= value;
    return GestureDetector(
      onTap: () {
        setState(() {
          rating = value;
        });
      },
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Colors.blue : Colors.grey[200],
        ),
        child: Center(
          child: Text(
            value.toString(),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F9FF),
        body: _pages[selected_page],

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selected_page,
          onTap: (int index) {
            setState(() {
              selected_page = index;
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
