// These tests talk to the database directly (no repository) to prove that
// the SCHEMA itself rejects bad data, even if app code has a bug.

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/data/db/app_database.dart';

import 'test_db.dart';

void main() {
  late AppDatabase db;
  late String cash;
  late String bank;
  late String food;

  setUp(() async {
    db = openTestDb();
    cash = await accountId(db, 'Cash');
    bank = await accountId(db, 'Bank Account');
    food = await categoryId(db, 'Food');
  });
  tearDown(() => db.close());

  /// A valid expense row; tests override one field to make it invalid.
  TransactionsCompanion expense({
    String? id,
    String? accountId,
    Value<String?>? categoryId,
    int amountMinor = 1000,
    String occurredOn = '2026-11-05',
  }) =>
      TransactionsCompanion.insert(
        id: id ?? 'tx-1',
        type: 'expense',
        occurredOn: occurredOn,
        accountId: accountId ?? cash,
        categoryId: categoryId ?? Value(food),
        amountMinor: amountMinor,
        currency: 'HKD',
        fxRateToBase: 1,
        baseAmountMinor: amountMinor,
        createdAt: 0,
        updatedAt: 0,
      );

  Future<void> insert(TransactionsCompanion row) => db.into(db.transactions).insert(row);
  final rejected = throwsA(isA<SqliteException>());

  group('seed data', () {
    test('creates currencies, accounts, categories and base currency', () async {
      expect(await db.select(db.currencies).get(), hasLength(5));
      expect(await db.select(db.accounts).get(), hasLength(3));
      expect(await db.select(db.categories).get(), hasLength(7));
      final jpy = await (db.select(db.currencies)..where((c) => c.code.equals('JPY'))).getSingle();
      expect(jpy.exponent, 0);
      final base = await (db.select(db.settings)..where((s) => s.key.equals('base_currency'))).getSingle();
      expect(base.value, 'HKD');
    });
  });

  group('constraints', () {
    test('a valid expense is accepted', () async {
      await insert(expense());
      expect(await db.select(db.transactions).get(), hasLength(1));
    });

    test('foreign keys: unknown account is rejected', () async {
      expect(insert(expense(accountId: 'no-such-account')), rejected);
    });

    test('amount must be positive', () async {
      expect(insert(expense(amountMinor: 0)), rejected);
      expect(insert(expense(amountMinor: -500)), rejected);
    });

    test('date must be YYYY-MM-DD', () async {
      expect(insert(expense(occurredOn: '2026-1-5')), rejected);
      expect(insert(expense(occurredOn: '05/11/2026')), rejected);
    });

    test('expense without a category is rejected', () async {
      expect(insert(expense(categoryId: const Value(null))), rejected);
    });

    test('transfer must have a different destination account', () async {
      TransactionsCompanion transfer({String? to}) => TransactionsCompanion.insert(
            id: 'tr-1',
            type: 'transfer',
            occurredOn: '2026-11-05',
            accountId: bank,
            toAccountId: Value(to),
            amountMinor: 5000,
            toAmountMinor: const Value(5000),
            currency: 'HKD',
            fxRateToBase: 1,
            baseAmountMinor: 5000,
            createdAt: 0,
            updatedAt: 0,
          );
      expect(insert(transfer()), rejected); // no destination
      expect(insert(transfer(to: bank)), rejected); // to itself
      await insert(transfer(to: cash)); // valid
    });

    test('category names are unique among live categories, ignoring case', () async {
      final duplicate = CategoriesCompanion.insert(
        id: 'c-dup',
        name: 'FOOD',
        kind: 'expense',
        createdAt: 0,
        updatedAt: 0,
      );
      expect(db.into(db.categories).insert(duplicate), rejected);

      // Once the old "Food" is soft-deleted, the name is free again.
      await (db.update(db.categories)..where((c) => c.id.equals(food)))
          .write(const CategoriesCompanion(deletedAt: Value(1)));
      await db.into(db.categories).insert(duplicate);
    });
  });
}
