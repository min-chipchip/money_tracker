import 'package:drift/drift.dart';
import 'package:money_tracker/core/ids.dart';
import 'package:money_tracker/data/db/app_database.dart';

class CategoryRepository {
  CategoryRepository(this._db, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  int get _now => _clock().millisecondsSinceEpoch;

  /// Live, non-archived categories, optionally only 'expense' or 'income'.
  /// It's a stream: it emits again whenever the categories table changes.
  Stream<List<Category>> watchAll({String? kind}) {
    final query = _db.select(_db.categories)
      ..where((c) => c.deletedAt.isNull() & c.archived.not())
      ..orderBy([(c) => OrderingTerm(expression: c.sortOrder), (c) => OrderingTerm(expression: c.name)]);
    if (kind != null) query.where((c) => c.kind.equals(kind));
    return query.watch();
  }

  /// Returns the new category's id. New categories go to the end of the list.
  /// Throws [CategoryNameTaken] if a live category of the same kind already
  /// has this name (ignoring case).
  Future<String> add({required String name, required String kind, int? color}) async {
    final trimmed = name.trim();
    await _ensureNameFree(trimmed, kind);
    final maxOrder = _db.categories.sortOrder.max();
    final lastOrder = await (_db.selectOnly(_db.categories)
          ..addColumns([maxOrder])
          ..where(_db.categories.kind.equals(kind)))
        .map((row) => row.read(maxOrder))
        .getSingle();
    final id = newId();
    final now = _now;
    await _db.into(_db.categories).insert(CategoriesCompanion.insert(
          id: id,
          name: trimmed,
          kind: kind,
          color: Value(color),
          sortOrder: Value((lastOrder ?? -1) + 1),
          createdAt: now,
          updatedAt: now,
        ));
    return id;
  }

  /// Renaming is one UPDATE on one row: transactions point at the id, not the
  /// name, so all history follows automatically.
  Future<void> rename(String id, String newName) async {
    final existing = await _get(id);
    await update(id, name: newName, color: existing.color);
  }

  /// Changes name and color. The kind (expense/income) is fixed after
  /// creation: the transactions using it are of that kind.
  Future<void> update(String id, {required String name, int? color}) async {
    final existing = await _get(id);
    final trimmed = name.trim();
    await _ensureNameFree(trimmed, existing.kind, exceptId: id);
    await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(trimmed),
        color: Value(color),
        updatedAt: Value(_now),
      ),
    );
  }

  /// Number of live transactions in this category.
  Future<int> liveTransactionCount(String id) {
    final t = _db.transactions;
    final count = t.id.count();
    final query = _db.selectOnly(t)
      ..addColumns([count])
      ..where(t.deletedAt.isNull() & t.categoryId.equals(id));
    return query.map((row) => row.read(count)!).getSingle();
  }

  /// Deletes the category if it's safe to, otherwise throws
  /// [CategoryDeleteBlocked] explaining why. Same idea as accounts:
  /// - a category still used by transactions can't go (their history and
  ///   the pie chart would point at a category you can no longer pick);
  /// - the last category of a kind can't go, or you couldn't add entries.
  Future<void> delete(String id) async {
    final used = await liveTransactionCount(id);
    if (used > 0) {
      throw CategoryDeleteBlocked(
        used == 1
            ? 'This category has 1 transaction. Move or delete it first.'
            : 'This category has $used transactions. Move or delete them first.',
      );
    }
    final kind = (await _get(id)).kind;
    final live = _db.categories.id.count();
    final sameKind = await (_db.selectOnly(_db.categories)
          ..addColumns([live])
          ..where(_db.categories.deletedAt.isNull() & _db.categories.kind.equals(kind)))
        .map((row) => row.read(live)!)
        .getSingle();
    if (sameKind <= 1) {
      throw CategoryDeleteBlocked('You need at least one $kind category.');
    }
    await softDelete(id);
  }

  /// Soft delete: the row stays (old transactions still reference it) but
  /// disappears from lists, and its name becomes free to reuse.
  Future<void> softDelete(String id) {
    final now = _now;
    return (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  Future<Category> _get(String id) =>
      (_db.select(_db.categories)..where((c) => c.id.equals(id))).getSingle();

  /// The database also enforces this (unique index ux_categories_name), but
  /// checking first lets us show a friendly message instead of a raw
  /// SQLite constraint error.
  Future<void> _ensureNameFree(String name, String kind, {String? exceptId}) async {
    final clash = await (_db.select(_db.categories)
          ..where((c) =>
              c.deletedAt.isNull() &
              c.kind.equals(kind) &
              c.name.lower().equals(name.toLowerCase()) &
              (exceptId == null ? const Constant(true) : c.id.equals(exceptId).not())))
        .getSingleOrNull();
    if (clash != null) throw CategoryNameTaken(name);
  }
}

class CategoryDeleteBlocked implements Exception {
  const CategoryDeleteBlocked(this.reason);
  final String reason;

  @override
  String toString() => reason;
}

class CategoryNameTaken implements Exception {
  const CategoryNameTaken(this.name);
  final String name;

  @override
  String toString() => 'There is already a category called "$name".';
}
