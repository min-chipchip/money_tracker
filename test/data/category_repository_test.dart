import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/data/db/app_database.dart';
import 'package:money_tracker/data/repositories/category_repository.dart';
import 'package:money_tracker/data/repositories/transaction_repository.dart';

import 'test_db.dart';

void main() {
  late AppDatabase db;
  late CategoryRepository categories;

  setUp(() {
    db = openTestDb();
    categories = CategoryRepository(db);
  });
  tearDown(() => db.close());

  Future<List<String>> names(String kind) async =>
      [for (final c in await categories.watchAll(kind: kind).first) c.name];

  test('new categories are added at the end of their kind', () async {
    await categories.add(name: 'Transport', kind: 'expense', color: 0xFF009688);
    expect((await names('expense')).last, 'Transport');
  });

  test('update changes name and color', () async {
    final food = await categoryId(db, 'Food');
    await categories.update(food, name: 'Groceries', color: 0xFFE91E63);
    final row = await (db.select(db.categories)..where((c) => c.id.equals(food))).getSingle();
    expect(row.name, 'Groceries');
    expect(row.color, 0xFFE91E63);
  });

  test('names must be unique per kind, ignoring case', () async {
    expect(
      categories.add(name: 'food', kind: 'expense'),
      throwsA(isA<CategoryNameTaken>()),
    );
    // Same name in the OTHER kind is fine.
    await categories.add(name: 'Food', kind: 'income');

    // Renaming onto an existing name is rejected, keeping your own is fine.
    final drink = await categoryId(db, 'Drink');
    expect(categories.update(drink, name: 'FOOD'), throwsA(isA<CategoryNameTaken>()));
    await categories.update(drink, name: 'Drink', color: 0xFF2196F3);
  });

  test('a category in use cannot be deleted', () async {
    final food = await categoryId(db, 'Food');
    await TransactionRepository(db).addEntry(
      type: TxType.expense,
      accountId: await accountId(db, 'Cash'),
      categoryId: food,
      amountMinor: 100,
      currency: 'HKD',
      occurredOn: DateTime(2026, 11, 5),
    );
    expect(
      categories.delete(food),
      throwsA(isA<CategoryDeleteBlocked>().having((e) => e.reason, 'reason', contains('1 transaction'))),
    );
  });

  test('an unused category can be deleted, and its name reused', () async {
    await categories.delete(await categoryId(db, 'Apparels'));
    expect(await names('expense'), isNot(contains('Apparels')));
    await categories.add(name: 'Apparels', kind: 'expense');
  });

  test('the last category of a kind cannot be deleted', () async {
    await categories.delete(await categoryId(db, 'Gift'));
    expect(
      categories.delete(await categoryId(db, 'Salary')),
      throwsA(isA<CategoryDeleteBlocked>()),
    );
  });
}
