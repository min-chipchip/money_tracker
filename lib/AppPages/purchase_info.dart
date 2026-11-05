import 'package:flutter/material.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/database.dart';
import 'package:money_tracker/AppItem/transaction_form.dart';

/// Edit page: the shared transaction form in "edit" mode.
/// Pops `true` when the transaction was saved, `false` on Return.
class PurchaseInfo extends StatelessWidget {
  const PurchaseInfo({super.key, required this.transaction});

  final TransactionModel transaction;

  Future<void> _save(BuildContext context, TransactionModel updated) async {
    await DatabaseHelper().insertTransaction(updated); // same id → replaces the row
    if (!context.mounted) return;
    showAppSnackBar(context, 'Transaction updated successfully!');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySoft,
                foregroundColor: Colors.black,
              ),
              child: const Text('Return', style: AppText.title),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.page, 30, AppSpacing.page, 20),
              child: Text(
                'PURCHASE INFO',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            TransactionForm(
              initial: transaction,
              submitLabel: 'Edit Entry',
              onSubmit: (t) => _save(context, t),
            ),
          ],
        ),
      ),
    );
  }
}
