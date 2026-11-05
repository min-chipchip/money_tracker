import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/data/db/app_database.dart';
import 'package:money_tracker/data/repositories/fx_repository.dart';

import 'test_db.dart';

void main() {
  late AppDatabase db;
  final today = DateTime(2026, 11, 5);

  setUp(() => db = openTestDb());
  tearDown(() => db.close());

  FxRepository repo({RateFetcher? fetcher}) =>
      FxRepository(db, fetcher: fetcher ?? () async => null, clock: () => today);

  test('a fresh database already has approximate rates (works offline)', () async {
    final rates = await repo().watchLatest().first;
    expect(rates.approximate, isTrue);
    expect(rates.perUsd['HKD'], 7.78);
    // 1 USD = 7.78 HKD and 1 USD = 150 JPY, so 1 JPY = 7.78 / 150 HKD.
    expect(rates.rate('JPY', 'HKD'), closeTo(7.78 / 150, 1e-12));
    expect(rates.rate('HKD', 'HKD'), 1);
    expect(rates.rate('HKD', 'XYZ'), isNull);
  });

  test('refresh saves known currencies only and replaces the approximation', () async {
    final saved = await repo(
      fetcher: () async => {'USD': 1, 'HKD': 7.8, 'EUR': 0.9, 'AUD': 1.5, 'JPY': 152, 'GBP': 0.79},
    ).refreshFromApi();
    expect(saved, isTrue);

    final rates = await repo().watchLatest().first;
    expect(rates.approximate, isFalse);
    expect(rates.perUsd['HKD'], 7.8);
    expect(rates.perUsd.containsKey('GBP'), isFalse, reason: 'not in currencies table');
  });

  test('ratesOn picks the newest rate on or before the date', () async {
    await repo(fetcher: () async => {'USD': 1, 'HKD': 7.8}).refreshFromApi();

    final onToday = await repo().ratesOn(today);
    expect(onToday.perUsd['HKD'], 7.8); // API rate from today

    final lastYear = await repo().ratesOn(DateTime(2025, 6, 1));
    expect(lastYear.perUsd['HKD'], 7.78); // only the old seed rate existed then
    expect(lastYear.approximate, isTrue);
  });

  test('refreshing twice on the same day overwrites instead of duplicating', () async {
    await repo(fetcher: () async => {'HKD': 7.8}).refreshFromApi();
    await repo(fetcher: () async => {'HKD': 7.81}).refreshFromApi();

    final hkdRows = await (db.select(db.exchangeRates)..where((r) => r.quote.equals('HKD'))).get();
    expect(hkdRows, hasLength(2)); // the seed row + one row for today
    expect((await repo().ratesOn(today)).perUsd['HKD'], 7.81);
  });

  test('being offline or failing is harmless', () async {
    expect(await repo(fetcher: () async => null).refreshFromApi(), isFalse);
    expect(await repo(fetcher: () async => throw Exception('no network')).refreshFromApi(), isFalse);
    expect((await repo().watchLatest().first).perUsd['HKD'], 7.78);
  });
}
