import 'package:flutter/material.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/database.dart';
import 'package:money_tracker/AppItem/transaction_form.dart';

/// Daily entry page: header + the shared transaction form in "add" mode.
class MyHomeForm extends StatelessWidget {
  const MyHomeForm({super.key});

  Future<void> _save(BuildContext context, TransactionModel transaction) async {
    await DatabaseHelper().insertTransaction(transaction);
    if (context.mounted) showAppSnackBar(context, 'Entry saved to Database!');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.page, 50, AppSpacing.page, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MoneyTracker', style: AppText.headline),
                Text('DAILY ENTRY', style: AppText.bodyMuted),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.page, 20, AppSpacing.page, 20),
            child: Text.rich(
              TextSpan(
                style: AppText.hero,
                children: [
                  TextSpan(text: 'What did you\n'),
                  TextSpan(text: 'spend money ', style: TextStyle(color: AppColors.accent)),
                  TextSpan(text: 'on?'),
                ],
              ),
            ),
          ),
          TransactionForm(
            submitLabel: 'Submit Entry',
            clearAfterSubmit: true,
            onSubmit: (t) => _save(context, t),
          ),
        ],
      ),
    );
  }
}
