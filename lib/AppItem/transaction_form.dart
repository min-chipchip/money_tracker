import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/database.dart';
import 'package:money_tracker/AppItem/dropdown_button.dart';
import 'package:money_tracker/AppItem/input_box.dart';

/// The one form for both adding and editing a transaction.
///
/// - Add:  `TransactionForm(onSubmit: ..., clearAfterSubmit: true)`
/// - Edit: `TransactionForm(initial: existing, onSubmit: ...)`
class TransactionForm extends StatefulWidget {
  const TransactionForm({
    super.key,
    this.initial,
    required this.submitLabel,
    required this.onSubmit,
    this.clearAfterSubmit = false,
  });

  /// The transaction being edited, or null when adding a new one.
  final TransactionModel? initial;
  final String submitLabel;
  final Future<void> Function(TransactionModel transaction) onSubmit;
  final bool clearAfterSubmit;

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  late final TextEditingController _amountController;
  late final TextEditingController _reasonController;
  late DateTime _date;
  late String _category;
  late String _account;
  late String _currency;
  late bool _isHighlighted;
  late int _rating;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _amountController = TextEditingController(text: t?.amount.toString() ?? '');
    _reasonController = TextEditingController(text: t?.reason ?? '');
    _date = t != null ? DateTime.parse(t.date) : DateTime.now();
    _category = t?.category ?? category.first;
    _account = t?.account ?? account.first;
    _currency = t?.currency ?? entryCurrencies.first;
    _isHighlighted = (t?.isHighlighted ?? 0) == 1;
    _rating = t?.rating ?? 3;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      showAppSnackBar(context, 'Please enter an amount', isError: true);
      return;
    }

    await widget.onSubmit(TransactionModel(
      id: widget.initial?.id,
      amount: amount,
      date: DateFormat('yyyy-MM-dd').format(_date),
      category: _category,
      account: _account,
      reason: _reasonController.text,
      isHighlighted: _isHighlighted ? 1 : 0,
      rating: _rating,
      currency: _currency,
    ));

    if (!mounted || !widget.clearAfterSubmit) return;
    _amountController.clear();
    _reasonController.clear();
    setState(() {
      _rating = 3;
      _isHighlighted = false;
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
    const rowGap = SizedBox(height: AppSpacing.section);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _amountAndDateRow(),
          rowGap,
          _categoryAndAccountRow(),
          rowGap,
          _reasonBox(),
          rowGap,
          _highlightAndImportanceRow(),
          const SizedBox(height: 20),
          PrimaryButton(label: widget.submitLabel, onPressed: _submit),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Two equal-height boxes side by side.
  Widget _pair(Widget left, Widget right, {int leftFlex = 1, int rightFlex = 1}) {
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

  Widget _amountAndDateRow() {
    return _pair(
      InputBox(
        label: 'AMOUNT',
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              child: MyDropdownButton(
                currentList: entryCurrencies,
                selectedValue: _currency,
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
                const Icon(Icons.calendar_today, color: AppColors.primary, size: 25),
                const SizedBox(width: 8),
                Text(DateFormat('dd/MM/yy').format(_date), style: AppText.title),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryAndAccountRow() {
    return _pair(
      InputBox(
        label: 'CATEGORY',
        icon: Icons.category,
        child: MyDropdownButton(
          currentList: category,
          selectedValue: _category,
          onChanged: (val) => setState(() => _category = val),
        ),
      ),
      InputBox(
        label: 'ACCOUNT',
        icon: Icons.account_balance_wallet,
        child: MyDropdownButton(
          currentList: account,
          selectedValue: _account,
          onChanged: (val) => setState(() => _account = val),
        ),
      ),
    );
  }

  Widget _reasonBox() {
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
          controller: _reasonController,
          decoration: const InputDecoration(
            hintText: 'e.g. Lunch with Sarah',
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _highlightAndImportanceRow() {
    return _pair(
      leftFlex: 3,
      rightFlex: 5,
      InputBox(
        child: Center(
          child: Column(
            children: [
              StarButton(
              isOn: _isHighlighted,
              size: 35,
              onPressed: () => setState(() => _isHighlighted = !_isHighlighted),
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
            RatingPicker(value: _rating, onChanged: (v) => setState(() => _rating = v)),
          ],
        ),
      ),
    );
  }
}
