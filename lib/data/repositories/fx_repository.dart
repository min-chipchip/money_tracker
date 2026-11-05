import 'package:money_tracker/AppAPI/currency_services.dart';
import 'package:money_tracker/core/date_range.dart';
import 'package:money_tracker/data/db/app_database.dart';

/// A set of exchange rates, all relative to USD ("1 USD = perUsd[code]").
class FxRates {
  const FxRates(this.perUsd, {required this.approximate});

  final Map<String, double> perUsd;

  /// True while any rate in use is a built-in 'seed' value rather than a
  /// rate fetched from the API.
  final bool approximate;

  /// "1 [from] = rate [to]", or null if either currency is unknown.
  double? rate(String from, String to) {
    if (from == to) return 1;
    final f = perUsd[from];
    final t = perUsd[to];
    if (f == null || t == null) return null;
    return t / f;
  }
}

/// Fetches "1 USD = x" rates from somewhere (the API in the app, a fake in
/// tests). Returns null when nothing could be fetched.
typedef RateFetcher = Future<Map<String, double>?> Function();

/// Exchange rates, cached in the `exchange_rates` table.
///
/// The app never asks the network for a rate. It always reads the database,
/// which is why conversion works offline. The network only WRITES into the
/// database (see [refreshFromApi]); streams then update every screen.
class FxRepository {
  FxRepository(this._db, {RateFetcher? fetcher, DateTime Function()? clock})
      : _fetch = fetcher ?? _fetchFromApi,
        _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final RateFetcher _fetch;
  final DateTime Function() _clock;

  static Future<Map<String, double>?> _fetchFromApi() async =>
      (await RemoteService().get())?.data;

  static FxRates _toRates(List<RatesOnResult> rows) => FxRates(
        {for (final r in rows) r.quote: r.perUsd},
        approximate: rows.any((r) => r.source == 'seed'),
      );

  /// Latest known rates; re-emits whenever new rates are saved.
  Stream<FxRates> watchLatest() => _db.ratesOn('9999-12-31').watch().map(_toRates);

  /// The rates that applied on [date]: for each currency, the newest rate on
  /// or before that day. Used when saving a transaction, so a back-dated
  /// entry is valued at (roughly) the rate of its own day.
  Future<FxRates> ratesOn(DateTime date) async => _toRates(await _db.ratesOn(dateKey(date)).get());

  /// Fetches today's rates and stores them, keeping only currencies the app
  /// knows (the API returns ~30; `quote` has a foreign key to currencies).
  /// Returns true if rates were saved. Never throws: being offline is normal.
  Future<bool> refreshFromApi() async {
    final Map<String, double>? fetched;
    try {
      fetched = await _fetch();
    } catch (_) {
      return false;
    }
    if (fetched == null || fetched.isEmpty) return false;

    final known = {for (final c in await _db.select(_db.currencies).get()) c.code};
    final today = dateKey(_clock());
    final now = _clock().millisecondsSinceEpoch;
    final rows = [
      for (final MapEntry(key: code, value: rate) in fetched.entries)
        if (known.contains(code) && rate > 0)
          ExchangeRatesCompanion.insert(
            rateDate: today,
            quote: code,
            perUsd: rate,
            source: 'api',
            fetchedAt: now,
          ),
    ];
    if (rows.isEmpty) return false;

    // Upsert: fetching twice on the same day just overwrites that day's rows.
    await _db.batch((b) => b.insertAllOnConflictUpdate(_db.exchangeRates, rows));
    return true;
  }
}
