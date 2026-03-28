import 'package:flutter/material.dart';
import 'package:money_tracker/AppItem/database.dart';
import 'package:money_tracker/AppPages/purchase_info.dart';
import 'package:money_tracker/AppItem/TextFunction.dart';

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

  void _getTabPosition(TapDownDetails details) {
    setState(() {
      _tapPosition = details.globalPosition;
    });
  }

  void _nextYear() {
    setState(() {
      _viewingDate = DateTime(_viewingDate.year + 1);
    });
  }

  void _previousYear() {
    setState(() {
      _viewingDate = DateTime(_viewingDate.year - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _viewingDate = DateTime(_viewingDate.year, _viewingDate.month + 1);
    });
  }

  void _previousMonth() {
    setState(() {
      _viewingDate = DateTime(_viewingDate.year, _viewingDate.month - 1);
    });
  }

  void _nextDay() {
    setState(() {
      _viewingDate = DateTime(
        _viewingDate.year,
        _viewingDate.month,
        _viewingDate.day + 1,
      );
    });
  }

  void _previousDay() {
    setState(() {
      _viewingDate = DateTime(
        _viewingDate.year,
        _viewingDate.month,
        _viewingDate.day - 1,
      );
    });
  }

  void _showContextMenu(BuildContext context, int id) async {
    final RenderObject? overlay = Overlay.of(
      context,
    ).context.findRenderObject();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (_viewmode == 1) {
                        _previousMonth();
                      } else if (_viewmode == 2) {
                        _previousYear();
                      } else {
                        _previousDay();
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[200],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(40, 5, 40, 5),
                      child: customText(
                        (_viewmode == 1
                            ? "${_viewingDate.month.toString().padLeft(2, '0')}/${_viewingDate.year}"
                            : (_viewmode == 2
                                  ? _viewingDate.year.toString()
                                  : "${_viewingDate.day.toString().padLeft(2, '0')}/${_viewingDate.month.toString().padLeft(2, '0')}/${_viewingDate.year}")),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_viewmode == 1) {
                        _nextMonth();
                      } else if (_viewmode == 2) {
                        _nextYear();
                      } else {
                        _nextDay();
                      }
                    },
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.blue),
              onPressed: () {
                setState(() {
                  _viewmode = (_viewmode + 1) % 3;
                });
              },
            ),
            Expanded(
              child: FutureBuilder<List<TransactionModel>>(
                future: dbHelper.getTransactions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: customText("Error: ${snapshot.error}"));
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

  Widget _buildTransactionCard(TransactionModel item) {
    return GestureDetector(
      onTapDown: _getTabPosition,
      onLongPress: () => _showContextMenu(context, item.id!),
      onDoubleTap: () => _showContextMenu(context, item.id!),
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
      child: Card(
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
            "${item.category} - ${item.amount} ${item.currency}",
            fontWeight: FontWeight.bold,
          ),
          subtitle: customText(
            "${item.date} (${item.account})${item.reason.isNotEmpty ? "\n${item.reason}" : ""}",
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
      ),
    );
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
}
