import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/database.dart';

// The actual form for adding daily entries
class MyHomeForm extends StatefulWidget {
  const MyHomeForm({super.key});

  @override
  State<MyHomeForm> createState() => _MyHomeFormState();
}

class _MyHomeFormState extends State<MyHomeForm> {
  DateTime selectedDate = DateTime.now();
  bool isHighlighted = false;
  int rating = 3;

  // Helper to build the importance level circles
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // --- HEADER SECTION ---
          Padding(
            padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 0.0), // Middle ground: 50.0
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
            padding: const EdgeInsets.fromLTRB(25.0, 20.0, 25.0, 0.0), // Middle ground: 20.0
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 16),
                children: [
                  const TextSpan(
                    text: "What did you\n",
                    style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold), // Middle ground: 35
                  ),
                  TextSpan(
                    text: "spend money ",
                    style: TextStyle(
                      fontSize: 35, // Middle ground: 35
                      color: Colors.blue[300],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(
                    text: "on?",
                    style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold), // Middle ground: 35
                  ),
                ],
              ),
            ),
          ),

          // --- AMOUNT & DATE ROW ---
          Padding(
            padding: const EdgeInsets.fromLTRB(25.0, 20.0, 25.0, 0.0), // Middle ground: 20.0
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
                          padding: const EdgeInsets.only(top: 10), // Middle ground: 10
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
            padding: const EdgeInsets.fromLTRB(25.0, 15.0, 25.0, 0.0), // Middle ground: 15.0
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: "CATEGORY",
                      icon: Icons.category,
                      child: _DropdownButton(category),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: "ACCOUNT",
                      icon: Icons.account_balance_wallet,
                      child: _DropdownButton(account),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- REASON SECTION ---
          Padding(
            padding: const EdgeInsets.fromLTRB(25.0, 15.0, 25.0, 0.0), // Middle ground: 15.0
            child: _buildInputBox(
              label: "REASON (OPTIONAL)",
              icon: Icons.create,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: "e.g. Lunch with Sarah",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),

          // --- HIGHLIGHT & IMPORTANCE ROW ---
          Padding(
            padding: const EdgeInsets.fromLTRB(25.0, 15.0, 25.0, 0.0), // Middle ground: 15.0
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
            padding: const EdgeInsets.fromLTRB(25, 20, 25, 20), // Middle ground: 20.0 top
            child: ElevatedButton(
              onPressed: () => print("Submitted"),
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

  // Common UI Wrapper for form boxes
  Widget _buildInputBox({String? label, IconData? icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16.0), // Middle ground: 16.0
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

// Custom reusable Dropdown component
class _DropdownButton extends StatefulWidget {
  final List<String> currentList;
  const _DropdownButton(this.currentList);

  @override
  State<_DropdownButton> createState() => _DropdownButtonState();
}

class _DropdownButtonState extends State<_DropdownButton> {
  late String dropdownValue;

  @override
  void initState() {
    super.initState();
    dropdownValue = widget.currentList.first;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: dropdownValue,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
      isExpanded: true,
      underline: Container(),
      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Nunito'),
      onChanged: (val) => setState(() => dropdownValue = val!),
      items: widget.currentList.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
    );
  }
}
