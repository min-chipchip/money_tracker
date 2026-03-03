import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Lists for dropdowns
List<String> category = <String>['Food', 'Drink', 'Education', 'Social Life', 'Apparels'];
List<String> account = <String>['Cash', 'Credit Card', 'Bank Account'];

class TransactionModel {
  final int? id;
  final double amount;
  final String date;
  final String category;
  final String account;
  final String reason;
  final int isHighlighted;
  final int rating;

  TransactionModel({
    this.id,
    required this.amount,
    required this.date,
    required this.category,
    required this.account,
    required this.reason,
    required this.isHighlighted,
    required this.rating,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date,
      'category': category,
      'account': account,
      'reason': reason,
      'isHighlighted': isHighlighted,
      'rating': rating,
    };
  }
}

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'money_tracker.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL, date TEXT, category TEXT, account TEXT, reason TEXT, isHighlighted INTEGER, rating INTEGER)',
        );
      },
    );
  }

  Future<void> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    print(db.path);
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions');
    return List.generate(maps.length, (i) {
      return TransactionModel(
        id: maps[i]['id'],
        amount: maps[i]['amount'],
        date: maps[i]['date'],
        category: maps[i]['category'],
        account: maps[i]['account'],
        reason: maps[i]['reason'],
        isHighlighted: maps[i]['isHighlighted'],
        rating: maps[i]['rating'],
      );
    });
  }
}

void addCategory(List<String> currentList, String newCategory) {
  if (!currentList.contains(newCategory)) {
    currentList.add(newCategory);
  }
}

void deleteCategory(List<String> currentList, String deleteCategory) {
  currentList.remove(deleteCategory);
}
