import 'package:flutter/material.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/data/db/app_database.dart';

/// One row in the transaction history list.
class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.item,
    required this.amountText,
    required this.onToggleStar,
  });

  final TransactionsInRangeResult item;
  final String amountText;
  final VoidCallback onToggleStar;

  @override
  Widget build(BuildContext context) {
    final t = item.t;
    final hasNote = t.note.isNotEmpty;
    final title = item.categoryName ?? 'Transfer → ${item.toAccountName}';
    return Card(
      elevation: 2,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: ListTile(
        leading: Icon(
          Icons.monetization_on,
          color: item.categoryColor != null ? Color(item.categoryColor!) : AppColors.primary,
        ),
        title: Text.rich(
          TextSpan(
            style: AppText.strong,
            children: [
              TextSpan(text: '$title - '),
              // Deposits (income) show as "+45.00 HKD" in green.
              t.type == 'income'
                  ? TextSpan(
                      text: '+$amountText',
                      style: const TextStyle(color: AppColors.income),
                    )
                  : TextSpan(text: amountText),
            ],
          ),
        ),
        subtitle: Text(
          '${t.occurredOn} (${item.accountName})${hasNote ? '\n${t.note}' : ''}',
          style: AppText.body,
        ),
        isThreeLine: hasNote,
        trailing: StarButton(isOn: t.isStarred, onPressed: onToggleStar),
      ),
    );
  }
}
