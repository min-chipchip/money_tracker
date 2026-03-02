import 'package:flutter/material.dart';

class MyInsightsForm extends StatefulWidget {
  const MyInsightsForm({super.key});

  @override
  State<MyInsightsForm> createState() => _MyInsightsFormState();
}

class _MyInsightsFormState extends State<MyInsightsForm> {
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
          const Icon(
            Icons.lightbulb,
            size: 100,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          Text(
            "Insights View",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Nunito',
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Your insights will appear here.",
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
}