import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:money_tracker/data/db/app_database.dart';

/// A brand-new database that lives only in memory: created (and seeded) per
/// test, gone when the test ends.
AppDatabase openTestDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

Future<String> accountId(AppDatabase db, String name) async =>
    (await (db.select(db.accounts)..where((a) => a.name.equals(name))).getSingle()).id;

Future<String> categoryId(AppDatabase db, String name) async =>
    (await (db.select(db.categories)
              ..where((c) => c.name.equals(name) & c.deletedAt.isNull()))
            .getSingle())
        .id;
