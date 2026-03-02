import 'package:flutter/material.dart';

class MyReceiptForm extends StatefulWidget {
  const MyReceiptForm({super.key});

  @override
  State<MyReceiptForm> createState() => _MyReceiptFormState();
}

class _MyReceiptFormState extends State<MyReceiptForm> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long,
            size: 100,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          Text(
            "Receipt View",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Nunito',
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Your receipt will appear here.",
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