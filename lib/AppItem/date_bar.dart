import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/AppAPI/currency_provider.dart';
import 'package:money_tracker/AppItem/app_theme.dart';

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

  /// Whether [date] is in the same day/month/year as [viewing].
  bool contains(DateTime viewing, DateTime date) => switch (this) {
        ViewMode.day => date.year == viewing.year &&
            date.month == viewing.month &&
            date.day == viewing.day,
        ViewMode.month => date.year == viewing.year && date.month == viewing.month,
        ViewMode.year => date.year == viewing.year,
      };

  String format(DateTime date) => switch (this) {
        ViewMode.day => DateFormat('dd/MM/yyyy').format(date),
        ViewMode.month => DateFormat('MM/yyyy').format(date),
        ViewMode.year => '${date.year}',
      };
}

class MyDateBar extends StatelessWidget {
  const MyDateBar({
    super.key,
    required this.viewingDate,
    required this.viewMode,
    required this.onDateChanged,
    required this.onCurrencyToggle,
  });

  final DateTime viewingDate;
  final ViewMode viewMode;
  final void Function(DateTime date, ViewMode mode) onDateChanged;
  final VoidCallback onCurrencyToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => onDateChanged(viewMode.shift(viewingDate, -1), viewMode),
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Text(viewMode.format(viewingDate), style: AppText.title),
              ),
              IconButton(
                onPressed: () => onDateChanged(viewMode.shift(viewingDate, 1), viewMode),
                icon: const Icon(Icons.arrow_forward_ios, color: AppColors.primary),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.settings, color: AppColors.primary),
              onPressed: () => onDateChanged(viewingDate, viewMode.next),
            ),
            IconButton(
              icon: const Icon(Icons.attach_money, color: AppColors.primary),
              onPressed: onCurrencyToggle,
            ),
            Text(CurrencyProvider().currentCurrency, style: AppText.strong),
          ],
        ),
      ],
    );
  }
}
