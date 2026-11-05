import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/currency_sheet.dart';
import 'package:money_tracker/state/providers.dart';

/// Settings → Currencies: the currencies the app can record amounts in, each
/// with the rate it converts at, plus "Add currency".
class CurrenciesPage extends ConsumerWidget {
  const CurrenciesPage({super.key});

  Future<void> _add(BuildContext context) async {
    final code = await showCurrencySheet(context);
    if (code != null && context.mounted) showAppSnackBar(context, 'Added $code');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencies = ref.watch(currenciesProvider).value;
    final rates = ref.watch(fxRatesProvider).value?.perUsd ?? const {};
    final base = ref.watch(baseCurrencyProvider).value;
    final number = NumberFormat.decimalPattern();

    return FormPage(
      title: 'CURRENCIES',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (currencies == null)
              const Center(child: CircularProgressIndicator())
            else
              for (final c in currencies)
                Card(
                  elevation: 2,
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Text(c.symbol, style: AppText.label.copyWith(color: AppColors.primary)),
                    ),
                    title: Text(c.code, style: AppText.strong),
                    subtitle: Text(
                      [
                        '${c.exponent} decimal${c.exponent == 1 ? '' : 's'}',
                        if (c.code != 'USD' && rates[c.code] != null)
                          '1 USD = ${number.format(rates[c.code])} ${c.code}',
                      ].join(' · '),
                      style: AppText.label,
                    ),
                    trailing: c.code == base ? const Text('BASE', style: AppText.label) : null,
                  ),
                ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Add currency',
              icon: Icons.add_circle,
              onPressed: () => _add(context),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
