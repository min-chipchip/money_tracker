import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/AppItem/database.dart';
import 'package:money_tracker/AppItem/input_box.dart';
import 'package:money_tracker/AppItem/dropdown_button.dart';
import 'package:money_tracker/AppItem/TextFunction.dart';

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
  late String selectedCurrency;

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
    selectedCurrency = widget.transaction.currency;
    reasonController = TextEditingController(text: widget.transaction.reason);
  }

  @override
  void dispose() {
    amountController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              _buildReturnButton(),
              _buildHeader(),
              _buildAmountAndDateRow(),
              _buildCategoryAndAccountRow(),
              _buildReasonSection(),
              _buildHighlightAndImportanceRow(),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReturnButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context, false);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[100],
      ),
      child: customText(
        "Return",
        fontSize: 20,
        color: Colors.black,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25.0, 30.0, 25.0, 0.0),
      child: customText(
        "PURCHASE INFO",
        fontSize: 40,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildAmountAndDateRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25.0, 20.0, 25.0, 0.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Amount Input
            Expanded(
              child: buildInputBox(
                label: "AMOUNT",
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
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
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: MyDropdownButton(
                        currentList: const ['HKD', 'USD', 'AUD', 'EUR', 'JPY'],
                        selectedValue: selectedCurrency,
                        onChanged: (val) => setState(() => selectedCurrency = val!),
                        textSize: 20,
                        hideTriangularIcon: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
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
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
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
                        customText(
                          DateFormat('dd/MM/yy').format(selectedDate),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildCategoryAndAccountRow() {
    return Padding(
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
                  onChanged: (val) => setState(() => selectedCategory = val!),
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
                  onChanged: (val) => setState(() => selectedAccount = val!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonSection() {
    return Padding(
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
    );
  }

  Widget _buildHighlightAndImportanceRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25.0, 15.0, 25.0, 0.0),
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
                          color: isHighlighted ? Colors.yellow[800] : Colors.grey[400],
                          size: 35,
                        ),
                        onPressed: () => setState(() => isHighlighted = !isHighlighted),
                      ),
                      customText(
                        "Highlight",
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Importance Rating
            Expanded(
              flex: 5,
              child: buildInputBox(
                child: Column(
                  children: [
                    customText(
                      "IMPORTANCE LEVEL",
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [1, 2, 3, 4, 5].map((e) => ratingCircle(e)).toList(),
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

  Widget _buildSubmitButton() {
    return Padding(
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            customText(
              "Edit Entry",
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
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
          child: customText(
            value.toString(),
            color: isSelected ? Colors.white : Colors.grey[600]!,
            fontWeight: FontWeight.bold,
            fontSize: 16,
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
      amount: amount,
      date: date,
      category: selectedCategory,
      account: selectedAccount,
      reason: reason,
      isHighlighted: isHighlighted ? 1 : 0,
      rating: rating,
      currency: selectedCurrency,
    );

    await dbHelper.insertTransaction(updatedTransaction);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: customText("Transaction updated successfully!", color: Colors.white)),
      );
      Navigator.pop(context, true);
    }
  }
}
