import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:money_tracker/core/ids.dart';
import 'package:money_tracker/data/db/app_database.steps.dart';

part 'app_database.g.dart';

/// The app's local SQLite database.
///
/// Tables, the view and the named queries live in the `.drift` files next to
/// this one; drift generates the typed Dart code into `app_database.g.dart`.
/// After changing a `.drift` file, regenerate with:
///
///     dart run build_runner build
///
/// The file is called `money_tracker_v2` (v2 of the APP, not of the schema;
/// the schema version is [schemaVersion]).
@DriftDatabase(include: {'schema.drift', 'queries.drift'})
class AppDatabase extends _$AppDatabase {
  /// Pass an executor in tests, e.g. `AppDatabase(NativeDatabase.memory())`.
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'money_tracker_v2'));

  /// Bump this whenever the schema changes, then run
  /// `dart run drift_dev make-migrations` to snapshot the new version and
  /// regenerate app_database.steps.dart, and add the new step below.
  /// Never edit a migration that has already shipped.
  ///
  /// History:
  ///   1 — initial schema
  ///   2 — exchange_rates (offline currency conversion)
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        // Brand-new install: create the latest schema directly.
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaults();
          await _seedApproximateRates();
        },
        // Existing install: walk version by version (1→2, later 2→3, ...).
        // `schema` is a frozen snapshot of that version, so old steps keep
        // working even after later versions change the tables again.
        onUpgrade: stepByStep(
          from1To2: (m, schema) async {
            await m.createTable(schema.exchangeRates);
            await _seedApproximateRates();
          },
        ),
        beforeOpen: (details) async {
          // SQLite ignores REFERENCES constraints unless this is switched on,
          // and it has to be switched on for every new connection.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Rough, hand-picked "1 USD = x" values so conversion works offline
  /// before the first successful API fetch. They are marked source='seed'
  /// and get superseded by newer 'api' rows as soon as the API is reachable.
  /// NOT live market rates.
  static const approximatePerUsd = {
    'USD': 1.0,
    'HKD': 7.78,
    'EUR': 0.92,
    'AUD': 1.53,
    'JPY': 150.0,
  };

  /// Raw SQL on purpose: migrations must not depend on today's generated
  /// classes, which will keep changing as the schema evolves.
  /// Dated 2000-01-01 so it is the fallback for any transaction date, and any
  /// real API rate (dated today) counts as newer.
  Future<void> _seedApproximateRates() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final MapEntry(key: code, value: rate) in approximatePerUsd.entries) {
      await customStatement(
        'INSERT OR IGNORE INTO exchange_rates '
        '(rate_date, quote, per_usd, source, fetched_at) '
        "VALUES ('2000-01-01', ?, ?, 'seed', ?)",
        [code, rate, now],
      );
    }
  }

  /// Starter data written once, when the database file is first created.
  Future<void> _seedDefaults() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await batch((b) {
      b.insertAll(currencies, [
        CurrenciesCompanion.insert(code: 'HKD', exponent: 2, symbol: r'HK$'),
        CurrenciesCompanion.insert(code: 'USD', exponent: 2, symbol: r'$'),
        CurrenciesCompanion.insert(code: 'EUR', exponent: 2, symbol: '€'),
        CurrenciesCompanion.insert(code: 'AUD', exponent: 2, symbol: r'A$'),
        CurrenciesCompanion.insert(code: 'JPY', exponent: 0, symbol: '¥'),
      ]);

      b.insert(settings, SettingsCompanion.insert(key: 'base_currency', value: 'HKD'));

      const defaultAccounts = [
        ('Cash', 'cash'),
        ('Credit Card', 'credit_card'),
        ('Bank Account', 'bank'),
      ];
      b.insertAll(accounts, [
        for (final (i, (name, kind)) in defaultAccounts.indexed)
          AccountsCompanion.insert(
            id: newId(),
            name: name,
            kind: kind,
            currency: 'HKD',
            sortOrder: Value(i),
            createdAt: now,
            updatedAt: now,
          ),
      ]);

      // (name, kind, ARGB color)
      const defaultCategories = [
        ('Food', 'expense', 0xFF2196F3),
        ('Drink', 'expense', 0xFFF44336),
        ('Education', 'expense', 0xFF4CAF50),
        ('Social Life', 'expense', 0xFFF9A825),
        ('Apparels', 'expense', 0xFF9C27B0),
        ('Salary', 'income', 0xFF009688),
        ('Gift', 'income', 0xFFFF9800),
      ];
      b.insertAll(categories, [
        for (final (i, (name, kind, color)) in defaultCategories.indexed)
          CategoriesCompanion.insert(
            id: newId(),
            name: name,
            kind: kind,
            color: Value(color),
            sortOrder: Value(i),
            createdAt: now,
            updatedAt: now,
          ),
      ]);
    });
  }
}
