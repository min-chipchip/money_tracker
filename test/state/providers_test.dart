import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/state/display_currency.dart';
import 'package:money_tracker/state/providers.dart';
import 'package:money_tracker/state/stats_view.dart';
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

  test('a new account appears in accountsProvider (what Home and Accounts watch)', () async {
    container.listen(accountsProvider, (_, _) {});
    expect(await container.read(accountsProvider.future), hasLength(3));

    await container.read(accountRepositoryProvider).add(
          name: 'Travel Card',
          kind: 'credit_card',
          currency: 'JPY',
          openingBalanceMinor: -5000,
        );
    // Let drift's stream notice the insert and re-run the query.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final accounts = await container.read(accountsProvider.future);
    expect(accounts.last.a.name, 'Travel Card', reason: 'new accounts sort last');
    final travel = accounts.singleWhere((r) => r.a.name == 'Travel Card');
    expect(travel.a.currency, 'JPY');
    expect(travel.balanceMinor, -5000);
  });

  test('display currency starts from the saved main currency', () async {
    container.listen(displayCurrencyProvider, (_, _) {});
    await container.read(mainCurrencyProvider.future);
    expect(container.read(displayCurrencyProvider), 'HKD'); // falls back to base

    await container.read(settingsRepositoryProvider).setMainCurrency('JPY');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(displayCurrencyProvider), 'JPY');
  });

  test('stats view toggles between list and chart', () {
    expect(container.read(statsViewProvider), StatsView.list);
    container.read(statsViewProvider.notifier).toggle();
    expect(container.read(statsViewProvider), StatsView.chart);
  });

  test('a foreign currency saves offline using the cached rate', () async {
    final now = DateTime.now();
    await container.read(transactionActionsProvider).save(draft(500, now, currency: 'USD'));

    container.listen(transactionsInPeriodProvider, (_, _) {});
    final saved = (await container.read(transactionsInPeriodProvider.future)).single.t;
    expect(saved.currency, 'USD');
    expect(saved.fxRateToBase, 7.78); // approximate seed rate USD→HKD
    expect(saved.baseAmountMinor, 3890); // $5.00 × 7.78 = HK$38.90
  });
}
