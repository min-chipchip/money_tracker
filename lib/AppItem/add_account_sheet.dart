import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/AppItem/account_kinds.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/dropdown_button.dart';
import 'package:money_tracker/AppItem/input_box.dart';
import 'package:money_tracker/core/money.dart';
import 'package:money_tracker/state/providers.dart';

/// Opens the "New account" sheet. Returns the new account's name, or null
/// if the user closed the sheet without saving.
Future<String?> showAddAccountSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true, // lets the sheet move up above the keyboard
    useSafeArea: true, // ...but never under the status bar
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.boxRadius),
      ),
    ),
    builder: (_) => const _AddAccountSheet(),
  );
}

class _AddAccountSheet extends ConsumerStatefulWidget {
  const _AddAccountSheet();

  @override
  ConsumerState<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<_AddAccountSheet> {
  final _nameController = TextEditingController();
  final _openingController = TextEditingController();
  String _kind = 'bank';
  String? _currency; // defaults to the base currency once loaded
  String? _nameError;
  String? _openingError;

  @override
  void dispose() {
    _nameController.dispose();
    _openingController.dispose();
    super.dispose();
  }

  /// "" -> 0, "1,200.50" -> 120050, "-300" -> -30000 (e.g. a credit card
  /// that already owes money). Null if invalid.
  int? _parseOpening(String text, int exponent) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    final negative = trimmed.startsWith('-');
    final minor = parseMinor(
      negative ? trimmed.substring(1) : trimmed,
      exponent,
    );
    if (minor == null) return null;
    return negative ? -minor : minor;
  }

  Future<void> _save(Map<String, int> exponents) async {
    final name = _nameController.text.trim();
    final opening = _parseOpening(
      _openingController.text,
      exponents[_currency] ?? 2,
    );
    setState(() {
      _nameError = name.isEmpty ? 'Give the account a name' : null;
      _openingError = opening == null ? 'Enter an amount like 1200.50' : null;
    });
    if (_nameError != null || _openingError != null) return;

    await ref
        .read(accountRepositoryProvider)
        .add(
          name: name,
          kind: _kind,
          currency: _currency!,
          openingBalanceMinor: opening!,
        );
    if (mounted) Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final currencies = ref.watch(currenciesProvider).value;
    final base = ref.watch(baseCurrencyProvider).value;
    if (currencies == null || base == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    _currency ??= base;
    final exponents = {for (final c in currencies) c.code: c.exponent};

    void unfocus(PointerDownEvent _) => FocusScope.of(context).unfocus();

    return Padding(
      // Push the content above the on-screen keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          25,
          AppSpacing.page,
          30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('New account', style: AppText.headline),
            const SizedBox(height: AppSpacing.section),
            InputBox(
              label: 'NAME',
              icon: Icons.edit,
              child: TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                onTapOutside: unfocus,
                style: AppText.title,
                decoration: InputDecoration(
                  hintText: 'e.g. HSBC Savings',
                  border: InputBorder.none,
                  errorText: _nameError,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: InputBox(
                      label: 'TYPE',
                      child: MyDropdownButton<String>(
                        items: accountKinds.keys.toList(),
                        value: _kind,
                        labelOf: (k) => accountKinds[k]!.label,
                        onChanged: (k) => setState(() => _kind = k),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gap),
                  Expanded(
                    flex: 2,
                    child: InputBox(
                      label: 'CURRENCY',
                      child: MyDropdownButton<String>(
                        items: [for (final c in currencies) c.code],
                        value: _currency!,
                        onChanged: (c) => setState(() => _currency = c),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            InputBox(
              label: 'STARTING BALANCE (OPTIONAL)',
              child: TextField(
                controller: _openingController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                onTapOutside: unfocus,
                style: AppText.title,
                decoration: InputDecoration(
                  hintText: '0.00',
                  border: InputBorder.none,
                  errorText: _openingError,
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Create account',
              icon: Icons.add_circle,
              onPressed: () => _save(exponents),
            ),
          ],
        ),
      ),
    );
  }
}
