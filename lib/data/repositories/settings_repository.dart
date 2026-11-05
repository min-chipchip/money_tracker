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
}
