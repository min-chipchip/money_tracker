import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/currency_presets.dart';
import 'package:money_tracker/data/repositories/settings_repository.dart';
import 'package:money_tracker/state/providers.dart';
import 'package:money_tracker/state/transaction_actions.dart';

import 'test_db.dart';

void main() {
  late ProviderContainer container;
  late SettingsRepository settings;

  setUp(() {
    final db = openTestDb();
    container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(db.close);
    addTearDown(container.dispose);
    settings = container.read(settingsRepositoryProvider);
  });

  group('addCurrency', () {
    test('adds the currency and a rate that converts straight away', () async {
      await settings.addCurrency(code: 'vnd', symbol: '₫', exponent: 0, perUsd: 25400);

      final vnd = (await settings.watchCurrencies().first).singleWhere((c) => c.code == 'VND');
      expect(vnd.exponent, 0);
      expect(vnd.symbol, '₫');

      final rates = await container.read(fxRepositoryProvider).ratesOn(DateTime(2026, 11, 5));
      // 1 USD = 25,400 VND = 7.78 HKD, so 181,440 VND ≈ 55.57 HKD.
      expect(181440 * rates.rate('VND', 'HKD')!, closeTo(55.57, 0.01));
    });

    test('a VND expense can then be saved offline', () async {
      await settings.addCurrency(code: 'VND', symbol: '₫', exponent: 0, perUsd: 25400);
      final db = container.read(databaseProvider);
      await container.read(transactionActionsProvider).save(
            TransactionDraft(
              accountId: await accountId(db, 'Cash'),
              categoryId: await categoryId(db, 'Drink'),
              amountMinor: 181440, // VND has no decimals
              currency: 'VND',
              occurredOn: DateTime(2026, 11, 5),
            ),
          );
      final saved = await db.select(db.transactions).getSingle();
      expect(saved.currency, 'VND');
      expect(saved.baseAmountMinor, 5557); // HK$55.57
    });

    test('rejects bad input with a message for the user', () async {
      Future<void> add(String code, {int exponent = 2, double perUsd = 1}) =>
          settings.addCurrency(code: code, symbol: '', exponent: exponent, perUsd: perUsd);

      await expectLater(add('HKD'), throwsA(isA<CurrencyInputError>().having((e) => e.message, 'm', contains('already'))));
      await expectLater(add('VN'), throwsA(isA<CurrencyInputError>()));
      await expectLater(add('VND', perUsd: 0), throwsA(isA<CurrencyInputError>()));
      await expectLater(add('VND', exponent: 5), throwsA(isA<CurrencyInputError>()));
      expect((await settings.watchCurrencies().first).map((c) => c.code), isNot(contains('VND')));
    });

    test('a blank symbol falls back to the code', () async {
      await settings.addCurrency(code: 'XAF', symbol: ' ', exponent: 0, perUsd: 600);
      final xaf = (await settings.watchCurrencies().first).singleWhere((c) => c.code == 'XAF');
      expect(xaf.symbol, 'XAF');
    });
  });

  test('presets are valid and not already built in', () {
    const builtIn = {'HKD', 'USD', 'EUR', 'AUD', 'JPY'};
    for (final p in currencyPresets) {
      expect(p.code, matches(RegExp(r'^[A-Z]{3}$')));
      expect(builtIn, isNot(contains(p.code)));
      expect(p.approxPerUsd, greaterThan(0));
    }
    expect(presetFor('vnd')?.exponent, 0);
  });
}
