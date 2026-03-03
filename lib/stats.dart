import 'package:flutter/material.dart';
import 'package:money_tracker/database.dart';

class MyStatsPage extends StatefulWidget {
  const MyStatsPage({super.key});

  @override
  State<MyStatsPage> createState() => _MyStatsPageState();
}

class _MyStatsPageState extends State<MyStatsPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Uses the background from main.dart
      body: FutureBuilder<List<TransactionModel>>(
        future: dbHelper.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final transactions = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(50.0),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final item = transactions[index];
              return Card(
                elevation: 5,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const Icon(Icons.monetization_on, color: Colors.blue),
                  title: Text("${item.category} - \$${item.amount}"),
                  subtitle: Text("${item.date} (${item.account})"),
                  trailing: Icon(
                    item.isHighlighted == 1 ? Icons.star : Icons.star_border,
                    color: item.isHighlighted == 1 ? Colors.yellow[800] : Colors.grey,
                  ),
                ),
              );
            },
          );
        },
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
          const Text(
            "No Data Yet",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Nunito'),
          ),
          const SizedBox(height: 10),
          Text(
            "Add some entries to see your statistics.",
            style: TextStyle(fontSize: 16, fontFamily: 'Nunito', color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
