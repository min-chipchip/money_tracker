import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/transaction_form.dart';
import 'package:money_tracker/data/db/app_database.dart';
import 'package:money_tracker/state/transaction_actions.dart';

/// Edit page: the shared transaction form in "edit" mode. Works for both
/// expenses and deposits (income); the form takes the type from [transaction].
class PurchaseInfo extends ConsumerWidget {
  const PurchaseInfo({super.key, required this.transaction});

  final MoneyTransaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FormPage(
      title: transaction.type == 'income' ? 'DEPOSIT INFO' : 'PURCHASE INFO',
      child: TransactionForm(
        initial: transaction,
        submitLabel: 'Edit Entry',
        onSubmit: (draft) async {
          await ref.read(transactionActionsProvider).save(draft, id: transaction.id);
          if (!context.mounted) return;
          showAppSnackBar(context, 'Transaction updated successfully!');
          Navigator.pop(context);
        },
      ),
    );
  }
}
