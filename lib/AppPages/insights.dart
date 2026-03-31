import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money_tracker/AppItem/database.dart';
import 'package:money_tracker/AppItem/TextFunction.dart';
import 'package:money_tracker/AppItem/DateBar.dart';
import 'package:money_tracker/AppAPI/currency_provider.dart';

class MyInsightsForm extends StatefulWidget {
  const MyInsightsForm({super.key});

  @override
  State<MyInsightsForm> createState() => _MyInsightsFormState();
}

class _MyInsightsFormState extends State<MyInsightsForm> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  DateTime _viewingDate = DateTime.now();
  int _viewmode = 1; double total_spent = 0;


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
          child: customText(
            value.toString(),
            color: isSelected ? Colors.white : Colors.grey[600]!,
            fontWeight: FontWeight.bold,
            fontSize: 16,
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
          MyDateBar(viewingDate: _viewingDate, viewmode: _viewmode,
            onDateChanged: (newDate, newMode){
              setState((){
                _viewingDate = newDate;
                _viewmode = newMode;
              });
            },
            onCurrencyToggle: () => setState(() => CurrencyProvider().toggleCurrency()),
          ),

          AspectRatio(
            aspectRatio: 1.0,
            child: FutureBuilder<List<TransactionModel>>(
              future: dbHelper.getTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: customText("Error: ${snapshot.error}"));
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
                          customText("TOTAL", color: Colors.grey, fontSize: 25),
                          customText("${total_spent.toStringAsFixed(2)} ${CurrencyProvider().currentCurrency}", fontWeight: FontWeight.bold, fontSize: 25),
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
          customText(
            "No Data Yet",
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 10),
          customText(
            "Add some entries to see your statistics.",
            fontSize: 16,
            color: Colors.grey[600]!,
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
        if (_viewmode == 1) {
          return itemDate.month == _viewingDate.month &&
              itemDate.year == _viewingDate.year;
        }
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

    for (var item in filtered){
      if(categoryTotals.containsKey(item.category)){
        categoryTotals[item.category] = categoryTotals[item.category]! + CurrencyProvider().convertNum(item.amount, item.currency);
      } else {
        categoryTotals[item.category] = CurrencyProvider().convertNum(item.amount, item.currency);
      }
      total_spent = total_spent + CurrencyProvider().convertNum(item.amount, item.currency);
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
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Nunito'),
      );
    }).toList();

  }
}
