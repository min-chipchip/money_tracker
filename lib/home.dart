import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/database.dart';
import 'package:money_tracker/DropdownButton.dart';

// The actual form for adding daily entries
class MyHomeForm extends StatefulWidget {
  const MyHomeForm({super.key});

  @override
  State<MyHomeForm> createState() => _MyHomeFormState();
}

class _MyHomeFormState extends State<MyHomeForm> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final DatabaseHelper dbHelper = DatabaseHelper(); // Database Instance

  DateTime selectedDate = DateTime.now();
  bool isHighlighted = false;
  int rating = 3;

  late String selectedCategory;
  late String selectedAccount;

  @override
  void initState() {
    super.initState();
    selectedCategory = category.first;
    selectedAccount = account.first;
  }

  @override
  void dispose() {
    amountController.dispose();
    reasonController.dispose();
    super.dispose();
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

  Future<void> _submitEntry() async {
    if (amountController.text.isEmpty || double.tryParse(amountController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an amount")),
      );
      return;
    }

    final double amount = double.tryParse(amountController.text) ?? 0.1;
    final String reason = reasonController.text;
    final String date = DateFormat('yyyy-MM-dd').format(selectedDate);

    // Create the model
    final transaction = TransactionModel(
      amount: amount,
      date: date,
      category: selectedCategory,
      account: selectedAccount,
      reason: reason,
      isHighlighted: isHighlighted ? 1 : 0,
      rating: rating,
    );

    // Save to SQLite
    await dbHelper.insertTransaction(transaction);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Entry saved to Database!"),
        backgroundColor: Colors.green[400],
      ),
    );

    // Clear form
    amountController.clear();
    reasonController.clear();
    setState(() {
      rating = 3;
      isHighlighted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // --- HEADER SECTION ---
          Padding(
            padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  "MoneyTracker",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                Text(
                  "DAILY ENTRY",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // --- QUESTION SECTION ---
          Padding(
            padding: const EdgeInsets.fromLTRB(25.0, 20.0, 25.0, 0.0),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 16),
                children: [
                  const TextSpan(
                    text: "What did you\n",
                    style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: "spend money ",
                    style: TextStyle(
                      fontSize: 35,
                      color: Colors.blue[300],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(
                    text: "on?",
                    style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // --- AMOUNT & DATE ROW ---
          Padding(
            padding: const EdgeInsets.fromLTRB(25.0, 20.0, 25.0, 0.0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Amount Input
                  Expanded(
                    child: _buildInputBox(
                      label: "AMOUNT",
                      child: Row(
                        children: [
                          const Text("\$", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blue)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, fontFamily: 'Nunito'),
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
                  const SizedBox(width: 10),
                  // Date Picker
                  Expanded(
                    child: _buildInputBox(
                      label: "DATE",
                      child: InkWell(
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => selectedDate = picked);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.blue, size: 25),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('yy/MM/dd').format(selectedDate),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Nunito'),
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

          // --- CATEGORY & ACCOUNT ROW ---
          Padding(
            padding: const EdgeInsets.fromLTRB(25.0, 15.0, 25.0, 0.0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: "CATEGORY",
                      icon: Icons.category,
                      child: MyDropdownButton(
                        currentList: category,
                        selectedValue: selectedCategory,
                        onChanged: (val) => setState(() => selectedCategory = val),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: "ACCOUNT",
                      icon: Icons.account_balance_wallet,
                      child: MyDropdownButton(
                        currentList: account,
                        selectedValue: selectedAccount,
                        onChanged: (val) => setState(() => selectedAccount = val),
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
            child: _buildInputBox(
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
                  decoration: const InputDecoration(
                    hintText: "e.g. Lunch with Sarah",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),

          // --- HIGHLIGHT & IMPORTANCE ROW ---
          Padding(
            padding: const EdgeInsets.fromLTRB(25.0, 15.0, 25.0, 0.0),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Highlight Toggle
                  Expanded(
                    flex: 3,
                    child: _buildInputBox(
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
                          const Text("Highlight", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Importance Rating
                  Expanded(
                    flex: 5,
                    child: _buildInputBox(
                      child: Column(
                        children: [
                          const Text("IMPORTANCE LEVEL", style: TextStyle(color: Colors.grey, fontSize: 12)),
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
          ),

          // --- SUBMIT BUTTON ---
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 20, 25, 20),
            child: ElevatedButton(
              onPressed: _submitEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35.0)),
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Text("Submit Entry", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBox({String? label, IconData? icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (label != null)
            Row(
              children: [
                if (icon != null) ...[Icon(icon, color: Colors.blue, size: 20), const SizedBox(width: 8)],
                Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          if (label != null) const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
