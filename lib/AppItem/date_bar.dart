import 'package:flutter/material.dart';
import 'package:money_tracker/AppItem/TextFunction.dart';
import 'package:money_tracker/AppAPI/currency_provider.dart';

class MyDateBar extends StatelessWidget {
  final DateTime viewingDate;
  final int viewmode;
  final Function(DateTime, int) onDateChanged;
  final VoidCallback onCurrencyToggle;

  const MyDateBar({
    super.key,
    required this.viewingDate,
    required this.viewmode,
    required this.onDateChanged,
    required this.onCurrencyToggle,
  });

  void _handleLeft() {
    DateTime newDate;
    if (viewmode == 1) {
      newDate = DateTime(viewingDate.year, viewingDate.month - 1);
    } else if (viewmode == 2) {
      newDate = DateTime(viewingDate.year - 1, viewingDate.month);
    } else {
      newDate = DateTime(viewingDate.year, viewingDate.month, viewingDate.day - 1);
    }
    onDateChanged(newDate, viewmode);
  }

  void _handleRight() {
    DateTime newDate;
    if (viewmode == 1) {
      newDate = DateTime(viewingDate.year, viewingDate.month + 1);
    } else if (viewmode == 2) {
      newDate = DateTime(viewingDate.year + 1, viewingDate.month);
    } else {
      newDate = DateTime(viewingDate.year, viewingDate.month, viewingDate.day + 1);
    }
    onDateChanged(newDate, viewmode);
  }

  void _handleSettings() {
    int newMode = (viewmode + 1) % 3;
    onDateChanged(viewingDate, newMode);
  }

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
                onPressed: _handleLeft,
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
                    (viewmode == 1
                        ? "${viewingDate.month.toString().padLeft(2, '0')}/${viewingDate.year}"
                        : (viewmode == 2
                            ? viewingDate.year.toString()
                            : "${viewingDate.day.toString().padLeft(2, '0')}/${viewingDate.month.toString().padLeft(2, '0')}/${viewingDate.year}")),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              IconButton(
                onPressed: _handleRight,
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.blue),
              onPressed: _handleSettings,
            ),
            IconButton(
              icon: const Icon(Icons.attach_money, color: Colors.blue),
              onPressed: onCurrencyToggle,
            ),
            customText(CurrencyProvider().currentCurrency, fontWeight: FontWeight.bold),
          ],
        )
      ],
    );
  }
}
