import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/AppItem/account_kinds.dart';
import 'package:money_tracker/AppItem/account_sheet.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/input_box.dart';
import 'package:money_tracker/AppPages/deposit.dart';
import 'package:money_tracker/core/money.dart';
import 'package:money_tracker/data/db/app_database.dart';
import 'package:money_tracker/state/providers.dart';

/// Every account with its current balance. Tap a card to edit or delete
/// it; "Deposit" adds money to an account; "Add account" creates one.
///
/// Balances aren't stored anywhere: the `accountBalances` SQL query adds up
/// the opening balance and every transaction (via the account_movements
/// view). New accounts appear here AND in the Home form's account dropdown
/// automatically, because both watch the same accountsProvider stream.
class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  /// Add (existing == null) or edit/delete an account, then confirm.
  Future<void> _openSheet(BuildContext context, {Account? existing}) async {
    final message = await showAccountSheet(context, existing: existing);
    if (message != null && context.mounted) showAppSnackBar(context, message);
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
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Accounts', style: AppText.headline),
                      Text('REMAINING BALANCE', style: AppText.bodyMuted),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DepositPage()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  icon: const Icon(Icons.savings),
                  label: const Text('Deposit', style: AppText.strong),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _TotalsBox(rows: rows, exponents: exponents),
            const SizedBox(height: AppSpacing.section),
            for (final row in rows)
              _AccountCard(
                row: row,
                exponents: exponents,
                onTap: () => _openSheet(context, existing: row.a),
              ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Add account',
              icon: Icons.add_circle,
              onPressed: () => _openSheet(context),
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
  const _AccountCard({
    required this.row,
    required this.exponents,
    required this.onTap,
  });

  final AccountBalancesResult row;
  final Map<String, int> exponents;
  final VoidCallback onTap;

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
      clipBehavior: Clip.antiAlias, // keeps the tap ripple inside the rounded card
      child: ListTile(
        onTap: onTap,
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
