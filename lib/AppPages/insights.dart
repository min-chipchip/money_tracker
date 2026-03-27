import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money_tracker/AppItem/database.dart';
import 'dart:math';

class MyInsightsForm extends StatefulWidget {
  const MyInsightsForm({super.key});

  @override
  State<MyInsightsForm> createState() => _MyInsightsFormState();
}

class _MyInsightsFormState extends State<MyInsightsForm> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  DateTime _viewingDate = DateTime.now();
  int _viewmode = 1; double total_spent = 0;

  void _nextYear() {
    setState(() {
      _viewingDate = DateTime(_viewingDate.year + 1);
    });
  }

  void _previousYear() {
    setState(() {
      _viewingDate = DateTime(_viewingDate.year - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _viewingDate = DateTime(_viewingDate.year, _viewingDate.month + 1);
    });
  }

  void _previousMonth() {
    setState(() {
      _viewingDate = DateTime(_viewingDate.year, _viewingDate.month - 1);
    });
  }

  void _nextDay() {
    setState(() {
      _viewingDate = DateTime(
        _viewingDate.year,
        _viewingDate.month,
        _viewingDate.day + 1,
      );
    });
  }

  void _previousDay() {
    setState(() {
      _viewingDate = DateTime(
        _viewingDate.year,
        _viewingDate.month,
        _viewingDate.day - 1,
      );
    });
  }

  DateTime selectedDate = DateTime.now();
  bool isHighlighted = false;
  int rating = 3;

  // Helper to build the importance level circles
  Widget ratingCircle(int value) {
    bool isSelected = rating >= value;
    return GestureDetector(
      onTap: () => setState(() => rating = value),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Date - Month - Year View Controller
          Padding(
            padding: EdgeInsetsGeometry.fromLTRB(15, 5, 15, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    if (_viewmode == 1) {
                      _previousMonth();
                    } else if (_viewmode == 2)
                      // ignore: curly_braces_in_flow_control_structures
                      _previousYear();
                    else
                      // ignore: curly_braces_in_flow_control_structures
                      _previousDay();
                  },
                  icon: Icon(Icons.arrow_back_ios, color: Colors.blue),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[200],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 5, 40, 5),
                    child: Text(
                      (_viewmode == 1
                          ? "${_viewingDate.month.toString().padLeft(2, '0')}/${_viewingDate.year}"
                          : (_viewmode == 2
                                ? _viewingDate.year.toString()
                                : "${_viewingDate.day.toString().padLeft(2, '0')}/${_viewingDate.month.toString().padLeft(2, '0')}/${_viewingDate.year}")),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_viewmode == 1) {
                      _nextMonth();
                    } else if (_viewmode == 2)
                      // ignore: curly_braces_in_flow_control_structures
                      _nextYear();
                    else
                      _nextDay();
                  },
                  icon: Icon(Icons.arrow_forward_ios, color: Colors.blue),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.blue),
            onPressed: () {
              setState(() {
                _viewmode = (_viewmode + 1) % 3;
              });
            },
          ),

          AspectRatio(
            aspectRatio: 1.0,
            child: FutureBuilder<List<TransactionModel>>(
              future: dbHelper.getTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                };

                final sections = _generateSections(snapshot.data!);

                if (sections.isEmpty) {
                  return _buildEmptyState();
                }

                return Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 100,
                          sectionsSpace: 2,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("TOTAL", style: TextStyle(color: Colors.grey, fontSize: 30)),
                          Text(total_spent.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 35)),
                        ],
                      ),
                  ]
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pie_chart_rounded, size: 100, color: Colors.blue),
          const SizedBox(height: 20),
          const Text(
            "No Data Yet",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Add some entries to see your statistics.",
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Nunito',
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateSections(
    List<TransactionModel> transactions,
  ) {
    // 1. Filter by date/viewmode
    final filtered = transactions.where((item) {
      try {
        final itemDate = DateTime.parse(item.date);
        if (_viewmode == 1)
          return itemDate.month == _viewingDate.month &&
              itemDate.year == _viewingDate.year;
        if (_viewmode == 2) return itemDate.year == _viewingDate.year;
        return itemDate.day == _viewingDate.day &&
            itemDate.month == _viewingDate.month &&
            itemDate.year == _viewingDate.year;
      } catch (e) {
        return false;
      }
    }).toList();

    Map<String, double> categoryTotals = {};
    total_spent = 0;

    for (var item in filtered){      if(categoryTotals.containsKey(item.category)){
        categoryTotals[item.category] = categoryTotals[item.category]! + item.amount;
      } else {
        categoryTotals[item.category] = item.amount;
      }
      total_spent = total_spent + item.amount;
    }

    final List<Color?> myPalette = [
      Colors.blue, Colors.red, Colors.green, Colors.yellow[800], Colors.purple, Colors.orange
    ];

    int colorIndex = 0; // Track the index

    return categoryTotals.entries.map((entry) {
      final Color? categoryColor = myPalette[colorIndex % myPalette.length];
      colorIndex++; // Move to next color for next slice

      // Use the name of the category to pick a color so it's consistent

      return PieChartSectionData(
        value: entry.value,
        color: categoryColor,
        title: "${entry.key}\n\$${entry.value.toStringAsFixed(0)}",
        radius: 80,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      );
    }).toList();

  }
}
