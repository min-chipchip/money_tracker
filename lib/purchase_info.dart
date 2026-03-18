import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/database.dart';
import 'package:money_tracker/input_box.dart';
import 'package:money_tracker/dropdown_button.dart';

class PurchaseInfo extends StatefulWidget {
  final TransactionModel transaction;

  const PurchaseInfo({super.key, required this.transaction});

  @override
  State<PurchaseInfo> createState() => _MyPurchaseInfoState();
}

class _MyPurchaseInfoState extends State<PurchaseInfo> {
  final DatabaseHelper dbHelper = DatabaseHelper();

  late TextEditingController amountController;
  late DateTime selectedDate;
  late int rating;
  late bool isHighlighted;
  late int id;
  late String selectedCategory;
  late String selectedAccount;
  late TextEditingController reasonController;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController(
      text: widget.transaction.amount.toString(),
    );
    selectedDate = DateTime.parse(widget.transaction.date);
    selectedCategory = widget.transaction.category;
    selectedAccount = widget.transaction.account;
    isHighlighted = widget.transaction.isHighlighted > 0;
    rating = widget.transaction.rating;
    id = widget.transaction.id!;
    reasonController = TextEditingController(text: widget.transaction.reason);
  }

  //
  @override
  void dispose() {
    // 3. Always dispose controllers when the widget is destroyed
    amountController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
              ),
              child: Text(
                "Return",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsGeometry.fromLTRB(25.0, 30.0, 25.0, 0.0),

              child: Text(
                "PURCHASE INFO",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25.0, 20.0, 25.0, 0.0),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amount Input
                    Expanded(
                      child: buildInputBox(
                        label: "AMOUNT",
                        child: Row(
                          children: [
                            const Text(
                              "\$",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: amountController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Nunito',
                                ),
                                decoration: const InputDecoration(
                                  hintText: "0.00",
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Date Picker
                    Expanded(
                      child: buildInputBox(
                        label: "DATE",
                        child: InkWell(
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null)
                              setState(() => selectedDate = picked);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Colors.blue,
                                  size: 25,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('yy/MM/dd').format(selectedDate),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(25.0, 15.0, 25.0, 0.0),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: buildInputBox(
                        label: "CATEGORY",
                        icon: Icons.category,
                        child: MyDropdownButton(
                          currentList: category,
                          selectedValue: selectedCategory,
                          onChanged: (val) =>
                              setState(() => selectedCategory = val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildInputBox(
                        label: "ACCOUNT",
                        icon: Icons.account_balance_wallet,
                        child: MyDropdownButton(
                          currentList: account,
                          selectedValue: selectedAccount,
                          onChanged: (val) =>
                              setState(() => selectedAccount = val),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- REASON SECTION ---
            Padding(
              padding: const EdgeInsets.fromLTRB(25.0, 15.0, 25.0, 0.0),
              child: buildInputBox(
                label: "REASON (OPTIONAL)",
                icon: Icons.create,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
              ),
            ),

            // --- HIGHLIGHT & IMPORTANCE ROW ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 0.0),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Highlight Toggle
                    Expanded(
                      flex: 3,
                      child: buildInputBox(
                        child: Center(
                          child: Column(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.star,
                                  color: isHighlighted
                                      ? Colors.yellow[800]
                                      : Colors.grey[400],
                                  size: 35,
                                ),
                                onPressed: () => setState(
                                  () => isHighlighted = !isHighlighted,
                                ),
                              ),
                              const Text(
                                "Highlight",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Importance Rating
                    Expanded(
                      flex: 5,
                      child: buildInputBox(
                        child: Column(
                          children: [
                            const Text(
                              "IMPORTANCE LEVEL",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                1,
                                2,
                                3,
                                4,
                                5,
                              ].map((e) => ratingCircle(e)).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 20),
              child: ElevatedButton(
                onPressed: _editEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "Edit Entry",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget ratingCircle(int value) {
    bool isSelected = rating >= value;
    return GestureDetector(
      onTap: () => setState(() => rating = value),
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Colors.blue : Colors.grey[200],
        ),
        child: Center(
          child: Text(
            value.toString(),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _editEntry() async {
    final double amount = double.tryParse(amountController.text) ?? 0.0;
    final String reason = reasonController.text;
    final String date = DateFormat('yyyy-MM-dd').format(selectedDate);

    TransactionModel updatedTransaction = TransactionModel(
      id: id,
      //Original ID
      amount: amount,
      date: date,
      category: selectedCategory,
      account: selectedAccount,
      reason: reason,
      isHighlighted: isHighlighted ? 1 : 0,
      // Convert bool back to int
      rating: rating,
    );

    await dbHelper.insertTransaction(updatedTransaction);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transaction updated successfully!")),
      );
      Navigator.pop(context, true);
    }
  }
}
