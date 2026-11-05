import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/state/providers.dart';
import 'package:money_tracker/state/transaction_actions.dart';
import 'package:money_tracker/state/view_period.dart';

import '../data/test_db.dart';

void main() {
  late ProviderContainer container;
  late String cash;
  late String food;

  setUp(() async {
    final db = openTestDb();
    // Swap the real database file for an in-memory one. Everything built on
    // top of databaseProvider (repositories, streams) uses it automatically.
    container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(db.close);
    addTearDown(container.dispose);
    cash = await accountId(db, 'Cash');
    food = await categoryId(db, 'Food');
  });

  TransactionDraft draft(int minor, DateTime on, {String currency = 'HKD'}) => TransactionDraft(
        accountId: cash,
        categoryId: food,
        amountMinor: minor,
        currency: currency,
        occurredOn: on,
      );

  test('changing the period re-queries the transactions', () async {
    final now = DateTime.now();
    final actions = container.read(transactionActionsProvider);
    await actions.save(draft(100, now));
    await actions.save(draft(200, DateTime(now.year, now.month - 1, 15)));

    // Keep the stream provider alive while we read it.
    container.listen(transactionsInPeriodProvider, (_, _) {});

    final thisMonth = await container.read(transactionsInPeriodProvider.future);
    expect(thisMonth.single.t.amountMinor, 100);

    container.read(viewPeriodProvider.notifier).previous();
    final lastMonth = await container.read(transactionsInPeriodProvider.future);
    expect(lastMonth.single.t.amountMinor, 200);
  });

  test('saving a foreign currency without live rates is refused clearly', () async {
    final actions = container.read(transactionActionsProvider);
    expect(
      () => actions.save(draft(500, DateTime.now(), currency: 'USD')),
      throwsA(isA<MissingExchangeRate>()),
    );
  });
}
