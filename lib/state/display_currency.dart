import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/AppAPI/currency_provider.dart';
import 'package:money_tracker/core/money.dart';

/// The currency amounts are SHOWN in (the $ button cycles it). Stored values
/// never change; this only affects display.
///
/// Live rates still come from the old CurrencyProvider, fetched at startup.
/// Phase 3 replaces that with rates cached in the database.
class DisplayCurrencyNotifier extends Notifier<String> {
  @override
  String build() => CurrencyProvider().currentCurrency;

  void toggle() {
    CurrencyProvider().toggleCurrency();
    state = CurrencyProvider().currentCurrency;
  }
}

final displayCurrencyProvider =
    NotifierProvider<DisplayCurrencyNotifier, String>(DisplayCurrencyNotifier.new);

/// "1 [from] = rate [to]" from today's live rates, or null if rates
/// didn't load (e.g. no FX_API_KEY) or a currency is unknown.
double? liveRate(String from, String to) {
  if (from == to) return 1;
  final perUsd = CurrencyProvider().rates?.data;
  final fromRate = perUsd?[from];
  final toRate = perUsd?[to];
  if (fromRate == null || toRate == null) return null;
  return toRate / fromRate;
}

/// Formats [minor] units of [currency] in the display currency if a live
/// rate exists, otherwise in its own currency. Display only: uses doubles.
String formatForDisplay({
  required int minor,
  required String currency,
  required String displayCurrency,
  required Map<String, int> exponents,
}) {
  final exponent = exponents[currency] ?? 2;
  final rate = liveRate(currency, displayCurrency);
  if (rate == null || currency == displayCurrency) {
    return '${formatMinor(minor, exponent)} $currency';
  }
  final converted = minor / math.pow(10, exponent) * rate;
  return '${converted.toStringAsFixed(exponents[displayCurrency] ?? 2)} $displayCurrency';
}
