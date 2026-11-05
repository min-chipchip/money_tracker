import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/data/db/app_database.dart';
import 'package:money_tracker/data/repositories/account_repository.dart';
import 'package:money_tracker/data/repositories/transaction_repository.dart';

import 'test_db.dart';

void main() {
  late AppDatabase db;
  late AccountRepository accounts;
  late TransactionRepository txs;

  setUp(() {
    db = openTestDb();
    accounts = AccountRepository(db);
    txs = TransactionRepository(db);
  });
  tearDown(() => db.close());

  Future<Map<String, int>> balances() async => {
        for (final b in await accounts.watchWithBalances().first) b.a.name: b.balanceMinor,
      };

  test('updateDetails changes name, type and starting balance', () async {
    final cash = await accountId(db, 'Cash');
    await accounts.updateDetails(cash, name: 'Wallet', kind: 'other', openingBalanceMinor: 10000);

    final row = await (db.select(db.accounts)..where((a) => a.id.equals(cash))).getSingle();
    expect(row.name, 'Wallet');
    expect(row.kind, 'other');
    expect((await balances())['Wallet'], 10000);
  });

  test('a deposit (income) raises the balance, an expense lowers it', () async {
    final bank = await accountId(db, 'Bank Account');
    await txs.addEntry(
      type: TxType.income,
      accountId: bank,
      categoryId: await categoryId(db, 'Salary'),
      amountMinor: 2000000,
      currency: 'HKD',
      occurredOn: DateTime(2026, 11, 1),
    );
    await txs.addEntry(
      type: TxType.expense,
      accountId: bank,
      categoryId: await categoryId(db, 'Food'),
      amountMinor: 4550,
      currency: 'HKD',
      occurredOn: DateTime(2026, 11, 2),
    );
    expect((await balances())['Bank Account'], 2000000 - 4550);
  });

  test('an unused account can be deleted', () async {
    final id = await accounts.add(name: 'Old Card', kind: 'credit_card', currency: 'HKD');
    await accounts.delete(id);
    expect((await balances()).containsKey('Old Card'), isFalse);
  });

  test('an account with transactions cannot be deleted', () async {
    final cash = await accountId(db, 'Cash');
    final txId = await txs.addEntry(
      type: TxType.expense,
      accountId: cash,
      categoryId: await categoryId(db, 'Food'),
      amountMinor: 100,
      currency: 'HKD',
      occurredOn: DateTime(2026, 11, 2),
    );
    await expectLater(
      accounts.delete(cash),
      throwsA(isA<AccountDeleteBlocked>().having((e) => e.reason, 'reason', contains('1 transaction'))),
    );

    // Once its transaction is deleted, the account can go.
    await txs.softDelete(txId);
    await accounts.delete(cash);
    expect((await balances()).containsKey('Cash'), isFalse);
  });

  test('accounts used as a transfer destination also count as in use', () async {
    final cash = await accountId(db, 'Cash');
    final bank = await accountId(db, 'Bank Account');
    await txs.addTransfer(
      fromAccountId: bank,
      toAccountId: cash,
      amountMinor: 5000,
      currency: 'HKD',
      occurredOn: DateTime(2026, 11, 3),
    );
    expect(accounts.delete(cash), throwsA(isA<AccountDeleteBlocked>()));
  });

  test('the last account cannot be deleted', () async {
    await accounts.delete(await accountId(db, 'Cash'));
    await accounts.delete(await accountId(db, 'Credit Card'));
    expect(
      accounts.delete(await accountId(db, 'Bank Account')),
      throwsA(isA<AccountDeleteBlocked>()),
    );
  });
}
