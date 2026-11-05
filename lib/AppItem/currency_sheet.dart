import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/input_box.dart';
import 'package:money_tracker/core/currency_presets.dart';
import 'package:money_tracker/data/repositories/settings_repository.dart';
import 'package:money_tracker/state/providers.dart';

/// Opens the "Add currency" sheet, filled in for [code] when given (e.g.
/// from a receipt in VND). Returns the added code, or null if cancelled.
Future<String?> showCurrencySheet(BuildContext context, {String? code}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.boxRadius)),
    ),
    builder: (_) => _CurrencySheet(initialCode: code),
  );
}

class _CurrencySheet extends ConsumerStatefulWidget {
  const _CurrencySheet({this.initialCode});
  final String? initialCode;

  @override
  ConsumerState<_CurrencySheet> createState() => _CurrencySheetState();
}

class _CurrencySheetState extends ConsumerState<_CurrencySheet> {
  final _code = TextEditingController();
  final _symbol = TextEditingController();
  final _rate = TextEditingController();
  int _exponent = 2;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final code = widget.initialCode?.toUpperCase();
    if (code != null) {
      _code.text = code;
      _applyPreset(code);
    }
    _code.addListener(_onCodeChanged);
    _rate.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _code.dispose();
    _symbol.dispose();
    _rate.dispose();
    super.dispose();
  }

  String _lastCode = '';
  void _onCodeChanged() {
    final code = _code.text.toUpperCase();
    if (code == _lastCode) return;
    _lastCode = code;
    setState(() {
      _error = null;
      if (code.length == 3) _applyPreset(code);
    });
  }

  /// Fills symbol, decimals and rate from the preset list, if it has [code].
  void _applyPreset(String code) {
    final preset = presetFor(code);
    if (preset == null) return;
    _symbol.text = preset.symbol;
    _exponent = preset.exponent;
    _rate.text = _plain(preset.approxPerUsd);
  }

  static String _plain(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  double? get _perUsd => double.tryParse(_rate.text.replaceAll(',', '').trim());

  Future<void> _save() async {
    final code = _code.text.trim().toUpperCase();
    final perUsd = _perUsd;
    if (perUsd == null) {
      setState(() => _error = 'Enter how many $code one US dollar buys');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(settingsRepositoryProvider).addCurrency(
            code: code,
            symbol: _symbol.text,
            exponent: _exponent,
            perUsd: perUsd,
          );
    } on CurrencyInputError catch (e) {
      setState(() {
        _error = e.message;
        _saving = false;
      });
      return;
    }
    // If FX_API_KEY is set, fetch a real rate for the new currency too.
    // Fire and forget: the typed rate already works offline.
    ref.read(fxRepositoryProvider).refreshFromApi();
    if (mounted) Navigator.pop(context, code);
  }

  /// "100,000 VND ≈ 30.63 HKD": a sanity check of the typed rate against
  /// the user's main currency.
  String? _example() {
    final code = _code.text.trim().toUpperCase();
    final perUsd = _perUsd;
    final main = ref.watch(mainCurrencyProvider).value;
    final mainPerUsd = main == null ? null : ref.watch(fxRatesProvider).value?.perUsd[main];
    if (code.length != 3 || perUsd == null || perUsd <= 0 || main == null || mainPerUsd == null) return null;
    if (code == main) return null;
    // A round amount of the new currency worth roughly 10-100 USD.
    final amount = math.pow(10, (math.log(perUsd * 10) / math.ln10).ceil()).toDouble();
    final converted = amount / perUsd * mainPerUsd;
    final f = NumberFormat.decimalPatternDigits(decimalDigits: converted < 10 ? 2 : 0);
    return '${NumberFormat.decimalPattern().format(amount)} $code ≈ ${f.format(converted)} $main';
  }

  @override
  Widget build(BuildContext context) {
    final existing = {for (final c in ref.watch(currenciesProvider).value ?? const []) c.code};
    final suggestions = [for (final p in currencyPresets) if (!existing.contains(p.code)) p];
    final example = _example();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 25, AppSpacing.page, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add currency', style: AppText.headline),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in suggestions)
                    ChoiceChip(
                      label: Text(p.code),
                      tooltip: p.name,
                      selected: _code.text.toUpperCase() == p.code,
                      onSelected: (_) => _code.text = p.code,
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.section),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InputBox(
                    label: 'CODE',
                    icon: Icons.currency_exchange,
                    child: TextField(
                      controller: _code,
                      autofocus: widget.initialCode == null,
                      maxLength: 3,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]'))],
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      style: AppText.title,
                      decoration: const InputDecoration(hintText: 'VND', border: InputBorder.none, counterText: ''),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputBox(
                    label: 'SYMBOL',
                    icon: Icons.attach_money,
                    child: TextField(
                      controller: _symbol,
                      maxLength: 4,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      style: AppText.title,
                      decoration: const InputDecoration(hintText: '₫', border: InputBorder.none, counterText: ''),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            InputBox(
              label: 'DECIMAL PLACES',
              icon: Icons.pin,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('0')),
                    ButtonSegment(value: 2, label: Text('2')),
                    ButtonSegment(value: 3, label: Text('3')),
                  ],
                  selected: {_exponent},
                  onSelectionChanged: (s) => setState(() => _exponent = s.first),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            InputBox(
              label: 'RATE: 1 USD =',
              icon: Icons.swap_horiz,
              child: TextField(
                controller: _rate,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                style: AppText.title,
                decoration: InputDecoration(
                  hintText: '25400',
                  border: InputBorder.none,
                  suffixText: _code.text.length == 3 ? _code.text.toUpperCase() : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              example != null
                  ? '$example. An approximate rate is fine: downloaded rates replace it when available.'
                  : 'An approximate rate is fine: downloaded rates replace it when available.',
              style: AppText.label,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: AppText.label.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: _saving ? 'Adding...' : 'Add currency',
              icon: Icons.add_circle,
              onPressed: _saving || _code.text.length != 3 ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
