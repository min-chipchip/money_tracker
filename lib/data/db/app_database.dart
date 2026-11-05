import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:money_tracker/core/ids.dart';

part 'app_database.g.dart';

/// The app's local SQLite database.
///
/// Tables, the view and the named queries live in the `.drift` files next to
/// this one; drift generates the typed Dart code into `app_database.g.dart`.
/// After changing a `.drift` file, regenerate with:
///
///     dart run build_runner build
///
/// This is a NEW database file (`money_tracker_v2`). The old sqflite
/// database (`money_tracker.db`) is left untouched until we migrate the UI.
@DriftDatabase(include: {'schema.drift', 'queries.drift'})
class AppDatabase extends _$AppDatabase {
  /// Pass an executor in tests, e.g. `AppDatabase(NativeDatabase.memory())`.
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'money_tracker_v2'));

  /// Bump this whenever the schema changes, and add a migration step below.
  /// Never edit a migration that has already shipped.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaults();
        },
        // Future schema changes go here, e.g.:
        // onUpgrade: stepByStep(from1To2: (m, schema) async { ... }),
        beforeOpen: (details) async {
          // SQLite ignores REFERENCES constraints unless this is switched on,
          // and it has to be switched on for every new connection.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

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
