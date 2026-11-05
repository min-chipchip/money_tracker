import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/AppItem/account_kinds.dart';
import 'package:money_tracker/AppItem/add_account_sheet.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/input_box.dart';
import 'package:money_tracker/core/money.dart';
import 'package:money_tracker/data/db/app_database.dart';
import 'package:money_tracker/state/providers.dart';

/// Every account with its current balance, plus "Add account".
///
/// Balances aren't stored anywhere: the `accountBalances` SQL query adds up
/// the opening balance and every transaction (via the account_movements
/// view). New accounts appear here AND in the Home form's account dropdown
/// automatically, because both watch the same accountsProvider stream.
class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  Future<void> _addAccount(BuildContext context) async {
    final name = await showAddAccountSheet(context);
    if (name != null && context.mounted) {
      showAppSnackBar(context, 'Added "$name"');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final exponents = ref.watch(currencyExponentsProvider);

    return SafeArea(
      child: accounts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rows) => ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.page,
            vertical: 25,
          ),
          children: [
            const Text('Accounts', style: AppText.headline),
            const Text('REMAINING BALANCE', style: AppText.bodyMuted),
            const SizedBox(height: 20),
            _TotalsBox(rows: rows, exponents: exponents),
            const SizedBox(height: AppSpacing.section),
            for (final row in rows)
              _AccountCard(row: row, exponents: exponents),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Add account',
              icon: Icons.add_circle,
              onPressed: () => _addAccount(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Total across accounts, one line per currency. Different currencies are
/// never added together without an exchange rate.
class _TotalsBox extends StatelessWidget {
  const _TotalsBox({required this.rows, required this.exponents});

  final List<AccountBalancesResult> rows;
  final Map<String, int> exponents;

  @override
  Widget build(BuildContext context) {
    final totals = <String, int>{};
    for (final r in rows) {
      totals[r.a.currency] = (totals[r.a.currency] ?? 0) + r.balanceMinor;
    }
    return InputBox(
      label: 'TOTAL',
      icon: Icons.savings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final MapEntry(key: currency, value: minor) in totals.entries)
            Text(
              '${formatMinor(minor, exponents[currency] ?? 2)} $currency',
              style: AppText.amount.copyWith(
                color: minor < 0 ? AppColors.error : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.row, required this.exponents});

  final AccountBalancesResult row;
  final Map<String, int> exponents;

  @override
  Widget build(BuildContext context) {
    final account = row.a;
    final kind = accountKinds[account.kind] ?? accountKinds['other']!;
    final balance = row.balanceMinor;
    return Card(
      elevation: 2,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: ListTile(
        leading: Icon(kind.icon, color: AppColors.primary),
        title: Text(account.name, style: AppText.strong),
        subtitle: Text(
          '${kind.label} · ${account.currency}',
          style: AppText.label,
        ),
        trailing: Text(
          formatMinor(balance, exponents[account.currency] ?? 2),
          style: AppText.title.copyWith(
            color: balance < 0 ? AppColors.error : null,
          ),
        ),
      ),
    );
  }
}
