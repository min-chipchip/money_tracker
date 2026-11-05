/// Money helpers. Amounts are always integers in the currency's smallest
/// unit ("minor units"): 12.34 HKD is 1234, 500 JPY is 500.
/// `exponent` is the number of decimal places (HKD = 2, JPY = 0).
library;

import 'dart:math' as math;

final _amountPattern = RegExp(r'^(\d+)(?:\.(\d*))?$');

/// Parses what the user typed ("45.5", "1,200") into minor units.
///
/// Works on the text itself, never through a double, so "0.1" is exactly 10
/// cents. Returns null for empty or invalid input, or more decimals than the
/// currency allows ("1.234" HKD, "1.5" JPY).
int? parseMinor(String input, int exponent) {
  final match = _amountPattern.firstMatch(input.trim().replaceAll(',', ''));
  if (match == null) return null;
  final whole = match.group(1)!;
  final fraction = match.group(2) ?? '';
  if (fraction.length > exponent) return null;
  return int.parse(whole + fraction.padRight(exponent, '0'));
}

/// Formats minor units for display: (4550, 2) -> "45.50", (500, 0) -> "500".
String formatMinor(int minor, int exponent) {
  final sign = minor < 0 ? '-' : '';
  final digits = minor.abs().toString().padLeft(exponent + 1, '0');
  if (exponent == 0) return '$sign$digits';
  final split = digits.length - exponent;
  return '$sign${digits.substring(0, split)}.${digits.substring(split)}';
}

/// Converts an amount between currencies with possibly different exponents.
///
/// `rate` is "1 unit of FROM = rate units of TO". Example: 1000 JPY
/// (exponent 0) at 0.052 HKD/JPY -> 52.00 HKD -> 5200 minor units.
/// Rounds half away from zero to the nearest minor unit.
int convertMinor({
  required int amountMinor,
  required int fromExponent,
  required int toExponent,
  required double rate,
}) {
  final scale = math.pow(10, toExponent - fromExponent);
  return (amountMinor * rate * scale).round();
}
