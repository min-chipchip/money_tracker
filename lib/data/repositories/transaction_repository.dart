import 'package:drift/drift.dart';
import 'package:money_tracker/core/date_range.dart';
import 'package:money_tracker/core/ids.dart';
import 'package:money_tracker/core/money.dart';
import 'package:money_tracker/data/db/app_database.dart';
import 'package:money_tracker/data/repositories/settings_repository.dart';

/// Stored in the `type` column as its name: 'expense', 'income', 'transfer'.
enum TxType { expense, income, transfer }

/// Everything the app does with transactions goes through here. The UI never
/// writes SQL or touches tables directly.
class TransactionRepository {
  TransactionRepository(this._db, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        _settings = SettingsRepository(_db);

  final AppDatabase _db;
  final DateTime Function() _clock;
  final SettingsRepository _settings;

  int get _now => _clock().millisecondsSinceEpoch;

  // ---------------------------------------------------------------- reads
  // All reads are streams: they re-emit whenever the tables they read change,
  // so every screen watching them updates on its own.

  Stream<List<TransactionsInRangeResult>> watchInRange(DateRange range) =>
      _db.transactionsInRange(range.startKey, range.endKey).watch();

  Stream<List<CategoryTotalsResult>> watchCategoryTotals(DateRange range) =>
      _db.categoryTotals(range.startKey, range.endKey).watch();

  Stream<List<MonthlyTotalsResult>> watchMonthlyTotals(DateRange range) =>
      _db.monthlyTotals(range.startKey, range.endKey).watch();

  Future<List<String>> tagsFor(String transactionId) async {
    final query = _db.select(_db.tags).join([
      innerJoin(_db.transactionTags, _db.transactionTags.tagId.equalsExp(_db.tags.id)),
    ])
      ..where(_db.transactionTags.transactionId.equals(transactionId))
      ..orderBy([OrderingTerm(expression: _db.tags.name)]);
    final rows = await query.get();
    return [for (final row in rows) row.readTable(_db.tags).name];
  }

  // --------------------------------------------------------------- writes

  /// Adds an expense or income and returns its id.
  ///
  /// [fxRateToBase] ("1 unit of [currency] = rate units of base currency") is
  /// required when [currency] isn't the base currency. Phase 3 replaces this
  /// parameter with cached exchange rates.
  Future<String> addEntry({
    required TxType type,
    required String accountId,
    required String categoryId,
    required int amountMinor,
    required String currency,
    required DateTime occurredOn,
    String note = '',
    bool isStarred = false,
    int importance = 3,
    double? fxRateToBase,
    List<String> tags = const [],
  }) async {
    if (type == TxType.transfer) {
      throw ArgumentError.value(type, 'type', 'use addTransfer for transfers');
    }
    final id = newId();
    final now = _now;
    final base = await _toBase(amountMinor, currency, fxRateToBase);

    // One DB transaction: the row and its tags are saved together or not at all.
    await _db.transaction(() async {
      await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
            id: id,
            type: type.name,
            occurredOn: dateKey(occurredOn),
            accountId: accountId,
            categoryId: Value(categoryId),
            amountMinor: amountMinor,
            currency: currency,
            fxRateToBase: base.rate,
            baseAmountMinor: base.minor,
            note: Value(note),
            isStarred: Value(isStarred),
            importance: Value(importance),
            createdAt: now,
            updatedAt: now,
          ));
      await _replaceTags(id, tags, now);
    });
    return id;
  }

  /// Edits an expense or income. Recomputes the base-currency value.
  Future<void> updateEntry(
    String id, {
    required TxType type,
    required String accountId,
    required String categoryId,
    required int amountMinor,
    required String currency,
    required DateTime occurredOn,
    String note = '',
    bool isStarred = false,
    int importance = 3,
    double? fxRateToBase,
    List<String> tags = const [],
  }) async {
    final now = _now;
    final base = await _toBase(amountMinor, currency, fxRateToBase);
    await _db.transaction(() async {
      await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          type: Value(type.name),
          occurredOn: Value(dateKey(occurredOn)),
          accountId: Value(accountId),
          categoryId: Value(categoryId),
          amountMinor: Value(amountMinor),
          currency: Value(currency),
          fxRateToBase: Value(base.rate),
          baseAmountMinor: Value(base.minor),
          note: Value(note),
          isStarred: Value(isStarred),
          importance: Value(importance),
          updatedAt: Value(now),
        ),
      );
      await _replaceTags(id, tags, now);
    });
  }

  /// Moves money between two of the user's accounts. [toAmountMinor] is what
  /// arrives in the destination; it defaults to [amountMinor] (same currency).
  Future<String> addTransfer({
    required String fromAccountId,
    required String toAccountId,
    required int amountMinor,
    required String currency,
    required DateTime occurredOn,
    int? toAmountMinor,
    String note = '',
    double? fxRateToBase,
  }) async {
    final id = newId();
    final now = _now;
    final base = await _toBase(amountMinor, currency, fxRateToBase);
    await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
          id: id,
          type: TxType.transfer.name,
          occurredOn: dateKey(occurredOn),
          accountId: fromAccountId,
          toAccountId: Value(toAccountId),
          amountMinor: amountMinor,
          toAmountMinor: Value(toAmountMinor ?? amountMinor),
          currency: currency,
          fxRateToBase: base.rate,
          baseAmountMinor: base.minor,
          note: Value(note),
          createdAt: now,
          updatedAt: now,
        ));
    return id;
  }

  /// Soft delete: sets deleted_at instead of erasing the row, so a future
  /// sync can tell other devices "this was deleted".
  Future<void> softDelete(String id) {
    final now = _now;
    return (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  Future<void> toggleStar(String id) {
    // Raw SQL must declare which tables it changes (`updates`), otherwise
    // drift's streams don't know to re-emit.
    return _db.customUpdate(
      'UPDATE transactions SET is_starred = NOT is_starred, updated_at = ? WHERE id = ?',
      variables: [Variable.withInt(_now), Variable.withString(id)],
      updates: {_db.transactions},
    );
  }

  // -------------------------------------------------------------- helpers

  /// Snapshot of the value in the base currency at the time of saving.
  Future<({double rate, int minor})> _toBase(
    int amountMinor,
    String currency,
    double? fxRateToBase,
  ) async {
    final base = await _settings.baseCurrency();
    if (currency == base) return (rate: 1.0, minor: amountMinor);
    if (fxRateToBase == null) {
      throw ArgumentError.value(
        currency,
        'currency',
        'fxRateToBase is required for currencies other than $base',
      );
    }
    return (
      rate: fxRateToBase,
      minor: convertMinor(
        amountMinor: amountMinor,
        fromExponent: await _exponentOf(currency),
        toExponent: await _exponentOf(base),
        rate: fxRateToBase,
      ),
    );
  }

  Future<int> _exponentOf(String code) async {
    final row = await (_db.select(_db.currencies)..where((c) => c.code.equals(code)))
        .getSingle();
    return row.exponent;
  }

  /// Makes [names] the transaction's full tag list. Reuses existing tags
  /// case-insensitively ("Trip" == "trip") and creates missing ones.
  Future<void> _replaceTags(String transactionId, List<String> names, int now) async {
    await (_db.delete(_db.transactionTags)
          ..where((tt) => tt.transactionId.equals(transactionId)))
        .go();

    final unique = <String, String>{}; // lowercase -> as typed
    for (final name in names) {
      final trimmed = name.trim();
      if (trimmed.isNotEmpty) unique.putIfAbsent(trimmed.toLowerCase(), () => trimmed);
    }

    for (final MapEntry(key: lower, value: name) in unique.entries) {
      final existing = await (_db.select(_db.tags)
            ..where((t) => t.name.lower().equals(lower) & t.deletedAt.isNull()))
          .getSingleOrNull();
      final tagId = existing?.id ?? newId();
      if (existing == null) {
        await _db.into(_db.tags).insert(TagsCompanion.insert(
              id: tagId,
              name: name,
              createdAt: now,
              updatedAt: now,
            ));
      }
      await _db.into(_db.transactionTags).insert(TransactionTagsCompanion.insert(
            transactionId: transactionId,
            tagId: tagId,
          ));
    }
  }
}
