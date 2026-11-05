import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/AppItem/account_kinds.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/dropdown_button.dart';
import 'package:money_tracker/AppItem/input_box.dart';
import 'package:money_tracker/core/money.dart';
import 'package:money_tracker/data/db/app_database.dart';
import 'package:money_tracker/data/repositories/account_repository.dart';
import 'package:money_tracker/state/providers.dart';

/// Opens the account sheet: "New account" when [existing] is null,
/// otherwise "Edit account" with a Delete button.
///
/// Returns a short message for a snackbar ('Added "X"', 'Deleted "X"', ...),
/// or null if the user closed the sheet without changing anything.
Future<String?> showAccountSheet(BuildContext context, {Account? existing}) {
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
    builder: (_) => _AccountSheet(existing: existing),
  );
}

class _AccountSheet extends ConsumerStatefulWidget {
  const _AccountSheet({this.existing});

  final Account? existing;

  @override
  ConsumerState<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends ConsumerState<_AccountSheet> {
  late final TextEditingController _nameController;
  final _openingController = TextEditingController();
  late String _kind;
  String? _currency; // new account: defaults to the base currency once loaded
  bool _filledOpening = false;
  String? _nameError;
  String? _openingError;
  String? _deleteError;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _nameController = TextEditingController(text: a?.name ?? '');
    _kind = a?.kind ?? 'bank';
    _currency = a?.currency;
  }

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

    final repo = ref.read(accountRepositoryProvider);
    if (_isEdit) {
      await repo.updateDetails(
        widget.existing!.id,
        name: name,
        kind: _kind,
        openingBalanceMinor: opening!,
      );
    } else {
      await repo.add(
        name: name,
        kind: _kind,
        currency: _currency!,
        openingBalanceMinor: opening!,
      );
    }
    if (mounted) Navigator.pop(context, _isEdit ? 'Saved "$name"' : 'Added "$name"');
  }

  Future<void> _delete() async {
    final account = widget.existing!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${account.name}"?'),
        content: const Text('The account will disappear from your lists.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(accountRepositoryProvider).delete(account.id);
    } on AccountDeleteBlocked catch (e) {
      setState(() => _deleteError = e.reason);
      return;
    }
    if (mounted) Navigator.pop(context, 'Deleted "${account.name}"');
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
    if (!_filledOpening) {
      _filledOpening = true;
      final a = widget.existing;
      if (a != null && a.openingBalanceMinor != 0) {
        _openingController.text = formatMinor(a.openingBalanceMinor, exponents[a.currency] ?? 2);
      }
    }

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
            Text(_isEdit ? 'Edit account' : 'New account', style: AppText.headline),
            const SizedBox(height: AppSpacing.section),
            InputBox(
              label: 'NAME',
              icon: Icons.edit,
              child: TextField(
                controller: _nameController,
                autofocus: !_isEdit,
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
                      // Fixed after creation: amounts already recorded in
                      // this account are in this currency.
                      child: _isEdit
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(_currency!, style: AppText.title),
                            )
                          : MyDropdownButton<String>(
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
              label: _isEdit ? 'Save changes' : 'Create account',
              icon: _isEdit ? Icons.check_circle : Icons.add_circle,
              onPressed: () => _save(exponents),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _delete,
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete account', style: AppText.strong),
              ),
              if (_deleteError != null)
                Text(
                  _deleteError!,
                  textAlign: TextAlign.center,
                  style: AppText.label.copyWith(color: AppColors.error),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
