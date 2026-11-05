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

  /// Returns the new category's id. Throws if a live category of the same
  /// kind already has this name (enforced by the `ux_categories_name` index).
  Future<String> add({required String name, required String kind, int? color}) async {
    final id = newId();
    final now = _now;
    await _db.into(_db.categories).insert(CategoriesCompanion.insert(
          id: id,
          name: name.trim(),
          kind: kind,
          color: Value(color),
          createdAt: now,
          updatedAt: now,
        ));
    return id;
  }

  /// Renaming is one UPDATE on one row: transactions point at the id, not the
  /// name, so all history follows automatically.
  Future<void> rename(String id, String newName) {
    return (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(name: Value(newName.trim()), updatedAt: Value(_now)),
    );
  }

  /// Soft delete: the row stays (old transactions still reference it) but
  /// disappears from lists, and its name becomes free to reuse.
  Future<void> softDelete(String id) {
    final now = _now;
    return (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }
}
