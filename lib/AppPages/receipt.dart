import 'package:flutter/material.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';

class MyReceiptForm extends StatelessWidget {
  const MyReceiptForm({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.receipt,
      title: 'Receipts',
      message: 'Receipt scanning is coming soon.',
    );
  }
}
