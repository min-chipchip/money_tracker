import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/transaction_form.dart';
import 'package:money_tracker/state/transaction_actions.dart';

/// Daily entry page: header + the shared transaction form in "add" mode.
class MyHomeForm extends ConsumerWidget {
  const MyHomeForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onSubmit: (draft) async {
              await ref.read(transactionActionsProvider).save(draft);
              if (context.mounted) showAppSnackBar(context, 'Entry saved!');
            },
          ),
        ],
      ),
    );
  }
}
