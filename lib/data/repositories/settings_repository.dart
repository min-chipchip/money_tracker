import 'package:drift/drift.dart';
import 'package:money_tracker/data/db/app_database.dart';

/// App preferences stored in the `settings` key/value table.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const baseCurrencyKey = 'base_currency';

  Future<String?> get(String key) async {
    final row = await (_db.select(_db.settings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// Inserts the key, or overwrites it if it already exists ("upsert").
  Future<void> set(String key, String value) {
    return _db
        .into(_db.settings)
        .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
  }

  /// The currency every total is reported in.
  Future<String> baseCurrency() async => await get(baseCurrencyKey) ?? 'HKD';

  Stream<String> watchBaseCurrency() =>
      (_db.select(_db.settings)..where((s) => s.key.equals(baseCurrencyKey)))
          .watchSingleOrNull()
          .map((row) => row?.value ?? 'HKD');

  /// The currency amounts are SHOWN in when the app opens.
  ///
  /// Not the same as the base currency: the base currency is what
  /// `base_amount_minor` is stored in (changing it means recomputing every
  /// transaction), while the main currency is only a display preference.
  static const mainCurrencyKey = 'main_currency';

  /// Main currency, falling back to the base currency until one is chosen.
  Stream<String> watchMainCurrency() => _db.select(_db.settings).watch().map((rows) {
        final values = {for (final r in rows) r.key: r.value};
        return values[mainCurrencyKey] ?? values[baseCurrencyKey] ?? 'HKD';
      });

  Future<void> setMainCurrency(String code) => set(mainCurrencyKey, code);

  /// Supported currencies (code, decimal places, symbol).
  Stream<List<CurrencyInfo>> watchCurrencies() =>
      (_db.select(_db.currencies)..orderBy([(c) => OrderingTerm(expression: c.code)])).watch();

  /// Adds a currency together with a rough rate ("1 USD = [perUsd]"), so
  /// amounts in it can be converted straight away, even offline.
  ///
  /// The rate is stored like the built-in ones: as an approximate 'seed'
  /// rate dated 2000-01-01, the fallback for any date. Rates downloaded
  /// later (with FX_API_KEY) are newer and take over automatically.
  Future<void> addCurrency({
    required String code,
    required String symbol,
    required int exponent,
    required double perUsd,
  }) async {
    final normalized = code.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(normalized)) {
      throw const CurrencyInputError('Use the 3-letter code, e.g. VND');
    }
    if (exponent < 0 || exponent > 4) {
      throw const CurrencyInputError('Decimal places must be 0 to 4');
    }
    if (!(perUsd > 0)) {
      throw const CurrencyInputError('The rate must be more than 0');
    }
    await _db.transaction(() async {
      final exists = await (_db.select(_db.currencies)..where((c) => c.code.equals(normalized)))
          .getSingleOrNull();
      if (exists != null) throw CurrencyInputError('$normalized is already set up');

      await _db.into(_db.currencies).insert(
            CurrenciesCompanion.insert(
              code: normalized,
              exponent: exponent,
              symbol: symbol.trim().isEmpty ? normalized : symbol.trim(),
            ),
          );
      await _db.into(_db.exchangeRates).insertOnConflictUpdate(
            ExchangeRatesCompanion.insert(
              rateDate: '2000-01-01',
              quote: normalized,
              perUsd: perUsd,
              source: 'seed',
              fetchedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    });
  }
}

/// Why a currency couldn't be added, worded for the user.
class CurrencyInputError implements Exception {
  const CurrencyInputError(this.message);
  final String message;
  @override
  String toString() => message;
}
