import 'package:drift/drift.dart';
import 'package:money_tracker/core/ids.dart';
import 'package:money_tracker/data/db/app_database.dart';

class AccountRepository {
  AccountRepository(this._db, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  int get _now => _clock().millisecondsSinceEpoch;

  /// Every live account with its balance, computed by SQL from the
  /// `account_movements` view (balances are derived, never stored).
  Stream<List<AccountBalancesResult>> watchWithBalances() =>
      _db.accountBalances().watch();

  Future<String> add({
    required String name,
    required String kind,
    required String currency,
    int openingBalanceMinor = 0,
  }) async {
    final id = newId();
    final now = _now;
    // New accounts go to the end of the list: SELECT MAX(sort_order) + 1.
    final maxOrder = _db.accounts.sortOrder.max();
    final lastOrder = await (_db.selectOnly(_db.accounts)..addColumns([maxOrder]))
        .map((row) => row.read(maxOrder))
        .getSingle();
    await _db.into(_db.accounts).insert(AccountsCompanion.insert(
          id: id,
          name: name.trim(),
          kind: kind,
          currency: currency,
          openingBalanceMinor: Value(openingBalanceMinor),
          sortOrder: Value((lastOrder ?? -1) + 1),
          createdAt: now,
          updatedAt: now,
        ));
    return id;
  }

  Future<void> rename(String id, String newName) {
    return (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(name: Value(newName.trim()), updatedAt: Value(_now)),
    );
  }

  Future<void> softDelete(String id) {
    final now = _now;
    return (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }
}
