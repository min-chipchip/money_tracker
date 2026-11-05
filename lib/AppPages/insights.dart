import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/date_bar.dart';
import 'package:money_tracker/data/db/app_database.dart';
import 'package:money_tracker/state/display_currency.dart';
import 'package:money_tracker/state/providers.dart';
import 'package:money_tracker/state/view_period.dart';

/// Pie chart of spending per category. The totals are computed by SQL
/// (GROUP BY in queries.drift); this page only draws them.
class MyInsightsForm extends ConsumerWidget {
  const MyInsightsForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(categoryTotalsInPeriodProvider);
    final base = ref.watch(baseCurrencyProvider).value ?? 'HKD';
    final display = ref.watch(displayCurrencyProvider);
    final exponents = ref.watch(currencyExponentsProvider);

    // Totals are stored in the base currency; convert for display if we can.
    final rate = liveRate(base, display);
    final shownCurrency = rate == null ? base : display;
    double toShown(int baseMinor) =>
        baseMinor / math.pow(10, exponents[base] ?? 2) * (rate ?? 1);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MyDateBar(),
          AspectRatio(
            aspectRatio: 1,
            child: totals.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (rows) {
                if (rows.isEmpty) return const EmptyState();
                final grandTotal = toShown(rows.fold(0, (sum, r) => sum + (r.totalMinor ?? 0)));
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: _sections(rows, toShown),
                        centerSpaceRadius: 100,
                        sectionsSpace: 2,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('TOTAL', style: AppText.label),
                        Text(
                          '${grandTotal.toStringAsFixed(exponents[shownCurrency] ?? 2)} $shownCurrency',
                          style: AppText.headline,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _sections(
    List<CategoryTotalsResult> rows,
    double Function(int baseMinor) toShown,
  ) {
    // fl_chart draws text itself, so the font family must be set explicitly.
    final titleStyle = AppText.strong.copyWith(
      color: Colors.white,
      fontFamily: AppText.fontFamily,
    );
    return [
      for (final (i, row) in rows.indexed)
        PieChartSectionData(
          value: toShown(row.totalMinor ?? 0),
          color: row.color != null ? Color(row.color!) : AppColors.chart[i % AppColors.chart.length],
          title: '${row.name}\n${toShown(row.totalMinor ?? 0).toStringAsFixed(0)}',
          radius: 80,
          titleStyle: titleStyle,
        ),
    ];
  }
}
