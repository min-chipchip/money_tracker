import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/dropdown_button.dart';
import 'package:money_tracker/AppPages/categories.dart';
import 'package:money_tracker/state/providers.dart';

class MySettingsForm extends ConsumerWidget {
  const MySettingsForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencies = ref.watch(currenciesProvider).value ?? const [];
    final mainCurrency = ref.watch(mainCurrencyProvider).value;
    final expenseCount = ref.watch(expenseCategoriesProvider).value?.length;
    final incomeCount = ref.watch(incomeCategoriesProvider).value?.length;
    final approximateRates = ref.watch(fxRatesProvider).value?.approximate ?? true;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: 25),
        children: [
          const Text('Settings', style: AppText.headline),
          const SizedBox(height: 20),

          const _SectionLabel('GENERAL'),
          _SettingsCard(children: [
            ListTile(
              leading: const Icon(Icons.currency_exchange, color: AppColors.primary),
              title: const Text('Main currency', style: AppText.strong),
              subtitle: const Text('Amounts are shown in this when the app opens', style: AppText.label),
              trailing: SizedBox(
                width: 80,
                child: mainCurrency == null || currencies.isEmpty
                    ? const SizedBox.shrink()
                    : MyDropdownButton<String>(
                        items: [for (final c in currencies) c.code],
                        value: mainCurrency,
                        onChanged: (code) =>
                            ref.read(settingsRepositoryProvider).setMainCurrency(code),
                      ),
              ),
            ),
            ListTile(
              leading: Icon(
                approximateRates ? Icons.cloud_off : Icons.cloud_done,
                color: AppColors.primary,
              ),
              title: const Text('Exchange rates', style: AppText.strong),
              subtitle: Text(
                approximateRates
                    ? 'Approximate built-in rates (no API key or offline)'
                    : 'Downloaded rates, saved for offline use',
                style: AppText.label,
              ),
            ),
          ]),

          const SizedBox(height: 20),
          const _SectionLabel('DATA'),
          _SettingsCard(children: [
            ListTile(
              leading: const Icon(Icons.category, color: AppColors.primary),
              title: const Text('Categories', style: AppText.strong),
              subtitle: Text(
                expenseCount == null
                    ? ' '
                    : '$expenseCount expense · $incomeCount income',
                style: AppText.label,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesPage()),
              ),
            ),
            // Placeholder for Phase 5/6 of docs/restart-plan.md: a backend
            // with sign-in and sync. Nothing is sent anywhere yet.
            ListTile(
              leading: const Icon(Icons.cloud_sync, color: AppColors.muted),
              title: const Text('Link to online database', style: AppText.strong),
              subtitle: const Text('Not connected · coming soon', style: AppText.label),
              trailing: OutlinedButton(
                onPressed: () => showAppSnackBar(
                  context,
                  'Cloud sync is coming in a later version. Your data stays on this phone.',
                ),
                child: const Text('Link'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 6),
        child: Text(text, style: AppText.label),
      );
}

/// White rounded card holding a group of setting rows, with dividers.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            child,
          ],
        ],
      ),
    );
  }
}
