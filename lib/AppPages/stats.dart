import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/date_bar.dart';
import 'package:money_tracker/AppItem/spending_chart.dart';
import 'package:money_tracker/AppItem/transaction_card.dart';
import 'package:money_tracker/AppPages/purchase_info.dart';
import 'package:money_tracker/data/db/app_database.dart';
import 'package:money_tracker/state/display_currency.dart';
import 'package:money_tracker/state/providers.dart';
import 'package:money_tracker/state/stats_view.dart';
import 'package:money_tracker/state/view_period.dart';

/// Transaction history for the selected period.
///
/// No setState after saving/deleting: the list is a stream from the
/// database, so it updates itself whenever the data changes.
class MyStatsPage extends ConsumerStatefulWidget {
  const MyStatsPage({super.key});

  @override
  ConsumerState<MyStatsPage> createState() => _MyStatsPageState();
}

class _MyStatsPageState extends ConsumerState<MyStatsPage> {
  Offset _tapPosition = Offset.zero; // where the context menu opens

  Future<void> _showContextMenu(String id) async {
    final overlay = Overlay.of(context).context.findRenderObject()!;
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(_tapPosition.dx, _tapPosition.dy, 30, 30),
        Offset.zero & overlay.paintBounds.size,
      ),
      items: const [
        PopupMenuItem(value: 'delete', child: Text('Delete this entry')),
        PopupMenuItem(value: 'star', child: Text('Star / unstar')),
      ],
    );

    final repo = ref.read(transactionRepositoryProvider);
    if (result == 'delete') await repo.softDelete(id);
    if (result == 'star') await repo.toggleStar(id);
  }

  void _openDetails(MoneyTransaction t) {
    if (t.type == 'transfer') return; // the form only edits expenses for now
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PurchaseInfo(transaction: t)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const MyDateBar(),
          Expanded(
            // The list/chart button in the date bar flips this.
            child: switch (ref.watch(statsViewProvider)) {
              StatsView.list => _transactionList(),
              StatsView.chart => const SpendingChart(),
            },
          ),
        ],
      ),
    );
  }

  Widget _transactionList() {
    final transactions = ref.watch(transactionsInPeriodProvider);
    final displayCurrency = ref.watch(displayCurrencyProvider);
    final exponents = ref.watch(currencyExponentsProvider);

    return transactions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rows) {
        if (rows.isEmpty) return const EmptyState();
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final item = rows[index];
            return GestureDetector(
              onTapDown: (details) => _tapPosition = details.globalPosition,
              onTap: () => _openDetails(item.t),
              onLongPress: () => _showContextMenu(item.t.id),
              onDoubleTap: () => _showContextMenu(item.t.id),
              child: TransactionCard(
                item: item,
                amountText: formatForDisplay(
                  minor: item.t.amountMinor,
                  currency: item.t.currency,
                  displayCurrency: displayCurrency,
                  exponents: exponents,
                ),
                onToggleStar: () => ref
                    .read(transactionRepositoryProvider)
                    .toggleStar(item.t.id),
              ),
            );
          },
        );
      },
    );
  }
}
