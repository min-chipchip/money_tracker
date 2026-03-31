import 'package:flutter/material.dart';
import 'package:money_tracker/AppItem/database.dart';
import 'package:money_tracker/AppPages/purchase_info.dart';
import 'package:money_tracker/AppItem/TextFunction.dart';
import 'package:money_tracker/AppAPI/currency_services.dart';
import 'package:money_tracker/AppAPI/currency.dart';
import 'package:money_tracker/AppAPI/currency_provider.dart';
import 'package:money_tracker/AppItem/DateBar.dart';

class MyStatsPage extends StatefulWidget {
  const MyStatsPage({super.key});

  @override
  State<MyStatsPage> createState() => _MyStatsPageState();
}

class _MyStatsPageState extends State<MyStatsPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  Offset _tapPosition = Offset.zero;

  DateTime _viewingDate = DateTime.now();
  int _viewmode = 1;

  @override
  void initState() {
    super.initState();
  }

  void nextYear() => setState(() => _viewingDate = DateTime(_viewingDate.year + 1));
  void previousYear() => setState(() => _viewingDate = DateTime(_viewingDate.year - 1));
  void nextMonth() => setState(() => _viewingDate = DateTime(_viewingDate.year, _viewingDate.month + 1));
  void previousMonth() => setState(() => _viewingDate = DateTime(_viewingDate.year, _viewingDate.month - 1));
  void nextDay() => setState(() => _viewingDate = DateTime(_viewingDate.year, _viewingDate.month, _viewingDate.day + 1));
  void previousDay() => setState(() => _viewingDate = DateTime(_viewingDate.year, _viewingDate.month, _viewingDate.day - 1));


  void getTabPosition(TapDownDetails details) {
    setState(() {
      _tapPosition = details.globalPosition;
    });
  }

  void showContextMenu(BuildContext context, int id) async {
    final RenderObject? overlay = Overlay
        .of(
      context,
    )
        .context
        .findRenderObject();

    final result = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(_tapPosition.dx, _tapPosition.dy, 30, 30),
        Rect.fromLTWH(
          0,
          0,
          overlay!.paintBounds.size.width,
          overlay!.paintBounds.size.height,
        ),
      ),
      items: [
        PopupMenuItem(value: "erase", child: customText('Delete this entry')),
        PopupMenuItem(
          value: "importance",
          child: customText('Change importance'),
        ),
      ],
    );

    if (result == "erase") {
      await dbHelper.deleteTransaction(id);
      setState(() {}); // Refresh the list
    }

    if (result == "importance") {
      await dbHelper.changeImportance(id);
      setState(() {});
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pie_chart_rounded, size: 100, color: Colors.blue),
          const SizedBox(height: 20),
          customText(
            "No Data Yet",
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 10),
          customText(
            "Add some entries to see your statistics.",
            fontSize: 16,
            color: Colors.grey[600]!,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildUpperBar(),
            Expanded(
              child: FutureBuilder<List<TransactionModel>>(
                future: dbHelper.getTransactions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                        child: customText("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final transactions = (snapshot.data!).where((item) {
                    try {
                      final itemDate = DateTime.parse(item.date);
                      if (_viewmode == 1) {
                        return itemDate.month == _viewingDate.month &&
                            itemDate.year == _viewingDate.year;
                      }
                      if (_viewmode == 2) {
                        return itemDate.year == _viewingDate.year;
                      }
                      return itemDate.day == _viewingDate.day &&
                          itemDate.month == _viewingDate.month &&
                          itemDate.year == _viewingDate.year;
                    } catch (e) {
                      return false;
                    }
                  }).toList();

                  if (transactions.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25.0,
                      vertical: 20.0,
                    ),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final item = transactions[index];
                      return _buildTransactionCard(item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpperBar() {
    return MyDateBar(
      viewingDate: _viewingDate,
      viewmode: _viewmode,
      onDateChanged: (newDate, newMode){
        setState((){
          _viewingDate = newDate;
          _viewmode = newMode;
        });
      },
      onCurrencyToggle: () => setState(() => CurrencyProvider().toggleCurrency()),
    );
  }

  Widget _buildTransactionCard(TransactionModel item) {
    return GestureDetector(
      onTapDown: getTabPosition,
      onLongPress: () => showContextMenu(context, item.id!),
      onDoubleTap: () => showContextMenu(context, item.id!),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PurchaseInfo(transaction: item),
          ),
        );

        if (result == true) {
          setState(() {});
        }
      },
      child: _getTransactionCard(item),
    );
  }

  Widget _getTransactionCard(TransactionModel item){
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.monetization_on,
          color: Colors.blue,
        ),
        title: customText(
          "${item.category} - ${CurrencyProvider().convert(item.amount, item.currency)}",
          fontWeight: FontWeight.bold,
        ),
        subtitle: customText(
          "${item.date} (${item.account})${item.reason.isNotEmpty ? "\n${item
              .reason}" : ""}",
        ),
        trailing: ElevatedButton(
          onPressed: () {
            dbHelper.changeImportance(item.id!);
            setState(() {});
          },
          child: Icon(
            item.isHighlighted == 1 ? Icons.star : Icons.star_border,
            color: item.isHighlighted == 1 ? Colors.yellow[800] : Colors.grey,
          ),
        ),
        isThreeLine: item.reason.isNotEmpty,
      ),
    );
  }
}
