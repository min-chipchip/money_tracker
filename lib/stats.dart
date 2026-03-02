import 'package:flutter/material.dart';

class MyStatsPage extends StatefulWidget {
  const MyStatsPage({super.key});

  @override
  State<MyStatsPage> createState() => _MyStatsPageState();
}

class _MyStatsPageState extends State<MyStatsPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pie_chart_rounded,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            Text(
              "Statistics View",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Your financial overview will appear here.",
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
