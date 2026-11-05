import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:money_tracker/AppAPI/currency_provider.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/database.dart';
import 'package:money_tracker/AppItem/date_bar.dart';

class MyInsightsForm extends StatefulWidget {
  const MyInsightsForm({super.key});

  @override
  State<MyInsightsForm> createState() => _MyInsightsFormState();
}

class _MyInsightsFormState extends State<MyInsightsForm> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  DateTime _viewingDate = DateTime.now();
  ViewMode _viewMode = ViewMode.month;

  /// Spending per category (in the selected currency) for the visible period.
  Map<String, double> _categoryTotals(List<TransactionModel> transactions) {
    final currency = CurrencyProvider();
    final totals = <String, double>{};
    for (final t in transactions) {
      if (!_viewMode.contains(_viewingDate, DateTime.parse(t.date))) continue;
      final value = currency.convertNum(t.amount, t.currency);
      totals[t.category] = (totals[t.category] ?? 0) + value;
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MyDateBar(
            viewingDate: _viewingDate,
            viewMode: _viewMode,
            onDateChanged: (date, mode) => setState(() {
              _viewingDate = date;
              _viewMode = mode;
            }),
            onCurrencyToggle: () => setState(() => CurrencyProvider().toggleCurrency()),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: FutureBuilder<List<TransactionModel>>(
              future: dbHelper.getTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final totals = _categoryTotals(snapshot.data ?? []);
                if (totals.isEmpty) return const EmptyState();

                final totalSpent = totals.values.fold(0.0, (a, b) => a + b);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: _sections(totals),
                        centerSpaceRadius: 100,
                        sectionsSpace: 2,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('TOTAL', style: AppText.label),
                        Text(
                          '${totalSpent.toStringAsFixed(2)} ${CurrencyProvider().currentCurrency}',
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

  List<PieChartSectionData> _sections(Map<String, double> totals) {
    // fl_chart draws text itself, so the font family must be set explicitly.
    final titleStyle = AppText.strong.copyWith(
      color: Colors.white,
      fontFamily: AppText.fontFamily,
    );
    var i = 0;
    return [
      for (final entry in totals.entries)
        PieChartSectionData(
          value: entry.value,
          color: AppColors.chart[i++ % AppColors.chart.length],
          title: '${entry.key}\n${entry.value.toStringAsFixed(0)}',
          radius: 80,
          titleStyle: titleStyle,
        ),
    ];
  }
}
