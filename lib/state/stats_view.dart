import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the Stats page shows: the transaction list or the spending chart.
enum StatsView { list, chart }

class StatsViewNotifier extends Notifier<StatsView> {
  @override
  StatsView build() => StatsView.list;

  void toggle() =>
      state = state == StatsView.list ? StatsView.chart : StatsView.list;
}

final statsViewProvider = NotifierProvider<StatsViewNotifier, StatsView>(
  StatsViewNotifier.new,
);
