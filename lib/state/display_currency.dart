import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/core/money.dart';
import 'package:money_tracker/data/repositories/fx_repository.dart';
import 'package:money_tracker/state/providers.dart';

/// The currency amounts are SHOWN in (the $ button cycles it). Stored values
/// never change; this only affects display.
///
/// It starts as the main currency from Settings, and resets to it whenever
/// the main currency is changed (because build() watches it).
class DisplayCurrencyNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(mainCurrencyProvider).value ?? 'HKD';

  /// Next currency in the currencies table (alphabetical), wrapping around.
  void toggle() {
    final codes = [
      for (final c in ref.read(currenciesProvider).value ?? const []) c.code,
    ];
    if (codes.isEmpty) return;
    state = codes[(codes.indexOf(state) + 1) % codes.length];
  }
}

final displayCurrencyProvider =
    NotifierProvider<DisplayCurrencyNotifier, String>(DisplayCurrencyNotifier.new);

/// Formats [minor] units of [currency] in the display currency, converting
/// with the cached [rates] (falls back to its own currency if a rate is
/// missing). Display only: uses doubles.
String formatForDisplay({
  required int minor,
  required String currency,
  required String displayCurrency,
  required Map<String, int> exponents,
  required FxRates? rates,
}) {
  final exponent = exponents[currency] ?? 2;
  final rate = rates?.rate(currency, displayCurrency);
  if (rate == null || currency == displayCurrency) {
    return '${formatMinor(minor, exponent)} $currency';
  }
  final converted = minor / math.pow(10, exponent) * rate;
  return '${converted.toStringAsFixed(exponents[displayCurrency] ?? 2)} $displayCurrency';
}
