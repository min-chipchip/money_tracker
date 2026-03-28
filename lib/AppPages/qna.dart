import 'package:flutter/material.dart';
import 'package:money_tracker/AppItem/TextFunction.dart';

class MyQnAForm extends StatefulWidget {
  const MyQnAForm({super.key});

  @override
  State<MyQnAForm> createState() => _MyQnAFormState();
}

class _MyQnAFormState extends State<MyQnAForm> {
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.question_answer,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            customText(
              "QnA View",
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800]!,
            ),
            const SizedBox(height: 10),
            customText(
              "Your QnA will appear here.",
              fontSize: 16,
              color: Colors.grey[600]!,
            ),
          ],
        ),
      );
  }

}
