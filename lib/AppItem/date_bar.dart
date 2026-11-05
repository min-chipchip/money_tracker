import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/state/display_currency.dart';
import 'package:money_tracker/state/stats_view.dart';
import 'package:money_tracker/state/view_period.dart';

/// ‹ 11/2026 ›  plus the day/month/year, display-currency and list/chart
/// buttons.
///
/// Reads and changes the shared period itself, so pages don't need to pass
/// dates or callbacks in: every DateBar shows the same period.
class MyDateBar extends ConsumerWidget {
  const MyDateBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(viewPeriodProvider);
    final periodNotifier = ref.read(viewPeriodProvider.notifier);
    final displayCurrency = ref.watch(displayCurrencyProvider);
    final view = ref.watch(statsViewProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: periodNotifier.previous,
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Text(period.label, style: AppText.title),
              ),
              IconButton(
                onPressed: periodNotifier.next,
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.settings, color: AppColors.primary),
              onPressed: periodNotifier.cycleMode,
            ),
            IconButton(
              icon: const Icon(Icons.attach_money, color: AppColors.primary),
              onPressed: ref.read(displayCurrencyProvider.notifier).toggle,
            ),
            Text(displayCurrency, style: AppText.strong),
            const SizedBox(width: 8),
            IconButton(
              tooltip: view == StatsView.list ? 'Show chart' : 'Show list',
              icon: Icon(
                view == StatsView.list ? Icons.pie_chart : Icons.view_list,
                color: AppColors.primary,
              ),
              onPressed: ref.read(statsViewProvider.notifier).toggle,
            ),
          ],
        ),
      ],
    );
  }
}
