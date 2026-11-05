import 'package:flutter/material.dart';
import 'package:money_tracker/AppAPI/currency_provider.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/database.dart';
import 'package:money_tracker/AppItem/date_bar.dart';
import 'package:money_tracker/AppItem/transaction_card.dart';
import 'package:money_tracker/AppPages/purchase_info.dart';

class MyStatsPage extends StatefulWidget {
  const MyStatsPage({super.key});

  @override
  State<MyStatsPage> createState() => _MyStatsPageState();
}

class _MyStatsPageState extends State<MyStatsPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  Offset _tapPosition = Offset.zero;
  DateTime _viewingDate = DateTime.now();
  ViewMode _viewMode = ViewMode.month;

  Future<void> _toggleStar(int id) async {
    await dbHelper.changeImportance(id);
    setState(() {});
  }

  Future<void> _showContextMenu(int id) async {
    final overlay = Overlay.of(context).context.findRenderObject()!;
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(_tapPosition.dx, _tapPosition.dy, 30, 30),
        Offset.zero & overlay.paintBounds.size,
      ),
      items: const [
        PopupMenuItem(value: 'erase', child: Text('Delete this entry')),
        PopupMenuItem(value: 'importance', child: Text('Change importance')),
      ],
    );

    if (result == 'erase') {
      await dbHelper.deleteTransaction(id);
      setState(() {}); // refresh the list
    } else if (result == 'importance') {
      await _toggleStar(id);
    }
  }

  Future<void> _openDetails(TransactionModel item) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PurchaseInfo(transaction: item)),
    );
    if (saved == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
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
          Expanded(
            child: FutureBuilder<List<TransactionModel>>(
              future: dbHelper.getTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final transactions = (snapshot.data ?? [])
                    .where((t) => _viewMode.contains(_viewingDate, DateTime.parse(t.date)))
                    .toList();
                if (transactions.isEmpty) return const EmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final item = transactions[index];
                    return GestureDetector(
                      onTapDown: (details) => _tapPosition = details.globalPosition,
                      onTap: () => _openDetails(item),
                      onLongPress: () => _showContextMenu(item.id!),
                      onDoubleTap: () => _showContextMenu(item.id!),
                      child: TransactionCard(
                        item: item,
                        onToggleStar: () => _toggleStar(item.id!),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
