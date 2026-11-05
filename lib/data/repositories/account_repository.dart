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

  /// Edits everything except the currency. Changing an account's currency
  /// would silently re-interpret every amount already recorded in it, so
  /// the currency is fixed once the account exists.
  Future<void> updateDetails(
    String id, {
    required String name,
    required String kind,
    required int openingBalanceMinor,
  }) {
    return (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        name: Value(name.trim()),
        kind: Value(kind),
        openingBalanceMinor: Value(openingBalanceMinor),
        updatedAt: Value(_now),
      ),
    );
  }

  /// Number of live (not deleted) transactions that use this account, on
  /// either side of a transfer.
  Future<int> liveTransactionCount(String id) {
    final t = _db.transactions;
    final count = t.id.count();
    final query = _db.selectOnly(t)
      ..addColumns([count])
      ..where(t.deletedAt.isNull() & (t.accountId.equals(id) | t.toAccountId.equals(id)));
    return query.map((row) => row.read(count)!).getSingle();
  }

  /// Deletes the account if it's safe to, otherwise throws
  /// [AccountDeleteBlocked] explaining why.
  ///
  /// The rule lives HERE (not in a widget) so every screen has to obey it:
  /// - an account that still has transactions can't go, or history would
  ///   point at an account the user can no longer see;
  /// - the last account can't go, because every entry needs an account.
  Future<void> delete(String id) async {
    final used = await liveTransactionCount(id);
    if (used > 0) {
      throw AccountDeleteBlocked(
        used == 1
            ? 'This account has 1 transaction. Delete it first.'
            : 'This account has $used transactions. Delete them first.',
      );
    }
    final live = _db.accounts.id.count();
    final liveAccounts = await (_db.selectOnly(_db.accounts)
          ..addColumns([live])
          ..where(_db.accounts.deletedAt.isNull()))
        .map((row) => row.read(live)!)
        .getSingle();
    if (liveAccounts <= 1) {
      throw const AccountDeleteBlocked('You need at least one account.');
    }
    await softDelete(id);
  }

  Future<void> softDelete(String id) {
    final now = _now;
    return (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }
}

/// Why an account can't be deleted, in words the user can read.
class AccountDeleteBlocked implements Exception {
  const AccountDeleteBlocked(this.reason);
  final String reason;

  @override
  String toString() => reason;
}
