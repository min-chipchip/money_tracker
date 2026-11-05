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

  /// Supported currencies (code, decimal places, symbol).
  Stream<List<CurrencyInfo>> watchCurrencies() =>
      (_db.select(_db.currencies)..orderBy([(c) => OrderingTerm(expression: c.code)])).watch();
}
