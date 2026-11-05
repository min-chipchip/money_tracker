import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/transaction_form.dart';
import 'package:money_tracker/data/repositories/transaction_repository.dart';
import 'package:money_tracker/state/transaction_actions.dart';

/// Money coming INTO an account (salary, a gift, a top-up...).
///
/// A deposit is just an `income` transaction, so this page reuses the same
/// form as Home with `type: TxType.income`: categories switch to income
/// categories, and the account's balance goes UP (see account_movements).
class DepositPage extends ConsumerWidget {
  const DepositPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FormPage(
      title: 'DEPOSIT',
      child: TransactionForm(
        type: TxType.income,
        submitLabel: 'Deposit',
        onSubmit: (draft) async {
          await ref.read(transactionActionsProvider).save(draft);
          if (!context.mounted) return;
          showAppSnackBar(context, 'Deposit saved!');
          Navigator.pop(context);
        },
      ),
    );
  }
}
