import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/date_range.dart';
import 'package:money_tracker/data/db/app_database.dart';
import 'package:money_tracker/data/repositories/account_repository.dart';
import 'package:money_tracker/data/repositories/category_repository.dart';
import 'package:money_tracker/data/repositories/transaction_repository.dart';

import 'test_db.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository txs;
  late String cash;
  late String bank;
  late String food;
  late String drink;
  final november = DateRange.month(DateTime(2026, 11));

  setUp(() async {
    db = openTestDb();
    txs = TransactionRepository(db);
    cash = await accountId(db, 'Cash');
    bank = await accountId(db, 'Bank Account');
    food = await categoryId(db, 'Food');
    drink = await categoryId(db, 'Drink');
  });
  tearDown(() => db.close());

  Future<String> spend(int minor, DateTime on, {String? category, String currency = 'HKD', double? rate}) =>
      txs.addEntry(
        type: TxType.expense,
        accountId: cash,
        categoryId: category ?? food,
        amountMinor: minor,
        currency: currency,
        occurredOn: on,
        fxRateToBase: rate,
      );

  test('month range is half-open: includes the 30th, excludes the next 1st', () async {
    await spend(100, DateTime(2026, 10, 31));
    await spend(200, DateTime(2026, 11, 1));
    await spend(300, DateTime(2026, 11, 30));
    await spend(400, DateTime(2026, 12, 1));

    final rows = await txs.watchInRange(november).first;
    expect(rows.map((r) => r.t.amountMinor), unorderedEquals([200, 300]));
    expect(rows.first.accountName, 'Cash');
    expect(rows.first.categoryName, 'Food');
  });

  test('category totals are summed by SQL in base currency', () async {
    await spend(4550, DateTime(2026, 11, 2)); // 45.50 HKD food
    await spend(1000, DateTime(2026, 11, 3)); // 10.00 HKD food
    await spend(1000, DateTime(2026, 11, 4), category: drink, currency: 'JPY', rate: 0.052); // ¥1000

    final totals = await txs.watchCategoryTotals(november).first;
    expect({for (final t in totals) t.name: t.totalMinor}, {
      'Food': 5550,
      'Drink': 5200, // ¥1000 × 0.052 = HK$52.00
    });
    expect(totals.first.name, 'Food', reason: 'sorted largest first');
  });

  test('a foreign currency without an exchange rate is refused', () async {
    expect(() => spend(1000, DateTime(2026, 11, 4), currency: 'USD'), throwsArgumentError);
  });

  test('updateEntry recomputes the base-currency value', () async {
    final id = await spend(1000, DateTime(2026, 11, 2));
    await txs.updateEntry(
      id,
      type: TxType.expense,
      accountId: cash,
      categoryId: food,
      amountMinor: 20,
      currency: 'USD',
      occurredOn: DateTime(2026, 11, 2),
      fxRateToBase: 7.8,
    );
    final row = (await txs.watchInRange(november).first).single.t;
    expect(row.currency, 'USD');
    expect(row.baseAmountMinor, 156); // $0.20 × 7.8 = HK$1.56
  });

  test('account balances include transfers on both sides', () async {
    await spend(1234, DateTime(2026, 11, 2)); // cash -12.34
    await txs.addTransfer(
      fromAccountId: bank,
      toAccountId: cash,
      amountMinor: 5000,
      currency: 'HKD',
      occurredOn: DateTime(2026, 11, 3),
    );

    final balances = await AccountRepository(db).watchWithBalances().first;
    final byName = {for (final b in balances) b.a.name: b.balanceMinor};
    expect(byName['Cash'], 3766); // -12.34 + 50.00
    expect(byName['Bank Account'], -5000);
    expect(byName['Credit Card'], 0);
  });

  test('soft-deleted transactions disappear from lists, totals and balances', () async {
    final id = await spend(1000, DateTime(2026, 11, 2));
    await txs.softDelete(id);

    expect(await txs.watchInRange(november).first, isEmpty);
    expect(await txs.watchCategoryTotals(november).first, isEmpty);
    final balances = await AccountRepository(db).watchWithBalances().first;
    expect(balances.firstWhere((b) => b.a.name == 'Cash').balanceMinor, 0);
    // ...but the row is still in the table, marked deleted.
    expect((await db.select(db.transactions).getSingle()).deletedAt, isNotNull);
  });

  test('streams re-emit when data changes', () async {
    final id = await spend(1000, DateTime(2026, 11, 2));
    final starred = txs.watchInRange(november).map((rows) => rows.single.t.isStarred);

    expect(starred, emitsInOrder([false, true]));
    await Future<void>.delayed(Duration.zero);
    await txs.toggleStar(id);
  });

  test('tags are reused case-insensitively and replaced on edit', () async {
    final a = await txs.addEntry(
      type: TxType.expense,
      accountId: cash,
      categoryId: food,
      amountMinor: 100,
      currency: 'HKD',
      occurredOn: DateTime(2026, 11, 2),
      tags: ['Trip', 'work'],
    );
    final b = await txs.addEntry(
      type: TxType.expense,
      accountId: cash,
      categoryId: food,
      amountMinor: 200,
      currency: 'HKD',
      occurredOn: DateTime(2026, 11, 2),
      tags: ['trip', ' trip '],
    );
    expect(await db.select(db.tags).get(), hasLength(2), reason: '"trip" reuses "Trip"');
    expect(await txs.tagsFor(b), ['Trip']);

    await txs.updateEntry(
      a,
      type: TxType.expense,
      accountId: cash,
      categoryId: food,
      amountMinor: 100,
      currency: 'HKD',
      occurredOn: DateTime(2026, 11, 2),
      tags: ['work'],
    );
    expect(await txs.tagsFor(a), ['work']);
  });

  test('renaming a category updates its history', () async {
    await spend(1000, DateTime(2026, 11, 2));
    await CategoryRepository(db).rename(food, 'Groceries');
    final row = (await txs.watchInRange(november).first).single;
    expect(row.categoryName, 'Groceries');
  });
}
