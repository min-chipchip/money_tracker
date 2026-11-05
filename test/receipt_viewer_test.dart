import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/AppAPI/receipt_reader.dart';
import 'package:money_tracker/AppItem/transaction_form.dart';
import 'package:money_tracker/AppPages/receipt.dart';
import 'package:money_tracker/data/db/app_database.dart';
import 'package:money_tracker/state/providers.dart';

void main() {
  testWidgets('Read with AI explains how to set the key when GEMINI_API_KEY is missing', (tester) async {
    final dir = Directory.systemTemp.createTempSync('receipt_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final receipt = File('${dir.path}/r.jpg')..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xD9]);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(home: ReceiptViewer(receipt: receipt))),
    );
    await tester.tap(find.text('Read with AI'));
    await tester.pump();

    expect(find.textContaining('GEMINI_API_KEY'), findsOneWidget);
    // It fails fast: no spinner left behind.
    expect(find.text('Reading receipt...'), findsNothing);
  });

  testWidgets('review page pre-fills the form from what the AI read', (tester) async {
    const food = Category(id: 'food', name: 'Food', kind: 'expense', archived: false, sortOrder: 0, createdAt: 0, updatedAt: 0);
    const drink = Category(id: 'drink', name: 'Drink', kind: 'expense', archived: false, sortOrder: 1, createdAt: 0, updatedAt: 0);
    const cash = Account(
      id: 'cash', name: 'Cash', kind: 'cash', currency: 'HKD',
      openingBalanceMinor: 0, archived: false, sortOrder: 0, createdAt: 0, updatedAt: 0,
    );
    final dir = Directory.systemTemp.createTempSync('receipt_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final receipt = File('${dir.path}/r.jpg')..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xD9]);

    await tester.pumpWidget(
      ProviderScope(
        // Fixed data instead of a database: drift's streams don't run inside
        // widget tests' fake async.
        overrides: [
          accountsProvider.overrideWith((ref) => Stream.value([AccountBalancesResult(a: cash, balanceMinor: 0)])),
          expenseCategoriesProvider.overrideWith((ref) => Stream.value([food, drink])),
          currenciesProvider.overrideWith(
            (ref) => Stream.value([const CurrencyInfo(code: 'HKD', exponent: 2, symbol: r'HK$')]),
          ),
        ],
        child: MaterialApp(
          home: ReceiptReviewPage(
            receipt: receipt,
            reading: const ReceiptReading(
              merchant: 'Highlands Coffee',
              currency: 'VND',
              total: 181440,
              items: [ReceiptLine('Banh Mi Thit', 35000)],
            ),
            prefill: TransactionPrefill(
              currency: 'VND',
              date: DateTime(2026, 11, 4),
              categoryId: 'drink',
              note: 'Highlands Coffee',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // VND isn't set up: the amount stays empty instead of 181440 "HKD".
    expect(find.text('181440'), findsNothing);
    expect(find.text('HKD'), findsOneWidget);
    expect(find.text('04/11/26'), findsOneWidget);
    expect(find.text('Drink'), findsOneWidget);
    expect(find.text('Highlands Coffee'), findsNWidgets(2)); // header + note field
    expect(find.text('Banh Mi Thit'), findsOneWidget);
    expect(find.textContaining('VND, which is not set up'), findsOneWidget);
  });

  testWidgets('adding the receipt currency fills in the blank amount', (tester) async {
    const drink = Category(id: 'drink', name: 'Drink', kind: 'expense', archived: false, sortOrder: 1, createdAt: 0, updatedAt: 0);
    const cash = Account(
      id: 'cash', name: 'Cash', kind: 'cash', currency: 'HKD',
      openingBalanceMinor: 0, archived: false, sortOrder: 0, createdAt: 0, updatedAt: 0,
    );
    const hkd = CurrencyInfo(code: 'HKD', exponent: 2, symbol: r'HK$');
    final currencies = StreamController<List<CurrencyInfo>>();
    addTearDown(currencies.close);
    final dir = Directory.systemTemp.createTempSync('receipt_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final receipt = File('${dir.path}/r.jpg')..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xD9]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountsProvider.overrideWith((ref) => Stream.value([AccountBalancesResult(a: cash, balanceMinor: 0)])),
          expenseCategoriesProvider.overrideWith((ref) => Stream.value([drink])),
          currenciesProvider.overrideWith((ref) => currencies.stream),
        ],
        child: MaterialApp(
          home: ReceiptReviewPage(
            receipt: receipt,
            reading: const ReceiptReading(merchant: 'Highlands Coffee', currency: 'VND', total: 181440),
            prefill: const TransactionPrefill(currency: 'VND', note: 'Highlands Coffee'),
          ),
        ),
      ),
    );
    currencies.add([hkd]);
    await tester.pump();
    await tester.pump();
    expect(find.text('Add VND'), findsOneWidget);
    expect(find.text('181440'), findsNothing);

    // What the "Add VND" sheet does once saved: VND joins the currencies.
    currencies.add([hkd, const CurrencyInfo(code: 'VND', exponent: 0, symbol: '₫')]);
    await tester.pump();
    await tester.pump();
    expect(find.text('Add VND'), findsNothing);
    expect(find.text('181440'), findsOneWidget);
    expect(find.text('VND'), findsOneWidget);
  });

  group('prefillFromReading', () {
    const drink = Category(id: 'drink', name: 'Drink', kind: 'expense', archived: false, sortOrder: 1, createdAt: 0, updatedAt: 0);

    test('fills the amount when the currency is set up', () {
      final p = prefillFromReading(
        const ReceiptReading(total: 12.5, currency: 'HKD', category: 'drink', merchant: 'Cafe'),
        categories: [drink],
        knownCurrencies: {'HKD'},
      );
      expect(p.amount, 12.5);
      expect(p.categoryId, 'drink');
      expect(p.note, 'Cafe');
    });

    test('leaves the amount blank when the currency is not set up', () {
      final p = prefillFromReading(
        const ReceiptReading(total: 181440, currency: 'VND', merchant: 'Highlands Coffee'),
        categories: [drink],
        knownCurrencies: {'HKD', 'USD'},
      );
      expect(p.amount, isNull);
      expect(p.note, 'Highlands Coffee');
    });
  });
}
