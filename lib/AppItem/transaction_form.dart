import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/dropdown_button.dart';
import 'package:money_tracker/AppItem/input_box.dart';
import 'package:money_tracker/core/money.dart';
import 'package:money_tracker/data/db/app_database.dart';
import 'package:money_tracker/state/providers.dart';
import 'package:money_tracker/state/transaction_actions.dart';

/// The one form for both adding and editing a transaction.
///
/// - Add:  `TransactionForm(onSubmit: ..., clearAfterSubmit: true)`
/// - Edit: `TransactionForm(initial: existing, onSubmit: ...)`
///
/// Accounts, categories and currencies come from the database via providers.
class TransactionForm extends ConsumerStatefulWidget {
  const TransactionForm({
    super.key,
    this.initial,
    required this.submitLabel,
    required this.onSubmit,
    this.clearAfterSubmit = false,
  });

  /// The transaction being edited, or null when adding a new one.
  final MoneyTransaction? initial;
  final String submitLabel;
  final Future<void> Function(TransactionDraft draft) onSubmit;
  final bool clearAfterSubmit;

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  final _amountController = TextEditingController();
  late final TextEditingController _noteController;
  late DateTime _date;
  late bool _isStarred;
  late int _importance;

  // Filled in on the first build where the dropdown lists have loaded.
  String? _accountId;
  String? _categoryId;
  String? _currency;
  bool _filledInitialAmount = false;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _noteController = TextEditingController(text: t?.note ?? '');
    _date = t != null ? DateTime.parse(t.occurredOn) : DateTime.now();
    _isStarred = t?.isStarred ?? false;
    _importance = t?.importance ?? 3;
    _accountId = t?.accountId;
    _categoryId = t?.categoryId;
    _currency = t?.currency;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit(Map<String, int> exponents) async {
    final amountMinor = parseMinor(
      _amountController.text,
      exponents[_currency] ?? 2,
    );
    if (amountMinor == null || amountMinor <= 0) {
      showAppSnackBar(context, 'Please enter a valid amount', isError: true);
      return;
    }

    final draft = TransactionDraft(
      accountId: _accountId!,
      categoryId: _categoryId!,
      amountMinor: amountMinor,
      currency: _currency!,
      occurredOn: _date,
      note: _noteController.text.trim(),
      isStarred: _isStarred,
      importance: _importance,
    );

    try {
      await widget.onSubmit(draft);
    } on MissingExchangeRate catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'No exchange rate for ${e.currency} yet. Save in ${e.base}, or run with FX_API_KEY.',
          isError: true,
        );
      }
      return;
    }

    if (!mounted || !widget.clearAfterSubmit) return;
    _amountController.clear();
    _noteController.clear();
    setState(() {
      _importance = 3;
      _isStarred = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value;
    final categories = ref.watch(expenseCategoriesProvider).value;
    final currencies = ref.watch(currenciesProvider).value;
    if (accounts == null || categories == null || currencies == null) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // First build with data: pick defaults and show the existing amount.
    _accountId ??= accounts.first.a.id;
    _categoryId ??= categories.first.id;
    _currency ??= accounts.firstWhere((a) => a.a.id == _accountId).a.currency;
    final exponents = {for (final c in currencies) c.code: c.exponent};
    if (!_filledInitialAmount) {
      _filledInitialAmount = true;
      final t = widget.initial;
      if (t != null) {
        _amountController.text = formatMinor(
          t.amountMinor,
          exponents[t.currency] ?? 2,
        );
      }
    }

    const rowGap = SizedBox(height: AppSpacing.section);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _amountAndDateRow([for (final c in currencies) c.code]),
          rowGap,
          _categoryAndAccountRow(categories, [for (final a in accounts) a.a]),
          rowGap,
          _noteBox(),
          rowGap,
          _starAndImportanceRow(),
          const SizedBox(height: 20),
          PrimaryButton(
            label: widget.submitLabel,
            onPressed: () => _submit(exponents),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Two equal-height boxes side by side.
  Widget _pair(
    Widget left,
    Widget right, {
    int leftFlex = 1,
    int rightFlex = 1,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: leftFlex, child: left),
          const SizedBox(width: AppSpacing.gap),
          Expanded(flex: rightFlex, child: right),
        ],
      ),
    );
  }

  Widget _amountAndDateRow(List<String> currencyCodes) {
    return _pair(
      InputBox(
        label: 'AMOUNT',
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                // The number pad has no "Done" key: tapping elsewhere closes it.
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                style: AppText.amount,
                decoration: const InputDecoration(
                  hintText: '0.00',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            SizedBox(
              width: 56, // fits a 3-letter currency code
              child: MyDropdownButton<String>(
                items: currencyCodes,
                value: _currency!,
                onChanged: (val) => setState(() => _currency = val),
                showArrow: false,
              ),
            ),
          ],
        ),
      ),
      InputBox(
        label: 'DATE',
        child: InkWell(
          onTap: _pickDate,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                  size: 25,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yy').format(_date),
                  style: AppText.title,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryAndAccountRow(
    List<Category> categories,
    List<Account> accounts,
  ) {
    final categoryNames = {for (final c in categories) c.id: c.name};
    final accountNames = {for (final a in accounts) a.id: a.name};
    return _pair(
      InputBox(
        label: 'CATEGORY',
        icon: Icons.category,
        child: MyDropdownButton<String>(
          items: categoryNames.keys.toList(),
          value: _categoryId!,
          labelOf: (id) => categoryNames[id]!,
          onChanged: (id) => setState(() => _categoryId = id),
        ),
      ),
      InputBox(
        label: 'ACCOUNT',
        icon: Icons.account_balance_wallet,
        child: MyDropdownButton<String>(
          items: accountNames.keys.toList(),
          value: _accountId!,
          labelOf: (id) => accountNames[id]!,
          // Switching account also switches to that account's currency.
          onChanged: (id) => setState(() {
            _accountId = id;
            _currency = accounts.firstWhere((a) => a.id == id).currency;
          }),
        ),
      ),
    );
  }

  Widget _noteBox() {
    return InputBox(
      label: 'REASON (OPTIONAL)',
      icon: Icons.create,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: TextField(
          controller: _noteController,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          decoration: const InputDecoration(
            hintText: 'e.g. Lunch with Sarah',
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _starAndImportanceRow() {
    return _pair(
      leftFlex: 3,
      rightFlex: 5,
      InputBox(
        child: Center(
          child: Column(
            children: [
              StarButton(
                isOn: _isStarred,
                size: 35,
                onPressed: () => setState(() => _isStarred = !_isStarred),
              ),
              const Text('Highlight', style: AppText.strong),
            ],
          ),
        ),
      ),
      InputBox(
        child: Column(
          children: [
            const Text('IMPORTANCE LEVEL', style: AppText.caption),
            const SizedBox(height: 5),
            RatingPicker(
              value: _importance,
              onChanged: (v) => setState(() => _importance = v),
            ),
          ],
        ),
      ),
    );
  }
}
