import 'package:flutter/material.dart';
import 'package:money_tracker/AppAPI/currency_services.dart';
import 'package:money_tracker/AppItem/TextFunction.dart';

class MyReceiptForm extends StatefulWidget {
  const MyReceiptForm({super.key});

  @override
  State<MyReceiptForm> createState() => _MyReceiptFormState();
}

class _MyReceiptFormState extends State<MyReceiptForm> {
  bool isLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isLoaded,
      replacement: const Center(
        child: CircularProgressIndicator(),
      ),
      child: Center(
        child: customText(
          "你好",
          fontSize: 30,
        )
      ),
    );
  }
}
