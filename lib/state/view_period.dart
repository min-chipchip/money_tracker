import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/core/date_range.dart';
import 'package:money_tracker/state/providers.dart';

/// How much time the Stats / Insights pages show at once.
enum ViewMode {
  day,
  month,
  year;

  /// The mode the settings button switches to: day → month → year → day.
  ViewMode get next => values[(index + 1) % values.length];

  /// Moves [date] one day/month/year forward (step = 1) or back (step = -1).
  DateTime shift(DateTime date, int step) => switch (this) {
        ViewMode.day => DateTime(date.year, date.month, date.day + step),
        ViewMode.month => DateTime(date.year, date.month + step),
        ViewMode.year => DateTime(date.year + step, date.month),
      };

  String format(DateTime date) => switch (this) {
        ViewMode.day => DateFormat('dd/MM/yyyy').format(date),
        ViewMode.month => DateFormat('MM/yyyy').format(date),
        ViewMode.year => '${date.year}',
      };
}

/// The period on screen, e.g. "November 2026, month view".
class ViewPeriod {
  const ViewPeriod(this.date, this.mode);

  final DateTime date;
  final ViewMode mode;

  String get label => mode.format(date);

  DateRange get range => switch (mode) {
        ViewMode.day => DateRange.day(date),
        ViewMode.month => DateRange.month(date),
        ViewMode.year => DateRange.year(date),
      };
}

/// Holds the period and the only ways to change it.
class ViewPeriodNotifier extends Notifier<ViewPeriod> {
  @override
  ViewPeriod build() => ViewPeriod(DateTime.now(), ViewMode.month);

  void previous() => state = ViewPeriod(state.mode.shift(state.date, -1), state.mode);
  void next() => state = ViewPeriod(state.mode.shift(state.date, 1), state.mode);
  void cycleMode() => state = ViewPeriod(state.date, state.mode.next);
}

/// ONE period shared by Stats and Insights, so they always show the same dates.
final viewPeriodProvider =
    NotifierProvider<ViewPeriodNotifier, ViewPeriod>(ViewPeriodNotifier.new);

/// Transactions in the current period. Re-queries when the period changes,
/// and re-emits when the transactions table changes.
final transactionsInPeriodProvider = StreamProvider((ref) {
  final range = ref.watch(viewPeriodProvider).range;
  return ref.watch(transactionRepositoryProvider).watchInRange(range);
});

/// Spending per category in the current period (base currency).
final categoryTotalsInPeriodProvider = StreamProvider((ref) {
  final range = ref.watch(viewPeriodProvider).range;
  return ref.watch(transactionRepositoryProvider).watchCategoryTotals(range);
});
