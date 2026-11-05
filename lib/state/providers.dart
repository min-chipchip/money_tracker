/// App-wide Riverpod providers: the database, the repositories, and the
/// streams of reference data (accounts, categories, currencies).
///
/// Widgets never create these objects themselves. They ask for them with
/// `ref.watch(...)` (rebuild when it changes) or `ref.read(...)` (use once,
/// e.g. inside a button handler).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/data/db/app_database.dart';
import 'package:money_tracker/data/repositories/account_repository.dart';
import 'package:money_tracker/data/repositories/category_repository.dart';
import 'package:money_tracker/data/repositories/fx_repository.dart';
import 'package:money_tracker/data/repositories/settings_repository.dart';
import 'package:money_tracker/data/repositories/transaction_repository.dart';

/// The one database connection for the whole app. Tests can replace it with
/// an in-memory database using `ProviderScope(overrides: [...])`.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final transactionRepositoryProvider =
    Provider((ref) => TransactionRepository(ref.watch(databaseProvider)));
final accountRepositoryProvider =
    Provider((ref) => AccountRepository(ref.watch(databaseProvider)));
final categoryRepositoryProvider =
    Provider((ref) => CategoryRepository(ref.watch(databaseProvider)));
final fxRepositoryProvider =
    Provider((ref) => FxRepository(ref.watch(databaseProvider)));
final settingsRepositoryProvider =
    Provider((ref) => SettingsRepository(ref.watch(databaseProvider)));

/// Accounts with their live balances.
final accountsProvider =
    StreamProvider((ref) => ref.watch(accountRepositoryProvider).watchWithBalances());

final expenseCategoriesProvider =
    StreamProvider((ref) => ref.watch(categoryRepositoryProvider).watchAll(kind: 'expense'));

final incomeCategoriesProvider = StreamProvider(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(kind: 'income'),
);

final currenciesProvider =
    StreamProvider((ref) => ref.watch(settingsRepositoryProvider).watchCurrencies());

/// Currency code -> number of decimal places, e.g. {'HKD': 2, 'JPY': 0}.
/// Empty until the currencies have loaded.
final currencyExponentsProvider = Provider<Map<String, int>>((ref) {
  final list = ref.watch(currenciesProvider).value ?? const [];
  return {for (final c in list) c.code: c.exponent};
});

final baseCurrencyProvider =
    StreamProvider((ref) => ref.watch(settingsRepositoryProvider).watchBaseCurrency());

/// Latest exchange rates from the database (works offline). Updates
/// automatically when a fresh API fetch is saved.
final fxRatesProvider =
    StreamProvider((ref) => ref.watch(fxRepositoryProvider).watchLatest());

/// The display currency to start with (Settings → Main currency).
final mainCurrencyProvider =
    StreamProvider((ref) => ref.watch(settingsRepositoryProvider).watchMainCurrency());
