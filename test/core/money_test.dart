import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/date_range.dart';
import 'package:money_tracker/core/money.dart';

void main() {
  group('parseMinor', () {
    test('parses user input exactly, without floating point', () {
      expect(parseMinor('45.5', 2), 4550);
      expect(parseMinor('0.1', 2), 10);
      expect(parseMinor('1,200', 2), 120000);
      expect(parseMinor(' 7 ', 2), 700);
      expect(parseMinor('500', 0), 500);
    });

    test('rejects invalid input and too many decimals', () {
      expect(parseMinor('', 2), isNull);
      expect(parseMinor('abc', 2), isNull);
      expect(parseMinor('-5', 2), isNull);
      expect(parseMinor('1.234', 2), isNull);
      expect(parseMinor('1.5', 0), isNull); // JPY has no decimals
    });
  });

  test('formatMinor', () {
    expect(formatMinor(4550, 2), '45.50');
    expect(formatMinor(5, 2), '0.05');
    expect(formatMinor(-1234, 2), '-12.34');
    expect(formatMinor(500, 0), '500');
  });

  test('convertMinor handles different exponents', () {
    // ¥1000 (exp 0) at 0.052 HKD/JPY = HK$52.00 (exp 2)
    expect(convertMinor(amountMinor: 1000, fromExponent: 0, toExponent: 2, rate: 0.052), 5200);
    // HK$52.00 at 19.23 JPY/HKD = ¥1000 (rounded)
    expect(convertMinor(amountMinor: 5200, fromExponent: 2, toExponent: 0, rate: 19.23), 1000);
  });

  test('DateRange.month is half-open and handles December', () {
    final dec = DateRange.month(DateTime(2026, 12, 15));
    expect(dec.startKey, '2026-12-01');
    expect(dec.endKey, '2027-01-01');
  });
}
