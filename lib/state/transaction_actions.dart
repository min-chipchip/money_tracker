import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/data/repositories/fx_repository.dart';
import 'package:money_tracker/data/repositories/settings_repository.dart';
import 'package:money_tracker/data/repositories/transaction_repository.dart';
import 'package:money_tracker/state/providers.dart';

/// What the add/edit form produces: plain values, no database types.
class TransactionDraft {
  const TransactionDraft({
    this.type = TxType.expense,
    required this.accountId,
    required this.categoryId,
    required this.amountMinor,
    required this.currency,
    required this.occurredOn,
    this.note = '',
    this.isStarred = false,
    this.importance = 3,
  });

  /// Expense or income (a deposit). Transfers have their own method.
  final TxType type;
  final String accountId;
  final String categoryId;
  final int amountMinor;
  final String currency;
  final DateTime occurredOn;
  final String note;
  final bool isStarred;
  final int importance;
}

/// Thrown when saving in a foreign currency but no exchange rate is known.
class MissingExchangeRate implements Exception {
  const MissingExchangeRate(this.currency, this.base);
  final String currency;
  final String base;

  @override
  String toString() => 'No exchange rate from $currency to $base';
}

/// Saving logic shared by the add page and the edit page.
class TransactionActions {
  TransactionActions(this._transactions, this._settings, this._fx);

  final TransactionRepository _transactions;
  final SettingsRepository _settings;
  final FxRepository _fx;

  /// Adds the draft, or updates transaction [id] when given.
  Future<void> save(TransactionDraft d, {String? id}) async {
    final base = await _settings.baseCurrency();
    // The rate that applied on the transaction's own date, from the cache.
    final rate = (await _fx.ratesOn(d.occurredOn)).rate(d.currency, base);
    if (rate == null) throw MissingExchangeRate(d.currency, base);

    if (id == null) {
      await _transactions.addEntry(
        type: d.type,
        accountId: d.accountId,
        categoryId: d.categoryId,
        amountMinor: d.amountMinor,
        currency: d.currency,
        occurredOn: d.occurredOn,
        note: d.note,
        isStarred: d.isStarred,
        importance: d.importance,
        fxRateToBase: rate,
      );
    } else {
      await _transactions.updateEntry(
        id,
        type: d.type,
        accountId: d.accountId,
        categoryId: d.categoryId,
        amountMinor: d.amountMinor,
        currency: d.currency,
        occurredOn: d.occurredOn,
        note: d.note,
        isStarred: d.isStarred,
        importance: d.importance,
        fxRateToBase: rate,
      );
    }
  }
}

final transactionActionsProvider = Provider(
  (ref) => TransactionActions(
    ref.watch(transactionRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
    ref.watch(fxRepositoryProvider),
  ),
);
