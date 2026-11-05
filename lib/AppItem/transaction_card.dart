import 'package:flutter/material.dart';
import 'package:money_tracker/AppAPI/currency_provider.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/database.dart';

/// One row in the transaction history list.
class TransactionCard extends StatelessWidget {
  const TransactionCard({super.key, required this.item, required this.onToggleStar});

  final TransactionModel item;
  final VoidCallback onToggleStar;

  @override
  Widget build(BuildContext context) {
    final hasReason = item.reason.isNotEmpty;
    return Card(
      elevation: 2,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: ListTile(
        leading: const Icon(Icons.monetization_on, color: AppColors.primary),
        title: Text(
          '${item.category} - ${CurrencyProvider().convert(item.amount, item.currency)}',
          style: AppText.strong,
        ),
        subtitle: Text(
          '${item.date} (${item.account})${hasReason ? '\n${item.reason}' : ''}',
          style: AppText.body,
        ),
        isThreeLine: hasReason,
        trailing: StarButton(isOn: item.isHighlighted == 1, onPressed: onToggleStar),
      ),
    );
  }
}
