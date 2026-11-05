import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/transaction_form.dart';
import 'package:money_tracker/data/db/app_database.dart';
import 'package:money_tracker/state/transaction_actions.dart';

/// Edit page: the shared transaction form in "edit" mode.
class PurchaseInfo extends ConsumerWidget {
  const PurchaseInfo({super.key, required this.transaction});

  final MoneyTransaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
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
              onSubmit: (draft) async {
                await ref.read(transactionActionsProvider).save(draft, id: transaction.id);
                if (!context.mounted) return;
                showAppSnackBar(context, 'Transaction updated successfully!');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
